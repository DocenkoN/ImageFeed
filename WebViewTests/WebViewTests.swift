import XCTest
@testable import ImageFeed

final class WebViewTests: XCTestCase {

    // MARK: - Test 1
    func testViewControllerCallsViewDidLoad() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: WebViewViewController.self))

        guard let viewController = storyboard.instantiateViewController(
            withIdentifier: "WebView"
        ) as? WebViewViewController else {
            XCTFail("Не удалось загрузить WebViewViewController из Storyboard")
            return
        }

        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        _ = viewController.view  // форсим загрузку view, вызовется viewDidLoad у VC
        // Ждем выполнения async блока из viewDidLoad
        let expectation = expectation(description: "Presenter viewDidLoad called")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5)

        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    // MARK: - Test 2
    func testPresenterCallsLoadRequest() {
        // given
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertTrue(viewController.loadRequestCalled)
    }

    // MARK: - Test 3
    func testProgressHiddenWhenOne() {
        // given
        let authHelper = AuthHelper() // Dummy helper
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0

        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // then
        XCTAssertTrue(shouldHideProgress)
    }

    // MARK: - Test 4
    func testAuthHelperAuthURL() {
        // given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)

        // when
        guard let url = authHelper.authURL(),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems
        else {
            return XCTFail("authURL() вернул некорректный URL")
        }

        // then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "unsplash.com")
        XCTAssertEqual(components.path, "/oauth/authorize")

        func value(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }

        XCTAssertEqual(value("client_id"), configuration.accessKey)
        XCTAssertEqual(value("redirect_uri"), configuration.redirectURI) // OK: сравнение уже с декодированным значением
        XCTAssertEqual(value("response_type"), "code")
        XCTAssertEqual(value("scope"), configuration.accessScope)
    }

    // MARK: - Test 5
    func testCodeFromURL() {
        // given
        // URL должен соответствовать схеме imagefeed://auth с параметром code
        var urlComponents = URLComponents(string: "imagefeed://auth")!
        urlComponents.queryItems = [URLQueryItem(name: "code", value: "test code")]
        let url = urlComponents.url!
        let authHelper = AuthHelper()

        // when
        let code = authHelper.code(from: url)

        // then
        XCTAssertEqual(code, "test code")
    }
}
