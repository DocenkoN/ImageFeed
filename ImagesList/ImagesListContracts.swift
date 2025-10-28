import UIKit

protocol ImagesListViewProtocol: AnyObject {
    func insertRows(at indexPaths: [IndexPath])
    func reloadRows(at indexPaths: [IndexPath])
    func reloadTable()
    func showLikeError()
    func setLikeButtonEnabled(_ enabled: Bool, at indexPath: IndexPath)
    func showHUD()
    func dismissHUD()
}

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewProtocol? { get set }
    var photosCount: Int { get }
    func photo(at index: Int) -> Photo
    func viewDidLoad()
    func didSelectRow(at indexPath: IndexPath)
    func willDisplayRow(at indexPath: IndexPath)
    func didTapLike(at indexPath: IndexPath)
}
