import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let dataStorage = OAuth2TokenStorage()
    private let urlSession = URLSession.shared

    // Текущий активный запрос
    private var task: URLSessionTask?

    // Код, по которому идёт текущий запрос
    private var lastCode: String?

    // Все замыкания для текущего кода
    private var completionHandlers: [(Result<String, Error>) -> Void] = []

    private(set) var authToken: String? {
        get { dataStorage.token }
        set { dataStorage.token = newValue }
    }

    private init() {}

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        // Если запрос уже идёт с этим же кодом, просто добавляем completion
        if lastCode == code {
            completionHandlers.append(completion)
            return
        }

        // Если пришёл новый код, отменяем старый запрос и возвращаем error старым completions
        task?.cancel()
        if !completionHandlers.isEmpty {
            completionHandlers.forEach { $0(.failure(AuthServiceError.invalidRequest)) }
        }
        completionHandlers = [completion]
        lastCode = code

        // Создаём URLRequest
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service]: Ошибка — не удалось создать URLRequest для получения токена")
            finish(.failure(AuthServiceError.invalidRequest))
            return
        }

        // Используем objectTask (с декодированием в OAuthTokenResponseBody)
        let objectTask = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, NetworkError>) in
            DispatchQueue.main.async {
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
                    // Логирование ошибки в едином формате
                    switch error {
                    case .httpStatus(let code, _):
                        print("[OAuth2Service]: NetworkError - httpStatus код ошибки \(code)")
                    case .urlRequestError(let e):
                        print("[OAuth2Service]: NetworkError - ошибка запроса: \(e.localizedDescription)")
                    case .invalidResponse:
                        print("[OAuth2Service]: NetworkError - некорректный ответ сервера")
                    case .noData:
                        print("[OAuth2Service]: NetworkError - отсутствуют данные")
                    case .decodingError(let e):
                        print("[OAuth2Service]: Ошибка декодирования: \(e.localizedDescription)")
                    case .urlSessionError:
                        print("[OAuth2Service]: NetworkError - ошибка сессии")
                    }
                    self.finish(.failure(error))
                }
            }
        }

        self.task = objectTask
        objectTask.resume()
    }

    // Вызов всех completions и очистка массива
    private func finish(_ result: Result<String, Error>) {
        let handlers = completionHandlers
        completionHandlers = []
        handlers.forEach { $0(result) }
    }

    // Создание запроса на получение токена
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

    private struct OAuthTokenResponseBody: Decodable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }
}
