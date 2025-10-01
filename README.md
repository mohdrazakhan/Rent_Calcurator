<div align="center">

# 🏠 Room Rent & Electricity Split Calculator

Compute fair electricity usage and rent sharing across multiple floors (rooms) with optional per‑floor rent and equal water meter distribution.

</div>

## ✨ Features

- 📊 Per-floor meter readings (last & current) + separate water meter
- 💧 Water consumption split equally across all floors
- ⚡ Automatic adjusted unit + cost calculation per floor
- 🏠 Two rent modes:
	- Legacy: Total rent applied only to Ground floor (configurable)
	- Per-floor: Individual rent amount for each floor
- 💾 Save & restore past bill calculations (history) using `SharedPreferences`
- ♻️ Persist default settings (rate, rent(s), floors, water readings)
- 🧮 Dynamic add/remove floors
- 🎨 Themed UI with Material 3 and Google Fonts

## 📸 Screens (Conceptual)
| Home | Result | Settings | History |
|------|--------|----------|---------|
| Enter readings | Per-floor totals | Configure rates/rent | Past bills |

> (Add screenshots/gifs here once you have them.)

## 🧠 Calculation Logic

Given N floors:

1. Raw floor units = `max(0, current - last)` per floor.
2. Water units = `max(0, waterCurrent - waterLast)`.
3. Equal water share per floor = `waterUnits / N`.
4. Adjusted units per floor = `rawFloor + waterShare` (new approach — no longer subtracting all water from ground).
5. Electricity cost per floor = `adjustedUnits * ratePerUnit`.
6. Rent handling:
	 - If per-floor rent enabled: use supplied rent per floor.
	 - Else if legacy mode: add full rent only to Ground (or whichever floor is marked as ground) if enabled.
7. Final per-floor total = `electricityCost + rentContribution`.
8. Grand total = sum of final per-floor totals.

## 🗂 Key Files

| File | Purpose |
|------|---------|
| `lib/src/providers/bill_provider.dart` | State management + compute + persistence |
| `lib/src/models/reading.dart` | Meter & water reading models |
| `lib/src/models/bill_result.dart` | Result aggregation (supports per-floor rent) |
| `lib/src/screens/home_screen.dart` | Data entry & navigation |
| `lib/src/screens/result_screen.dart` | Computed bill presentation |
| `lib/src/screens/settings_screen.dart` | Rate, rent modes, floors management |
| `lib/src/screens/history_screen.dart` | Saved bills list |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9+ required per `pubspec.yaml`)
- Dart SDK bundled with Flutter

### Install & Run
```bash
git clone https://github.com/your-username/rent_calculator.git
cd rent_calculator/rent_calculator
flutter pub get
flutter run -d chrome   # or macos / ios / android
```

### Build Release (examples)
```bash
flutter build apk --release
flutter build macos --release
flutter build web --release
```

## 🛠 Configuration & Usage

1. Go to Settings:
	 - Set rate per unit (₹).
	 - Choose rent mode:
		 - Toggle ON “Per-floor rent” to enter individual amounts.
		 - Toggle OFF to use single rent + optional inclusion in Ground floor.
2. Add/remove floors as needed.
3. Enter last/current readings for each floor + water readings.
4. Tap Calculate → View results.
5. Save to History for future reference.

## 💾 Persistence
Defaults and history are stored locally via `SharedPreferences` keys:
```
bill_history_v1
bill_defaults_v1
```
Backward compatibility is preserved: older history entries (without `rentPerFloor`) still deserialize.

## 🔄 Future Ideas
- CSV / PDF export
- Share via system intent
- Dark theme toggle
- Automatic OCR for meter readings
- Graphs / usage trends

## ✅ Testing (Suggested)
Add unit tests for:
- `BillProvider.computeBill()` – electricity & water distribution
- Per-floor vs legacy rent totals
- Persistence (mock SharedPreferences)

## 🤝 Contributing
PRs welcome! Please:
1. Fork & branch (`feat/your-feature`)
2. Run `flutter analyze` & ensure no new errors
3. Add/update tests when logic changes
4. Open PR with clear description

## 📄 License
MIT License – feel free to use and adapt. Add a `LICENSE` file if distributing.

## 🙏 Acknowledgements
- Flutter & Dart teams
- `provider`, `shared_preferences`, `google_fonts`, `intl`

---
If this project helps you, consider starring it ⭐ and sharing feedback. Happy calculating!
# Rent_Calcurator
