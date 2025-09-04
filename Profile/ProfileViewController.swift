import UIKit

class ProfileViewController: UIViewController {
    
    private var userPick = UIImage()
    private var userPickVeiw = UIImageView()
    private var nameLabel = UILabel()
    private var logoutButton = UIButton()
    private var loginLabel = UILabel()
    private var descriptionLabel = UILabel()
    
    private let mockName = "Екатерина Новикова"
    private let mockLoginName = "@ekaterina_novikova"
    private let mockDescriptionLabel = "Hello, world!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUIObjects()
        setupConstraints()
    }
    
    private func setupView() {
        view.contentMode = .scaleToFill
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
    }
    
    // UI
    
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
        userPickVeiw.layer.masksToBounds = false
        userPickVeiw.layer.cornerRadius = 35
        userPickVeiw.contentMode = .scaleAspectFit
        userPickVeiw.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userPickVeiw)
    }

    private func setupLogoutButton() {
        let image = UIImage(named: "logOut")?.withRenderingMode(.alwaysOriginal) ?? UIImage(systemName: "arrow.backward")!
        
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
    
    // констрейны
    
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
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 16),
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
        
    //
    @objc private func didTapLogoutButton(_ sender: Any) {}
}
