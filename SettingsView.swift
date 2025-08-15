import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Battery Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Battery Capacity")
                            Spacer()
                            Text("\(settingsManager.batteryCapacity, specifier: "%.1f") kWh")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.batteryCapacity, in: 10...200, step: 0.5) {
                            Text("Battery Capacity")
                        }
                        .accentColor(.blue)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("State of Health (SOH)")
                            Spacer()
                            Text("\(settingsManager.stateOfHealth, specifier: "%.1f")%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.stateOfHealth, in: 50...100, step: 0.5) {
                            Text("State of Health")
                        }
                        .accentColor(.green)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Charge Losses")
                            Spacer()
                            Text("\(settingsManager.chargeLosses, specifier: "%.1f")%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.chargeLosses, in: 5...25, step: 0.5) {
                            Text("Charge Losses")
                        }
                        .accentColor(.orange)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Calculated Values")) {
                    HStack {
                        Text("Effective Capacity")
                        Spacer()
                        Text("\(settingsManager.effectiveBatteryCapacity, specifier: "%.1f") kWh")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Usable Capacity (10-90%)")
                        Spacer()
                        Text("\(settingsManager.effectiveBatteryCapacity * 0.8, specifier: "%.1f") kWh")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(footer: Text("Adjust these values based on your EV's specifications. Battery capacity is the total kWh rating, SOH represents battery degradation over time, and charge losses account for charging inefficiencies.")) {
                    EmptyView()
                }
            }
            .navigationTitle("EV Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
