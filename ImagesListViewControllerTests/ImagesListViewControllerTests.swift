import XCTest
@testable import ImageFeed

final class ImagesListViewControllerTests: XCTestCase {

    private func makeSUT() -> (vc: ImagesListViewController, spy: ImagesListPresenterSpy) {
        let vc = ImagesListViewController()
        let spy = ImagesListPresenterSpy()
        vc.loadViewIfNeeded()
        vc.viewDidLoad() 
        spy.photos = [
            Photo(id: "1", size: CGSize(width: 1000, height: 500), createdAt: nil, welcomeDescription: nil, thumbImageURL: "https://ex/1", largeImageURL: "https://ex/1l", fullImageURL: "https://ex/1f", isLiked: false),
            Photo(id: "2", size: CGSize(width: 800, height: 1200), createdAt: nil, welcomeDescription: nil, thumbImageURL: "https://ex/2", largeImageURL: "https://ex/2l", fullImageURL: "https://ex/2f", isLiked: true)
        ]
        spy.photosCount = spy.photos.count
        vc.configure(spy)
        return (vc, spy)
    }

    func test_configure_bindsView_andCallsPresenterViewDidLoad() {
        let vc = ImagesListViewController()
        let spy = ImagesListPresenterSpy()

        vc.configure(spy)
        vc.loadViewIfNeeded()
        XCTAssertTrue(spy.view === vc)
        XCTAssertEqual(spy.viewDidLoadCalls, 1, "viewDidLoad должен быть вызван один раз у presenter")
    }

    func test_tableViewDataSource_usesPresenterCountAndPhoto() {
        let (vc, spy) = makeSUT()
        let table = UITableView()
        table.dataSource = vc

        // зарегистрируем ячейку той же reuse id
        table.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)

        XCTAssertEqual(vc.tableView(table, numberOfRowsInSection: 0), spy.photos.count)


        let cell = vc.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertNotNil(cell)
        XCTAssertTrue(cell is ImagesListCell)
    }

    func test_delegate_forwardsEventsToPresenter() {
        let (vc, spy) = makeSUT()
        let table = UITableView()
        table.delegate = vc

        vc.tableView(table, didSelectRowAt: IndexPath(row: 1, section: 0))
        vc.tableView(table, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 1, section: 0))

        XCTAssertEqual(spy.didSelectCalls, [IndexPath(row: 1, section: 0)])
        XCTAssertEqual(spy.willDisplayCalls, [IndexPath(row: 1, section: 0)])
    }

    func test_heightForRow_usesPresenterPhotoSize() {
        let (vc, spy) = makeSUT()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        table.delegate = vc

        let h0 = vc.tableView(table, heightForRowAt: IndexPath(row: 0, section: 0))
        let h1 = vc.tableView(table, heightForRowAt: IndexPath(row: 1, section: 0))

        XCTAssertNotEqual(h0, h1) // размеры разные → высоты разные
        XCTAssertGreaterThan(h0, 0)
        XCTAssertGreaterThan(h1, 0)
    }

    func test_likeTap_forwardsToPresenter() {
        let (vc, spy) = makeSUT()
        // Устанавливаем размер для tableView, чтобы heightForRowAt работал корректно
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        table.dataSource = vc
        table.delegate = vc
        table.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)

        // Создадим ячейку через tableView, чтобы она была правильно связана
        let indexPath = IndexPath(row: 0, section: 0)
        guard let cell = vc.tableView(table, cellForRowAt: indexPath) as? ImagesListCell else {
            XCTFail("Не удалось получить ImagesListCell")
            return
        }
        
        cell.delegate = vc
        
        // Симулируем нажатие на кнопку лайка
        vc.imagesListCellDidTapLike(cell)

        XCTAssertEqual(spy.didTapLikeCalls, [indexPath]) // ожидаем вызов на первой строке
    }
}
