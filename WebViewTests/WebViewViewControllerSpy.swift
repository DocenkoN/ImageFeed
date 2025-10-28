import Foundation
import ImageFeed
@testable import ImageFeed

final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: ImageFeed.WebViewPresenterProtocol?

    var loadRequestCalled = false

    func load(request: URLRequest) {
        loadRequestCalled = true
    }

    func setProgressValue(_ newValue: Float) {
        // не используется в этом тесте
    }

    func setProgressHidden(_ isHidden: Bool) {
        // не используется в этом тесте
    }
}
