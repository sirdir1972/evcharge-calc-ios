import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var currentSOCText: String = ""
    @State private var targetSOCText: String = ""
    @State private var showingSettings = false
    @State private var isEditingCurrentSOC = false
    @State private var isEditingTargetSOC = false
    @StateObject private var goEChargerAPI = GoEChargerAPI()
    @State private var isPushingLimit = false
    @State private var pushResult: String? = nil
    
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
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "ev.charger.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("EV Charge Calculator")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Main calculation card
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            // Current SOC Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "battery.25")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    Text("Current Charge")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        TextField("", text: $currentSOCText)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                            .font(.title2.weight(.semibold))
                                            .foregroundColor(currentSOCError != nil ? .red : (settingsManager.currentSOC < 20 ? .red : (settingsManager.currentSOC < 50 ? .orange : .green)))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(currentSOCError != nil ? Color.red : Color.clear, lineWidth: 1)
                                            )
                                            .onChange(of: currentSOCText) { newValue in
                                                let validation = settingsManager.validateSOCInput(newValue)
                                                currentSOCError = validation.error
                                                
                                                if let value = validation.value {
                                                    settingsManager.setCurrentSOC(value)
                                                }
                                            }
                                        
                                        if let error = currentSOCError {
                                            Text(error)
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                                .frame(maxWidth: 80, alignment: .trailing)
                                        }
                                    }
                                }
                                
                                Slider(value: Binding(
                                    get: { settingsManager.currentSOC },
                                    set: { newValue in
                                        settingsManager.setCurrentSOC(newValue)
                                        currentSOCError = nil // Clear errors when using slider
                                    }
                                ), in: 0...100, step: 1) { editing in
                                    if !editing {
                                        currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
                                    }
                                }
                                .accentColor(currentSOCError != nil ? .red : .orange)
                            }
                            
                            Divider()
                                .padding(.horizontal, -16)
                            
                            // Target SOC Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "battery.100")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                    Text("Target Charge")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        TextField("", text: $targetSOCText)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                            .font(.title2.weight(.semibold))
                                            .foregroundColor(targetSOCError != nil ? .red : (settingsManager.targetSOC < 20 ? .red : (settingsManager.targetSOC < 50 ? .orange : .green)))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(targetSOCError != nil ? Color.red : Color.clear, lineWidth: 1)
                                            )
                                            .onChange(of: targetSOCText) { newValue in
                                                let validation = settingsManager.validateSOCInput(newValue)
                                                targetSOCError = validation.error
                                                
                                                if let value = validation.value {
                                                    settingsManager.setTargetSOC(value)
                                                }
                                            }
                                        
                                        if let error = targetSOCError {
                                            Text(error)
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                                .frame(maxWidth: 80, alignment: .trailing)
                                        }
                                    }
                                }
                                
                                Slider(value: Binding(
                                    get: { settingsManager.targetSOC },
                                    set: { newValue in
                                        settingsManager.setTargetSOC(newValue)
                                        targetSOCError = nil // Clear errors when using slider
                                    }
                                ), in: 0...100, step: 1) { editing in
                                    if !editing {
                                        targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                                    }
                                }
                                .accentColor(targetSOCError != nil ? .red : .green)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    
                    // Validation warning banner
                    if let validationMessage = settingsManager.getSOCValidationMessage() {
                        HStack(spacing: 8) {
                            Text("⚠️")
                                .font(.title3)
                            Text("Auto-adjusted: \(validationMessage)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Results Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Charge Required")
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Energy Needed:")
                                Spacer()
                                Text("\(requiredEnergy, specifier: "%.2f") kWh")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("SOC Increase:")
                                Spacer()
                                Text("\(socDifference, specifier: "%.0f")%")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(socDifference >= 0 ? .green : .red)
                            }
                            
                            HStack {
                                Text("Effective Capacity:")
                                Spacer()
                                Text("\(settingsManager.effectiveBatteryCapacity, specifier: "%.1f") kWh")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if socDifference < 0 {
                            Text("Target charge is lower than current charge. Please adjust values.")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        } else if socDifference == 0 {
                            Text("Target charge equals current charge - no charging needed.")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                                .padding(.top, 8)
                        }
                        
                        // go-eCharger Control Section (only if enabled and connected)
                        if settingsManager.goEChargerEnabled &&
                           settingsManager.goEChargerConnectionStatus.hasPrefix("✓") &&
                           settingsManager.targetSOC > settingsManager.currentSOC {
                            
                            Divider()
                                .padding(.horizontal, -16)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "ev.charger.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    Text("go-eCharger Control")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    }
                                
                                let energyNeeded = settingsManager.calculateRequiredEnergy(
                                    from: settingsManager.currentSOC,
                                    to: settingsManager.targetSOC
                                )
                                let energyNeededRounded = ceil(energyNeeded * 10.0) / 10.0
                                let energyNeededWh = energyNeededRounded * 1000
                                
                                HStack {
                                    Text("Energy limit: \(energyNeededRounded, specifier: "%.1f") kWh")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("(\(Int(energyNeededWh)) Wh)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button {
                                    setEnergyLimit(energyWh: energyNeededWh)
                                } label: {
                                    HStack(spacing: 8) {
                                        if isPushingLimit {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Pushing...")
                                        } else {
                                            Image(systemName: "paperplane.fill")
                                            Text("Set Energy Limit")
                                        }
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                                .disabled(isPushingLimit)
                                
                                // Push result status
                                if let result = pushResult {
                                    Text(result)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(result.hasPrefix("✓") ? .green : .red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    
                    // Settings Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                            Text("Battery Configuration")
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Battery Capacity:")
                                Spacer()
                                Text("\(settingsManager.batteryCapacity, specifier: "%.1f") kWh")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("State of Health:")
                                Spacer()
                                Text("\(settingsManager.stateOfHealth, specifier: "%.1f")%")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(settingsManager.stateOfHealth > 90 ? .green : (settingsManager.stateOfHealth > 80 ? .orange : .red))
                            }
                            
                            HStack {
                                Text("Charge Losses:")
                                Spacer()
                                Text("\(settingsManager.chargeLosses, specifier: "%.1f")%")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    
                    // Quick presets
                    VStack(spacing: 12) {
                        Text("Quick Presets")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 12) {
                            PresetButton(title: "Daily\n80%", targetSOC: 80, onTap: { target in
                                settingsManager.setTargetSOC(target)
                                targetSOCError = nil
                                targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                            })
                            
                            PresetButton(title: "Top Up\n90%", targetSOC: 90, onTap: { target in
                                settingsManager.setTargetSOC(target)
                                targetSOCError = nil
                                targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                            })
                            
                            PresetButton(title: "Road Trip\n100%", targetSOC: 100, onTap: { target in
                                settingsManager.setTargetSOC(target)
                                targetSOCError = nil
                                targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("EV Charge Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsManager: settingsManager)
        }
        .onAppear {
            currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
            targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Clear push result when app comes back to foreground
            if pushResult != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    pushResult = nil
                }
            }
        }
    }
    
    private func setEnergyLimit(energyWh: Double) {
        isPushingLimit = true
        pushResult = nil
        
        Task {
            let result = await goEChargerAPI.setEnergyLimit(
                ipAddress: settingsManager.goEChargerIpAddress,
                energyWh: energyWh
            )
            
            await MainActor.run {
                isPushingLimit = false
                
                if result.success {
                    pushResult = "✓ Energy limit set successfully"
                } else {
                    pushResult = "✗ \(result.error ?? "Failed")"
                }
                
                // Clear result after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    pushResult = nil
                }
            }
        }
    }
}

struct PresetButton: View {
    let title: String
    let targetSOC: Double
    let onTap: (Double) -> Void
    
    var body: some View {
        Button {
            onTap(targetSOC)
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
