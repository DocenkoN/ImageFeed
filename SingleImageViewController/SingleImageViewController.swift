import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imageView: UIImageView!

    // сюда передаём URL в prepare(for:)
    var imageURL: URL?
    
    private var currentRotation: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self

        imageView.contentMode = .scaleAspectFit
        imageView.kf.indicatorType = .none
        
        // Настройка жестов
        setupGestureRecognizers()

        startLoadingFullImage()
    }
    
    private func setupGestureRecognizers() {
        // Двойной тап для зумирования
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        
        // Поворот изображения
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        imageView.addGestureRecognizer(rotationGesture)
        
        // Включаем взаимодействие с imageView для жестов
        imageView.isUserInteractionEnabled = true
    }

    // MARK: - Actions
    @IBAction private func didTapBackButton(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(share, animated: true)
    }

    // MARK: - Loading
    private func startLoadingFullImage() {
        guard let url = imageURL else { return }
        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: url, options: [.transition(.fade(0.25)), .cacheOriginalImage]) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            switch result {
            case .success(let value):
                self.rescaleAndCenterImageInScrollView(image: value.image)
            case .failure:
                self.showPlaceholder()
                self.showError()
            }
        }
    }

    private func showPlaceholder() {
        guard let placeholder = UIImage(named: "placeholder") else { return }
        imageView.image = placeholder
        rescaleAndCenterImageInScrollView(image: placeholder)
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.startLoadingFullImage()
        })
        present(alert, animated: true)
    }

    // MARK: - Zoom & Center
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        view.layoutIfNeeded()

        // Сбрасываем поворот при загрузке нового изображения
        imageView.transform = .identity
        currentRotation = 0

        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size

        let scrollSize = scrollView.bounds.size
        let hScale = scrollSize.width / image.size.width
        let vScale = scrollSize.height / image.size.height
        let scaleToFit = min(hScale, vScale)

        scrollView.minimumZoomScale = scaleToFit
        scrollView.maximumZoomScale = scaleToFit * 3
        scrollView.zoomScale = scaleToFit

        centerImage()
    }

    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize

        let offsetX = max((boundsSize.width  - contentSize.width)  * 0.5, 0)
        let offsetY = max((boundsSize.height - contentSize.height) * 0.5, 0)

        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: imageView)

        if abs(scrollView.zoomScale - scrollView.minimumZoomScale) < .ulpOfOne {
            let newScale = min(scrollView.maximumZoomScale, scrollView.minimumZoomScale * 2)
            let size = scrollView.bounds.size
            let w = size.width / newScale
            let h = size.height / newScale
            let rect = CGRect(x: point.x - w/2, y: point.y - h/2, width: w, height: h)
            scrollView.zoom(to: rect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    @objc private func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
        guard recognizer.state == .began || recognizer.state == .changed else {
            // Фиксируем поворот при окончании жеста
            if recognizer.state == .ended || recognizer.state == .cancelled {
                currentRotation = atan2(imageView.transform.b, imageView.transform.a)
            }
            return
        }
        
        // Применяем поворот к изображению
        let rotation = recognizer.rotation + currentRotation
        imageView.transform = CGAffineTransform(rotationAngle: rotation)
        recognizer.rotation = 0
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}

extension SingleImageViewController: UIGestureRecognizerDelegate {
    // Разрешаем одновременное выполнение жестов (zoom, pan, rotation)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
