import Foundation

/// OpenWeatherMap のレスポンスで使用する最低限のデータモデル
///
/// API レスポンスの構造に対応する型定義を保持する

/// 現在天気のレスポンスモデル
struct CurrentWeatherResponse: Codable {
    /// 座標情報
    let coord: Coordinate?
    /// 天気配列
    let weather: [WeatherCondition]
    /// 主な気象情報
    let main: MainInfo
    /// 風情報
    let wind: Wind?
    /// 取得時刻のタイムスタンプ
    let dt: Int?
    /// システム情報（国、日没・日の出など）
    let sys: Sys?
    /// 都市名
    let name: String?
}

/// 予報（forecast）のレスポンスモデル
struct ForecastResponse: Codable {
    /// 予報エントリの配列
    let list: [ForecastEntry]
    /// 都市情報
    let city: CityInfo
}

/// 予報の個々のエントリ
struct ForecastEntry: Codable, Identifiable {
    var id: Int { dt }
    /// Unix タイムスタンプ
    let dt: Int
    /// 主な気象情報
    let main: MainInfo
    /// 天気配列
    let weather: [WeatherCondition]
    /// 日時文字列（API の提供する表示用）
    let dt_txt: String?
}

/// 天気条件の情報
struct WeatherCondition: Codable {
    /// 天気ID
    let id: Int
    /// 簡易な分類名
    let main: String?
    /// 説明文
    let description: String?
    /// アイコンコード
    let icon: String?
}

/// 主な気象情報（温度・湿度等）
struct MainInfo: Codable {
    /// 温度（摂氏）
    let temp: Double
    /// 体感温度
    let feels_like: Double?
    /// 最低気温
    let temp_min: Double?
    /// 最高気温
    let temp_max: Double?
    /// 気圧（hPa）
    let pressure: Int?
    /// 湿度（%）
    let humidity: Int?
}

/// 風情報
struct Wind: Codable {
    /// 風速（m/s）
    let speed: Double?
    /// 風向き（度）
    let deg: Int?
}

/// 座標情報
struct Coordinate: Codable {
    /// 経度
    let lon: Double?
    /// 緯度
    let lat: Double?
}

/// システム情報
struct Sys: Codable {
    /// 国コード
    let country: String?
    /// 日の出時刻（Unix）
    let sunrise: Int?
    /// 日の入り時刻（Unix）
    let sunset: Int?
}

/// 都市情報
struct CityInfo: Codable {
    /// 都市ID
    let id: Int?
    /// 都市名
    let name: String?
    /// 座標情報
    let coord: Coordinate?
    /// 国コード
    let country: String?
    /// タイムゾーンオフセット
    let timezone: Int?
}
