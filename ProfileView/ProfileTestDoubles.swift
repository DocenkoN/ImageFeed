import Foundation
@testable import ImageFeed

final class ProfileViewSpy: ProfileViewProtocol {
    private(set) var setProfileCalls: [Profile] = []
    private(set) var setAvatarCalls: [String?] = []
    private(set) var presentLogoutAlertCalls = 0

    func setProfile(_ profile: Profile) { setProfileCalls.append(profile) }
    func setAvatar(urlString: String?) { setAvatarCalls.append(urlString) }
    func presentLogoutAlert() { presentLogoutAlertCalls += 1 }
}

// Стаб-зависимости — реализуем протоколы из ProfilePresenter.swift (видны через @testable)
final class ProfileServiceStub: ProfileServiceProviding {
    let profile: Profile?
    init(profile: Profile?) { self.profile = profile }
}

final class ProfileImageServiceStub: ProfileImageServiceProviding {
    let avatarURL: String?
    init(avatarURL: String?) { self.avatarURL = avatarURL }
}

final class LogoutServiceSpy: ProfileLogoutServicing {
    private(set) var called = false
    func logout() { called = true }
}
