//
//  HistorySanitizer.swift
//  MyWealth
//
//  Removes duplicate consecutive history snapshots created by the now-fixed
//  double-recording bug (two rapid calls to recordPortfolioHistory within the
//  same run loop, both reading a stale @Query array).
//
//  Rule
//  ────
//  For each asset (grouped by identifier) sort snapshots oldest-first.
//  Delete any snapshot whose amount is within 0.01 of the immediately
//  preceding snapshot for the same asset.
//
//  This rule is safe because under normal (non-bug) operation the
//  should-record guard already prevents writing a new snapshot when the
//  amount hasn't changed.  Any consecutive same-amount pair is therefore
//  always a bug artefact.
//
//  The same rule applies to NetWorthSnapshots, grouped by currency code.

import SwiftData
import Foundation

enum HistorySanitizer {

    private static let defaultsKey = "historySanitizer.v1.didRun"

    // MARK: - Public API

    /// Removes duplicate snapshots and returns the total count deleted.
    @discardableResult
    static func sanitize(modelContext: ModelContext) throws -> Int {
        let assetDups  = try deduplicateAssetSnapshots(in: modelContext)
        let worthDups  = try deduplicateNetWorthSnapshots(in: modelContext)
        return assetDups + worthDups
    }

    /// Runs `sanitize` exactly once per installation (tracked in UserDefaults).
    /// Safe to call on every launch — subsequent calls are instant no-ops.
    static func sanitizeOnceIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: defaultsKey) else { return }
        do {
            let removed = try sanitize(modelContext: modelContext)
            UserDefaults.standard.set(true, forKey: defaultsKey)
            if removed > 0 {
                print("[HistorySanitizer] Removed \(removed) duplicate snapshot(s).")
            }
        } catch {
            print("[HistorySanitizer] Error during sanitization: \(error)")
        }
    }

    // MARK: - Asset value snapshots

    private static func deduplicateAssetSnapshots(in modelContext: ModelContext) throws -> Int {
        let all = try modelContext.fetch(
            FetchDescriptor<AssetValueSnapshot>(
                sortBy: [SortDescriptor(\.recordedAt, order: .forward)]
            )
        )

        // Group by asset identifier, preserving the chronological order from the fetch.
        var groups: [String: [AssetValueSnapshot]] = [:]
        for snapshot in all {
            groups[snapshot.displayAssetIdentifier, default: []].append(snapshot)
        }

        var removed = 0
        for snapshots in groups.values {
            var previous: AssetValueSnapshot? = nil
            for snapshot in snapshots {
                // Never deduplicate user-authored manual entries; they represent
                // deliberate valuations on a chosen date, even if the amount
                // matches the preceding snapshot.
                let isManual = snapshot.isManual ?? false
                if !isManual,
                   let prev = previous,
                   !(prev.isManual ?? false),
                   abs(prev.displayAmount - snapshot.displayAmount) < 0.01 {
                    modelContext.delete(snapshot)
                    removed += 1
                } else {
                    previous = snapshot
                }
            }
        }
        return removed
    }

    // MARK: - Net worth snapshots

    private static func deduplicateNetWorthSnapshots(in modelContext: ModelContext) throws -> Int {
        let all = try modelContext.fetch(
            FetchDescriptor<NetWorthSnapshot>(
                sortBy: [SortDescriptor(\.recordedAt, order: .forward)]
            )
        )

        var groups: [String: [NetWorthSnapshot]] = [:]
        for snapshot in all {
            groups[snapshot.displayCurrencyCode, default: []].append(snapshot)
        }

        var removed = 0
        for snapshots in groups.values {
            var previous: NetWorthSnapshot? = nil
            for snapshot in snapshots {
                if let prev = previous,
                   abs(prev.displayAmount - snapshot.displayAmount) < 0.01 {
                    modelContext.delete(snapshot)
                    removed += 1
                } else {
                    previous = snapshot
                }
            }
        }
        return removed
    }
}
