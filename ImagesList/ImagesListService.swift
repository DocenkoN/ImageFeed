import Foundation

// MARK: - Protocol
protocol ImagesListServiceProtocol {
    var photos: [Photo] { get }
    func fetchPhotosNextPage(completion: @escaping (Result<[Photo], Error>) -> Void)
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Bool, Error>) -> Void)
}

// MARK: - Model (под Unsplash)
struct Photo: Equatable {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let fullImageURL: String
    var isLiked: Bool
}

// DTO из Unsplash
private struct PhotoResult: Decodable {
    struct Urls: Decodable { let thumb: String; let small: String; let regular: String }
    struct LikeUser: Decodable { let liked_by_user: Bool }
    let id: String
    let width: Int
    let height: Int
    let created_at: String?
    let description: String?
    let urls: Urls
    let liked_by_user: Bool
}

final class ImagesListService: ImagesListServiceProtocol {

    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    private let session: URLSession
    private(set) var photos: [Photo] = []
    private var isLoading = false
    private var nextPage = 1

    private init(session: URLSession = .shared) {
        self.session = session
    }

    // Сброс состояния сервиса (для логаута)
    func reset() {
        photos = []
        isLoading = false
        nextPage = 1
    }

    // MARK: - Fetch
    func fetchPhotosNextPage(completion: @escaping (Result<[Photo], Error>) -> Void) {
        guard !isLoading else { return }
        guard let token = OAuth2TokenStorage.shared.token, !token.isEmpty else {
            completion(.failure(NSError(domain: "Auth", code: 401)))
            return
        }
        isLoading = true

        var comps = URLComponents(string: "https://api.unsplash.com/photos")!
        comps.queryItems = [
            .init(name: "page", value: "\(nextPage)"),
            .init(name: "per_page", value: "10"),
            .init(name: "order_by", value: "latest")
        ]
        var request = URLRequest(url: comps.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            defer { self.isLoading = false }

            if let error { return DispatchQueue.main.async { completion(.failure(error)) } }

            guard
                let http = response as? HTTPURLResponse,
                (200...299).contains(http.statusCode),
                let data
            else {
                return DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Network", code: (response as? HTTPURLResponse)?.statusCode ?? -1)))
                }
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let iso = ISO8601DateFormatter()
                let results = try decoder.decode([PhotoResult].self, from: data)
                let mapped: [Photo] = results.map { dto in
                    let w = max(1, dto.width)
                    let h = max(1, dto.height)
                    return Photo(
                        id: dto.id,
                        size: CGSize(width: w, height: h),
                        createdAt: dto.created_at.flatMap { iso.date(from: $0) },
                        welcomeDescription: dto.description,
                        thumbImageURL: dto.urls.small,
                        largeImageURL: dto.urls.regular,
                        fullImageURL: dto.urls.regular,
                        isLiked: dto.liked_by_user
                    )
                }
                self.photos.append(contentsOf: mapped)
                self.nextPage += 1
                DispatchQueue.main.async { completion(.success(mapped)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        task.resume() // ВАЖНО
    }

    // MARK: - Like / Unlike
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NSError(domain: "Auth", code: 401))); return
        }
        let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like")!
        var req = URLRequest(url: url)
        req.httpMethod = isLike ? "POST" : "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = session.dataTask(with: req) { [weak self] data, response, error in
            if let error { return DispatchQueue.main.async { completion(.failure(error)) } }
            guard (response as? HTTPURLResponse).map({ (200...299).contains($0.statusCode) }) == true else {
                return DispatchQueue.main.async { completion(.failure(NSError(domain: "Network", code: -1))) }
            }
            // локально обновим
            if let idx = self?.photos.firstIndex(where: { $0.id == photoId }) {
                self?.photos[idx].isLiked = isLike
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self,
                        userInfo: ["updatedIndex": idx]
                    )
                }
            }
            DispatchQueue.main.async { completion(.success(isLike)) }
        }
        task.resume()
    }
}
