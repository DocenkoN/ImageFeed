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

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.makeKeyAndVisible()
        
        // Убеждаемся, что view полностью загружена и готова к презентации
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        // Вызываем presentLogoutAlert
        vc.presentLogoutAlert()
        
        // Ждем, пока alert будет представлен, проверяя периодически через RunLoop
        var alert: UIAlertController?
        let maxAttempts = 50
        var attempts = 0
        
        while alert == nil && attempts < maxAttempts {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            alert = vc.presentedViewController as? UIAlertController
            attempts += 1
        }

        guard let finalAlert = alert else {
            return XCTFail("Ожидался UIAlertController, но он не был представлен. presentedViewController = \(String(describing: vc.presentedViewController))")
        }
        
        guard let action = finalAlert.actions.first(where: { $0.style == .destructive }) else {
            return XCTFail("Нет destructive action")
        }

        // Проверяем структуру alert'а
        XCTAssertEqual(finalAlert.actions.count, 2, "Должно быть 2 action: cancel и destructive")
        XCTAssertNotNil(finalAlert.actions.first(where: { $0.style == .cancel }), "Должна быть cancel action")
        XCTAssertNotNil(finalAlert.actions.first(where: { $0.style == .destructive }), "Должна быть destructive action")
        
        
        // Проверяем, что action имеет правильный стиль
        XCTAssertEqual(action.style, .destructive, "Action должен иметь стиль .destructive")
        XCTAssertEqual(action.title, "Да", "Action должен иметь заголовок 'Да'")
    }
}
