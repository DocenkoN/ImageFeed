import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let dataStorage = OAuth2TokenStorage()
    private let urlSession = URLSession.shared

    private var task: URLSessionTask?
    private var lastCode: String?
    private var completionHandlers: [(Result<String, Error>) -> Void] = []

    private(set) var authToken: String? {
        get { dataStorage.token }
        set { dataStorage.token = newValue }
    }

    private init() {}

    func fetchOAuthToken(
        _ code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        if lastCode == code {
            completionHandlers.append(completion)
            return
        }

        task?.cancel()
        completionHandlers.forEach { $0(.failure(AuthServiceError.invalidRequest)) }
        completionHandlers = [completion]
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service]: Ошибка — не удалось создать URLRequest")
            finish(.failure(AuthServiceError.invalidRequest))
            return
        }

        // Используем objectTask
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, NetworkError>) in
            guard let self = self else { return }
            
            defer {
                self.task = nil
                self.lastCode = nil
            }

            switch result {
            case .success(let decodedData):
                self.authToken = decodedData.accessToken
                self.finish(.success(decodedData.accessToken))
            case .failure(let error):
                print("[OAuth2Service]: Ошибка выполнения запроса — \(error)")
                self.finish(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }

    private func finish(_ result: Result<String, Error>) {
        let handlers = completionHandlers
        completionHandlers = []
        handlers.forEach { $0(result) }
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            assertionFailure("Failed to create URL")
            return nil
        }

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)
        return request
    }

    private struct OAuthTokenResponseBody: Codable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }
}
