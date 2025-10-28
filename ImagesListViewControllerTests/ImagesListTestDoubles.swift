import Foundation
@testable import ImageFeed

// MARK: - View spy для презентера
final class ImagesListViewSpy: ImagesListViewProtocol {
    private(set) var inserted: [IndexPath] = []
    private(set) var reloaded: [IndexPath] = []
    private(set) var reloadTableCalls = 0
    private(set) var likeEnabledAt: [IndexPath: Bool] = [:]
    private(set) var hudShowCalls = 0
    private(set) var hudDismissCalls = 0
    private(set) var likeErrorCalls = 0

    func insertRows(at indexPaths: [IndexPath]) { inserted.append(contentsOf: indexPaths) }
    func reloadRows(at indexPaths: [IndexPath]) { reloaded.append(contentsOf: indexPaths) }
    func reloadTable() { reloadTableCalls += 1 }
    func showLikeError() { likeErrorCalls += 1 }
    func setLikeButtonEnabled(_ enabled: Bool, at indexPath: IndexPath) { likeEnabledAt[indexPath] = enabled }
    func showHUD() { hudShowCalls += 1 }
    func dismissHUD() { hudDismissCalls += 1 }
}

// MARK: - Presenter spy для VC-тестов
final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    weak var view: ImagesListViewProtocol?

    private(set) var viewDidLoadCalls = 0
    private(set) var didSelectCalls: [IndexPath] = []
    private(set) var willDisplayCalls: [IndexPath] = []
    private(set) var didTapLikeCalls: [IndexPath] = []

    var photosCount: Int = 0
    var photos: [Photo] = []

    func viewDidLoad() { viewDidLoadCalls += 1 }
    func photo(at index: Int) -> Photo { photos[index] }
    func didSelectRow(at indexPath: IndexPath) { didSelectCalls.append(indexPath) }
    func willDisplayRow(at indexPath: IndexPath) { willDisplayCalls.append(indexPath) }
    func didTapLike(at indexPath: IndexPath) { didTapLikeCalls.append(indexPath) }
}
