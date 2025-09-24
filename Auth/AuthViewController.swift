import UIKit

final class AuthViewController: UIViewController {

    @IBOutlet private weak var loginButton: UIButton?

    // Блокировка повторного открытия WebView
    private var isFetchingToken = false

    var onAuthorizationFinished: (() -> Void)?

    // MARK: - Action
    @IBAction private func didTapLogin(_ sender: UIButton) {
        guard !isFetchingToken else { return } // не даём открыть повторно
        isFetchingToken = true
        sender.isEnabled = false

        let webVC = WebViewViewController()
        webVC.delegate = self
        let navController = UINavigationController(rootViewController: webVC)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true) { [weak self] in
            self?.isFetchingToken = false
            sender.isEnabled = true
        }
    }

    // MARK: - OAuth
    private func exchangeAuthorizationCodeForToken(_ code: String) {
        isFetchingToken = true
        loginButton?.isEnabled = false
        UIBlockingProgressHUD.show()

        OAuth2Service.shared.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }

            UIBlockingProgressHUD.dismiss()
            self.isFetchingToken = false
            self.loginButton?.isEnabled = true

            switch result {
            case .success(let accessToken):
                OAuth2TokenStorage.shared.token = accessToken
                self.dismiss(animated: true) {
                    self.onAuthorizationFinished?()
                    NotificationCenter.default.post(name: .init("AuthSuccess"), object: nil)
                }

            case .failure:
                let alert = UIAlertController(
                    title: "Что-то пошло не так",
                    message: "Не удалось войти в систему",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Ок", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode code: String) {
        viewController.dismiss(animated: true) { [weak self] in
            self?.exchangeAuthorizationCodeForToken(code)
        }
    }

    func webViewViewControllerDidCancel(_ viewController: WebViewViewController) {
        viewController.dismiss(animated: true)
    }
}







