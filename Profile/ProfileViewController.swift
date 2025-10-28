import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {

    // MARK: - UI
    private let userPickView = UIImageView()
    private let nameLabel = UILabel()
    private let logoutButton = UIButton(type: .custom)
    private let loginLabel = UILabel()
    private let descriptionLabel = UILabel()

    // MARK: - MVP
    private var presenter: ProfilePresenterProtocol?

    // Инъекция презентера (для VC из Storyboard)
    func configure(_ presenter: ProfilePresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
        #if DEBUG
        print("[ProfileVC] configure()")
        #endif
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUIObjects()
        setupConstraints()

        if presenter == nil {
            #if DEBUG
            // Фолбэк в DEBUG/UI-тестах, чтобы не падать, а увидеть проблему в логах
            print("[ProfileVC] ⚠️ presenter == nil в viewDidLoad — автоинъекция")
            configure(ProfilePresenter())
            #else
            assertionFailure("ProfilePresenterProtocol не сконфигурирован. Вызови configure(_:) до показа VC.")
            return
            #endif
        }

        presenter?.viewDidLoad()
    }

    // MARK: - UI setup
    private func setupView() {
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
    }

    private func setupUIObjects() {
        setupUserPickView()
        setupLogoutButton()
        setupNameLabel()
        setupLoginLabel()
        setupDescriptionLabel()

        // Accessibility для UI-тестов
        userPickView.isAccessibilityElement = true
        userPickView.accessibilityIdentifier = "Profile.avatar"

        nameLabel.isAccessibilityElement = true
        nameLabel.accessibilityIdentifier = "Profile.username"

        logoutButton.isAccessibilityElement = true
        logoutButton.accessibilityIdentifier = "Profile.logoutButton"
    }

    private func setupUserPickView() {
        userPickView.layer.masksToBounds = true
        userPickView.layer.cornerRadius = 35
        userPickView.contentMode = .scaleAspectFill
        userPickView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userPickView)
    }

    private func setupLogoutButton() {
        let image = UIImage(named: "logOut")?.withRenderingMode(.alwaysOriginal)
            ?? UIImage(systemName: "arrow.backward")
        logoutButton.setImage(image, for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        view.addSubview(logoutButton)
    }

    private func setupNameLabel() {
        nameLabel.textColor = UIColor(named: "YP White (iOS)")
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
    }

    private func setupLoginLabel() {
        loginLabel.textColor = UIColor(named: "YP Gray (iOS)")
        loginLabel.font = UIFont.systemFont(ofSize: 13)
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)
    }

    private func setupDescriptionLabel() {
        descriptionLabel.textColor = UIColor(named: "YP White (iOS)")
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            userPickView.widthAnchor.constraint(equalToConstant: 70),
            userPickView.heightAnchor.constraint(equalTo: userPickView.widthAnchor),
            userPickView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            userPickView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),

            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.centerYAnchor.constraint(equalTo: userPickView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            nameLabel.leadingAnchor.constraint(equalTo: userPickView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: userPickView.bottomAnchor, constant: 8),

            loginLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),

            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 8)
        ])
    }

    // MARK: - Actions
    /// internal (доступно для @testable в тестах)
    @objc func didTapLogout() {
        guard let presenter else {
            #if DEBUG
            print("[ProfileVC] ⚠️ didTapLogout без презентера — игнор")
            #else
            assertionFailure("Presenter отсутствует")
            #endif
            return
        }
        presenter.didTapLogout()
    }
}

// MARK: - ProfileViewProtocol
extension ProfileViewController: ProfileViewProtocol {
    func setProfile(_ profile: Profile) {
        nameLabel.text = profile.name
        loginLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
    }

    func setAvatar(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else {
            userPickView.image = UIImage(named: "avatar") ?? UIImage(systemName: "person.crop.circle.fill")
            return
        }
        let placeholder = UIImage(named: "avatar") ?? UIImage(systemName: "person.crop.circle.fill")
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        userPickView.kf.indicatorType = .activity
        userPickView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ]
        )
    }

    func presentLogoutAlert() {
        let alert = UIAlertController(
            title: "Выйти из аккаунта?",
            message: "Понадобится повторный вход.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.presenter?.confirmLogout()
        })
        present(alert, animated: true)
    }
}
