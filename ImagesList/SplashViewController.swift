import UIKit

final class SplashViewController: UIViewController {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let token = oauth2TokenStorage.token else {
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
            return
        }
        
        // загружаем профиль, если токен уже есть
        fetchProfile(username: token)
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
    
    private func fetchProfile(username: String) {
        profileService.fetchProfile(username: username) { result in
            switch result {
            case .success(let profile):
                print("Profile loaded: \(profile.name), \(profile.loginName), \(profile.bio ?? "")")
                
                // загружаем URL аватарки
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { result in
                    switch result {
                    case .success(let url):
                        print("Avatar URL loaded: \(url)")
                    case .failure(let error):
                        print("Failed to load avatar URL: \(error)")
                    }
                }
                
            case .failure(let error):
                print("Failed to load profile: \(error)")
            }
        }
    }
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers.first as? AuthViewController
            else {
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                return
            }
            
            viewController.onAuthorizationFinished = { [weak self] in
                guard let self = self else { return }
                
                // Загружаем профиль после авторизации
                if let token = self.oauth2TokenStorage.token {
                    self.fetchProfile(username: token)
                }
                
                self.switchToTabBarController()
            }
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}



