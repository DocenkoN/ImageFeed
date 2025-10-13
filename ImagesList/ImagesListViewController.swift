import UIKit

final class ImagesListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    private var photos: [Photo] = []
    private let imagesListService = ImagesListService.shared

    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onImagesListServiceDidChange(_:)),
            name: ImagesListService.didChangeNotification,
            object: imagesListService
        )

        imagesListService.fetchPhotosNextPage()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let vc = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            let photo = photos[indexPath.row]
            vc.imageURL = URL(string: photo.fullImageURL)   
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    // MARK: - Notifications
    @objc private func onImagesListServiceDidChange(_ note: Notification) {
        assert(Thread.isMainThread)

        if let updatedIndex = note.userInfo?["updatedIndex"] as? Int {
            // точечный апдейт лайка
            photos = imagesListService.photos
            let ip = IndexPath(row: updatedIndex, section: 0)
            if let cell = tableView.cellForRow(at: ip) as? ImagesListCell {
                cell.setIsLiked(photos[updatedIndex].isLiked)
                cell.setLikeButtonEnabled(true)
            }
            UIBlockingProgressHUD.dismiss()
            return
        }

        // пагинация
        updateTableViewAnimated()
    }

    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos

        guard newCount > oldCount else { return }

        let toInsert = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        tableView.performBatchUpdates({
            tableView.insertRows(at: toInsert, with: .automatic)
        })
    }

    // MARK: - UI helpers
    private func showLikeError() {
        let alert = UIAlertController(title: "Не удалось поставить лайк",
                                      message: "Повторите попытку позже.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }

        let model = photos[indexPath.row]
        cell.delegate = self
        cell.configure(with: model, dateFormatter: dateFormatter)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - insets.left - insets.right
        let scale = imageViewWidth / max(photo.size.width, 1)
        let cellHeight = photo.size.height * scale + insets.top + insets.bottom
        return cellHeight
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    func imagesListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              photos.indices.contains(indexPath.row) else { return }

        let photo = photos[indexPath.row]
        let newLike = !photo.isLiked

        // Блокирующий лоадер + блокируем кнопку на время операции
        UIBlockingProgressHUD.show()
        cell.setLikeButtonEnabled(false)

        imagesListService.changeLike(photoId: photo.id, isLike: newLike) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Сервис сам обновит массив и пришлёт notification с updatedIndex,
                    // где мы обновим UI, включим кнопку и спрячем HUD.
                    break
                case .failure:
                    // Ошибка: снимаем HUD, включаем кнопку, откатываем визуал
                    UIBlockingProgressHUD.dismiss()
                    if let visibleCell = self.tableView.cellForRow(at: indexPath) as? ImagesListCell {
                        visibleCell.setIsLiked(photo.isLiked) // вернуть прежнее
                        visibleCell.setLikeButtonEnabled(true)
                    }
                    self.showLikeError()
                }
            }
        }
    }
}
