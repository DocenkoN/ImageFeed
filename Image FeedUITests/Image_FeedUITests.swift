import XCTest
@testable import ImageFeed

final class ImageFeedUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTest"]
        app.launch()
    }
    
    private func authenticateIfNeeded() {
        // Проверяем, нужно ли авторизоваться
        let loginButton = app.buttons["Войти"]
        guard loginButton.waitForExistence(timeout: 3) && loginButton.isHittable else {
            return // Уже авторизованы
        }
        
        // Авторизуемся
        loginButton.tap()
        
        // Ждем появления WebView
        let webView = app.webViews["UnsplashWebView"]
        guard webView.waitForExistence(timeout: 15) else {
            return
        }
        
        sleep(2)
        
        // Вводим логин
        let loginTextField = webView.descendants(matching: .textField).element
        if loginTextField.waitForExistence(timeout: 10) {
            loginTextField.tap()
            sleep(1)
            loginTextField.typeText("_____")
            if app.toolbars.buttons["Done"].exists {
                app.toolbars.buttons["Done"].tap()
            }
        }
        
        // Вводим пароль
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        if passwordTextField.waitForExistence(timeout: 10) {
            passwordTextField.tap()
            sleep(1)
            passwordTextField.typeText("_____")
            if app.toolbars.buttons["Done"].exists {
                app.toolbars.buttons["Done"].tap()
            }
        }
        
        sleep(2)
        
        // Нажимаем Login
        let unsplashLoginButton = webView.buttons["Login"]
        if unsplashLoginButton.waitForExistence(timeout: 10) {
            if !unsplashLoginButton.isHittable {
                webView.swipeDown()
                sleep(1)
            }
            if unsplashLoginButton.isHittable {
                unsplashLoginButton.tap()
            } else {
                let coordinate = unsplashLoginButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                coordinate.tap()
            }
        }
        
        // Ждем завершения авторизации
        let tablesQuery = app.tables
        _ = tablesQuery.cells.element(boundBy: 0).waitForExistence(timeout: 15)
    }

    func testAuth() throws {
<<<<<<< HEAD
        // 1. Нажать кнопку авторизации
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
        authButton.tap()

        // 2. Подождать, пока экран авторизации загрузится
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 10))

        // 3. Ввести логин
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        loginTextField.tap()
        loginTextField.typeText("***")
        webView.swipeUp() // скрыть клавиатуру

        // 4. Ввести пароль
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField.tap()
        passwordTextField.typeText("***")
        webView.swipeUp()

        // 5. Нажать кнопку логина
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
=======
        // Ждем появления и тапаем кнопку входа
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5), "Кнопка 'Войти' не найдена")
        XCTAssertTrue(loginButton.isHittable, "Кнопка 'Войти' недоступна")
>>>>>>> 08a83ef (все тесты кроме UI проходят, какие то проблемы с сетью или с unsplash)
        loginButton.tap()
        //нажали кнопку войти

        let isUITest = ProcessInfo.processInfo.arguments.contains("-uiTest")
        //проверили режим теста,чтобы остановить загрузку ленты

        // Ждем появления WebView
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15), "WebView не загрузилось")
        //ждем появления страницы 15 сек, с VPN у меня туго работает
        
        // Небольшая задержка для полной загрузки страницы
        sleep(2)

        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 10), "Поле не найдено")
        //ищем поле логина

        loginTextField.tap()
        sleep(1) // Задержка для появления клавиатуры
        loginTextField.typeText("_____")
        //вводим логин

        // Нажимаем Done на клавиатуре, чтобы закрыть её после ввода логина
        if app.toolbars.buttons["Done"].exists {
            app.toolbars.buttons["Done"].tap()
        }

        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10), "Поле password не найдено")
        //нашли поле ввода пароля

        passwordTextField.tap()
        sleep(1) // Задержка для появления клавиатуры
        passwordTextField.typeText("_____")
        //ввели пароль

        // Нажимаем Done на клавиатуре, чтобы закрыть её
        if app.toolbars.buttons["Done"].exists {
            app.toolbars.buttons["Done"].tap()
        }
        //убрали клавиатуру,закрывает кнопку логин
        
        // Небольшая задержка после закрытия клавиатуры
        sleep(2)

        // Ждем появления кнопки Login (может быть видна или ниже на странице)
        let unsplashLoginButton = webView.buttons["Login"]
        XCTAssertTrue(unsplashLoginButton.waitForExistence(timeout: 10), "Кнопка Login не найдена")
        
        // Если кнопка не видна, прокручиваем страницу
        if !unsplashLoginButton.isHittable {
            // Прокручиваем вниз, чтобы кнопка стала видна
            webView.swipeDown()
            sleep(1)
        }
        
        // Проверяем доступность и тапаем
        if unsplashLoginButton.isHittable {
            unsplashLoginButton.tap()
        } else {
            // Если все еще недоступна, используем координаты
            let coordinate = unsplashLoginButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
        //зашли в приложение

        let tablesQuery = app.tables
        let cell = tablesQuery.cells.element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        //ждем появления первой ячейки
    }

    func testFeed() throws {
        // Авторизуемся, если нужно
        authenticateIfNeeded()
        
        // Подождать, пока открывается и загружается экран ленты
        let tablesQuery = app.tables
        let firstCell = tablesQuery.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 15), "Экран ленты не загрузился")
        
        // Сделать жест «смахивания» вверх по экрану для его скролла
        firstCell.swipeUp()
        
        // Поставить лайк в ячейке верхней картинки
        let cellToLike = tablesQuery.cells.element(boundBy: 0)
        XCTAssertTrue(cellToLike.buttons["LikeButton"].waitForExistence(timeout: 5))
        cellToLike.buttons["LikeButton"].tap()
        
        // Отменить лайк в ячейке верхней картинки
        cellToLike.buttons["LikeButton"].tap()
        
        // Нажать на верхнюю ячейку
        cellToLike.tap()
        
        // Подождать, пока картинка открывается на весь экран
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 5), "Картинка не открылась на весь экран")
        
        // Увеличить картинку
        image.pinch(withScale: 3, velocity: 1)
        
        // Уменьшить картинку
        image.pinch(withScale: 0.5, velocity: -1)
        
        // Вернуться на экран ленты
        let navBackButton = app.buttons["BackButton"]
        XCTAssertTrue(navBackButton.waitForExistence(timeout: 5))
        navBackButton.tap()
        
        // Проверяем, что вернулись на экран ленты
        XCTAssertTrue(tablesQuery.cells.element(boundBy: 0).exists)
    }

    func testProfile() throws {
        // Авторизуемся, если нужно
        authenticateIfNeeded()
        
        sleep(3)  // Подождать, пока открывается и загружается экран ленты

        // Ждем появления TabBar и переходим на профиль
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "TabBar не найден")
        
        // Ищем кнопку профиля - обычно это вторая кнопка (индекс 1)
        let allTabs = tabBar.buttons
        guard allTabs.count > 1 else {
            XCTFail("В TabBar должно быть минимум 2 кнопки")
            return
        }
        
        let profileTab = allTabs.element(boundBy: 1)
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Кнопка профиля не найдена")
        if profileTab.isHittable {
            profileTab.tap()
        } else {
            // Пытаемся тапнуть по координатам
            let coordinate = profileTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
        //перешли на страниц профиля

        XCTAssertTrue(app.staticTexts["Nikolay"].exists)
        XCTAssertTrue(app.staticTexts["i_do"].exists)
        //проверка отображения данных

        app.buttons["exitButton"].tap()
        //нажали кнопку выхода из профиля

        app.alerts["Пока, пока!"].scrollViews.otherElements.buttons["Да"].tap()
        //нашли алерт нажали ДА

        let authenticateButton = app.buttons["Войти"]
        XCTAssertTrue(authenticateButton.waitForExistence(timeout: 5))
        //проверили что вышли на экран входа
    }
}
