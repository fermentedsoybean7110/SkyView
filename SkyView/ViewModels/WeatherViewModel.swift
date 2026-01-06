import Foundation
import CoreLocation
import Combine
import os

/// 現在地の天気情報を取得・管理する ViewModel
///
/// `LocationManager` の位置情報更新を監視し、`WeatherRepositoryProtocol` を介して
/// OpenWeatherMap の API から現在天気と予報を取得して公開する
@MainActor
final class WeatherViewModel: ObservableObject {
    /// ローディング状態を表すフラグ
    @Published var isLoading: Bool = false
    /// エラー表示用メッセージ
    @Published var errorMessage: String?
    /// 表示用の都市名
    @Published var cityName: String = ""
    /// 表示用の気温文字列
    @Published var temp: String = "--"
    /// 天気説明文
    @Published var descriptionText: String = ""
    /// アイコンコード
    @Published var iconCode: String = ""
    /// 詳細情報（体感温度、湿度、風速、気圧など）
    @Published var details: [String: String] = [:]
    /// 予報リスト（簡易的に日ごとの集約済み）
    @Published var forecast: [ForecastEntry] = []

    private let repository: WeatherRepositoryProtocol
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.sample.SkyView", category: "WeatherViewModel")

    /// 初期化
    ///
    /// - Parameters:
    ///   - repository: 天気データを提供するリポジトリ実装
    ///   - locationManager: 位置情報管理オブジェクト
    init(repository: WeatherRepositoryProtocol, locationManager: LocationManager) {
        self.repository = repository
        self.locationManager = locationManager

        logger.debug("WeatherViewModel initialized")

        // 位置情報の更新を監視
        locationManager.$lastLocation
            .sink { [weak self] location in
                guard let self = self, let loc = location else { return }
                self.logger.debug("received new location: lat=\(loc.coordinate.latitude), lon=\(loc.coordinate.longitude)")
                Task {
                    await self.fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
                }
            }
            .store(in: &cancellables)

        // 位置取得エラーを監視して表示
        locationManager.$locationError
            .sink { [weak self] err in
                guard let self = self, let e = err else { return }
                self.errorMessage = e.localizedDescription
                self.logger.error("location error: \(e.localizedDescription, privacy: .public)")
            }
            .store(in: &cancellables)
    }

    /// 位置情報の取得を要求する
    ///
    /// 許可ダイアログを表示し、単発で位置を要求する
    func requestLocation() {
        logger.debug("requestLocation called: requesting authorization and location")
        locationManager.requestAuthorization()
        locationManager.requestLocationOnce()
    }

    /// 指定座標で天気情報を API から取得する
    ///
    /// - Parameters:
    ///   - lat: 緯度
    ///   - lon: 経度
    /// - Note: 取得結果は ViewModel の公開プロパティに反映される
    func fetchWeather(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil
        logger.debug("fetchWeather start: lat=\(lat), lon=\(lon)")
        do {
            async let current = repository.fetchCurrentWeather(lat: lat, lon: lon)
            async let forecastResp = repository.fetchForecast(lat: lat, lon: lon)

            let (currentRes, forecastRes) = try await (current, forecastResp)

            cityName = currentRes.name ?? "Unknown"
            temp = String(format: "%.0f℃", currentRes.main.temp)
            descriptionText = currentRes.weather.first?.description ?? ""
            iconCode = currentRes.weather.first?.icon ?? ""

            var dets: [String: String] = [:]
            dets["体感温度"] = currentRes.main.feels_like != nil ? String(format: "%.0f℃", currentRes.main.feels_like!) : "--"
            dets["湿度"] = currentRes.main.humidity != nil ? "\(currentRes.main.humidity!)%" : "--"
            dets["風速"] = currentRes.wind?.speed != nil ? String(format: "%.1fm/s", currentRes.wind!.speed!) : "--"
            dets["気圧"] = currentRes.main.pressure != nil ? "\(currentRes.main.pressure!) hPa" : "--"
            details = dets

            // 5日予報は list から日ごとに最高/最低を計算する簡易処理
            forecast = Self.reduceForecastToDaily(forecastRes.list)

            isLoading = false
            logger.info("fetchWeather success: city=\(self.cityName, privacy: .public)")
        } catch let err as WeatherError {
            isLoading = false
            errorMessage = err.errorDescription
            let desc = err.errorDescription ?? ""
            logger.error("fetchWeather failed: \(desc, privacy: .public)")
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            logger.error("fetchWeather unexpected error: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 予報リストを日別に簡易集約する
    ///
    /// - Parameters:
    ///   - list: API から取得した予報エントリの配列
    /// - Returns: 日別に集約した予報エントリ（現状は先頭5件を返す）
    static func reduceForecastToDaily(_ list: [ForecastEntry]) -> [ForecastEntry] {
        // 簡易実装: そのまま先頭5アイテムを返す（将来的に日毎集約をする）
        return Array(list.prefix(5))
    }
}
