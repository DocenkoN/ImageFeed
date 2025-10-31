import Foundation
@testable import ImageFeed

final class ProfileViewSpy: ProfileViewProtocol {
    private(set) var setProfileCalls: [Profile] = []
    private(set) var clearProfileCalls = 0
    private(set) var setAvatarCalls: [String?] = []
    private(set) var presentLogoutAlertCalls = 0

    func setProfile(_ profile: Profile) { setProfileCalls.append(profile) }
    func clearProfile() { clearProfileCalls += 1 }
    func setAvatar(urlString: String?) { setAvatarCalls.append(urlString) }
    func presentLogoutAlert() { presentLogoutAlertCalls += 1 }
}

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
