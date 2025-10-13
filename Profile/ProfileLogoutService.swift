// ProfileLogoutService.swift
import Foundation
import WebKit
import UIKit
import Kingfisher

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    private init() {}

    /// Точка входа логаута: чистим всё и переходим на сплэш.
    func logout() {
        clearAuthToken()
        cleanCookies()
        resetAppServices()
        switchToSplash()
    }

    // MARK: - Private

    private func clearAuthToken() {
        // Обнуляем OAuth-токен
        OAuth2TokenStorage.shared.token = nil

        // Чистим сетевой кэш на всякий
        URLCache.shared.removeAllCachedResponses()
    }

    private func cleanCookies() {
        // Куки для URLSession
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)

        // Данные WKWebView (LocalStorage/IndexedDB/Service Workers и пр.)
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: types) { records in
            WKWebsiteDataStore.default().removeData(ofTypes: types, for: records, completionHandler: {})
        }
    }

    private func resetAppServices() {
        // Кэш изображений
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()

        // Сервисы профиля/аватара/ленты
        ProfileService.shared.reset()
        ProfileImageService.shared.reset()
        ImagesListService.shared.reset()
    }

    private func switchToSplash() {
        DispatchQueue.main.async {
            guard
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = scene.windows.first
            else { return }

            let splash = SplashViewController()
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: {
                window.rootViewController = splash
                window.makeKeyAndVisible()
            }, completion: nil)
        }
    }
}
