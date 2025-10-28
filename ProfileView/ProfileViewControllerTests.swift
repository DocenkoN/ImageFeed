import XCTest
@testable import ImageFeed

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?
    private(set) var viewDidLoadCalled = 0
    private(set) var didTapLogoutCalled = 0
    private(set) var confirmLogoutCalled = 0

    func viewDidLoad() { viewDidLoadCalled += 1 }
    func didTapLogout() { didTapLogoutCalled += 1 }
    func confirmLogout() { confirmLogoutCalled += 1 }
}

final class ProfileViewControllerTests: XCTestCase {

    func test_configure_bindsView_andCallsViewDidLoad() {
        let vc = ProfileViewController()
        let spy = ProfilePresenterSpy()

        vc.loadViewIfNeeded()
        vc.configure(spy)
        vc.viewDidLoad()

        XCTAssertTrue(spy.view === vc)
        XCTAssertEqual(spy.viewDidLoadCalled, 1)
    }

    func test_didTapLogout_forwardsToPresenter() {
        let vc = ProfileViewController()
        let spy = ProfilePresenterSpy()
        vc.loadViewIfNeeded()
        vc.configure(spy)

        vc.didTapLogout()

        XCTAssertEqual(spy.didTapLogoutCalled, 1)
    }

    func test_presentLogoutAlert_callsPresenterConfirm_onDestructiveAction() {
        let vc = ProfileViewController()
        let spy = ProfilePresenterSpy()
        vc.loadViewIfNeeded()
        vc.configure(spy)

        vc.presentLogoutAlert()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.makeKeyAndVisible()

        guard let alert = vc.presentedViewController as? UIAlertController else {
            return XCTFail("Ожидался UIAlertController")
        }
        guard let action = alert.actions.first(where: { $0.style == .destructive }) else {
            return XCTFail("Нет destructive action")
        }

        let handler = action.value(forKey: "handler") as AnyObject?
        typealias Handler = @convention(block) (UIAlertAction) -> Void
        (handler as? Handler)?(action)

        XCTAssertEqual(spy.confirmLogoutCalled, 1)
    }
}
