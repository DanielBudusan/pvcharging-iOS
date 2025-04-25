//
//  RestServices.swift
//  PV-Charging
//
//  Created by Daniel Budusan on 25.06.2024.
//

import SwiftUI

struct Description: Codable {
    let label: String
    let value: String
}

struct Node: Codable {
    let description: Description
}

struct Flow: Codable {
    let nodes: [Node]
}

struct DataObject: Codable {
    let flow: Flow
}

struct Root: Codable {
    let data: DataObject
    let success: Bool
    let failCode: Int
}

struct LoginRequest: Codable {
    let appClientId: String
    let grantType: String
    let isRenew: Bool
    let orgName: String?
    let refreshToken: String?
    let userName: String
    let value: String?
    let verifyCode: String?
    let renew: Bool
}

struct LoginResponse: Codable {
    let description: String
    let code: Int
    let data: ResponseData?
    
    struct ResponseData: Codable {
        let expires: Int
        let regionFive: Bool
        let roaRand: String
        let regionFloatIp: String
        let accessToken: String
        let refreshToken: String
    }
}

struct PlantInfo: Codable {
    var area: String?
    var curPage: Int
    var deviceType: String?
    var dns: String?
    var gridConnectedTime: String
    var installedCapacity: Double?
    var locale: String
    var pageSize: Int
    var plantStatus: String?
    var plantType: String?
    var queryTime: String?
    var searchName: String?
    var sortDir: String
    var sortId: String
    var supportMDevice: Int
    var timeZone: String?
}

struct StationListResponse: Codable {
    let data: StationList
    let success: Bool
    let failCode: Int
}

struct StationList: Codable {
    let list: [Plant]
}

struct Plant: Codable {
    let dn: String
}


enum grantType: String   {
    case password = "password"
    case refreshtoken = "refreshtoken"
    
}

extension UserDefaults {
    private enum Keys {
        static let isLoggedIn = "isLoggedIn"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let userName = "userName"
        static let roaRand = "roaRand"
        static let plantNr = "plantNr"
    }
    
    func setIsLoggedIn(_ value: Bool) {
        set(value, forKey: Keys.isLoggedIn)
    }
    
    func isLoggedIn() -> Bool {
        bool(forKey: Keys.isLoggedIn)
    }
    
    func setAccessToken(_ value: String) {
        set(value, forKey: Keys.accessToken)
    }
    
    func accessToken() -> String? {
        string(forKey: Keys.accessToken)
    }
    
    func setRefreshToken(_ value: String) {
        set(value, forKey: Keys.refreshToken)
    }
    
    func refreshToken() -> String? {
        string(forKey: Keys.refreshToken)
    }
    
    func setRoaRand(_ value: String) {
        set(value, forKey: Keys.roaRand)
    }
    
    func roaRand() -> String? {
        string(forKey: Keys.roaRand)
    }
    
    func setUserName(_ value: String) {
        set(value, forKey: Keys.userName)
    }
    
    func userName() -> String? {
        string(forKey: Keys.userName)
    }
    
    func setPlantNr(_ value: String) {
        set(value, forKey: Keys.plantNr)
    }
    
    func plantNr() -> String? {
        string(forKey: Keys.plantNr)
    }
    
    
}

class RestServices: ObservableObject {
    @Published var userName: String
    @Published var password: String
    @Published var isLoggedin: Bool
    @Published var accessToken: String
    @Published var refreshToken: String
    @Published var roaRand: String
    @Published var plantNumber: String
    @Published var pvPower = Root(data: DataObject(flow: Flow(nodes: [Node(description: Description(label: "asa", value: "123"))])), success: true, failCode: 1)
    
    init() {
        self.userName = UserDefaults.standard.userName() ?? ""
        self.password = ""
        self.isLoggedin = UserDefaults.standard.isLoggedIn()
        self.accessToken = UserDefaults.standard.accessToken() ?? ""
        self.refreshToken = UserDefaults.standard.refreshToken() ?? ""
        self.roaRand = UserDefaults.standard.roaRand() ?? ""
        self.plantNumber = UserDefaults.standard.plantNr() ?? ""
    }
    
    func logOut() {
        isLoggedin = false
        userName = ""
        UserDefaults.standard.setIsLoggedIn(isLoggedin)
        UserDefaults.standard.setUserName(userName)
    }
    
    @MainActor
    func requestStationList() async {
        guard let url = URL(string: "https://uni002eu5.fusionsolar.huawei.com:32800/rest/pvms/web/station/v1/station/station-list") else {
            print("Invalid URL")
            return
        }
        
        let requestBody = PlantInfo(curPage: 1,
                                    gridConnectedTime: "",
                                    locale: "en_US",
                                    pageSize: 10,
                                    sortDir: "DESC",
                                    sortId: "createTime",
                                    supportMDevice: 1
        )
        
        var request = URLRequest(url: url)
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.setValue("dp-session=\(accessToken)", forHTTPHeaderField: "Cookie")
            request.setValue("\(roaRand)", forHTTPHeaderField: "roaRand")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }
            
            let stationListResponse = try JSONDecoder().decode(StationListResponse.self, from: data)
            if stationListResponse.success {
                let responseData = stationListResponse.data
                print(responseData.list[0].dn)
                plantNumber = responseData.list[0].dn
                
            }
        } catch {
            print("Request failed with error: \(error)")
        }
    }
    
    @MainActor
    func requestToken(grantType: grantType, isRenew: Bool) async {
        guard let url = URL(string: "https://intl.fusionsolar.huawei.com:32800/rest/neteco/appauthen/v1/smapp/app/token") else {
            print("Invalid URL")
            return
        }
        
        let loginRequest = LoginRequest(
            appClientId: "f28c5d59eb1307e88ffc2943867931a33eaa9dbd2e246e40e60c1c12139bd960",
            grantType: grantType.rawValue,
            isRenew: isRenew,
            orgName: nil,
            refreshToken: grantType == .refreshtoken ? refreshToken : nil,
            userName: userName,
            value: grantType == .password ? password : nil,
            verifyCode: nil,
            renew: isRenew
        )
        
        do {
            let jsonData = try JSONEncoder().encode(loginRequest)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("locale=en-us; dp-session=; bspsession=; JSESSIONID=481B0CAB21DCB6C2E2932499B0E03AF1; Path=/; Secure; HttpOnly", forHTTPHeaderField: "Cookie")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            if loginResponse.code == 0 {
                print("Login successful")
                if let responseData = loginResponse.data {
                    print("AccessToken: \(responseData.accessToken)")
                    print("RefreshToken: \(responseData.refreshToken)")
                    print("RoaRand: \(responseData.roaRand)")
                    
                    accessToken = responseData.accessToken
                    refreshToken = responseData.refreshToken
                    roaRand = responseData.roaRand
                    UserDefaults.standard.setAccessToken(accessToken)
                    UserDefaults.standard.setRefreshToken(refreshToken)
                    UserDefaults.standard.setRoaRand(roaRand)
                    await requestStationList()
                    if grantType == .password {
                        isLoggedin = true
                        UserDefaults.standard.setIsLoggedIn(isLoggedin)
                        UserDefaults.standard.setUserName(userName)
                    }
                }
            } else {
                print("Login failed: \(loginResponse.description)")
            }
        } catch {
            print("Request failed with error: \(error)")
        }
    }
    
    func fetchData() async {
        guard let url = URL(string: "https://uni002eu5.fusionsolar.huawei.com:32800/rest/pvms/web/station/v1/overview/energy-flow?stationDn=\(plantNumber)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("locale=en-us; dp-session=\(accessToken); bspsession=\(accessToken); HWWAFSESID=2184119cc8548e5b51c0; path=/", forHTTPHeaderField: "Cookie")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let decodedResponse = try? JSONDecoder().decode(Root.self, from: data) {
                    
                    DispatchQueue.main.async {
                        self.pvPower = decodedResponse
                    }
                } else {
                    print("Failed to decode response")
                }
            } else {
                print("HTTP request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        } catch {
            print("Request failed with error: \(error.localizedDescription)")
        }
    }
    
    func keepAlive() async {
        guard let url = URL(string: "https://uni002eu5.fusionsolar.huawei.com/rest/dpcloud/auth/v1/keep-alive") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("dp-session=\(accessToken)", forHTTPHeaderField: "Cookie")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Keep-alive response status code: \(httpResponse.statusCode)")
            }
        } catch {
            print("Keep-alive request failed with error: \(error.localizedDescription)")
        }
    }
}
