import Foundation
import os

/// WeatherService を内部で使用しアプリ向けの天気データ取得を提供するリポジトリ実装
///
/// リモートおよびローカルキャッシュを統合して ViewModel に対して一貫したデータ提供を行う
final class WeatherRepository: WeatherRepositoryProtocol {
    private let service: WeatherServiceProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.sample.SkyView", category: "WeatherRepository")

    init(service: WeatherServiceProtocol) {
        self.service = service
    }

    /// 指定座標の現在天気を取得する
    ///
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: CurrentWeatherResponse モデル
    /// - Throws: ネットワークまたはデコードに関するエラー
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse {
        logger.debug("repository: fetchCurrentWeather lat=\(lat), lon=\(lon)")
        let res = try await service.fetchCurrentWeather(lat: lat, lon: lon)
        logger.info("repository: fetchCurrentWeather succeeded: city=\(res.name ?? "-", privacy: .public)")
        return res
    }

    /// 指定座標の予報データを取得する
    ///
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: ForecastResponse モデル
    /// - Throws: ネットワークまたはデコードに関するエラー
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        logger.debug("repository: fetchForecast lat=\(lat), lon=\(lon)")
        let res = try await service.fetchForecast(lat: lat, lon: lon)
        logger.info("repository: fetchForecast succeeded: entries=\(res.list.count)")
        return res
    }
}
