import UIKit

final class SplashViewController: UIViewController {
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared

    private var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupImageView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("[Splash] token is \(oauth2TokenStorage.token == nil ? "nil" : "present")")

        if oauth2TokenStorage.token != nil {
            fetchProfile()
        } else {
            presentAuthViewController()
        }
    }

    // MARK: - UI
    private func setupImageView() {
        let image = UIImage(named: "splash_screen_logo")
        imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Navigation
    private func presentAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authVC = storyboard.instantiateViewController(
            withIdentifier: "AuthViewController"
        ) as? AuthViewController else {
            assertionFailure("Не удалось найти AuthViewController")
            return
        }

        authVC.delegate = self
        authVC.modalPresentationStyle = .fullScreen
        present(authVC, animated: true)
    }

    private func switchToTabBarController() {
        DispatchQueue.main.async {
            guard
                let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene }).first,
                let window = windowScene.windows.first
            else {
                assertionFailure("Не удалось получить окно/сцену")
                return
            }

            // ВАЖНО: Storyboard ID = "TabBarController"
            let tabBar = UIStoryboard(name: "Main", bundle: .main)
                .instantiateViewController(withIdentifier: "TabBarController")

            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
                window.rootViewController = tabBar
                window.makeKeyAndVisible()
            }
        }
    }

    // MARK: - Profile
    private func fetchProfile() {
        profileService.fetchProfile { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let profile):
                print("[Splash] профиль загружен: \(profile.name)")
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()

            case .failure(let error):
                print("[Splash] ошибка загрузки профиля: \(error.localizedDescription)")
                self.presentAuthViewController()
            }
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ viewController: AuthViewController) {
        viewController.dismiss(animated: true) { [weak self] in
            print("[Splash] didAuthenticate → fetchProfile()")
            self?.fetchProfile()
        }
    }
}

