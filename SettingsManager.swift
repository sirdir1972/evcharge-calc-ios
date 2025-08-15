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
    
    // SOC persistence
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
}
