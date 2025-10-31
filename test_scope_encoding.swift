import Foundation

// Проверяем как кодируется scope в URL
let scope = "public+read_user+write_likes"
let authURLString = "https://unsplash.com/oauth/authorize"

guard var urlComponents = URLComponents(string: authURLString) else {
    print("❌ Не удалось создать URLComponents")
    exit(1)
}

urlComponents.queryItems = [
    URLQueryItem(name: "client_id", value: "test_key"),
    URLQueryItem(name: "redirect_uri", value: "imagefeed://auth"),
    URLQueryItem(name: "response_type", value: "code"),
    URLQueryItem(name: "scope", value: scope)
]

if let finalURL = urlComponents.url {
    print("✅ Final URL создан:")
    print("   \(finalURL.absoluteString)")
    print("\n📋 Разбор параметров:")
    if let query = finalURL.query {
        let params = query.components(separatedBy: "&")
        for param in params {
            print("   \(param)")
        }
    }
} else {
    print("❌ Final URL НЕ создан")
}

