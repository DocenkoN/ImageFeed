import XCTest
@testable import ImageFeed

final class ImagesListPresenterTests: XCTestCase {

    // smoke: viewDidLoad не падает (без данных)
    func test_viewDidLoad_smoke() {
        let sut = ImagesListPresenter(notificationCenter: NotificationCenter())
        let view = ImagesListViewSpy()
        sut.view = view

        sut.viewDidLoad()
        // ничего не ассертим — важно, что не крашится
    }

    // При получении нотификации с updatedIndex презентер дергает reloadRows, включает кнопку и скрывает HUD
    func test_onUpdatedIndexNotification_triggersRowReload_enableButton_andDismissHUD() {
        let nc = NotificationCenter()
        let sut = ImagesListPresenter(notificationCenter: nc)
        let view = ImagesListViewSpy()
        sut.view = view
        sut.viewDidLoad()

        let updated = 3
        nc.post(name: ImagesListService.didChangeNotification, object: ImagesListService.shared, userInfo: ["updatedIndex": updated])

        XCTAssertTrue(view.reloaded.contains(IndexPath(row: updated, section: 0)))
        XCTAssertEqual(view.likeEnabledAt[IndexPath(row: updated, section: 0)], true)
        XCTAssertEqual(view.hudDismissCalls, 1)
    }
}
