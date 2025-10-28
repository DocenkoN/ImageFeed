import UIKit
import ProgressHUD
import Kingfisher

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ProgressHUD стиль
        ProgressHUD.animationType = .systemActivityIndicator
        ProgressHUD.colorHUD = .white
        ProgressHUD.colorAnimation = .black

        // UITabBar стиль
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "YP Black (iOS)")
        appearance.selectionIndicatorImage = UIImage()
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }

        // Флаг UI-тестов
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-isUITesting")
        if isUITesting {
            UIView.setAnimationsEnabled(false)
            ImageCache.default.clearMemoryCache()
            ImageCache.default.clearDiskCache()
        }
        return true
    }

    // MARK: UISceneSession
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(
            name: "Main",
            sessionRole: connectingSceneSession.role
        )
        // Весь root делаем в SceneDelegate
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }
}


