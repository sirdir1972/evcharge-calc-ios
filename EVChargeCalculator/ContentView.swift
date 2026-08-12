import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var currentSOCText: String = ""
    @State private var targetSOCText: String = ""
    @State private var showingSettings = false
    @StateObject private var goEChargerAPI = GoEChargerAPI()
    @State private var isPushingLimit = false
    @State private var pushResult: String? = nil
    @State private var pushResultIsSuccess = false
    
    // Validation states
    @State private var currentSOCError: String? = nil
    @State private var targetSOCError: String? = nil
    
    private var requiredEnergy: Double {
        settingsManager.calculateRequiredEnergy(from: settingsManager.currentSOC, to: settingsManager.targetSOC)
    }
    
    private var socDifference: Double {
        settingsManager.targetSOC - settingsManager.currentSOC
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main Content
                ScrollView {
                    VStack(spacing: 12) {
                        // Header info
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(settingsManager.tr("app_name"))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(String(format: "%.1f kWh (%.0f%% SOH)", settingsManager.effectiveBatteryCapacity, settingsManager.stateOfHealth))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Input Card
                        VStack(spacing: 16) {
                            // Current SOC
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(settingsManager.tr("current_charge"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    HStack(spacing: 2) {
                                        TextField("", text: $currentSOCText)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .font(.title3.weight(.bold))
                                            .foregroundColor(.orange)
                                            .frame(width: 44)
                                            .onChange(of: currentSOCText) { newValue in
                                                let validation = settingsManager.validateSOCInput(newValue)
                                                currentSOCError = validation.error
                                                if let value = validation.value {
                                                    settingsManager.setCurrentSOC(value)
                                                    targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                                                }
                                            }
                                        Text("%")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                                
                                Slider(value: Binding(
                                    get: { settingsManager.currentSOC },
                                    set: { newValue in
                                        settingsManager.setCurrentSOC(newValue)
                                        currentSOCText = String(format: "%.0f", newValue)
                                        targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                                        currentSOCError = nil
                                    }
                                ), in: 0...100, step: 1)
                                .accentColor(.orange)
                            }
                            
                            Divider()
                            
                            // Target SOC
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(settingsManager.tr("target_charge"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    HStack(spacing: 2) {
                                        TextField("", text: $targetSOCText)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .font(.title3.weight(.bold))
                                            .foregroundColor(.green)
                                            .frame(width: 44)
                                            .onChange(of: targetSOCText) { newValue in
                                                let validation = settingsManager.validateSOCInput(newValue)
                                                targetSOCError = validation.error
                                                if let value = validation.value {
                                                    settingsManager.setTargetSOC(value)
                                                    currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
                                                }
                                            }
                                        Text("%")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                                
                                Slider(value: Binding(
                                    get: { settingsManager.targetSOC },
                                    set: { newValue in
                                        settingsManager.setTargetSOC(newValue)
                                        targetSOCText = String(format: "%.0f", newValue)
                                        currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
                                        targetSOCError = nil
                                    }
                                ), in: 0...100, step: 1)
                                .accentColor(.green)
                                
                                // Quick Presets row directly below Target Charge
                                HStack(spacing: 8) {
                                    PresetChip(
                                        title: settingsManager.tr("preset_daily_80"),
                                        isSelected: abs(settingsManager.targetSOC - 80.0) < 0.5
                                    ) {
                                        applyPreset(80.0)
                                    }
                                    
                                    PresetChip(
                                        title: settingsManager.tr("preset_top_up_90"),
                                        isSelected: abs(settingsManager.targetSOC - 90.0) < 0.5
                                    ) {
                                        applyPreset(90.0)
                                    }
                                    
                                    PresetChip(
                                        title: settingsManager.tr("preset_road_trip_100"),
                                        isSelected: abs(settingsManager.targetSOC - 100.0) < 0.5
                                    ) {
                                        applyPreset(100.0)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // Validation warning if any
                        if let validationMessage = settingsManager.getSOCValidationMessage(), !settingsManager.isSOCConfigurationValid() {
                            HStack {
                                Text("⚠️")
                                    .font(.caption)
                                Text(String(format: settingsManager.tr("auto_adjusted_format"), validationMessage))
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.0))
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 1.0, green: 0.95, blue: 0.8))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                        }
                        
                        // Results Hero Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(settingsManager.tr("charge_required"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.2f kWh", requiredEnergy))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.blue)
                                    
                                    Text(String(
                                        format: "%d%% ➔ %d%% (%@)",
                                        Int(settingsManager.currentSOC.rounded()),
                                        Int(settingsManager.targetSOC.rounded()),
                                        String(format: settingsManager.tr("incl_losses_format"), Int(settingsManager.chargeLosses.rounded()))
                                    ))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "+%.0f%%", socDifference))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(Color(red: 0.15, green: 0.55, blue: 0.25))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(red: 0.9, green: 0.96, blue: 0.9))
                                    .cornerRadius(8)
                            }
                            
                            // go-eCharger Integration inside Hero Card
                            if settingsManager.goEChargerEnabled {
                                Divider()
                                    .padding(.vertical, 2)
                                
                                HStack {
                                    Text(String(format: settingsManager.tr("energy_limit_format"), requiredEnergy))
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(String(format: settingsManager.tr("energy_limit_wh_format"), Int((requiredEnergy * 1000).rounded())))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: {
                                    pushLimitToCharger()
                                }) {
                                    HStack {
                                        if isPushingLimit {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                            Text(settingsManager.tr("btn_pushing"))
                                                .fontWeight(.semibold)
                                        } else {
                                            Image(systemName: "paperplane.fill")
                                            Text(settingsManager.tr("btn_set_energy_limit"))
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(isPushingLimit || requiredEnergy <= 0)
                                
                                if let result = pushResult {
                                    Text(result)
                                        .font(.caption)
                                        .foregroundColor(pushResultIsSuccess ? .green : .red)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView(settingsManager: settingsManager)
            }
            .onAppear {
                currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
                targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
            }
        }
    }
    
    private func applyPreset(_ targetValue: Double) {
        settingsManager.setTargetSOC(targetValue)
        targetSOCText = String(format: "%.0f", targetValue)
        currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
        targetSOCError = nil
    }
    
    private func pushLimitToCharger() {
        guard !settingsManager.goEChargerIpAddress.isEmpty else {
            pushResult = "✗ " + settingsManager.tr("error_required")
            pushResultIsSuccess = false
            return
        }
        
        isPushingLimit = true
        pushResult = nil
        
        let energyWh = requiredEnergy * 1000.0
        Task {
            let result = await goEChargerAPI.setEnergyLimit(ipAddress: settingsManager.goEChargerIpAddress, energyWh: energyWh)
            await MainActor.run {
                isPushingLimit = false
                pushResultIsSuccess = result.success
                if result.success {
                    pushResult = settingsManager.tr("goe_limit_success")
                } else {
                    pushResult = "✗ " + (result.error ?? settingsManager.tr("failed"))
                }
            }
        }
    }
}

struct PresetChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .blue : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                )
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
