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
    
    private var requiredEnergy: Double {
        settingsManager.calculateRequiredEnergy(from: settingsManager.currentSOC, to: settingsManager.targetSOC)
    }
    
    private var socDifference: Double {
        settingsManager.targetSOC - settingsManager.currentSOC
    }
    
    var body: some View {
        NavigationView {
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
                                    Text("\(settingsManager.currentSOC, specifier: "%.0f")%")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                Slider(value: $settingsManager.currentSOC, in: 0...100, step: 1) { editing in
                                    isEditingCurrentSOC = editing
                                    if !editing {
                                        currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
                                    }
                                }
                                .accentColor(.orange)
                                
                                TextField("Current SOC %", text: $currentSOCText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onSubmit {
                                        if let value = Double(currentSOCText), value >= 0, value <= 100 {
                                            settingsManager.currentSOC = value
                                        } else {
                                            currentSOCText = String(format: "%.0f", settingsManager.currentSOC)
                                        }
                                    }
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
                                    Text("\(settingsManager.targetSOC, specifier: "%.0f")%")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                Slider(value: $settingsManager.targetSOC, in: 0...100, step: 1) { editing in
                                    isEditingTargetSOC = editing
                                    if !editing {
                                        targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                                    }
                                }
                                .accentColor(.green)
                                
                                TextField("Target SOC %", text: $targetSOCText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onSubmit {
                                        if let value = Double(targetSOCText), value >= 0, value <= 100 {
                                            settingsManager.targetSOC = value
                                        } else {
                                            targetSOCText = String(format: "%.0f", settingsManager.targetSOC)
                                        }
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
                            Text("Target charge is lower than current charge")
                                .font(.caption)
                                .foregroundColor(.red)
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
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Energy limit: \(energyNeededRounded, specifier: "%.1f") kWh")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text("(\(Int(energyNeededWh)) Wh)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        setEnergyLimit(energyWh: energyNeededWh)
                                    } label: {
                                        HStack(spacing: 6) {
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
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isPushingLimit)
                                }
                                
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
                            Text("Settings")
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                            Button {
                                showingSettings = true
                            } label: {
                                Text("Open Settings")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple)
                                    .cornerRadius(8)
                            }
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
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            PresetButton(title: "Daily\n(20-80%)", currentSOC: 20, targetSOC: 80, onTap: { current, target in
                                settingsManager.currentSOC = current
                                settingsManager.targetSOC = target
                                currentSOCText = String(format: "%.0f", current)
                                targetSOCText = String(format: "%.0f", target)
                            })
                            
                            PresetButton(title: "Road Trip\n(20-100%)", currentSOC: 20, targetSOC: 100, onTap: { current, target in
                                settingsManager.currentSOC = current
                                settingsManager.targetSOC = target
                                currentSOCText = String(format: "%.0f", current)
                                targetSOCText = String(format: "%.0f", target)
                            })
                            
                            PresetButton(title: "Top Up\n(60-90%)", currentSOC: 60, targetSOC: 90, onTap: { current, target in
                                settingsManager.currentSOC = current
                                settingsManager.targetSOC = target
                                currentSOCText = String(format: "%.0f", current)
                                targetSOCText = String(format: "%.0f", target)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
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
    let currentSOC: Double
    let targetSOC: Double
    let onTap: (Double, Double) -> Void
    
    var body: some View {
        Button {
            onTap(currentSOC, targetSOC)
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
