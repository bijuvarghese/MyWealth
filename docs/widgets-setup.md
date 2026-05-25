# Wealth Map Widgets — Xcode Setup Guide

The widget source files are written. This guide walks through the one-time Xcode
project configuration needed to make them compile and run.

---

## Overview of what was added

| File | Target |
|---|---|
| `MyWealth/Core/Widget/WidgetDataStore.swift` | **Both** main app + widget extension |
| `MyWealth/Core/Widget/WidgetDataWriter.swift` | **Main app only** |
| `MyWealth/Features/Dashboard/PortfolioHistoryCoordinator.swift` | Main app (modified) |
| `MyWealthWidget/MyWealthWidgetBundle.swift` | Widget extension only |
| `MyWealthWidget/MyWealthWidgetProvider.swift` | Widget extension only |
| `MyWealthWidget/MyWealthWidgetViews.swift` | Widget extension only |
| `MyWealthWidget/Info.plist` | Widget extension only |

---

## Step 1 — Add the Widget Extension target

1. In Xcode, go to **File → New → Target**.
2. Select **Widget Extension** under the iOS section. Click **Next**.
3. Set:
   - **Product Name:** `MyWealthWidget`
   - **Include Configuration Intent:** ❌ (leave unchecked — we use `StaticConfiguration`)
4. Click **Finish**. Xcode will ask to activate the scheme — click **Activate**.
5. **Delete** the placeholder files Xcode auto-generates inside `MyWealthWidget/`
   (`MyWealthWidget.swift`, `MyWealthWidgetBundle.swift`, etc.) — our files replace them.

---

## Step 2 — Add files to the correct targets

Open the **File Inspector** (right panel) for each file and confirm Target Membership:

| File | MyWealth ✓ | MyWealthWidget ✓ |
|---|:---:|:---:|
| `WidgetDataStore.swift` | ✓ | ✓ |
| `WidgetDataWriter.swift` | ✓ | — |
| `MyWealthWidgetBundle.swift` | — | ✓ |
| `MyWealthWidgetProvider.swift` | — | ✓ |
| `MyWealthWidgetViews.swift` | — | ✓ |

`PortfolioHistoryCoordinator.swift` is already in the main app target — no change needed.

---

## Step 3 — Enable the App Group capability on BOTH targets

The widget reads data the app writes via a shared `UserDefaults` suite backed by an
**App Group**. Both targets must belong to the same group.

### On the main app target (MyWealth):
1. Select the **MyWealth** target → **Signing & Capabilities** tab.
2. Click **+ Capability** → search **App Groups** → add it.
3. Click **+** inside the App Groups box and enter:
   ```
   group.com.bv.MyWealth
   ```

### On the widget extension target (MyWealthWidget):
1. Select the **MyWealthWidget** target → **Signing & Capabilities** tab.
2. Add **App Groups** the same way.
3. Enable the same group: `group.com.bv.MyWealth`.

> The identifier `group.com.bv.MyWealth` is hard-coded in `WidgetDataStore.swift`.
> If your App Group identifier is different, update `WidgetDataStore.appGroupID`.

---

## Step 4 — Add WidgetKit to the main app target

`WidgetDataWriter.swift` imports `WidgetKit` (to call `WidgetCenter.shared.reloadAllTimelines()`).
The widget extension already links WidgetKit automatically, but the main app needs it too.

1. Select the **MyWealth** target → **General** tab → **Frameworks, Libraries, and Embedded Content**.
2. Click **+** → search **WidgetKit** → select `WidgetKit.framework` → **Add**.
   Set its embed setting to **Do Not Embed**.

---

## Step 5 — Verify the build

1. Select the **MyWealth** scheme and build (`⌘B`). It should compile cleanly.
2. Select the **MyWealthWidget** scheme and build. It should also compile cleanly.
3. Run on a simulator or device, open the Dashboard — the widget snapshot is written
   automatically. Long-press the home screen → **+** → search **Wealth Map** to add widgets.

---

## Widget sizes available

| Family | Description |
|---|---|
| Small (2×2) | Net worth in base currency on accent background |
| Medium (2×4) | Net worth + secondary currency breakdown |
| Lock Screen Circular | Abbreviated amount in a circle |
| Lock Screen Rectangular | Labelled net worth row |

---

## How data flows

```
User edits an asset / liability
        ↓
PortfolioHistoryCoordinationModifier
        ↓  (after exchange rates refresh)
coordinator.recordPortfolioHistory()   ← existing history recording
coordinator.writeWidgetSnapshot()      ← NEW: writes to App Group UserDefaults
        ↓
WidgetCenter.shared.reloadAllTimelines()
        ↓
MyWealthWidgetProvider.getTimeline()   ← widget extension reads the snapshot
        ↓
Widget UI updates on home / lock screen
```

The widget also refreshes independently at midnight each day via the
`Timeline(policy: .after(midnight))` in the provider, so it stays current even
if the user hasn't opened the app.

---

## Troubleshooting

**Widget shows "—" or placeholder data after install**
The app must be opened at least once after configuring the App Group so the
initial snapshot is written. Open the Dashboard tab; data will appear immediately.

**Build error: "No such module 'WidgetKit'" in PortfolioHistoryCoordinator**
You haven't linked WidgetKit to the main app target yet — see Step 4.

**App Group UserDefaults returns nil**
Double-check the App Group identifier matches exactly in both target entitlements
and in `WidgetDataStore.appGroupID`.
