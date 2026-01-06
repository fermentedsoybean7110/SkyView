import Foundation

/// 天気データをアプリ側に提供するリポジトリのインターフェース。
///
/// リモートとローカル（キャッシュ）を隠蔽して、ViewModel は本プロトコルの実装に依存します。
protocol WeatherRepositoryProtocol {
    /// 指定座標の現在天気を取得します。
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: CurrentWeatherResponse モデル
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse

    /// 指定座標の予報データを取得します。
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Returns: ForecastResponse モデル
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse
}
