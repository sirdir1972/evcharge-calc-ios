import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var goEChargerAPI = GoEChargerAPI()
    @State private var isTestingConnection = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(settingsManager.tr("battery_configuration"))) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(settingsManager.tr("battery_capacity"))
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
                            Text(settingsManager.tr("state_of_health"))
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
                            Text(settingsManager.tr("charge_losses"))
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
                
                Section(header: Text(settingsManager.tr("calculated_values"))) {
                    HStack {
                        Text(settingsManager.tr("effective_capacity"))
                        Spacer()
                        Text(String(format: "%.1f kWh", settingsManager.effectiveBatteryCapacity))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(settingsManager.tr("usable_capacity"))
                        Spacer()
                        Text(String(format: "%.1f kWh", settingsManager.effectiveBatteryCapacity * 0.8))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text(settingsManager.tr("goe_integration"))) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settingsManager.tr("enable_goe"))
                                    .font(.body)
                                Text(settingsManager.tr("enable_goe_desc"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settingsManager.goEChargerEnabled)
                                .onChange(of: settingsManager.goEChargerEnabled) { enabled in
                                    if !enabled {
                                        settingsManager.goEChargerConnectionStatus = settingsManager.tr("not_tested")
                                    }
                                }
                        }
                        
                        if settingsManager.goEChargerEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(settingsManager.tr("charger_ip_address"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField("192.168.1.100", text: $settingsManager.goEChargerIpAddress)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numbersAndPunctuation)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                    
                                    Button(action: {
                                        testConnection()
                                    }) {
                                        if isTestingConnection {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Text(settingsManager.tr("test"))
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(settingsManager.goEChargerIpAddress.isEmpty || isTestingConnection)
                                }
                                
                                HStack {
                                    Text(settingsManager.tr("connection_status"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(settingsManager.goEChargerConnectionStatus)
                                        .font(.caption)
                                        .foregroundColor(statusColor)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text(settingsManager.tr("language"))) {
                    Picker(settingsManager.tr("language"), selection: $settingsManager.appLanguage) {
                        ForEach(LanguageOption.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Text(settingsManager.tr("settings_description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(settingsManager.tr("ev_settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsManager.tr("done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var statusColor: Color {
        if settingsManager.goEChargerConnectionStatus.contains("Connected") || settingsManager.goEChargerConnectionStatus.contains("Verbunden") || settingsManager.goEChargerConnectionStatus.contains("Connecté") || settingsManager.goEChargerConnectionStatus.contains("Verbonden") || settingsManager.goEChargerConnectionStatus.contains("Conectado") || settingsManager.goEChargerConnectionStatus.contains("Connesso") || settingsManager.goEChargerConnectionStatus.contains("Tilkoblet") || settingsManager.goEChargerConnectionStatus.contains("Ansluten") || settingsManager.goEChargerConnectionStatus.contains("Ligado") {
            return .green
        } else if settingsManager.goEChargerConnectionStatus.contains("Failed") || settingsManager.goEChargerConnectionStatus.contains("Fehlgeschlagen") || settingsManager.goEChargerConnectionStatus.contains("Échec") || settingsManager.goEChargerConnectionStatus.contains("Mislukt") || settingsManager.goEChargerConnectionStatus.contains("Error") || settingsManager.goEChargerConnectionStatus.contains("Non riuscito") || settingsManager.goEChargerConnectionStatus.contains("Mislyktes") || settingsManager.goEChargerConnectionStatus.contains("Misslyckades") || settingsManager.goEChargerConnectionStatus.contains("Falha") {
            return .red
        } else {
            return .secondary
        }
    }
    
    private func testConnection() {
        guard !settingsManager.goEChargerIpAddress.isEmpty else { return }
        
        isTestingConnection = true
        settingsManager.goEChargerConnectionStatus = settingsManager.tr("testing")
        
        Task {
            let result = await goEChargerAPI.testConnection(ipAddress: settingsManager.goEChargerIpAddress)
            await MainActor.run {
                isTestingConnection = false
                if result.success {
                    settingsManager.goEChargerConnectionStatus = "✓ " + settingsManager.tr("connected")
                } else {
                    settingsManager.goEChargerConnectionStatus = "✗ " + settingsManager.tr("failed")
                }
            }
        }
    }
}
