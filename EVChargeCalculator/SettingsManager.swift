import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var batteryCapacity: Double {
        didSet {
            UserDefaults.standard.set(batteryCapacity, forKey: "batteryCapacity")
        }
    }
    
    @Published var stateOfHealth: Double {
        didSet {
            UserDefaults.standard.set(stateOfHealth, forKey: "stateOfHealth")
        }
    }
    
    @Published var chargeLosses: Double {
        didSet {
            UserDefaults.standard.set(chargeLosses, forKey: "chargeLosses")
        }
    }
    
    // SOC persistence with validation
    @Published var currentSOC: Double {
        didSet {
            UserDefaults.standard.set(currentSOC, forKey: "currentSOC")
        }
    }
    
    @Published var targetSOC: Double {
        didSet {
            UserDefaults.standard.set(targetSOC, forKey: "targetSOC")
        }
    }
    
    // go-eCharger settings
    @Published var goEChargerEnabled: Bool {
        didSet {
            UserDefaults.standard.set(goEChargerEnabled, forKey: "goEChargerEnabled")
        }
    }
    
    @Published var goEChargerIpAddress: String {
        didSet {
            UserDefaults.standard.set(goEChargerIpAddress, forKey: "goEChargerIpAddress")
        }
    }
    
    @Published var goEChargerConnectionStatus: String {
        didSet {
            UserDefaults.standard.set(goEChargerConnectionStatus, forKey: "goEChargerConnectionStatus")
        }
    }
    
    // App language selection
    @Published var appLanguage: String {
        didSet {
            UserDefaults.standard.set(appLanguage, forKey: "appLanguage")
        }
    }
    
    init() {
        // Load saved values or use defaults
        self.batteryCapacity = UserDefaults.standard.object(forKey: "batteryCapacity") as? Double ?? 75.0
        self.stateOfHealth = UserDefaults.standard.object(forKey: "stateOfHealth") as? Double ?? 95.0
        self.chargeLosses = UserDefaults.standard.object(forKey: "chargeLosses") as? Double ?? 10.0
        self.currentSOC = UserDefaults.standard.object(forKey: "currentSOC") as? Double ?? 20.0
        self.targetSOC = UserDefaults.standard.object(forKey: "targetSOC") as? Double ?? 80.0
        self.goEChargerEnabled = UserDefaults.standard.object(forKey: "goEChargerEnabled") as? Bool ?? false
        self.goEChargerIpAddress = UserDefaults.standard.object(forKey: "goEChargerIpAddress") as? String ?? ""
        self.goEChargerConnectionStatus = UserDefaults.standard.object(forKey: "goEChargerConnectionStatus") as? String ?? "Not tested"
        self.appLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
    }
    
    func tr(_ key: String) -> String {
        return L10n.tr(key, lang: appLanguage)
    }
    
    // Calculate effective battery capacity considering SOH
    var effectiveBatteryCapacity: Double {
        return batteryCapacity * (stateOfHealth / 100.0)
    }
    
    // Calculate required energy including losses
    func calculateRequiredEnergy(from currentSOC: Double, to targetSOC: Double) -> Double {
        let socDifference = targetSOC - currentSOC
        let baseEnergyNeeded = effectiveBatteryCapacity * (socDifference / 100.0)
        let energyWithLosses = baseEnergyNeeded * (1.0 + chargeLosses / 100.0)
        return max(0, energyWithLosses)
    }
    
    // MARK: - Smart SOC Validation Methods
    
    /// Set current SOC with automatic constraint enforcement
    func setCurrentSOC(_ value: Double) {
        let clampedValue = min(max(value, 0), 100)
        
        // If current SOC would exceed target SOC, adjust target SOC upward
        if clampedValue > targetSOC {
            targetSOC = clampedValue
        }
        
        currentSOC = clampedValue
    }
    
    /// Set target SOC with automatic constraint enforcement
    func setTargetSOC(_ value: Double) {
        let clampedValue = min(max(value, 0), 100)
        
        // If target SOC would be less than current SOC, adjust current SOC downward
        if clampedValue < currentSOC {
            currentSOC = clampedValue
        }
        
        targetSOC = clampedValue
    }
    
    /// Check if current SOC configuration is valid
    func isSOCConfigurationValid() -> Bool {
        return currentSOC <= targetSOC
    }
    
    /// Get validation message for current SOC state
    func getSOCValidationMessage() -> String? {
        if currentSOC > targetSOC {
            return tr("error_current_exceeds_target")
        } else if targetSOC - currentSOC < 1.0 {
            return tr("error_target_higher_than_current")
        }
        return nil
    }
    
    /// Validate input string and return parsed value or nil
    func validateSOCInput(_ input: String) -> (value: Double?, error: String?) {
        guard !input.isEmpty else {
            return (nil, tr("error_required"))
        }
        
        guard let value = Double(input) else {
            return (nil, tr("error_invalid_number"))
        }
        
        if value < 0 {
            return (nil, tr("error_cannot_be_negative"))
        }
        
        if value > 100 {
            return (nil, tr("error_cannot_exceed_100"))
        }
        
        return (value, nil)
    }
}
