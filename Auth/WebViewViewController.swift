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

    @IBOutlet private weak var webView: WKWebView?
    @IBOutlet private weak var progressView: UIProgressView?

    weak var delegate: WebViewViewControllerDelegate?

    private var estimatedProgressObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let webView = webView, let progressView = progressView else {
            assertionFailure("WebView или ProgressView не подключены из Storyboard")
            return
        }
        
        setupUserInterface()
        webView.navigationDelegate = self
        webView.accessibilityIdentifier = "UnsplashWebView"
        
        configureWebViewForVPN(webView)
        
        estimatedProgressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.presenter?.didUpdateProgressValue(webView.estimatedProgress)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.presenter != nil else { return }
            self.presenter?.viewDidLoad()
        }
    }

    deinit {
        estimatedProgressObservation = nil
    }

    // MARK: - Protocol
    func load(request: URLRequest) {
        guard let webView = webView else {
            assertionFailure("WebView не подключен из Storyboard")
            return
        }
        if webView.isLoading {
            webView.stopLoading()
        }
        webView.load(request)
    }
    
    func setProgressValue(_ newValue: Float) {
        guard let progressView = progressView else { return }
        progressView.setProgress(newValue, animated: true)
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        guard let progressView = progressView else { return }
        progressView.isHidden = isHidden
    }

    // MARK: - Configuration
    private func configureWebViewForVPN(_ webView: WKWebView) {
        webView.configuration.preferences.javaScriptEnabled = true
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        if #available(iOS 14.0, *) {
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.configuration.websiteDataStore = .default()
    }
    
    // MARK: - UI
    private func setupUserInterface() {
        progressView?.trackTintColor = .clear
        progressView?.accessibilityIdentifier = "WebView.progress"

        let closeItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        closeItem.accessibilityIdentifier = "WebView.backButton"
        navigationItem.leftBarButtonItem = closeItem
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
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        presenter?.didUpdateProgressValue(1.0)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        let errorCode = nsError.code
        
        #if DEBUG
        print("[WebView] Ошибка навигации: \(error.localizedDescription)")
        print("[WebView] Domain: \(nsError.domain), Code: \(errorCode)")
        print("[WebView] UserInfo: \(nsError.userInfo)")
        if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            print("[WebView] Failing URL: \(failingURL.absoluteString)")
        }
        #endif
        
        showErrorAlert(error: error, errorCode: errorCode)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        let errorCode = nsError.code
        
        #if DEBUG
        print("[WebView] Ошибка provisional: \(error.localizedDescription)")
        print("[WebView] Domain: \(nsError.domain), Code: \(errorCode)")
        if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            print("[WebView] Failing URL: \(failingURL.absoluteString)")
        }
        #endif
        
        showErrorAlert(error: error, errorCode: errorCode)
    }
    
    private func showErrorAlert(error: Error, errorCode: Int) {
        var errorMessage = "Не удалось загрузить страницу авторизации."
        var troubleshootingTips = ""
        
        // Диагностика конкретных ошибок
        switch errorCode {
        case NSURLErrorNotConnectedToInternet:
            errorMessage = "Нет подключения к интернету"
            troubleshootingTips = "\n\n• Проверьте Wi‑Fi или мобильный интернет\n• Убедитесь, что интернет работает в других приложениях"
            
        case NSURLErrorTimedOut:
            errorMessage = "Превышено время ожидания"
            troubleshootingTips = "\n\n• Проверьте скорость интернета\n• Попробуйте отключить VPN\n• Проверьте настройки файрвола/антивируса"
            
        case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
            errorMessage = "Не удалось найти сервер"
            troubleshootingTips = "\n\n• Проверьте DNS настройки\n• Попробуйте другой DNS (8.8.8.8 или 1.1.1.1)\n• Отключите VPN или прокси"
            
        case NSURLErrorCannotConnectToHost:
            errorMessage = "Не удалось подключиться к серверу"
            troubleshootingTips = "\n\n• Проверьте, не блокирует ли файрвол или антивирус\n• Отключите VPN\n• Проверьте настройки прокси"
            
        case NSURLErrorNetworkConnectionLost:
            errorMessage = "Соединение прервано"
            troubleshootingTips = "\n\n• Проверьте стабильность интернета\n• Перезапустите Wi‑Fi\n• Проверьте настройки VPN"
            
        case NSURLErrorSecureConnectionFailed:
            errorMessage = "Ошибка безопасного соединения"
            troubleshootingTips = "\n\n• Проверьте дату и время на устройстве\n• Отключите VPN, который может блокировать SSL\n• Проверьте корпоративный прокси/файрвол"
            
        case -1200...(-1000):
            errorMessage = "Ошибка SSL соединения"
            troubleshootingTips = "\n\n• Проверьте системную дату и время\n• Отключите VPN с неправильной конфигурацией\n• Проверьте настройки корпоративного прокси"
            
        default:
            troubleshootingTips = "\n\n• Проверьте подключение к интернету\n• Попробуйте отключить VPN\n• Перезапустите приложение\n• Проверьте, не блокирует ли антивирус или файрвол"
        }
        
        let alert = UIAlertController(
            title: "Ошибка загрузки",
            message: "\(errorMessage)\(troubleshootingTips)\n\nТехническая информация:\n\(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.presenter?.viewDidLoad()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.webViewViewControllerDidCancel(self)
        })
        present(alert, animated: true)
    }
}
