import UIKit
import Kingfisher

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"

    @IBOutlet private weak var cellImage: UIImageView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var likeButton: UIButton!

    weak var delegate: ImagesListCellDelegate?

    private let gradientHeight: CGFloat = 30
    private var gradientLayer: CAGradientLayer?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        cellImage.contentMode = .scaleAspectFill
        cellImage.clipsToBounds = true
        likeButton.adjustsImageWhenHighlighted = false
        likeButton.accessibilityLabel = "Like"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradientToImage()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
        cellImage.kf.indicatorType = .none

        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil

        dateLabel.text = nil
        delegate = nil
        likeButton.isEnabled = true
    }

    // MARK: - Configure
    func configure(with photo: Photo, dateFormatter: DateFormatter) {
        if let createdAt = photo.createdAt {
            dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            dateLabel.text = ""
        }

        setIsLiked(photo.isLiked)

        cellImage.kf.indicatorType = .activity
        let placeholder = UIImage(named: "placeholder")
        if let url = URL(string: photo.thumbImageURL) {
            let targetSize = CGSize(width: bounds.width, height: max(bounds.height, 200))
            let processor = DownsamplingImageProcessor(size: targetSize)
            cellImage.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [.processor(processor),
                          .scaleFactor(UIScreen.main.scale),
                          .transition(.fade(0.2)),
                          .cacheOriginalImage],
                completionHandler: { [weak self] _ in
                    self?.applyGradientToImage()
                }
            )
        } else {
            cellImage.image = placeholder
        }
    }

    // MARK: - Public
    func setIsLiked(_ isLiked: Bool) {
        let imageName = isLiked ? "like_button_on" : "like_button_off"
        likeButton.setImage(UIImage(named: imageName), for: .normal)
        likeButton.accessibilityValue = isLiked ? "liked" : "not liked"
    }

    func setLikeButtonEnabled(_ enabled: Bool) {
        likeButton.isEnabled = enabled
    }

    // MARK: - Private
    private func applyGradientToImage() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        guard cellImage.bounds.width > 0, cellImage.bounds.height > 0 else { return }

        let gradientColor = UIColor(named: "YP Black (iOS)") ?? .black
        let g = CAGradientLayer()
        g.frame = CGRect(
            x: 0,
            y: cellImage.bounds.height - gradientHeight,
            width: cellImage.bounds.width,
            height: gradientHeight
        )
        g.colors = [UIColor.clear.cgColor, gradientColor.withAlphaComponent(0.55).cgColor]
        g.locations = [0.0, 1.0]
        cellImage.layer.addSublayer(g)
        gradientLayer = g
    }

    // MARK: - Actions
    @IBAction private func likeButtonClicked() {
        delegate?.imagesListCellDidTapLike(self)
    }
}
