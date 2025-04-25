//
//  PV_ChargingApp.swift
//  PV-Charging
//
//  Created by Daniel Budusan on 18.06.2024.
//

import SwiftUI

@main
struct PV_ChargingApp: App {
    @StateObject var restServices = RestServices()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(restServices)
        }
    }
}
