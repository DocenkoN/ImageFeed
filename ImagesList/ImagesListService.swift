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

    static let shared = ImagesListService()

    private(set) var photos: [Photo] = []
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    private var lastLoadedPage: Int?
    private var pagingTask: URLSessionTask?
    private var likeTasks: [String: URLSessionTask] = [:]
    private let urlSession: URLSession = .shared

    // MARK: - DTO / Unsplash
    private struct PhotoResult: Decodable {
        let id: String
        let createdAt: String        // ← строка, как приходит из JSON
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

    // MARK: - Thread helper
    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    private enum DateParsers {
        static let iso8601 = ISO8601DateFormatter()
    }

    // MARK: - Публичный API
    var isLoading: Bool { pagingTask != nil }

    func reset() {
        pagingTask?.cancel()
        pagingTask = nil
        likeTasks.values.forEach { $0.cancel() }
        likeTasks.removeAll()
        photos.removeAll()
        lastLoadedPage = nil
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
    }

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
                    let dtos = try JSONDecoder().decode([PhotoResult].self, from: data)
                    let newPhotos: [Photo] = dtos.map { dto in
                        let date = DateParsers.iso8601.date(from: dto.createdAt) // Date?
                        return Photo(
                            id: dto.id,
                            size: CGSize(width: dto.width, height: dto.height),
                            createdAt: date,
                            welcomeDescription: dto.description,
                            thumbImageURL: dto.urls.thumb,
                            largeImageURL: dto.urls.regular,
                            fullImageURL: dto.urls.full,
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
                    print("[ImagesListService] decode error — \(error)")
                }

            case .failure(let error):
                print("[ImagesListService] network error — \(error)")
            }
        }

        return pagingTask
    }

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
                            fullImageURL: p.fullImageURL,
                            isLiked: !p.isLiked
                        )
                        self.photos[idx] = updated
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self,
                            userInfo: ["updatedIndex": idx]
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
