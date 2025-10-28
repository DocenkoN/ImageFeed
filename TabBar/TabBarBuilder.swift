import UIKit

enum TabBarBuilder {
    static func build() -> UITabBarController {
        let tabBar = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController

        // Обходим все вкладки и БЕЗ KVC настраиваем нужные VC
        (tabBar.viewControllers ?? []).forEach { root in
            if let nav = root as? UINavigationController {
                nav.viewControllers.forEach { vc in
                    configureIfNeeded(vc)
                }
            } else {
                configureIfNeeded(root)
            }
        }

        tabBar.selectedIndex = 0
        return tabBar
    }

    private static func configureIfNeeded(_ vc: UIViewController) {
        switch vc {
        case let feed as ImagesListViewController:
            // просто конфигурируем — configure() должна быть идемпотентной
            feed.configure(ImagesListPresenter())

        case let profile as ProfileViewController:
            profile.configure(ProfilePresenter())

        default:
            break
        }
    }
}
