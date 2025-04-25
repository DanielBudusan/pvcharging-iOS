//
//  ContentView.swift
//  PV-Charging
//
//  Created by Daniel Budusan on 18.06.2024.
//

import SwiftUI
import WebKit
import Combine


struct ContentView: View {
    @EnvironmentObject var restServices: RestServices
    @State private var teslaServices = TeslaRestServices()
    @State private var timerSubscription: AnyCancellable?
    @State private var countdown: Int = 300 // 5 minutes in seconds
    @State private var chargingAmps: Int = 0
    @State private var alertMessage: String = ""
    @State private var showingAlert = false
    
    var body: some View {
        if restServices.isLoggedin {
            VStack {
                Text("Next refresh in: \(countdownString())")
                    .padding()
                Text(restServices.userName)
                Text(restServices.pvPower.data.flow.nodes[0].description.value)
                    .padding()
                    .font(.largeTitle)
                Text("Token: \(restServices.accessToken)" )
                Divider()
                Text("RefreshToken: \(restServices.refreshToken)" )
                Button("Refresh PV data") {
                    Task {
                        await restServices.fetchData()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Request new token") {
                    Task {
                        await restServices.requestToken(grantType: .refreshtoken, isRenew: true)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                VStack {
                    Text("Set tesla charging amps:")
                        .font(.title)
                    Picker("Select a number (0-10)", selection: $teslaServices.chargingAmps) {
                        ForEach(0...15, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        self.submit()
                    }) {
                        Text("Set charging amps")
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Submitted Value"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
                Button("Log out") {
                    restServices.logOut()
                    stopTimer()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .onAppear {
                Task {
                    await restServices.fetchData()
                }
                startTimer()
                
            }
            .onDisappear {
                stopTimer()
                
            }
        } else {
            LoginView()
        }
    }
    
    private func submit() {
        alertMessage = "You entered: \(teslaServices.chargingAmps)"
        showingAlert = true
        }
    
    private func startTimer() {
        stopTimer()
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        timerSubscription = timer.sink { _ in
            countdown -= 1
            if countdown <= 0 {
                Task {
                    await restServices.fetchData()
                    resetCountdown()
                }
            }
        }
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    private func resetCountdown() {
        countdown = 300
    }
    
    private func countdownString() -> String {
        let minutes = countdown / 60
        let seconds = countdown % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
        .environmentObject(RestServices())
}
