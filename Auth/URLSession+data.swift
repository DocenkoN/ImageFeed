import Foundation

enum NetworkError: Error {
    case httpStatus(code: Int, data: Data?)
    case urlRequestError(Error)
    case urlSessionError
    case invalidResponse
    case noData
    case decodingError(Error)
}

extension URLSession {
    /// Аналог data(for:) с Result<Data, NetworkError> и логированием ошибок.
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<Data, NetworkError>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let task = dataTask(with: request) { data, response, error in
            // Обработка ошибок и логирование перед отдачей в completion
            if let error = error {
                print("[dataTask]: NetworkError - ошибка запроса (urlRequestError): \(error.localizedDescription)")
                fulfillCompletionOnTheMainThread(.failure(.urlRequestError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[dataTask]: NetworkError - некорректный ответ (invalidResponse)")
                fulfillCompletionOnTheMainThread(.failure(.invalidResponse))
                return
            }

            guard let data = data else {
                print("[dataTask]: NetworkError - отсутствуют данные (noData)")
                fulfillCompletionOnTheMainThread(.failure(.noData))
                return
            }

            if (200 ..< 300).contains(httpResponse.statusCode) {
                fulfillCompletionOnTheMainThread(.success(data))
            } else {
                print("[dataTask]: NetworkError - httpStatus код ошибки \(httpResponse.statusCode)")
                fulfillCompletionOnTheMainThread(.failure(.httpStatus(code: httpResponse.statusCode, data: data)))
            }
        }

        task.resume() // ← ОБЯЗАТЕЛЬНО: запускаем запрос
        return task
    }

    /// Дженериковое objectTask: делает data(...) и декодирует Data -> T с логированием ошибок декодирования
    @discardableResult
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()

        let task = data(for: request) { result in
            switch result {
            case .failure(let error):
                // Прокидываем NetworkError дальше, лог уже сделан в data(for:)
                print("[objectTask]: NetworkError - прокидываем ошибку \(error)")
                completion(.failure(error))

            case .success(let data):
                do {
                    let object = try decoder.decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    let dataString = String(data: data, encoding: .utf8) ?? "<не смогли получить строковое представление данных>"
                    print("[objectTask]: Ошибка декодирования: \(error.localizedDescription), Данные: \(dataString)")
                    completion(.failure(.decodingError(error)))
                }
            }
        }

        return task
    }
}
