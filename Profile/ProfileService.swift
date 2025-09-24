import Foundation

enum ProfileServiceError: Error {
    case invalidRequest
    case invalidResponse
    case decodingError
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
        
        guard let request = makeRequest(username: username) else {
            print("[ProfileService]: Ошибка — не удалось создать URLRequest для пользователя \(username)")
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.currentTask = nil
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode),
                    let data = data
                else {
                    completion(.failure(ProfileServiceError.invalidResponse))
                    return
                }
                
                do {
                    let profileResult = try JSONDecoder().decode(ProfileResult.self, from: data)
                    let profile = Profile(from: profileResult)
                    self.profile = profile
                    completion(.success(profile))
                } catch {
                    completion(.failure(ProfileServiceError.decodingError))
                }
            }
        }
        currentTask?.resume()
    }
    
    // MARK: - makeRequest
    private func makeRequest(username: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("[ProfileService]: Ошибка — некорректный URL для пользователя \(username)")
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

