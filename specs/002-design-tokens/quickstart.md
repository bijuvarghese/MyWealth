# Quickstart: Cross-Platform Design Tokens

1. Review `specs/002-design-tokens/spec.md` for scope, affected requirement IDs, and out-of-scope behavior.
2. Review `specs/002-design-tokens/plan.md` for the first implementation slice.
3. Confirm the token catalog covers every required category in `contracts/token-catalog.md`.
4. Confirm iOS, Android, and web mappings are present or documented in `contracts/platform-handoff.md`.
5. Apply tokens first to shared, low-risk presentation primitives.
6. Inspect adopted iOS surfaces in light mode, dark mode, high contrast, Dynamic Type, VoiceOver, long-label, large-value, stale/unavailable, warning, success, and destructive states.
7. Confirm no financial behavior, persistence, sync, backup/import, server request, widget payload, notification, or analytics payload changed.
8. For future token updates, use this review process:

   - Product/design owns the token intent, naming, and cross-platform mapping.
   - Engineering owns platform adoption, validation, accessibility checks, and rollback.
   - Every token change must list affected adoption surfaces from `plan.md`.
   - Rollback means restoring the previous token value or reverting the consuming component change; no user-data migration is expected.

9. Run repository hygiene:

   ```sh
   git diff --check
   ```

10. For app code changes, run the focused tests for touched behavior, then the full gate:

   ```sh
   xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
     -destination 'platform=iOS Simulator,name=iPhone 17'
   ```
