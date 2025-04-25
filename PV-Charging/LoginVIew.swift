//
//  LoginVIew.swift
//  PV-Charging
//
//  Created by Daniel Budusan on 21.06.2024.
//

import SwiftUI
import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: WebView
    
    init(parent: WebView) {
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                print("\(cookie.name) is set to \(cookie.value)")
                if cookie.name == "dp-session" {
                    DispatchQueue.main.async {
                        self.parent.restServices.accessToken = cookie.value
                        self.parent.restServices.isLoggedin = true
                        UserDefaults.standard.setAccessToken(cookie.value)
                        UserDefaults.standard.setIsLoggedIn(true)
                    }
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var restServices: RestServices
    
    func makeCoordinator() -> WebViewCoordinator {
        return WebViewCoordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct LoginView: View {
    @EnvironmentObject var restServices: RestServices
    @State private var isPresentWebView = false
   
    
    var body: some View {
        Form {
            TextField("Username", text: $restServices.userName)
                .autocapitalization(.none)

            SecureField("Password", text: $restServices.password)
                .autocapitalization(.none)
            
            Button("Login") {
                Task {
                    await restServices.requestToken(grantType: .password, isRenew: true)
                }
            }
            .buttonStyle(.borderedProminent)

        }
        .frame(maxHeight: 200)
        
        Spacer()
        Button("Login on web") {
            // 2
            isPresentWebView = true

        }
        .buttonStyle(.borderedProminent)
        .sheet(isPresented: $isPresentWebView) {
            NavigationStack {
                // 3
                WebView(url: URL(string: "https://eu5.fusionsolar.huawei.com/unisso/login.action?service=%2Funisess%2Fv1%2Fauth%3Fservice%3D%252Fnetecowebext%252Fhome%252Findex.html")!, restServices: restServices)

                    .ignoresSafeArea()
                    .navigationTitle("FusionSolar")
                    .navigationBarTitleDisplayMode(.inline)
                    
            }
        }
        Spacer()
    }
}


