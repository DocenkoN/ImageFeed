import Foundation

public protocol WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

final class WebViewPresenter: WebViewPresenterProtocol {

    weak var view: WebViewViewControllerProtocol?
    private let authHelper: AuthHelperProtocol

    init(authHelper: AuthHelperProtocol = AuthHelper()) {
        self.authHelper = authHelper
    }

    func viewDidLoad() {
        guard let request = authHelper.authRequest() else {
            return
        }
        didUpdateProgressValue(0)
        view?.load(request: request)
    }

    func didUpdateProgressValue(_ newValue: Double) {
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)

        let shouldHide = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHide)
    }

    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }

    func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }
}

