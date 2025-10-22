import Foundation

// Модель для декодирования JSON ответа
struct UserResult: Decodable {
    let profileImage: ProfileImage

    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }

    struct ProfileImage: Decodable {
        let small: String
    }
}

// Сервис для загрузки аватара
final class ProfileImageService {
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")

    static let shared = ProfileImageService()
    private init() {}

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    private(set) var avatarURL: String?

    /// Сброс состояния сервиса (для логаута)
    func reset() {
        task?.cancel()
        task = nil
        avatarURL = nil
        // Уведомим UI, что аватар сброшен
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: ProfileImageService.didChangeNotification,
                object: self,
                userInfo: ["URL": ""]
            )
        }
    }

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
            guard let self else { return }
            defer { self.task = nil }

            switch result {
            case .success(let userResult):
                let urlString = userResult.profileImage.small
                self.avatarURL = urlString
                print("[ProfileImageService]: Успех — avatar URL получен: \(urlString)")

                DispatchQueue.main.async {
                    completion(.success(urlString))
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": urlString]
                    )
                }

            case .failure(let error):
                self.log(error)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        task?.resume()
    }

    private func makeRequest(username: String) -> URLRequest? {
        guard
            let token = OAuth2TokenStorage.shared.token,
            let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "https://api.unsplash.com/users/\(encodedUsername)")
        else {
            print("[ProfileImageService]: Ошибка — отсутствует токен или некорректный username")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func log(_ error: NetworkError) {
        switch error {
        case .httpStatus(let code, _):
            print("[ProfileImageService]: NetworkError — httpStatus код ошибки \(code)")
        case .urlRequestError(let e):
            print("[ProfileImageService]: NetworkError — ошибка запроса: \(e.localizedDescription)")
        case .invalidResponse:
            print("[ProfileImageService]: NetworkError — некорректный ответ сервера")
        case .noData:
            print("[ProfileImageService]: NetworkError — отсутствуют данные")
        case .decodingError(let e):
            print("[ProfileImageService]: Ошибка декодирования: \(e.localizedDescription)")
        case .urlSessionError:
            print("[ProfileImageService]: NetworkError — ошибка сессии")
        }
    }
}
