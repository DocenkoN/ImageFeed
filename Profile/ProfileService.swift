import Foundation

enum ProfileServiceError: Error {
    case invalidRequest
    case invalidResponse
}

// MARK: - UI-модель профиля
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?

    init(from result: ProfileResult) {
        self.username = result.username
        self.name = [result.firstName, result.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        self.loginName = "@\(result.username)"
        self.bio = result.bio
    }
}

// MARK: - Модель для декодирования JSON от API
struct ProfileResult: Codable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?
    let profileImage: ProfileImage?

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
        case profileImage = "profile_image"
    }

    struct ProfileImage: Codable {
        let small: String?
        let medium: String?
        let large: String?
    }
}

// MARK: - Сервис для загрузки профиля
final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private var currentTask: URLSessionTask?
    private(set) var profile: Profile?

    func fetchProfile(username: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        currentTask?.cancel()

        guard let request = makeProfileRequest(username: username) else {
            print("[ProfileService]: Ошибка — не удалось создать URLRequest для пользователя \(username)")
