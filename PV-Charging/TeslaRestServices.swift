//
//  TeslaRestServices.swift
//  PV-Charging
//
//  Created by Daniel Budusan on 15.07.2024.
//

import Foundation
import SwiftUI
import Combine

struct Response: Codable {
    let result: Bool
    let reason: String
}

struct ApiResponse: Codable {
    let response: Response
}

class TeslaRestServices: ObservableObject {
    @Published var apiToken: String
    @Published var vehicleTag: String
    @Published var chargingAmps: Int
    
    init(apiToken: String = "testtoken123456", vehicleTag: String = "LRW3E7FS8RC967514") {
        self.apiToken = apiToken
        self.vehicleTag = vehicleTag
        self.chargingAmps = 0
    }
    
    func setChargingAmps() {
        guard let url = URL(string: "http://localhost:3000/set_charging_amps") else {
            print("Invalid URL")
            return
        }
        
        // TODO: setChargingAmps
    }
    
}
