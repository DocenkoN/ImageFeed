import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!

    // сюда передаём URL в prepare(for:)
    var imageURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self

        imageView.contentMode = .scaleAspectFit
        imageView.kf.indicatorType = .none  // используем общий HUD

        // double-tap для быстрого зума
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        startLoadingFullImage()
    }

    // MARK: - Actions
    @IBAction private func didTapBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(share, animated: true, completion: nil)
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
                self.showError()
            }
        }
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

        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size

        let scrollSize = scrollView.bounds.size
        let hScale = scrollSize.width / image.size.width
        let vScale = scrollSize.height / image.size.height
        let scaleToFit = min(hScale, vScale)              // важно: min, чтобы влезала целиком

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
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
