import XCTest
@testable import ImageFeed

final class ImagesListPresenterTests: XCTestCase {

    // MARK: - viewDidLoad тесты
    
    func test_viewDidLoad_callsFetchPhotosNextPage() {
        // given
        let serviceStub = ImagesListServiceStub()
        let sut = ImagesListPresenter(service: serviceStub, notificationCenter: NotificationCenter())
        let view = ImagesListViewSpy()
        sut.view = view
        
        // when
        sut.viewDidLoad()
        
        // then
        XCTAssertEqual(serviceStub.fetchPhotosNextPageCallCount, 1, "Должен вызываться fetchPhotosNextPage")
    }
    
    // MARK: - fetchPhotosNextPage тесты
    
    func test_fetchPhotosNextPage_success_insertsRows() {
        // given
        let serviceStub = ImagesListServiceStub()
        let newPhotos = [
            Photo(id: "1", size: CGSize(width: 100, height: 200), createdAt: nil, welcomeDescription: nil, thumbImageURL: "https://ex/1", largeImageURL: "https://ex/1l", fullImageURL: "https://ex/1f", isLiked: false),
            Photo(id: "2", size: CGSize(width: 200, height: 300), createdAt: nil, welcomeDescription: nil, thumbImageURL: "https://ex/2", largeImageURL: "https://ex/2l", fullImageURL: "https://ex/2f", isLiked: true)
        ]
        serviceStub.photos = newPhotos
        serviceStub.fetchPhotosNextPageResult = .success(newPhotos)
        
        let sut = ImagesListPresenter(service: serviceStub, notificationCenter: NotificationCenter())
        let view = ImagesListViewSpy()
        sut.view = view
        
        // when
        sut.viewDidLoad()
        
        // then
        let expectation = expectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(view.inserted.isEmpty, "Должны быть добавлены новые строки")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func test_fetchPhotosNextPage_failure_showsError() {
        // given
        let serviceStub = ImagesListServiceStub()
        serviceStub.fetchPhotosNextPageResult = .failure(NSError(domain: "test", code: 1))
        
        let sut = ImagesListPresenter(service: serviceStub, notificationCenter: NotificationCenter())
        let view = ImagesListViewSpy()
        sut.view = view
        
        // when
        sut.viewDidLoad()
        
        // then
        let expectation = expectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(view.likeErrorCalls, 1, "Должна быть показана ошибка")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // MARK: - changeLike тесты
    
    func test_didTapLike_callsServiceChangeLike() {
        // given
        let serviceStub = ImagesListServiceStub()
        let photo = Photo(id: "1", size: CGSize(width: 100, height: 200), createdAt: nil, welcomeDescription: nil, thumbImageURL: "https://ex/1", largeImageURL: "https://ex/1l", fullImageURL: "https://ex/1f", isLiked: false)
        serviceStub.photos = [photo]
        serviceStub.changeLikeResult = .success(true)
        
        let sut = ImagesListPresenter(service: serviceStub, notificationCenter: NotificationCenter())
        let view = ImagesListViewSpy()
        sut.view = view
        
        // when
        sut.didTapLike(at: IndexPath(row: 0, section: 0))
        
        // then
        XCTAssertEqual(serviceStub.changeLikeCallCount, 1, "Должен вызываться changeLike")
        XCTAssertEqual(serviceStub.changeLikePhotoId, "1", "Должен передаваться правильный photoId")
        XCTAssertEqual(serviceStub.changeLikeIsLike, true, "Должен инвертироваться isLiked")
    }
    
    func test_didTapLike_success_enablesButtonAndDismissesHUD() {
        // given
        let serviceStub = ImagesListServiceStub()
        let photo = Photo(id: "1", size: CGSize(width: 100, height: 200), createdAt: nil, welcomeDescription: nil, thumbImageURL: "https://ex/1", largeImageURL: "https://ex/1l", fullImageURL: "https://ex/1f", isLiked: false)
        serviceStub.photos = [photo]
        serviceStub.changeLikeResult = .success(true)
        
        let sut = ImagesListPresenter(service: serviceStub, notificationCenter: NotificationCenter())
        let view = ImagesListViewSpy()
        sut.view = view
        
        let indexPath = IndexPath(row: 0, section: 0)
        
        // when
        sut.didTapLike(at: indexPath)
        
        // then
        let expectation = expectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(view.likeEnabledAt[indexPath], true, "Кнопка должна быть включена")
            XCTAssertEqual(view.hudDismissCalls, 1, "HUD должен быть скрыт")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func test_didTapLike_failure_showsErrorAndEnablesButton() {
        // given
        let serviceStub = ImagesListServiceStub()
        let photo = Photo(id: "1", size: CGSize(width: 100, height: 200), createdAt: nil, welcomeDescription: nil, thumbImageURL: "https://ex/1", largeImageURL: "https://ex/1l", fullImageURL: "https://ex/1f", isLiked: false)
        serviceStub.photos = [photo]
        serviceStub.changeLikeResult = .failure(NSError(domain: "test", code: 1))
        
        let sut = ImagesListPresenter(service: serviceStub, notificationCenter: NotificationCenter())
        let view = ImagesListViewSpy()
        sut.view = view
        
        let indexPath = IndexPath(row: 0, section: 0)
        
        // when
        sut.didTapLike(at: indexPath)
        
        // then
        let expectation = expectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(view.likeErrorCalls, 1, "Должна быть показана ошибка")
            XCTAssertEqual(view.likeEnabledAt[indexPath], true, "Кнопка должна быть включена")
            XCTAssertEqual(view.hudDismissCalls, 1, "HUD должен быть скрыт")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // MARK: - Notification тесты
    
    func test_onUpdatedIndexNotification_triggersRowReload_enableButton_andDismissHUD() {
        // given
        let serviceStub = ImagesListServiceStub()
        let nc = NotificationCenter()
        let sut = ImagesListPresenter(service: serviceStub, notificationCenter: nc)
        let view = ImagesListViewSpy()
        sut.view = view
        sut.viewDidLoad()
        
        // when
        let updated = 3
        nc.post(name: ImagesListService.didChangeNotification, object: nil, userInfo: ["updatedIndex": updated])
        
        // then
        let expectation = expectation(description: "Wait for notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(view.reloaded.contains(IndexPath(row: updated, section: 0)))
            XCTAssertEqual(view.likeEnabledAt[IndexPath(row: updated, section: 0)], true)
            XCTAssertEqual(view.hudDismissCalls, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
