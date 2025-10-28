import XCTest
@testable import ImageFeed

final class ImagesListViewControllerTests: XCTestCase {

    private func makeSUT() -> (vc: ImagesListViewController, spy: ImagesListPresenterSpy) {
        let vc = ImagesListViewController()
        let spy = ImagesListPresenterSpy()
        vc.loadViewIfNeeded()
        // Подготовим данные для dataSource/height
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

        vc.loadViewIfNeeded()
        vc.configure(spy)
        vc.viewDidLoad()

        XCTAssertTrue(spy.view === vc)
        XCTAssertEqual(spy.viewDidLoadCalls, 1)
    }

    func test_tableViewDataSource_usesPresenterCountAndPhoto() {
        let (vc, spy) = makeSUT()
        let table = UITableView()
        table.dataSource = vc

        // зарегистрируем ячейку той же reuse id
        table.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)

        XCTAssertEqual(vc.tableView(table, numberOfRowsInSection: 0), spy.photos.count)

        // Ячейку проверить можем на тип — сам configure внутри требует XIB/IBOutlet,
        // поэтому просто убеждаемся, что dequeuing не падает.
        _ = vc.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
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
        let table = UITableView()
        table.dataSource = vc
        table.delegate = vc
        table.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)

        // Создадим «ячейку» и дернем делегат напрямую
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = ImagesListCell(style: .default, reuseIdentifier: ImagesListCell.reuseIdentifier)
        // Для корректной работы делегата он должен быть установлен
        cell.setValue(vc, forKey: "delegate")
        vc.imagesListCellDidTapLike(cell)

        XCTAssertEqual(spy.didTapLikeCalls, [indexPath]) // ожидаем вызов на первой строке
    }
}
