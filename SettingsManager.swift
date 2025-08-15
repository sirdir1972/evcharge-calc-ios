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
    
    init() {
        // Load saved values or use defaults
        self.batteryCapacity = UserDefaults.standard.object(forKey: "batteryCapacity") as? Double ?? 75.0
        self.stateOfHealth = UserDefaults.standard.object(forKey: "stateOfHealth") as? Double ?? 95.0
        self.chargeLosses = UserDefaults.standard.object(forKey: "chargeLosses") as? Double ?? 10.0
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
