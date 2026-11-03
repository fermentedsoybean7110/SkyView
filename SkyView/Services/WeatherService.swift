import Foundation
import os

/// Weather 関連のエラーを表す列挙型
///
/// - Note: LocalizedError に準拠し、ユーザ向けの説明を `errorDescription` で提供する
enum WeatherError: Error, LocalizedError {
    case invalidURL
    case network(Error)
    case invalidResponse(statusCode: Int)
    case decoding(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URLの生成に失敗しました"
        case .network(let e):
            return "ネットワークエラー: \(e.localizedDescription)"
        case .invalidResponse(let code):
            return "無効なレスポンス（HTTP \(code)）"
        case .decoding(let e):
            return "データの解析に失敗しました: \(e.localizedDescription)"
        case .noData:
            return "サーバからデータが返ってきませんでした"
        }
    }
}

/// Weather API 呼び出し用の抽象インターフェース
protocol WeatherServiceProtocol {
    /// 指定座標の現在の天気を取得する
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: `CurrentWeatherResponse` モデル
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse

    /// 指定座標の予報（forecast）を取得する
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: `ForecastResponse` モデル
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse
}

/// OpenWeatherMap に対する実装
///
/// `URLSession` を注入できるようにしてテストを容易にする
final class WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.sample.SkyView", category: "WeatherService")

    private enum Operation: String {
        case currentWeather = "current_weather"
        case forecast = "forecast"
    }

    /// 初期化
    /// - Parameters:
    ///   - session: `URLSession` インスタンス（テスト時はモックの session を渡す）
    ///   - apiKey: OpenWeatherMap の API キー
    init(session: URLSession = .shared, apiKey: String) {
        self.session = session
        self.apiKey = apiKey
        self.decoder = JSONDecoder()
        logger.debug("WeatherService initialized")
    }

    /// 現在天気を取得する
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: `CurrentWeatherResponse` モデル
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse {
        guard var components = URLComponents(string: "\(baseURL)/weather") else {
            logger.error("Invalid base URL")
            throw WeatherError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "ja")
        ]
        guard let url = components.url else {
            logger.error("Failed to build request URL (operation=\(Operation.currentWeather.rawValue, privacy: .public))")
            throw WeatherError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        logger.debug("Sending weather request (operation=\(Operation.currentWeather.rawValue, privacy: .public))")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                logger.error("Response is not HTTPURLResponse")
                throw WeatherError.noData
            }
            logger.debug("Received weather response (operation=\(Operation.currentWeather.rawValue, privacy: .public), status=\(http.statusCode), dataLength=\(data.count))")
            guard (200...299).contains(http.statusCode) else {
                logger.error("Invalid HTTP status code: \(http.statusCode)")
                throw WeatherError.invalidResponse(statusCode: http.statusCode)
            }
            do {
                let model = try decoder.decode(CurrentWeatherResponse.self, from: data)
                logger.debug("decoded CurrentWeatherResponse: city=\(model.name ?? "-", privacy: .public)")
                return model
            } catch {
                logger.error("Decoding error (operation=\(Operation.currentWeather.rawValue, privacy: .public), type=\(String(describing: type(of: error)), privacy: .public))")
                throw WeatherError.decoding(error)
            }
        } catch {
            // 既に WeatherError が投げられている場合はそのまま再スローする
            if let we = error as? WeatherError {
                logWeatherError(we, operation: .currentWeather)
                throw we
            }
            logNetworkError(error, operation: .currentWeather)
            throw WeatherError.network(error)
        }
    }

    /// 予報（forecast）を取得する
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: `ForecastResponse` モデル
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        guard var components = URLComponents(string: "\(baseURL)/forecast") else {
            logger.error("Invalid base URL for forecast")
            throw WeatherError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "ja")
        ]
        guard let url = components.url else {
            logger.error("Failed to build request URL (operation=\(Operation.forecast.rawValue, privacy: .public))")
            throw WeatherError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        logger.debug("Sending weather request (operation=\(Operation.forecast.rawValue, privacy: .public))")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                logger.error("Forecast response is not HTTPURLResponse")
                throw WeatherError.noData
            }
            logger.debug("Received weather response (operation=\(Operation.forecast.rawValue, privacy: .public), status=\(http.statusCode), dataLength=\(data.count))")
            guard (200...299).contains(http.statusCode) else {
                logger.error("Invalid HTTP status code for forecast: \(http.statusCode)")
                throw WeatherError.invalidResponse(statusCode: http.statusCode)
            }
            do {
                let model = try decoder.decode(ForecastResponse.self, from: data)
                logger.debug("decoded ForecastResponse: city=\(model.city.name ?? "-", privacy: .public), entries=\(model.list.count)")
                return model
            } catch {
                logger.error("Decoding error (operation=\(Operation.forecast.rawValue, privacy: .public), type=\(String(describing: type(of: error)), privacy: .public))")
                throw WeatherError.decoding(error)
            }
        } catch {
            if let we = error as? WeatherError {
                logWeatherError(we, operation: .forecast)
                throw we
            }
            logNetworkError(error, operation: .forecast)
            throw WeatherError.network(error)
        }
    }

    private func logWeatherError(_ error: WeatherError, operation: Operation) {
        switch error {
        case .invalidURL:
            logger.error("WeatherError.invalidURL (operation=\(operation.rawValue, privacy: .public))")
        case .network(let underlying):
            logNetworkError(underlying, operation: operation)
        case .invalidResponse(let statusCode):
            logger.error("WeatherError.invalidResponse (operation=\(operation.rawValue, privacy: .public), status=\(statusCode))")
        case .decoding(let underlying):
            logger.error("WeatherError.decoding (operation=\(operation.rawValue, privacy: .public), type=\(String(describing: type(of: underlying)), privacy: .public))")
        case .noData:
            logger.error("WeatherError.noData (operation=\(operation.rawValue, privacy: .public))")
        }
    }

    private func logNetworkError(_ error: Error, operation: Operation) {
        if let urlError = error as? URLError {
            logger.error("Network error (operation=\(operation.rawValue, privacy: .public), code=\(urlError.code.rawValue))")
            return
        }
        logger.error("Network error (operation=\(operation.rawValue, privacy: .public), type=\(String(describing: type(of: error)), privacy: .public))")
    }
}
