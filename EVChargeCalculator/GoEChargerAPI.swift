import Foundation

struct GoEChargerStatus {
    let carState: Int?
    let currentAmpere: Int?
    let allowCharging: Bool?
    let energyLimit: Double?
}

struct GoEChargerResult<T> {
    let success: Bool
    let data: T?
    let error: String?
}

class GoEChargerAPI: ObservableObject {
    private let timeoutInterval: TimeInterval = 5.0
    
    func testConnection(ipAddress: String) async -> GoEChargerResult<String> {
        guard !ipAddress.isEmpty else {
            return GoEChargerResult(success: false, data: nil, error: "IP address is empty")
        }
        
        guard let url = URL(string: "http://\(ipAddress)/api/status?filter=car,typ") else {
            return GoEChargerResult(success: false, data: nil, error: "Invalid IP address format")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return GoEChargerResult(success: false, data: nil, error: "Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                return GoEChargerResult(success: false, data: nil, error: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let deviceType = json["typ"] as? String {
                        return GoEChargerResult(success: true, data: "Connected to \(deviceType)", error: nil)
                    } else {
                        return GoEChargerResult(success: true, data: "Connected successfully", error: nil)
                    }
                } else {
                    return GoEChargerResult(success: false, data: nil, error: "Invalid JSON response")
                }
            } catch {
                return GoEChargerResult(success: false, data: nil, error: "JSON parsing error: \(error.localizedDescription)")
            }
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                return GoEChargerResult(success: false, data: nil, error: "Connection timeout - charger not responding")
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                return GoEChargerResult(success: false, data: nil, error: "Connection refused - check IP address and network")
            } else {
                return GoEChargerResult(success: false, data: nil, error: "Network error: \(error.localizedDescription)")
            }
        }
    }
    
    func getStatus(ipAddress: String) async -> GoEChargerResult<GoEChargerStatus> {
        guard !ipAddress.isEmpty else {
            return GoEChargerResult(success: false, data: nil, error: "IP address is empty")
        }
        
        guard let url = URL(string: "http://\(ipAddress)/api/status?filter=car,amp,alw,dwo,acu") else {
            return GoEChargerResult(success: false, data: nil, error: "Invalid IP address format")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return GoEChargerResult(success: false, data: nil, error: "Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                return GoEChargerResult(success: false, data: nil, error: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let status = GoEChargerStatus(
                        carState: json["car"] as? Int,
                        currentAmpere: json["acu"] as? Int,
                        allowCharging: json["alw"] as? Bool,
                        energyLimit: json["dwo"] as? Double
                    )
                    return GoEChargerResult(success: true, data: status, error: nil)
                } else {
                    return GoEChargerResult(success: false, data: nil, error: "Invalid JSON response")
                }
            } catch {
                return GoEChargerResult(success: false, data: nil, error: "JSON parsing error: \(error.localizedDescription)")
            }
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                return GoEChargerResult(success: false, data: nil, error: "Connection timeout")
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                return GoEChargerResult(success: false, data: nil, error: "Connection refused")
            } else {
                return GoEChargerResult(success: false, data: nil, error: "Network error: \(error.localizedDescription)")
            }
        }
    }
    
    func setEnergyLimit(ipAddress: String, energyWh: Double) async -> GoEChargerResult<String> {
        guard !ipAddress.isEmpty else {
            return GoEChargerResult(success: false, data: nil, error: "IP address is empty")
        }
        
        let energyWhInt = Int(energyWh)
        guard let url = URL(string: "http://\(ipAddress)/api/set?dwo=\(energyWhInt)") else {
            return GoEChargerResult(success: false, data: nil, error: "Invalid IP address format")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return GoEChargerResult(success: false, data: nil, error: "Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                return GoEChargerResult(success: false, data: nil, error: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check if the setting was successful - go-eCharger may return "true" or "1" for success
                    let energyResult = json["dwo"]
                    
                    var isSuccess = false
                    
                    // Check for string "true"
                    if let stringResult = energyResult as? String {
                        isSuccess = stringResult == "true"
                    }
                    // Check for number 1 (success) or the actual energy value
                    else if let numberResult = energyResult as? NSNumber {
                        // Consider it success if we get 1 (true) or if the value matches our set value (within tolerance)
                        let numValue = numberResult.doubleValue
                        isSuccess = (numValue == 1.0) || (abs(numValue - energyWh) < 100) // 100 Wh tolerance
                    }
                    
                    if isSuccess {
                        return GoEChargerResult(success: true, data: "Energy limit set to \(energyWhInt) Wh", error: nil)
                    } else {
                        return GoEChargerResult(success: false, data: nil, error: "Failed to set energy limit: \(energyResult ?? "unknown")")
                    }
                } else {
                    return GoEChargerResult(success: false, data: nil, error: "Invalid JSON response")
                }
            } catch {
                return GoEChargerResult(success: false, data: nil, error: "JSON parsing error: \(error.localizedDescription)")
            }
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                return GoEChargerResult(success: false, data: nil, error: "Connection timeout")
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                return GoEChargerResult(success: false, data: nil, error: "Connection refused")
            } else {
                return GoEChargerResult(success: false, data: nil, error: "Network error: \(error.localizedDescription)")
            }
        }
    }
    
    func getCarStateDescription(carState: Int?) -> String {
        switch carState {
        case 0: return "Unknown/Error"
        case 1: return "Idle"
        case 2: return "Charging"
        case 3: return "Wait for car"
        case 4: return "Complete"
        case 5: return "Error"
        default: return "Unknown"
        }
    }
}
