import UIKit
import WebKit

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode authorizationCode: String)
    func webViewViewControllerDidCancel(_ viewController: WebViewViewController)
}

final class WebViewViewController: UIViewController {

    private let webView: WKWebView = WKWebView()
    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.trackTintColor = .clear
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()

    weak var delegate: WebViewViewControllerDelegate?

    private var estimatedProgressObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserInterface()
        setupProgressObservation()
        loadAuthorizationPage()
    }

    // MARK: - UI
    private func setupUserInterface() {
        view.backgroundColor = .systemBackground
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view.addSubview(webView)
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapCloseButton)
        )
    }

    // MARK: - Прогресс
    private func setupProgressObservation() {
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
            options: []
        ) { [weak self] _, _ in
            guard let self = self else { return }
            self.updateProgressView()
        }
        updateProgressView()
    }

    private func updateProgressView() {
        let progress = Float(webView.estimatedProgress)
        progressView.setProgress(progress, animated: true)

        let shouldHide = abs(webView.estimatedProgress - 1.0) <= 0.0001
        if shouldHide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.progressView.isHidden = true
            }
        } else {
            progressView.isHidden = false
        }
    }

    // MARK: - Действия
    @objc private func didTapCloseButton() {
        delegate?.webViewViewControllerDidCancel(self)
    }

    // MARK: - Загрузка страницы
    private func loadAuthorizationPage() {
        do {
            let authorizationURL = try makeAuthorizationURL()
            let request = URLRequest(url: authorizationURL)
            webView.load(request)
        } catch {
            print("Ошибка формирования URL для авторизации: \(error)")
        }
    }

    private enum WebViewError: Error {
        case invalidURL
    }

    private func makeAuthorizationURL() throws -> URL {
        var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString)
        urlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        guard let url = urlComponents?.url else { throw WebViewError.invalidURL }
        return url
    }

    // MARK: - Код авторизации
    private func extractAuthorizationCode(from url: URL) -> String? {
        if url.absoluteString.starts(with: Constants.redirectURI),
           let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let codeValue = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value {
            return codeValue
        }
        return nil
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let navigationURL = navigationAction.request.url,
           let authorizationCode = extractAuthorizationCode(from: navigationURL) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: authorizationCode)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

extension URLSession {
    func object<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let task = data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
