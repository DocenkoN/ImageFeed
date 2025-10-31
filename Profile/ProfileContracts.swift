import Foundation

protocol ProfileViewProtocol: AnyObject {
    func setProfile(_ profile: Profile)
    func clearProfile()
    func setAvatar(urlString: String?)
    func presentLogoutAlert()
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
    func confirmLogout()
}
