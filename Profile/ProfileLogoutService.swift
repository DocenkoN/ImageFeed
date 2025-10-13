import Foundation
import WebKit
import Kingfisher
import UIKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    private init() {}

    /// Основной метод выхода
    func logout() {
        // 1) Удаляем токен авторизации
        clearAuthToken()

        // 2) Очищаем куки/веб-данные (WKWebView)
        cleanCookies()

        // 3) Чистим кэши/состояния локальных сервисов
        resetAppServices()

        // 4) Переходим на стартовый экран (без авторизации)
        switchToSplash()
    }

    // MARK: - Private

    private func clearAuthToken() {
        // Если у тебя OAuth2TokenStorage — здесь просто зануляем
        OAuth2TokenStorage.shared.token = nil
        // На всякий случай — чистим URLCache
        URLCache.shared.removeAllCachedResponses()
    }

    private func cleanCookies() {
        // Очищаем все куки из хранилища
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        // Очищаем все данные сайтов (LocalStorage, IndexedDB и т.п.)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                    for: records,
                                                    completionHandler: {})
        }
    }

    private func resetAppServices() {
        // Чистим кэш Kingfisher (изображения, аватар и т.д.)
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()

        // Если у тебя есть ProfileService — чистим профиль
        ProfileService.shared.reset()

        // Если у тебя есть ProfileImageService — чистим аватар/URL
        ProfileImageService.shared.reset()

        // Если у тебя есть ImagesListService с общим состоянием — чистим список/пагинацию
        ImagesListService.shared.reset()
    }

    private func switchToSplash() {
        DispatchQueue.main.async {
            // Находим активное окно и меняем корневой контроллер
            guard
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = scene.windows.first
            else { return }

            let splash = SplashViewController()
            window.rootViewController = splash
            window.makeKeyAndVisible()

            // Небольшая анимация, чтобы не мигало резко
            UIView.transition(with: window,
                              duration: 0.25,
                              options: [.transitionCrossDissolve],
                              animations: nil,
                              completion: nil)
        }
    }
}
