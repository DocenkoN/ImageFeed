import UIKit

final class AuthViewController: UIViewController {

    @IBOutlet private weak var loginButton: UIButton?
    private var isFetchingToken = false

    var onAuthorizationFinished: (() -> Void)?

    @IBAction private func didTapLogin(_ sender: UIButton) {
        guard !isFetchingToken else { return }
        isFetchingToken = true
        sender.isEnabled = false

        let webViewViewController = WebViewViewController()
        webViewViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: webViewViewController)
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true) { [weak self] in
            self?.isFetchingToken = false
            sender.isEnabled = true
        }
    }

    private func exchangeAuthorizationCodeForToken(_ authorizationCode: String) {
        guard !isFetchingToken else { return }
        isFetchingToken = true
        loginButton?.isEnabled = false

        OAuth2Service.shared.fetchOAuthToken(code: authorizationCode) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isFetchingToken = false
                self.loginButton?.isEnabled = true

                switch result {
                case .success(let accessToken):
                    OAuth2TokenStorage.shared.token = accessToken
                    self.dismiss(animated: true) {
                        self.onAuthorizationFinished?()
                        NotificationCenter.default.post(name: .init("AuthSuccess"), object: nil)
                    }
                case .failure(let error):
                    let alertController = UIAlertController(
                        title: "Ошибка авторизации",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alertController, animated: true)
                }
            }
        }
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode authorizationCode: String) {
        exchangeAuthorizationCodeForToken(authorizationCode)
    }

    func webViewViewControllerDidCancel(_ viewController: WebViewViewController) {
        viewController.dismiss(animated: true)
    }
}





