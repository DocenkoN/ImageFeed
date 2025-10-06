import Foundation

// Модель для декодирования JSON ответа
struct UserResult: Codable {
    let profileImage: ProfileImage

    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }

    struct ProfileImage: Codable {
        let small: String
    }
}

// Сервис для загрузки аватара
final class ProfileImageService {
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    static let shared = ProfileImageService()
    private init() {}

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    private(set) var avatarURL: String?

    func fetchProfileImageURL(
        username: String,
        _ completion: @escaping (Result<String, NetworkError>) -> Void
    ) {
        task?.cancel()

        guard let request = makeRequest(username: username) else {
            print("[ProfileImageService]: Ошибка — не удалось создать URLRequest для пользователя \(username)")
            completion(.failure(.invalidResponse))
            return
        }

        task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, NetworkError>) in
            defer { self?.task = nil }

            switch result {
            case .success(let userResult):
                let urlString = userResult.profileImage.small
                self?.avatarURL = urlString
                print("[ProfileImageService]: Успех - avatar URL получен: \(urlString)")
                completion(.success(urlString))

                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": urlString]
                )

            case .failure(let error):
                switch error {
                case .httpStatus(let code, _):
                    print("[ProfileImageService]: NetworkError - httpStatus код ошибки \(code)")
                case .urlRequestError(let e):
                    print("[ProfileImageService]: NetworkError - ошибка запроса: \(e.localizedDescription)")
                case .invalidResponse:
                    print("[ProfileImageService]: NetworkError - некорректный ответ сервера")
                case .noData:
                    print("[ProfileImageService]: NetworkError - отсутствуют данные")
                case .decodingError(let e):
                    print("[ProfileImageService]: Ошибка декодирования: \(e.localizedDescription)")
                case .urlSessionError:
                    print("[ProfileImageService]: NetworkError - ошибка сессии")
                }
                completion(.failure(error))
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
