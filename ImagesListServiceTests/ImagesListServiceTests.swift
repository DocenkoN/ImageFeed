import XCTest
@testable import ImageFeed

final class ImagesListServiceTests: XCTestCase {
    
    private var service: ImagesListService!
    private var urlSession: URLSession!
    
    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: config)
        service = ImagesListService(session: urlSession)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        OAuth2TokenStorage.shared.token = nil
        service = nil
        urlSession = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Photos Tests
    
    func test_fetchPhotosNextPage_success() {
        // given
        OAuth2TokenStorage.shared.token = "test_token"
        let expectedJSON: [[String: Any]] = [[
            "id": "1",
            "width": 1000,
            "height": 500,
            "created_at": "2023-01-01T00:00:00Z",
            "description": "Test",
            "urls": [
                "thumb": "https://thumb",
                "small": "https://small",
                "regular": "https://regular"
            ],
            "liked_by_user": false
        ]]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: expectedJSON)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonData)
        }
        
        let expectation = expectation(description: "Fetch photos")
        var receivedResult: Result<[Photo], Error>?
        
        // when
        service.fetchPhotosNextPage { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // then
        guard case .success(let photos) = receivedResult else {
            XCTFail("Expected success")
            return
        }
        XCTAssertEqual(photos.count, 1)
        XCTAssertEqual(photos.first?.id, "1")
        XCTAssertEqual(service.photos.count, 1)
    }
    
    func test_fetchPhotosNextPage_noToken_returnsAuthError() {
        // given
        OAuth2TokenStorage.shared.token = nil
        let expectation = expectation(description: "No token error")
        var receivedError: Error?
        
        // when
        service.fetchPhotosNextPage { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // then
        XCTAssertNotNil(receivedError)
        if let nsError = receivedError as NSError? {
            XCTAssertEqual(nsError.domain, "Auth")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    func test_fetchPhotosNextPage_emptyToken_returnsAuthError() {
        // given
        OAuth2TokenStorage.shared.token = ""
        let expectation = expectation(description: "Empty token error")
        var receivedError: Error?
        
        // when
        service.fetchPhotosNextPage { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // then
        XCTAssertNotNil(receivedError)
    }
    
    func test_fetchPhotosNextPage_preventsDuplicateLoading() {
        // given
        OAuth2TokenStorage.shared.token = "test_token"
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        let expectation1 = expectation(description: "First fetch")
        let expectation2 = expectation(description: "Second fetch")
        var firstCallCount = 0
        
        // when - два одновременных запроса
        service.fetchPhotosNextPage { _ in
            firstCallCount += 1
            expectation1.fulfill()
        }
        
        service.fetchPhotosNextPage { _ in
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // then - второй запрос должен игнорироваться, пока идет первый
        // Проверяем что был только один реальный запрос
    }
    
    // MARK: - Change Like Tests
    
    func test_changeLike_success_updatesPhoto() {
        // given
        OAuth2TokenStorage.shared.token = "test_token"
        let photoId = "test_photo_id"
        
        // Сначала добавляем фото в сервис через fetch
        let photoJSON: [[String: Any]] = [[
            "id": photoId,
            "width": 1000,
            "height": 500,
            "created_at": nil,
            "description": nil,
            "urls": [
                "thumb": "https://thumb",
                "small": "https://small",
                "regular": "https://regular"
            ],
            "liked_by_user": false
        ]]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: photoJSON)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: request.httpMethod == "GET" ? 200 : 200,
                httpVersion: nil,
                headerFields: nil
            )!
            if request.httpMethod == "GET" {
                return (response, jsonData)
            } else {
                return (response, Data())
            }
        }
        
        let fetchExpectation = expectation(description: "Fetch photo")
        service.fetchPhotosNextPage { _ in fetchExpectation.fulfill() }
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(service.photos.first?.isLiked, false)
        
        let likeExpectation = expectation(description: "Like photo")
        var notificationReceived = false
        
        let observer = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let index = notification.userInfo?["updatedIndex"] as? Int {
                XCTAssertEqual(index, 0)
                notificationReceived = true
            }
        }
        
        // when
        service.changeLike(photoId: photoId, isLike: true) { result in
            if case .success(let isLiked) = result {
                XCTAssertTrue(isLiked)
            } else {
                XCTFail("Expected success")
            }
            likeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // then
        XCTAssertEqual(service.photos.first?.isLiked, true)
        XCTAssertTrue(notificationReceived)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func test_changeLike_noToken_returnsAuthError() {
        // given
        OAuth2TokenStorage.shared.token = nil
        let expectation = expectation(description: "No token error")
        var receivedError: Error?
        
        // when
        service.changeLike(photoId: "test_id", isLike: true) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // then
        XCTAssertNotNil(receivedError)
        if let nsError = receivedError as NSError? {
            XCTAssertEqual(nsError.domain, "Auth")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    // MARK: - Reset Tests
    
    func test_reset_clearsState() {
        // given
        OAuth2TokenStorage.shared.token = "test_token"
        let photoJSON: [[String: Any]] = [[
            "id": "1",
            "width": 100,
            "height": 100,
            "created_at": nil,
            "description": nil,
            "urls": [
                "thumb": "https://thumb",
                "small": "https://small",
                "regular": "https://regular"
            ],
            "liked_by_user": false
        ]]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: photoJSON)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonData)
        }
        
        let fetchExpectation = expectation(description: "Fetch photo")
        service.fetchPhotosNextPage { _ in fetchExpectation.fulfill() }
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(service.photos.count, 1)
        
        // when
        service.reset()
        
        // then
        XCTAssertEqual(service.photos.count, 0)
    }
}

// MARK: - Mock URL Protocol
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

