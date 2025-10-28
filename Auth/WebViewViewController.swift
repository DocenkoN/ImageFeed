import UIKit
import WebKit

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode authorizationCode: String)
    func webViewViewControllerDidCancel(_ viewController: WebViewViewController)
}

public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

final class WebViewViewController: UIViewController & WebViewViewControllerProtocol {

    var presenter: WebViewPresenterProtocol?

    private let webView: WKWebView = {
        let wv = WKWebView()
        wv.accessibilityIdentifier = "UnsplashWebView"
        return wv
    }()
    private let progressView: UIProgressView = {
        let v = UIProgressView(progressViewStyle: .default)
        v.trackTintColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    weak var delegate: WebViewViewControllerDelegate?

    private let estimatedProgressKeyPath = #keyPath(WKWebView.estimatedProgress)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserInterface()
        webView.addObserver(self, forKeyPath: estimatedProgressKeyPath, options: .new, context: nil)
        webView.navigationDelegate = self
        presenter?.viewDidLoad()
    }

    deinit {
        webView.removeObserver(self, forKeyPath: estimatedProgressKeyPath, context: nil)
    }

    // MARK: - Protocol
    func load(request: URLRequest) { webView.load(request) }
    func setProgressValue(_ newValue: Float) { progressView.setProgress(newValue, animated: true) }
    func setProgressHidden(_ isHidden: Bool) { progressView.isHidden = isHidden }

    // MARK: - UI
    private func setupUserInterface() {
        view.backgroundColor = .systemBackground
        webView.translatesAutoresizingMaskIntoConstraints = false
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

        let closeItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        closeItem.accessibilityIdentifier = "WebView.backButton"
        navigationItem.leftBarButtonItem = closeItem

        // Accessibility
        progressView.accessibilityIdentifier = "WebView.progress"
    }

    @objc private func didTapCloseButton() {
        delegate?.webViewViewControllerDidCancel(self)
    }

    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            return presenter?.code(from: url)
        }
        return nil
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == estimatedProgressKeyPath {
            presenter?.didUpdateProgressValue(webView.estimatedProgress)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let authorizationCode = code(from: navigationAction) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: authorizationCode)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
