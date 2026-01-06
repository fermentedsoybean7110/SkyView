import XCTest
@testable import SkyView

/// `WeatherServiceProtocol` のモック実装
///
/// 成功時は事前に設定したレスポンスを返す、`shouldThrow` が true の場合はネットワークエラーを投げる
final class MockWeatherService: WeatherServiceProtocol {
    var shouldThrow: Bool = false
    var currentResponse: CurrentWeatherResponse?
    var forecastResponse: ForecastResponse?

    /// 指定座標の現在天気を返す（モック）
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: `CurrentWeatherResponse` または例外を投げる
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse {
        if shouldThrow {
            throw WeatherError.network(NSError(domain: "mock", code: -1, userInfo: [NSLocalizedDescriptionKey: "mock error"]))
        }
        guard let r = currentResponse else { throw WeatherError.noData }
        return r
    }

    /// 指定座標の予報を返す（モック）
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: `ForecastResponse` または例外を投げる
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        if shouldThrow {
            throw WeatherError.network(NSError(domain: "mock", code: -1, userInfo: [NSLocalizedDescriptionKey: "mock error"]))
        }
        guard let r = forecastResponse else { throw WeatherError.noData }
        return r
    }
}

final class WeatherRepositoryTests: XCTestCase {

    /// 成功ケース: モックサービスが有効なデータを返すと、`WeatherRepository` も同じデータを返すことを検証する
    @MainActor
    func testRepositoryFetchSuccess() async throws {
        // Arrange
        let main = MainInfo(temp: 20.0, feels_like: 19.0, temp_min: 18.0, temp_max: 22.0, pressure: 1005, humidity: 60)
        let weather = WeatherCondition(id: 500, main: "Rain", description: "light rain", icon: "10d")
        let current = CurrentWeatherResponse(coord: Coordinate(lon: 1.0, lat: 2.0), weather: [weather], main: main, wind: Wind(speed: 3.0, deg: 120), dt: nil, sys: nil, name: "RepoCity")
        let forecastEntry = ForecastEntry(dt: 1, main: main, weather: [weather], dt_txt: "2026-01-05 00:00:00")
        let forecast = ForecastResponse(list: [forecastEntry], city: CityInfo(id: 1, name: "RepoCity", coord: Coordinate(lon: 1.0, lat: 2.0), country: "JP", timezone: 9))

        let mockService = MockWeatherService()
        mockService.currentResponse = current
        mockService.forecastResponse = forecast

        let repo = WeatherRepository(service: mockService)

        // Act
        let fetchedCurrent = try await repo.fetchCurrentWeather(lat: 2.0, lon: 1.0)
        let fetchedForecast = try await repo.fetchForecast(lat: 2.0, lon: 1.0)

        // Assert
        XCTAssertEqual(fetchedCurrent.name, "RepoCity")
        XCTAssertEqual(fetchedCurrent.main.temp, 20.0)
        XCTAssertEqual(fetchedForecast.list.first?.dt_txt, "2026-01-05 00:00:00")
    }

    /// 失敗ケース: モックサービスがエラーを投げると、`WeatherRepository` も例外を返すことを検証する
    @MainActor
    func testRepositoryFetchFailure() async throws {
        // Arrange
        let mockService = MockWeatherService()
        mockService.shouldThrow = true
        let repo = WeatherRepository(service: mockService)

        // Act / Assert
        await XCTAssertThrowsErrorAsync({ _ = try await repo.fetchCurrentWeather(lat: 0.0, lon: 0.0) })
        await XCTAssertThrowsErrorAsync({ _ = try await repo.fetchForecast(lat: 0.0, lon: 0.0) })
    }
}

// MARK: - XCTest async helper

/// XCTest の非同期クロージャ用アサーションヘルパー
/// - Note: Swift/XCTest の async throwing クロージャを直接扱う際の簡易ラッパー
func XCTAssertThrowsErrorAsync(_ expression: @escaping @Sendable () async throws -> Void, file: StaticString = #file, line: UInt = #line) async {
    do {
        try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {
        // success: error thrown
    }
}
