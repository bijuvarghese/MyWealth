//
//  MyWealthWidgetProvider.swift
//  MyWealthWidget  (widget extension target)
//
//  TimelineProvider that reads the latest WidgetSnapshot written by the main
//  app and returns a timeline. The widget refreshes automatically whenever the
//  app calls WidgetCenter.shared.reloadAllTimelines() (after any portfolio change)
//  and falls back to a daily background refresh when the app isn't running.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MyWealthEntry: TimelineEntry {
    /// The point in time this entry should be displayed.
    let date: Date
    /// The portfolio snapshot powering the widget UI.
    let snapshot: WidgetSnapshot
    /// `true` when the entry is a WidgetKit placeholder (no real data yet).
    let isPlaceholder: Bool

    // Convenience placeholder used by WidgetKit during gallery preview.
    static var placeholder: MyWealthEntry {
        MyWealthEntry(
            date: Date(),
            snapshot: .placeholder,
            isPlaceholder: true
        )
    }
}

// MARK: - Timeline Provider

struct MyWealthWidgetProvider: TimelineProvider {

    // MARK: Placeholder

    /// Called when WidgetKit needs a placeholder to show while loading.
    func placeholder(in context: Context) -> MyWealthEntry {
        .placeholder
    }

    // MARK: Snapshot

    /// Called for the widget gallery preview — return quickly with real or sample data.
    func getSnapshot(in context: Context, completion: @escaping (MyWealthEntry) -> Void) {
        let snapshot = WidgetDataStore.load() ?? .placeholder
        completion(
            MyWealthEntry(date: Date(), snapshot: snapshot, isPlaceholder: false)
        )
    }

    // MARK: Timeline

    /// Called to build the timeline of entries WidgetKit will display over time.
    ///
    /// Strategy:
    /// - Return one entry for "right now" with the latest saved snapshot.
    /// - Ask WidgetKit to re-poll at the next calendar midnight so stale data
    ///   gets a daily refresh even when the user hasn't opened the app.
    /// - The main app also calls `WidgetCenter.shared.reloadAllTimelines()` after
    ///   every portfolio change, which triggers a fresh `getTimeline` call
    ///   immediately — so in practice the widget is always current.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MyWealthEntry>) -> Void) {
        let snapshot = WidgetDataStore.load() ?? .placeholder
        let entry = MyWealthEntry(date: Date(), snapshot: snapshot, isPlaceholder: false)

        // Refresh policy: wake up at the next calendar midnight.
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}
