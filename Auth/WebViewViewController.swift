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
    private var progressObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserInterface()
        setupProgressObservation()
        loadAuthorizationPage()
    }

    deinit {
        progressObservation = nil
    }

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

    private func setupProgressObservation() {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
            self?.updateProgressView()
        }
        updateProgressView()
    }

    @objc private func didTapCloseButton() {
        delegate?.webViewViewControllerDidCancel(self)
    }

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

    private func extractAuthorizationCode(from url: URL) -> String? {
        if url.absoluteString.starts(with: Constants.redirectURI),
           let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let codeValue = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value {
            return codeValue
        }
        return nil
    }
}

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

