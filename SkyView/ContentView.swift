import SwiftUI
import CoreLocation

/// メイン画面のエントリービュー
///
/// `LocationManager` を単一インスタンスで `StateObject` として保持し、
/// `WeatherViewModel` に `WeatherRepository` を注入して起動する
struct ContentView: View {
    @StateObject private var locationManager: LocationManager
    @StateObject private var viewModel: WeatherViewModel

    init() {
        // APIキーは Info.plist や xcconfig に配置される想定。
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String ?? ""
        let service = WeatherService(apiKey: apiKey)
        let repository = WeatherRepository(service: service)

        // LocationManager を一つ作成して View と ViewModel に共有する
        let lm = LocationManager()
        _locationManager = StateObject(wrappedValue: lm)
        _viewModel = StateObject(wrappedValue: WeatherViewModel(repository: repository, locationManager: lm))
    }

    var body: some View {
        ZStack {
            // アプリ全体の背景色
            Color(red: 210.0/255.0, green: 211.0/255.0, blue: 214.0/255.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // トップバー: 左にプレースホルダー、中央にタイトル、右に現在地ボタン
                HStack(alignment: .center) {
                    Color.clear
                        .frame(width: 44, height: 44)

                    Text("SkyView")
                        .font(.system(size: 28, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                        Button(action: { viewModel.requestLocation() }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 24, height: 24)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                        .padding(.trailing, 12)
                        .accessibilityLabel("現在地を取得")
                    } else {
                        Color.clear
                            .frame(width: 44, height: 44)
                            .padding(.trailing, 12)
                    }
                }
                .frame(height: 64)
                .padding(.top, 8)

                // メインコンテンツ
                if #available(iOS 16.0, *) {
                    ScrollView { content }
                        .scrollContentBackground(.hidden)
                } else {
                    ScrollView { content }
                        .background(Color.clear)
                }
            }
        }
    }

    /// メインスクロール領域に表示するビュー
    private var content: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .padding()
            } else if let err = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("エラー: \(err)")
                        .foregroundColor(.red)
                    Button("再試行") {
                        viewModel.requestLocation()
                    }
                }
                .padding()
            } else if viewModel.cityName.isEmpty {
                VStack(spacing: 16) {
                    Text("SkyViewへようこそ")
                        .font(.title)
                    Text("現在地の天気情報を取得してください。")

                    // スタイリングした現在地取得ボタン: 丸みのある白塗り、黒文字、影付き
                    Button(action: { viewModel.requestLocation() }) {
                        Text("現在地を取得")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.white)
                            .cornerRadius(22)
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                    }
                    .accessibilityLabel("現在地を取得")
                }
                .padding()
            } else {
                CurrentWeatherView(city: viewModel.cityName,
                                   temp: viewModel.temp,
                                   description: viewModel.descriptionText,
                                   iconCode: viewModel.iconCode,
                                   details: viewModel.details)

                ForecastListView(forecast: viewModel.forecast)
            }
        }
        .padding()
    }

    /// 現在の天気を表示するビュー
    ///
    /// 都市名、天気アイコン、現在気温、説明、および詳細情報カードの表示
    /// - Parameters:
    ///   - city: 都市名
    ///   - temp: 現在の気温表示文字列
    ///   - description: 天気の説明
    ///   - iconCode: 天気アイコンコード
    ///   - details: 詳細情報（体感温度、湿度、風速、気圧など）
    struct CurrentWeatherView: View {
        let city: String
        let temp: String
        let description: String
        let iconCode: String
        let details: [String: String]

        var body: some View {
            VStack(spacing: 12) {
                Text(city)
                    .font(.largeTitle)
                    .bold()
                HStack(alignment: .center, spacing: 16) {
                    if let url = URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            case .success(let image):
                                image
                                    .resizable()
                                    .frame(width: 80, height: 80)
                            case .failure:
                                Image(systemName: "photo")
                                    .frame(width: 80, height: 80)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(temp)
                            .font(.system(size: 44))
                            .bold()
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("体感温度: \(details["体感温度"] ?? "--")")
                        Text("湿度: \(details["湿度"] ?? "--")")
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("風速: \(details["風速"] ?? "--")")
                        Text("気圧: \(details["気圧"] ?? "--")")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }

    /// 予報リストビュー
    ///
    /// 5日分の予報をリスト表示する
    /// - Parameters:
    ///   - forecast: 予報エントリの配列
    struct ForecastListView: View {
        let forecast: [ForecastEntry]

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("5日予報")
                    .font(.headline)
                ForEach(forecast) { entry in
                    ForecastRowView(entry: entry)
                }
            }
        }
    }

    /// 予報の1行表示
    ///
    /// - Parameters:
    ///   - entry: 予報エントリ
    struct ForecastRowView: View {
        let entry: ForecastEntry

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.dt_txt ?? "")
                        .font(.subheadline)
                    Text(String(format: "%.0f℃", entry.main.temp))
                        .font(.headline)
                }
                Spacer()
                if let icon = entry.weather.first?.icon,
                   let url = URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 40, height: 40)
                        case .success(let image):
                            image
                                .resizable()
                                .frame(width: 40, height: 40)
                        case .failure:
                            Image(systemName: "photo")
                                .frame(width: 40, height: 40)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

#Preview {
    ContentView()
}
