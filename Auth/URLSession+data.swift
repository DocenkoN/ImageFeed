import Foundation

// MARK: - Тип ошибок сети
enum NetworkError: Error {
    case httpStatus(code: Int, data: Data?)   // HTTP статус-код не 2xx
    case urlRequestError(Error)               // Ошибка при создании или отправке запроса
    case urlSessionError                      // Ошибка на уровне сессии
    case invalidResponse                      // Некорректный ответ (не HTTPURLResponse)
    case noData                               // Данных нет
    case decodingError(Error)                 // Ошибка при декодировании JSON
    case invalidRequest                       // Некорректный запрос
}

// MARK: - Расширение URLSession
extension URLSession {
    /// Метод: выполняет запрос и возвращает только `Data`
    @discardableResult
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.urlRequestError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            completion(.success(data))
        }
        task.resume()
        return task
    }

    /// Метод: выполняет запрос и сразу декодирует JSON в модель (`Decodable`)
    @discardableResult
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) -> URLSessionTask {
        return data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(.decodingError(error)))
                }

            case .failure(let error):
                if let netError = error as? NetworkError {
                    completion(.failure(netError))
                } else {
                    completion(.failure(.urlSessionError))
                }
            }
        }
    }
}
