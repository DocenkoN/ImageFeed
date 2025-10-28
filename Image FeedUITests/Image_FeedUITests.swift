import XCTest
@testable import ImageFeed

final class ImageFeedUITests: XCTestCase {

    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testAuth() throws {
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
        loginTextField.typeText("kolyafire@gmail.com")
        webView.swipeUp() // скрыть клавиатуру

        // 4. Ввести пароль
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField.tap()
        passwordTextField.typeText("Qwerty123")
        webView.swipeUp()

        // 5. Нажать кнопку логина
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        loginButton.tap()

        // 6. Дождаться загрузки экрана ленты
        let tablesQuery = app.tables
        let firstCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10))
    }
    
    func testFeed() throws {
            // 1. Подождать, пока открывается и загружается экран ленты
            let tablesQuery = app.tables
            let firstCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
            XCTAssertTrue(firstCell.waitForExistence(timeout: 10))

            // 2. Сделать жест «смахивания» вверх для скролла
            firstCell.swipeUp()
            sleep(2)

            // 3. Поставить лайк во второй ячейке
            let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
            let likeButtonOff = cellToLike.buttons["like button off"]
            XCTAssertTrue(likeButtonOff.waitForExistence(timeout: 5))
            likeButtonOff.tap()

            // 4. Отменить лайк
            let likeButtonOn = cellToLike.buttons["like button on"]
            XCTAssertTrue(likeButtonOn.waitForExistence(timeout: 5))
            likeButtonOn.tap()

            sleep(2)

            // 5. Нажать на ячейку — открыть изображение на полный экран
            cellToLike.tap()
            sleep(2)

            // 6. Дождаться, пока откроется SingleImageView
            let image = app.scrollViews.images.element(boundBy: 0)
            XCTAssertTrue(image.waitForExistence(timeout: 5))

            // 7. Увеличить картинку (zoom in)
            image.pinch(withScale: 3, velocity: 1)

            // 8. Уменьшить картинку (zoom out)
            image.pinch(withScale: 0.5, velocity: -1)

            // 9. Вернуться на экран ленты
            let backButton = app.buttons["nav back button white"]
            XCTAssertTrue(backButton.waitForExistence(timeout: 5))
            backButton.tap()
        }
    
    func testProfile() throws {
        // 1. Подождать, пока открывается и загружается экран ленты
        sleep(3)

        // 2. Перейти на экран профиля
        app.tabBars.buttons.element(boundBy: 1).tap()

        // 3. Проверить, что отображаются персональные данные
        XCTAssertTrue(app.staticTexts["Nick Fury"].exists)
        XCTAssertTrue(app.staticTexts["@nick"].exists)

        // 4. Нажать кнопку логаута
        let logoutButton = app.buttons["logout button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()

        // 5. Подтвердить выход на алерте
        let alert = app.alerts["Bye bye!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.scrollViews.otherElements.buttons["Yes"].tap()

        // 6. Проверить, что снова открылся экран авторизации
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
    }

}
