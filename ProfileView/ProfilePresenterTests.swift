import XCTest
@testable import ImageFeed

final class ProfilePresenterTests: XCTestCase {

    func test_viewDidLoad_setsProfileAndAvatar_andReactsToNotification() {
        // given
        let profile = Profile(username: "nick", name: "Nick Fury", loginName: "@nick", bio: "S.H.I.E.L.D.")
        let pStub = ProfileServiceStub(profile: profile)
        let iStub = ProfileImageServiceStub(avatarURL: "https://example.com/a.png")
        let lSpy = LogoutServiceSpy()
        let nc = NotificationCenter()

        let sut = ProfilePresenter(
            profileService: pStub,
            profileImageService: iStub,
            logoutService: lSpy,
            notificationCenter: nc
        )
        let view = ProfileViewSpy()
        sut.view = view

        // when
        sut.viewDidLoad()

        // then
        XCTAssertEqual(view.setProfileCalls.count, 1)
        XCTAssertEqual(view.setProfileCalls.first?.loginName, "@nick")
        XCTAssertEqual(view.setAvatarCalls.count, 1)
        XCTAssertEqual(view.setAvatarCalls.first!, "https://example.com/a.png")

        // when (avatar changed)
        nc.post(name: ProfileImageService.didChangeNotification, object: nil, userInfo: ["URL": "https://example.com/b.png"])

        // then
        XCTAssertEqual(view.setAvatarCalls.last!, "https://example.com/b.png")
        XCTAssertEqual(view.setAvatarCalls.count, 2)
    }

    func test_didTapLogout_showsAlert() {
        let sut = ProfilePresenter(
            profileService: ProfileServiceStub(profile: nil),
            profileImageService: ProfileImageServiceStub(avatarURL: nil),
            logoutService: LogoutServiceSpy(),
            notificationCenter: .init()
        )
        let view = ProfileViewSpy()
        sut.view = view

        sut.didTapLogout()

        XCTAssertEqual(view.presentLogoutAlertCalls, 1)
    }

    func test_confirmLogout_callsLogout() {
        let lSpy = LogoutServiceSpy()
        let sut = ProfilePresenter(
            profileService: ProfileServiceStub(profile: nil),
            profileImageService: ProfileImageServiceStub(avatarURL: nil),
            logoutService: lSpy,
            notificationCenter: .init()
        )

        sut.confirmLogout()
        XCTAssertTrue(lSpy.called)
    }
}
