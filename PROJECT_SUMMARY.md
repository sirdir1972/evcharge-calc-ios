# EV Charge Calculator - Project Summary

## Project Overview
Two EV charge calculator apps with go-eCharger integration:
- **Android**: `/Users/pkormann/evcharge-calc-android` (Kotlin/Compose)
- **iOS**: `/Users/pkormann/evcharge-calc-ios` (Swift/SwiftUI)

## Key Features Implemented

### Core Functionality
- Calculate required charging energy based on current SOC, target SOC, and battery specs
- Support for battery capacity, state of health (SOH), and charge losses
- Real-time calculation updates with sliders and text input fields
- Quick charge presets (80%, 90%, 95%, 100%) that only set target SOC

### go-eCharger Integration
- **Persistent connection status** - Fixed main issue where connection status was lost on app restart
- Test connection to go-eCharger via IP address
- Push calculated energy limits directly to the charger
- Connection status persisted in SharedPreferences (Android) / UserDefaults (iOS)

### UI/UX Improvements
- **Clean design**: Single text fields for SOC input (removed redundant label+text field combinations)
- **Settings access**: Single entry point via gear icon in navigation bar (iOS HIG compliant)
- **Smart presets**: Only set target charge level, don't assume current charge level
- **Responsive design**: Text fields sync with sliders, color-coded SOC indicators

## Problem Solved
**Original Issue**: go-eCharger connection status was not persisted, so the "Set Energy Limit" button would disappear after app restarts, requiring users to re-test the connection every time.

**Solution**: Added persistent storage for `goEChargerConnectionStatus` in both apps' settings managers.

## Technical Implementation

### Android (Kotlin/Compose)
**Files Modified:**
- `SettingsManager.kt` - Added go-eCharger connection status persistence
- `SettingsScreen.kt` - Updated UI for connection testing
- `MainScreen.kt` - Added energy limit push functionality
- Fixed Compose icon deprecation warnings

**Key Classes:**
- `SettingsManager` - Handles SharedPreferences for all app settings
- `GoEChargerAPI` - HTTP client for charger communication
- `MainScreen` - Main UI with calculation and charger controls

### iOS (Swift/SwiftUI)
**Files Created/Modified:**
- `SettingsManager.swift` - UserDefaults-based settings with go-eCharger support
- `GoEChargerAPI.swift` - Async Swift HTTP client for charger API
- `ContentView.swift` - Main UI matching Android functionality
- `SettingsView.swift` - Settings form with charger configuration

**Key Features:**
- UserDefaults persistence for all settings including connection status
- Swift async/await for network calls
- SwiftUI forms and navigation following iOS design patterns

## go-eCharger API Integration
Both apps communicate with go-eCharger via HTTP JSON API:

### Test Connection
```http
GET http://{ip}/api/status?filter=car
```

### Set Energy Limit
```http
POST http://{ip}/api/set
Content-Type: application/json
{"dws": energy_in_wh}
```

## Project Structure

### Android
```
evcharge-calc-android/
├── app/src/main/java/com/example/evchargecalculator/
│   ├── MainActivity.kt
│   ├── MainScreen.kt
│   ├── SettingsScreen.kt
│   ├── SettingsManager.kt
│   └── GoEChargerAPI.kt
```

### iOS  
```
evcharge-calc-ios/
├── EVChargeCalculator.xcodeproj/
└── EVChargeCalculator/
    ├── EVChargeCalculatorApp.swift
    ├── ContentView.swift
    ├── SettingsView.swift
    ├── SettingsManager.swift
    └── GoEChargerAPI.swift
```

## Build Status
- ✅ Android: Builds successfully
- ✅ iOS: Builds successfully (minor deprecation warnings only)

## Design Decisions

### UI/UX
1. **Single text field approach**: Replaced label+text field combinations with just editable text fields for cleaner UI
2. **iOS navigation**: Settings accessible only via navigation bar gear icon (following Apple HIG)
3. **Smart presets**: Only set target SOC, don't assume current charge level (user knows their car's current state)
4. **Persistent connection**: Connection status survives app restarts for better UX

### Technical
1. **Platform-native storage**: SharedPreferences (Android) vs UserDefaults (iOS)
2. **Async networking**: Kotlin coroutines vs Swift async/await
3. **UI frameworks**: Jetpack Compose vs SwiftUI
4. **Error handling**: Both apps show connection status and API call results

## Future Considerations
- Consider adding more charger brands (currently go-eCharger specific)
- Potential for automatic current SOC detection (if car API available)
- Backup/sync settings across devices
- More sophisticated energy calculations (temperature, charging curve)

## Development Notes
- Both apps now have feature parity
- Code is clean and well-structured
- Following platform-specific design guidelines
- Persistent storage ensures good user experience
- Ready for further development or deployment

---
**Last Updated**: August 15, 2025
**Status**: Complete - Both Android and iOS apps fully functional with go-eCharger integration
