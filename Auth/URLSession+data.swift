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
    @discardableResult
    func perform(
        _ request: URLRequest,
        completion: @escaping (Result<(Data, HTTPURLResponse), NetworkError>) -> Void
    ) -> URLSessionTask {
        let task = dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.urlRequestError(error)))
                    return
                }
                guard let http = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                if (200...299).contains(http.statusCode) {
                    completion(.success((data, http)))
                } else {
                    completion(.failure(.httpStatus(code: http.statusCode, data: data)))
                }
            }
        }
        return task
    }

    @discardableResult
    func objectTask<T: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) -> URLSessionTask {
        return perform(request) { result in
            switch result {
            case .success(let (data, _)):
                do {
                    let object = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

