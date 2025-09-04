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
}

