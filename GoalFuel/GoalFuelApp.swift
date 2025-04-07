//
//  GoalFuelApp.swift
//  GoalFuel
//
//  Created by dsm 5e on 31.03.2025.
//

import SwiftUI

@main
struct GoalFuelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Использование @AppStorage для хранения состояния онбординга,
    // автоматически синхронизируется с UserDefaults
    @AppStorage("isOnboardingCompleted") var isOnboardingCompleted: Bool = false
    
    // При первом запуске приложения проверяем UserDefaults
    init() {
        // Загружаем сохраненное значение, если оно существует
        if UserDefaults.standard.object(forKey: "isOnboardingCompleted") != nil {
            self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
        }
    }

    var body: some Scene {
        WindowGroup {
            if isOnboardingCompleted {
                MainTabView()
            } else {
                OnboardingView(isOnboardingCompleted: $isOnboardingCompleted)
            }
        }
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    static var asiuqzoptqxbt = UIInterfaceOrientationMask.portrait {
        didSet {
            if #available(iOS 16.0, *) {
                UIApplication.shared.connectedScenes.forEach { scene in
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: asiuqzoptqxbt))
                    }
                }
                UIViewController.attemptRotationToDeviceOrientation()
            } else {
                if asiuqzoptqxbt == .landscape {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.asiuqzoptqxbt
    }
}


