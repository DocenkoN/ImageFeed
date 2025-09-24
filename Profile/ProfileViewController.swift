import UIKit
import Kingfisher   // понадобится для загрузки аватара

final class ProfileViewController: UIViewController {
    
    private var userPick = UIImage()
    private var userPickVeiw = UIImageView()
    private var nameLabel = UILabel()
    private var logoutButton = UIButton()
    private var loginLabel = UILabel()
    private var descriptionLabel = UILabel()
    
    private let mockName = "Иван Иванов"
    private let mockLoginName = "@ivan_ivanov"
    private let mockDescriptionLabel = "Hello, world!"
    
    // MARK: - Notification Observer
    private var profileImageServiceObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUIObjects()
        setupConstraints()
        
        // читаем профиль из profileService
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        }
        
        // подписка на обновление аватара
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.updateAvatar()
        }
        
        // обновляем аватар, если он уже был загружен
        updateAvatar()
    }
    
    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Update UI from Profile
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name
        loginLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else { return }
        
        // обновляем картинку с помощью Kingfisher
        userPickVeiw.kf.setImage(with: url, placeholder: UIImage(systemName: "person.crop.circle.fill"))
    }
    
    // MARK: - Setup View
    private func setupView() {
        view.contentMode = .scaleToFill
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
    }
    
    // MARK: - UI
    private func setupUIObjects() {
        setupUserPickVeiw()
        setupLogoutButton()
        setupNameLabel()
        setupLoginLabel()
        setupDescriptionLabel()
    }
    
    private func setupUserPickVeiw() {
        userPick = UIImage(named: "usepPick")
        ?? UIImage(systemName: "person.crop.circle.fill")
        ?? UIImage()
        
        userPickVeiw = UIImageView(image: userPick)
        userPickVeiw.layer.masksToBounds = true
        userPickVeiw.layer.cornerRadius = 35
        userPickVeiw.contentMode = .scaleAspectFill
        userPickVeiw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userPickVeiw)
    }
    
    private func setupLogoutButton() {
        let image = UIImage(named: "logOut")?.withRenderingMode(.alwaysOriginal)
        ?? UIImage(systemName: "arrow.backward")
        
        logoutButton = UIButton(type: .custom)
        logoutButton.setImage(image, for: .normal)
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        
        logoutButton.contentMode = .scaleToFill
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
    }
    
    private func setupNameLabel() {
        nameLabel.text = mockName
        nameLabel.textColor = UIColor(named: "YP White (iOS)")
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.contentMode = .left
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
    }
    
    private func setupLoginLabel() {
        loginLabel.text = mockLoginName
        loginLabel.textColor = UIColor(named: "YP Gray (iOS)")
        loginLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginLabel.contentMode = .left
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)
    }
    
    private func setupDescriptionLabel() {
        descriptionLabel.text = mockDescriptionLabel
        descriptionLabel.textColor = UIColor(named: "YP White (iOS)")
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.contentMode = .left
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        setupConstraintsUsepPick()
        setupConstraintsLogoutButton()
        setupConstraintsNameLabel()
        setupConstraintsLoginNameLabel()
        setupConstraintsDescriptionLabel()
    }
    
    private func setupConstraintsUsepPick() {
        NSLayoutConstraint.activate([
            userPickVeiw.widthAnchor.constraint(equalToConstant: 70),
            userPickVeiw.heightAnchor.constraint(equalTo: userPickVeiw.widthAnchor),
            userPickVeiw.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            userPickVeiw.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
        ])
    }
    
    private func setupConstraintsLogoutButton() {
        NSLayoutConstraint.activate([
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.centerYAnchor.constraint(equalTo: userPickVeiw.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
    }
    
    private func setupConstraintsNameLabel() {
        NSLayoutConstraint.activate([
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            nameLabel.leadingAnchor.constraint(equalTo: userPickVeiw.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: userPickVeiw.bottomAnchor, constant: 8),
        ])
    }
    
    private func setupConstraintsLoginNameLabel() {
        NSLayoutConstraint.activate([
            loginLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            loginLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
        ])
    }
    
    private func setupConstraintsDescriptionLabel() {
        NSLayoutConstraint.activate([
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 8),
        ])
    }
    
    // MARK: - Actions
    @objc private func didTapLogoutButton(_ sender: Any) {
        
    }
}
