import Foundation
import CoreGraphics
import UIKit

// MARK: - UI-модель
struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let fullImageURL: String
    let isLiked: Bool
}

// MARK: - Сервис ленты
final class ImagesListService {

    // Можно использовать как синглтон при логауте
    static let shared = ImagesListService()

    // Публичные данные и нотификация
    private(set) var photos: [Photo] = []
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    // Приватное состояние
    private var lastLoadedPage: Int?
    private var pagingTask: URLSessionTask?                // текущая задача постраничной загрузки
    private var likeTasks: [String: URLSessionTask] = [:]  // задачи лайков по photoId
    private let urlSession: URLSession = .shared

    // MARK: - DTO / Unsplash
    private struct PhotoResult: Decodable {
        let id: String
        let createdAt: Date?
        let width: Int
        let height: Int
        let likedByUser: Bool
        let description: String?
        let urls: UrlsResult

        enum CodingKeys: String, CodingKey {
            case id
            case createdAt = "created_at"
            case width, height
            case likedByUser = "liked_by_user"
            case description
            case urls
        }
    }

    private struct UrlsResult: Decodable {
        let raw: String
        let full: String
        let regular: String
        let small: String
        let thumb: String
    }

    // MARK: - Декодер дат Unsplash
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)
            let fmts = [
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            ]
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            for f in fmts {
                df.dateFormat = f
                if let date = df.date(from: s) { return date }
            }
            let iso = ISO8601DateFormatter()
            if let date = iso.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported date format: \(s)")
        }
        return d
    }()

    // MARK: - Thread helper
    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    // MARK: - Публичный API
    var isLoading: Bool { pagingTask != nil }

    /// Сброс состояния (для логаута)
    func reset() {
        pagingTask?.cancel()
        pagingTask = nil
        likeTasks.values.forEach { $0.cancel() }
        likeTasks.removeAll()
        photos.removeAll()
        lastLoadedPage = nil
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
    }

    /// Загружает следующую страницу фото.
    @discardableResult
    func fetchPhotosNextPage() -> URLSessionTask? {
        guard pagingTask == nil else { return pagingTask }

        guard let token = OAuth2TokenStorage.shared.token else {
            assertionFailure("No OAuth token")
            return nil
        }

        let nextPage = (lastLoadedPage ?? 0) + 1

        var components = URLComponents(string: "https://api.unsplash.com/photos")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(nextPage)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        pagingTask = urlSession.data(for: request) { [weak self] result in
            guard let self else { return }
            defer { self.pagingTask = nil }

            switch result {
            case .success(let data):
                do {
                    let dtos = try Self.decoder.decode([PhotoResult].self, from: data)
                    let newPhotos: [Photo] = dtos.map { dto in
                        Photo(
                            id: dto.id,
                            size: CGSize(width: dto.width, height: dto.height),
                            createdAt: dto.createdAt,
                            welcomeDescription: dto.description,
                            thumbImageURL: dto.urls.thumb,
                            largeImageURL: dto.urls.regular,   // regular — под список
                            fullImageURL: dto.urls.full,       // ← full для полноэкрана
                            isLiked: dto.likedByUser
                        )
                    }

                    self.onMain {
                        self.photos.append(contentsOf: newPhotos)
                        self.lastLoadedPage = nextPage
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self
                        )
                    }
                } catch {
                    print("[ImagesListService]: decode error:", error)
                }

            case .failure(let error):
                print("[ImagesListService]: network error:", error)
            }
        }

        return pagingTask
    }

    /// Лайк/анлайк фото.
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        if likeTasks[photoId] != nil {
            onMain { completion(.success(())) }
            return
        }

        guard let token = OAuth2TokenStorage.shared.token else {
            onMain { completion(.failure(NSError(domain: "NoToken", code: -1))) }
            return
        }
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            onMain { completion(.failure(NSError(domain: "BadURL", code: -2))) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = urlSession.data(for: request) { [weak self] result in
            guard let self else { return }
            defer { self.likeTasks[photoId] = nil }

            switch result {
            case .success:
                self.onMain {
                    if let idx = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let p = self.photos[idx]
                        let updated = Photo(
                            id: p.id,
                            size: p.size,
                            createdAt: p.createdAt,
                            welcomeDescription: p.welcomeDescription,
                            thumbImageURL: p.thumbImageURL,
                            largeImageURL: p.largeImageURL,
                            fullImageURL: p.fullImageURL,   // не теряем full
                            isLiked: !p.isLiked
                        )
                        self.photos[idx] = updated

                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self,
                            userInfo: ["updatedIndex": idx] // для точечного апдейта в VC
                        )
                    }
                    completion(.success(()))
                }

            case .failure(let error):
                self.onMain { completion(.failure(error)) }
            }
        }

        likeTasks[photoId] = task
    }
}

