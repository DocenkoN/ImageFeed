import Foundation

enum OAuth2ServiceError: Error {
    case badRequestBuild
    case transport(Error)
    case invalidResponse
    case httpStatus(Int, Data?)
    case decoding(Error)
}

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else { return nil }
        
        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id",     value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri",  value: Constants.redirectURI),
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "grant_type",    value: "authorization_code")
        ]
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)
        return request
    }

    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            DispatchQueue.main.async {
                completion(.failure(OAuth2ServiceError.badRequestBuild))
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка сети: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.transport(error)))
                }
                return
            }
            
            guard let http = response as? HTTPURLResponse, let data = data else {
                print("Некорректный ответ сервера")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.invalidResponse))
                }
                return
            }
            
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("Ошибка сервиса: код \(http.statusCode), ответ: \(body)")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.httpStatus(http.statusCode, data)))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(body.accessToken))
                }
            } catch {
                print("Ошибка декодирования: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.decoding(error)))
                }
            }
        }.resume()
    }
}

