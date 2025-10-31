import UIKit

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewProtocol?
    private let service: ImagesListServiceProtocol
    private let notificationCenter: NotificationCenter

    private var serviceObserver: NSObjectProtocol?

    init(
        service: ImagesListServiceProtocol = ImagesListService.shared,
        notificationCenter: NotificationCenter = .default
    ) {
        self.service = service
        self.notificationCenter = notificationCenter
    }

    deinit {
        if let serviceObserver { notificationCenter.removeObserver(serviceObserver) }
    }

    // MARK: - Protocol (VC expectations)
    var photosCount: Int { service.photos.count }

    func photo(at index: Int) -> Photo {
        service.photos[index]
    }

    func viewDidLoad() {
        observeServiceChanges()
        fetchNext()
    }

    func didSelectRow(at indexPath: IndexPath) {
        // Навигация обрабатывается VC; презентеру пока ничего делать не нужно
    }

    func willDisplayRow(at indexPath: IndexPath) {
        // В режиме UI теста не выполняем пагинацию
        let isUITest = ProcessInfo.processInfo.arguments.contains("-uiTest")
        if isUITest {
            return
        }
        
        if indexPath.row >= service.photos.count - 3 { fetchNext() }
    }

    func didTapLike(at indexPath: IndexPath) {
        let index = indexPath.row
        guard index < service.photos.count else { return }
        let photo = service.photos[index]
        view?.showHUD()
        view?.setLikeButtonEnabled(false, at: indexPath)
        service.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            switch result {
            case .success:
                self?.view?.setLikeButtonEnabled(true, at: indexPath)
                self?.view?.dismissHUD()
            case .failure:
                self?.view?.showLikeError()
                self?.view?.setLikeButtonEnabled(true, at: indexPath)
                self?.view?.dismissHUD()
            }
        }
    }

    // MARK: - Private
    private func fetchNext() {
        // В режиме UI теста не загружаем данные
        let isUITest = ProcessInfo.processInfo.arguments.contains("-uiTest")
        if isUITest {
            return
        }
        
        service.fetchPhotosNextPage { [weak self] result in
            switch result {
            case .success(let items):
                let start = (self?.service.photos.count ?? 0) - items.count
                guard start >= 0 else { return }
                let end = start + items.count
                let indexPaths = (start..<end).map { IndexPath(row: $0, section: 0) }
                self?.view?.insertRows(at: indexPaths)
            case .failure:
                self?.view?.showLikeError()
            }
        }
    }

    private func observeServiceChanges() {
        serviceObserver = notificationCenter.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            if let idx = note.userInfo?["updatedIndex"] as? Int {
                let indexPath = IndexPath(row: idx, section: 0)
                self.view?.reloadRows(at: [indexPath])
                self.view?.setLikeButtonEnabled(true, at: indexPath)
                self.view?.dismissHUD()
            }
        }
    }
}
