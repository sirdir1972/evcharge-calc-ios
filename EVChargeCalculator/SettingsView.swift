import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var goEChargerAPI = GoEChargerAPI()
    @State private var isTestingConnection = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Battery Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Battery Capacity")
                            Spacer()
                            TextField("", value: $settingsManager.batteryCapacity, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                                .font(.body.weight(.medium))
                            Text("kWh")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.batteryCapacity, in: 10...200, step: 0.5)
                        .accentColor(.blue)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("State of Health (SOH)")
                            Spacer()
                            TextField("", value: $settingsManager.stateOfHealth, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                                .font(.body.weight(.medium))
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.stateOfHealth, in: 50...100, step: 0.5)
                        .accentColor(.green)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Charge Losses")
                            Spacer()
                            TextField("", value: $settingsManager.chargeLosses, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                                .font(.body.weight(.medium))
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.chargeLosses, in: 5...25, step: 0.5)
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
                
                Section(header: Text("go-eCharger Integration")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable go-eCharger")
                                    .font(.body)
                                Text("Push charge limits to charger")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settingsManager.goEChargerEnabled)
                                .onChange(of: settingsManager.goEChargerEnabled) { enabled in
                                    if !enabled {
                                        settingsManager.goEChargerConnectionStatus = "Not tested"
                                    }
                                }
                        }
                        
                        if settingsManager.goEChargerEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Charger IP Address")
                                    .font(.body)
                                
                                HStack {
                                    TextField("192.168.1.100", text: $settingsManager.goEChargerIpAddress)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numbersAndPunctuation)
                                        .onChange(of: settingsManager.goEChargerIpAddress) { newValue in
                                            // Only reset status if IP actually changed
                                            if newValue != settingsManager.goEChargerIpAddress {
                                                settingsManager.goEChargerConnectionStatus = "Not tested"
                                            }
                                        }
                                    
                                    Button("Test") {
                                        testConnection()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(settingsManager.goEChargerIpAddress.isEmpty || isTestingConnection)
                                }
                                
                                HStack {
                                    Text("Connection Status:")
                                        .font(.body)
                                    Spacer()
                                    Text(isTestingConnection ? "Testing..." : settingsManager.goEChargerConnectionStatus)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(connectionStatusColor)
                                }
                            }
                        }
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
    
    private var connectionStatusColor: Color {
        if isTestingConnection {
            return .blue
        } else if settingsManager.goEChargerConnectionStatus.hasPrefix("✓") {
            return .green
        } else if settingsManager.goEChargerConnectionStatus.hasPrefix("✗") {
            return .red
        } else {
            return .secondary
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        settingsManager.goEChargerConnectionStatus = "Testing..."
        
        Task {
            let result = await goEChargerAPI.testConnection(ipAddress: settingsManager.goEChargerIpAddress)
            
            await MainActor.run {
                isTestingConnection = false
                
                if result.success {
                    settingsManager.goEChargerConnectionStatus = "✓ \(result.data ?? "Connected")"
                } else {
                    settingsManager.goEChargerConnectionStatus = "✗ \(result.error ?? "Failed")"
                }
            }
        }
    }
}
