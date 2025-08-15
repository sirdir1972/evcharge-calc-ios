import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var currentSOC: Double = 20.0
    @State private var targetSOC: Double = 80.0
    @State private var currentSOCText: String = "20"
    @State private var targetSOCText: String = "80"
    @State private var showingSettings = false
    @State private var isEditingCurrentSOC = false
    @State private var isEditingTargetSOC = false
    
    private var requiredEnergy: Double {
        settingsManager.calculateRequiredEnergy(from: currentSOC, to: targetSOC)
    }
    
    private var socDifference: Double {
        targetSOC - currentSOC
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
                                    Text("\(currentSOC, specifier: "%.0f")%")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                Slider(value: $currentSOC, in: 0...100, step: 1) { editing in
                                    isEditingCurrentSOC = editing
                                    if !editing {
                                        currentSOCText = String(format: "%.0f", currentSOC)
                                    }
                                }
                                .accentColor(.orange)
                                
                                TextField("Current SOC %", text: $currentSOCText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onSubmit {
                                        if let value = Double(currentSOCText), value >= 0, value <= 100 {
                                            currentSOC = value
                                        } else {
                                            currentSOCText = String(format: "%.0f", currentSOC)
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
                                    Text("\(targetSOC, specifier: "%.0f")%")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                Slider(value: $targetSOC, in: 0...100, step: 1) { editing in
                                    isEditingTargetSOC = editing
                                    if !editing {
                                        targetSOCText = String(format: "%.0f", targetSOC)
                                    }
                                }
                                .accentColor(.green)
                                
                                TextField("Target SOC %", text: $targetSOCText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onSubmit {
                                        if let value = Double(targetSOCText), value >= 0, value <= 100 {
                                            targetSOC = value
                                        } else {
                                            targetSOCText = String(format: "%.0f", targetSOC)
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
                                self.currentSOC = current
                                self.targetSOC = target
                                self.currentSOCText = String(format: "%.0f", current)
                                self.targetSOCText = String(format: "%.0f", target)
                            })
                            
                            PresetButton(title: "Road Trip\n(20-100%)", currentSOC: 20, targetSOC: 100, onTap: { current, target in
                                self.currentSOC = current
                                self.targetSOC = target
                                self.currentSOCText = String(format: "%.0f", current)
                                self.targetSOCText = String(format: "%.0f", target)
                            })
                            
                            PresetButton(title: "Top Up\n(60-90%)", currentSOC: 60, targetSOC: 90, onTap: { current, target in
                                self.currentSOC = current
                                self.targetSOC = target
                                self.currentSOCText = String(format: "%.0f", current)
                                self.targetSOCText = String(format: "%.0f", target)
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
            currentSOCText = String(format: "%.0f", currentSOC)
            targetSOCText = String(format: "%.0f", targetSOC)
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
