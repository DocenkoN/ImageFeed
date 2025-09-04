import Foundation
import WebKit

struct OAuthTokenResponseBody: Codable {
    let accessToken: String
    let tokenType: String?
    let scope: String?
    let createdAt: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType   = "token_type"
        case scope
        case createdAt   = "created_at"
    }
}

enum OAuth2ServiceError: Error {
    case badRequestBuild
    case transport(Error)
    case invalidResponse
    case httpStatus(Int, Data?)
    case decoding(Error)
}

final class OAuth2Service {

    // 1) Построение POST-запроса
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id",     value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri",  value: Constants.redirectURI),
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "grant_type",    value: "authorization_code"),
        ]

        guard let url = urlComponents.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // (по спецификации Unsplash token endpoint принимает в query, хедеры не обязательны)
        return request
    }

    // 2) Выполнение запроса и парсинг токена
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(OAuth2ServiceError.badRequestBuild))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            // транспортная ошибка
            if let error = error {
                completion(.failure(OAuth2ServiceError.transport(error)))
                return
            }

            guard
                let http = response as? HTTPURLResponse,
                let data = data
            else {
                completion(.failure(OAuth2ServiceError.invalidResponse))
                return
            }

            // проверим статус-код
            guard (200...299).contains(http.statusCode) else {
                completion(.failure(OAuth2ServiceError.httpStatus(http.statusCode, data)))
                return
            }

            do {
                let body = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                completion(.success(body.accessToken))
            } catch {
                completion(.failure(OAuth2ServiceError.decoding(error)))
            }
        }.resume()
    }
}
