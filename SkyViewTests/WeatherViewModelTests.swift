import XCTest
@testable import SkyView

/// `WeatherRepositoryProtocol` をモック実装し、テスト用のレスポンスやエラーを返す
final class MockWeatherRepository: WeatherRepositoryProtocol {
    var shouldThrow: Bool = false
    var currentResponse: CurrentWeatherResponse?
    var forecastResponse: ForecastResponse?

    /// 指定座標の現在天気を返す（モック）
    /// - Throws: `WeatherError.network` を返す場合がある
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse {
        if shouldThrow {
            throw WeatherError.network(NSError(domain: "mock", code: -1, userInfo: [NSLocalizedDescriptionKey: "mock error"]))
        }
        guard let r = currentResponse else {
            throw WeatherError.noData
        }
        return r
    }

    /// 指定座標の予報を返す（モック）
    /// - Throws: `WeatherError.network` を返す場合がある
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        if shouldThrow {
            throw WeatherError.network(NSError(domain: "mock", code: -1, userInfo: [NSLocalizedDescriptionKey: "mock error"]))
        }
        guard let r = forecastResponse else {
            throw WeatherError.noData
        }
        return r
    }
}

final class WeatherViewModelTests: XCTestCase {

    /// 成功ケース: レスポンスが正しく ViewModel に反映されることを検証する
    @MainActor
    func testFetchWeatherSuccess() async throws {
        // Arrange
        let mock = MockWeatherRepository()
        let main = MainInfo(temp: 12.0, feels_like: 11.0, temp_min: 10.0, temp_max: 13.0, pressure: 1010, humidity: 80)
        let weather = WeatherCondition(id: 800, main: "Clear", description: "clear sky", icon: "01d")
        let current = CurrentWeatherResponse(coord: Coordinate(lon: 0.0, lat: 0.0), weather: [weather], main: main, wind: Wind(speed: 1.0, deg: 0), dt: nil, sys: nil, name: "TestCity")
        mock.currentResponse = current
        mock.forecastResponse = ForecastResponse(list: [], city: CityInfo(id: 1, name: "TestCity", coord: Coordinate(lon: 0.0, lat: 0.0), country: "JP", timezone: 9))

        let lm = LocationManager()
        let vm = WeatherViewModel(repository: mock, locationManager: lm)

        // Act
        await vm.fetchWeather(lat: 0.0, lon: 0.0)

        // Assert
        XCTAssertEqual(vm.cityName, "TestCity")
        XCTAssertEqual(vm.temp, "12℃")
        XCTAssertNil(vm.errorMessage)
    }

    /// 失敗ケース: リポジトリがエラーを返した場合、`errorMessage` が設定されることを検証する
    @MainActor
    func testFetchWeatherFailure() async throws {
        // Arrange
        let mock = MockWeatherRepository()
        mock.shouldThrow = true
        let lm = LocationManager()
        let vm = WeatherViewModel(repository: mock, locationManager: lm)

        // Act
        await vm.fetchWeather(lat: 0.0, lon: 0.0)

        // Assert
        XCTAssertNotNil(vm.errorMessage)
    }
}
