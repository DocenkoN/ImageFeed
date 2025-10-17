import Foundation

enum ProfileServiceError: Error {
    case invalidRequest
    case invalidResponse
    case decodingError
}

// UI-модель профиля
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

// Модель для декодирования JSON от API
struct ProfileResult: Decodable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

// Сервис для загрузки профиля
final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private var currentTask: URLSessionTask?
    private(set) var profile: Profile?

    /// Сброс состояния сервиса (для логаута)
    func reset() {
        currentTask?.cancel()
        currentTask = nil
        profile = nil
    }

    func fetchProfile(completion: @escaping (Result<Profile, Error>) -> Void) {
        currentTask?.cancel()

        guard let request = makeRequest() else {
            print("[ProfileService]: Ошибка — не удалось создать запрос /me (нет токена или URL)")
            DispatchQueue.main.async { completion(.failure(ProfileServiceError.invalidRequest)) }
            return
        }

        currentTask = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentTask = nil

                switch result {
                case .success(let profileResult):
                    let profile = Profile(from: profileResult)
                    self.profile = profile
                    completion(.success(profile))

                case .failure(let error):
                    self.log(error)
                    completion(.failure(error))
                }
            }
        }


        currentTask?.resume()
    }

    private func makeRequest() -> URLRequest? {
        guard
            let token = OAuth2TokenStorage.shared.token,
            let url = URL(string: "https://api.unsplash.com/me")
        else {
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
            print("[ProfileService]: NetworkError — httpStatus код ошибки \(code)")
        case .urlRequestError(let e):
            print("[ProfileService]: NetworkError — ошибка запроса: \(e.localizedDescription)")
        case .invalidResponse:
            print("[ProfileService]: NetworkError — некорректный ответ сервера")
        case .noData:
            print("[ProfileService]: NetworkError — отсутствуют данные")
        case .decodingError(let e):
            print("[ProfileService]: Ошибка декодирования: \(e.localizedDescription)")
        case .urlSessionError:
            print("[ProfileService]: NetworkError — ошибка сессии")
        }
    }
}
