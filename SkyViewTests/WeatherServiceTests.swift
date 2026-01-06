import XCTest
@testable import SkyView

/// URLSession をモックするためのカスタム URLProtocol。
///
/// テストごとに `MockURLProtocol.requestHandler` を設定して、返却するデータ/レスポンス/エラーを制御します。
final class MockURLProtocol: URLProtocol {
    /// テストから設定するハンドラ。リクエストを受け取り、(Data?, HTTPURLResponse?, Error?) を返す。
    static var requestHandler: ((URLRequest) throws -> (Data?, HTTPURLResponse?, Error?))?

    override class func canInit(with request: URLRequest) -> Bool {
        // すべてのリクエストをインターセプトする
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler が未設定です")
        }

        do {
            let (data, response, error) = try handler(request)

            if let response = response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // no-op
    }
}

/// `WeatherService` の単体テスト。
///
/// - Note: 実ネットワークは使わず、`MockURLProtocol` でレスポンスを模擬します。
final class WeatherServiceTests: XCTestCase {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// 現在天気取得の成功ケースを検証します。
    @MainActor
    func testFetchCurrentWeatherSuccess() async throws {
        // Arrange
        let json: [String: Any] = [
            "coord": ["lon": 1.0, "lat": 2.0],
            "weather": [["id": 800, "main": "Clear", "description": "clear sky", "icon": "01d"]],
            "main": ["temp": 25.0, "feels_like": 24.0, "temp_min": 24.0, "temp_max": 26.0, "pressure": 1012, "humidity": 50],
            "wind": ["speed": 1.5, "deg": 80],
            "dt": 1600000000,
            "sys": ["country": "JP", "sunrise": 1600000000, "sunset": 1600040000],
            "name": "TestCity"
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])

        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (data, resp, nil)
        }

        let session = makeSession()
        let service = WeatherService(session: session, apiKey: "DUMMY")

        // Act
        let result = try await service.fetchCurrentWeather(lat: 2.0, lon: 1.0)

        // Assert
        XCTAssertEqual(result.name, "TestCity")
        XCTAssertEqual(result.main.temp, 25.0)
        XCTAssertEqual(result.weather.first?.id, 800)
    }

    /// 予報取得の成功ケースを検証します。
    @MainActor
    func testFetchForecastSuccess() async throws {
        // Arrange
        let entry: [String: Any] = [
            "dt": 1600003600,
            "main": ["temp": 20.0, "feels_like": 19.0, "pressure": 1010, "humidity": 60],
            "weather": [["id": 500, "main": "Rain", "description": "light rain", "icon": "10d"]],
            "dt_txt": "2026-01-05 00:00:00"
        ]
        let json: [String: Any] = [
            "list": [entry],
            "city": ["id": 1, "name": "CityForecast", "coord": ["lon": 1.0, "lat": 2.0], "country": "JP", "timezone": 9]
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])

        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (data, resp, nil)
        }

        let session = makeSession()
        let service = WeatherService(session: session, apiKey: "DUMMY")

        // Act
        let result = try await service.fetchForecast(lat: 2.0, lon: 1.0)

        // Assert
        XCTAssertEqual(result.city.name, "CityForecast")
        XCTAssertEqual(result.list.first?.dt, 1600003600)
    }

    /// HTTP エラー（ステータスコード 500）を受け取った場合、`WeatherError.invalidResponse` を投げることを検証します。
    @MainActor
    func testFetchCurrentWeatherHTTPError() async throws {
        // Arrange
        let data = "{\"error\":\"server error\"}".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let resp = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)
            return (data, resp, nil)
        }

        let session = makeSession()
        let service = WeatherService(session: session, apiKey: "DUMMY")

        // Act / Assert
        do {
            _ = try await service.fetchCurrentWeather(lat: 0.0, lon: 0.0)
            XCTFail("Expected to throw")
        } catch let error as WeatherError {
            switch error {
            case .invalidResponse(let code):
                XCTAssertEqual(code, 500)
            default:
                XCTFail("Unexpected WeatherError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// 不正な JSON を返した場合、デコードエラーになることを検証します。
    @MainActor
    func testFetchCurrentWeatherDecodingError() async throws {
        // Arrange: current weather に対して forecast 用の JSON（型が違う）を返すなどでデコード失敗を発生させる
        let invalidJSON = "{\"invalid\": true}".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (invalidJSON, resp, nil)
        }

        let session = makeSession()
        let service = WeatherService(session: session, apiKey: "DUMMY")

        // Act / Assert
        do {
            _ = try await service.fetchCurrentWeather(lat: 0.0, lon: 0.0)
            XCTFail("Expected decoding to fail")
        } catch let error as WeatherError {
            switch error {
            case .decoding:
                // success
                break
            default:
                XCTFail("Unexpected WeatherError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
