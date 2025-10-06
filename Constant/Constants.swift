import UIKit

enum WebViewConstants {
    static let unsplashBaseURLString = "https://unsplash.com"
    static let unsplashAuthorizeURLString = unsplashBaseURLString + "/oauth/authorize"
    static let unsplashTokenURLString = unsplashBaseURLString + "/oauth/token"
}

enum Constants {
    static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.unsplash.com") else {
            preconditionFailure("Invalid defaultBaseURL")
        }
        return url
    }()
    static let accessKey = "HGZqGD_jDTvxAilpbSL-Ht8_GaIuTvkvtaPxuJfZWPg"
    static let secretKey = "k6n2d6jIvk36vHi9yixAGuZp4JuYaH2vbhc3A7V-p18"
    static let redirectURI = "imagefeed://auth"
    static let accessScope = "public+read_user+write_likes"
}
enum OtherConstants {
    static let floatComparisonEpsilon: Double = 0.0001
}
