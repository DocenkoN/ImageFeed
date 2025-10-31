import Foundation
import UIKit

// Зависимости как протоколы
protocol ProfileServiceProviding {
    var profile: Profile? { get }
}
protocol ProfileImageServiceProviding {
    var avatarURL: String? { get }
}
protocol ProfileLogoutServicing {
    func logout()
}

// Адаптеры к вашим синглтонам
struct _ProfileServiceAdapter: ProfileServiceProviding { var profile: Profile? { ProfileService.shared.profile } }
struct _ProfileImageServiceAdapter: ProfileImageServiceProviding { var avatarURL: String? { ProfileImageService.shared.avatarURL } }
struct _ProfileLogoutServiceAdapter: ProfileLogoutServicing { func logout() { ProfileLogoutService.shared.logout() } }

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?

    private let profileService: ProfileServiceProviding
    private let profileImageService: ProfileImageServiceProviding
    private let logoutService: ProfileLogoutServicing
    private let notificationCenter: NotificationCenter

    private var avatarObserver: NSObjectProtocol?

    init(
        profileService: ProfileServiceProviding = _ProfileServiceAdapter(),
        profileImageService: ProfileImageServiceProviding = _ProfileImageServiceAdapter(),
        logoutService: ProfileLogoutServicing = _ProfileLogoutServiceAdapter(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.logoutService = logoutService
        self.notificationCenter = notificationCenter
    }

    deinit {
        if let avatarObserver { notificationCenter.removeObserver(avatarObserver) }
    }

    func viewDidLoad() {
        if let profile = profileService.profile {
            view?.setProfile(profile)
        } else {
            // Если данные профиля не подтянулись - очищаем поля
            view?.clearProfile()
        }
        view?.setAvatar(urlString: profileImageService.avatarURL)

        avatarObserver = notificationCenter.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let url = (note.userInfo?["URL"] as? String)
            self.view?.setAvatar(urlString: url ?? self.profileImageService.avatarURL)
        }
    }

    func didTapLogout() {
        view?.presentLogoutAlert()
    }

    func confirmLogout() {
        logoutService.logout()
    }
}
