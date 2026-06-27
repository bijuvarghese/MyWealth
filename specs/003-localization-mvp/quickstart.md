# Quickstart: Localization MVP Validation

Use this quickstart after implementation tasks are generated and completed.

## 1. Confirm Feature Scope

- Read [spec.md](spec.md) and [plan.md](plan.md).
- Confirm the MVP locale set is still English fallback, Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, and Arabic.
- Confirm there is no in-app language picker in this MVP.

## 2. Run Focused Tests

Run localization-focused tests once they are added:

```sh
xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MyWealthTests
```

Expected coverage:

- Display labels localize while raw values remain stable.
- Unsupported locales fall back to English.
- Plural/count text handles zero, one, and many.
- Currency names localize or fall back safely.
- Backup/import payloads remain compatible.
- Widget snapshot payloads remain unchanged.
- Reminder notification identifiers remain unchanged.

## 3. Manual Locale Smoke Matrix

Check these locales:

- English
- Hindi
- Spanish
- Portuguese Brazil
- French
- German
- Simplified Chinese
- Arabic
- One unsupported locale

For each locale, inspect:

- First-launch onboarding
- Dashboard empty and populated states
- Assets and liabilities
- Add/edit forms and validation
- Currency selection/search
- Net Worth and goals
- Rates
- Briefing and FIRE
- Settings, iCloud, backup/import, reminders
- Widget placeholder and populated states
- Reminder notification body

## 4. Accessibility and Layout Checks

- Test Dynamic Type with long translated labels.
- Test VoiceOver labels for controls whose accessible text differs from visible copy.
- Test Arabic right-to-left layout in app and widgets.
- Confirm destructive actions remain clearly labeled.
- Confirm large currency totals and long currency names do not overlap controls.

## 5. Repository Hygiene

```sh
git diff --check
```

Review localization resources for:

- No provider keys
- No Firebase credentials
- No real personal financial data
- No user-entered financial labels
- No environment-specific files

## 6. Full App Gate

```sh
xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

If the full gate cannot run, document the reason and the equivalent evidence collected before delivery.
