// MARK: - ImagesListViewController.swift (обновлённый)

import UIKit

final class ImagesListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView?

    // MVP
    private var presenter: ImagesListPresenterProtocol?

    // Инъекция презентера для VC из Storyboard
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }

    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    // Твой переиспользуемый форматтер — оставляем тут
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Для юнит-тестов: если tableView не загрузился из Storyboard, создаем программно
        if tableView == nil {
            let table = UITableView()
            table.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(table)
            NSLayoutConstraint.activate([
                table.topAnchor.constraint(equalTo: view.topAnchor),
                table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            tableView = table
        }
        
        guard let tableView = tableView else {
            assertionFailure("TableView не удалось создать")
            return
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        // ✅ Самолечение: если забыли вызвать configure(_:) — создаём презентер здесь
        if presenter == nil {
            let fallback = ImagesListPresenter()
            configure(fallback)
        }

        presenter?.viewDidLoad()
    }

    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let vc = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath,
                let presenter = presenter
            else {
                assertionFailure("Invalid segue destination or presenter is nil")
                return
            }
            let photo = presenter.photo(at: indexPath.row)
            vc.imageURL = URL(string: photo.fullImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter?.photosCount ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }

        guard let presenter = presenter else {
            return UITableViewCell()
        }
        
        let model = presenter.photo(at: indexPath.row)
        cell.delegate = self
        cell.configure(with: model, dateFormatter: dateFormatter)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter?.didSelectRow(at: indexPath)
        
        // В юнит-тестах segue может отсутствовать, поэтому проверяем наличие storyboard
        // Если storyboard == nil, значит view controller создан программно (в тестах)
        guard storyboard != nil else {
            return // В тестах просто выходим, segue не выполняется
        }
        
        // Выполняем segue только если есть storyboard
        // В реальном приложении segue должен существовать, если его нет - будет исключение
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        presenter?.willDisplayRow(at: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let presenter = presenter else {
            return UITableView.automaticDimension
        }
        
        let photo = presenter.photo(at: indexPath.row)
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
        guard let presenter = presenter else { return }
        
        if let tableView = tableView, let indexPath = tableView.indexPath(for: cell) {
            presenter.didTapLike(at: indexPath)
        } else {
            // Фолбэк для юнит-тестов, где ячейка не в таблице VC
            // Попробуем узнать индекс через суперьюхи и таблицу, если она другая
            if let otherTable = cell.superview as? UITableView,
               let idx = otherTable.indexPath(for: cell) {
                presenter.didTapLike(at: idx)
            }
        }
    }
}

// MARK: - ImagesListViewProtocol
extension ImagesListViewController: ImagesListViewProtocol {

    func insertRows(at indexPaths: [IndexPath]) {
        guard let tableView = tableView else { return }
        tableView.performBatchUpdates({
            tableView.insertRows(at: indexPaths, with: .automatic)
        })
    }

    func reloadRows(at indexPaths: [IndexPath]) {
        guard let tableView = tableView else { return }
        tableView.reloadRows(at: indexPaths, with: .automatic)
    }

    func reloadTable() {
        tableView?.reloadData()
    }

    func showLikeError() {
        let alert = UIAlertController(
            title: "Не удалось поставить лайк",
            message: "попробуйте еще раз",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func setLikeButtonEnabled(_ enabled: Bool, at indexPath: IndexPath) {
        guard let tableView = tableView else { return }
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            cell.setLikeButtonEnabled(enabled)
        }
    }

    func showHUD() {
        UIBlockingProgressHUD.show()
    }

    func dismissHUD() {
        UIBlockingProgressHUD.dismiss()
    }
}
