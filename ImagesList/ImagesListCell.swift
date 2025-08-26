import UIKit

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
   
    @IBOutlet weak var cellImage: UIImageView!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var likeButton: UIButton!
    
    private let gradientHeight: CGFloat = 30
    private var gradientLayer: CAGradientLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradientToImage()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
    }
    
    private func applyGradientToImage() {
        
        gradientLayer?.removeFromSuperlayer()
        
        guard cellImage.bounds.height > 0 else { return }

        let gradientColor = UIColor(named: "YP Black (iOS)") ?? .black
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(
            x: 0,
            y: cellImage.bounds.height - gradientHeight,
            width: cellImage.bounds.width,
            height: gradientHeight
        )
        gradient.colors = [
            UIColor.clear.cgColor,
            gradientColor.withAlphaComponent(0.5).cgColor
        ]
        gradient.locations = [0.0, 1.0]

        cellImage.layer.addSublayer(gradient)
        gradientLayer = gradient
    }
}
