import Foundation

// MARK: - Модель для декодирования JSON ответа
struct UserResult: Codable {
    let profileImage: ProfileImage

    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }

    struct ProfileImage: Codable {
        let small: String
    }
}

// MARK: - Сервис для загрузки аватара
final class ProfileImageService {
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    static let shared = ProfileImageService()
    private init() {}

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    private(set) var avatarURL: String?

    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        guard let request = makeRequest(username: username) else {
            print("[ProfileImageService]: Ошибка — не удалось создать URLRequest для пользователя \(username)")
            completion(.failure(URLError(.badURL)))
            return
        }

        task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            DispatchQueue.main.async {
                defer { self?.task = nil }

                switch result {
                case .success(let userResult):
                    let urlString = userResult.profileImage.small
                    self?.avatarURL = urlString
                    completion(.success(urlString))

                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": urlString]
                    )
                case .failure(let error):
                    print("[ProfileImageService]: Ошибка загрузки аватарки — \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }

        task?.resume()
    }

    private func makeRequest(username: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("[ProfileImageService]: Ошибка — некорректный URL для пользователя \(username)")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
