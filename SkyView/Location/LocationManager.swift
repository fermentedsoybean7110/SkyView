import Foundation
import CoreLocation
import Combine
import os

/// 位置情報管理の振る舞いを定義するプロトコル
///
/// 位置情報の認可状態・最後の位置・エラーを公開し、権限要求および単発取得を行う振る舞いを規定する
protocol LocationManagerProtocol: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var lastLocation: CLLocation? { get }
    var locationError: Error? { get }
    func requestAuthorization()
    func requestLocationOnce()
}

/// CLLocationManager を用いた位置情報管理の実装
///
/// ObservableObject として認可状態・位置情報・エラーを公開し、UI 層から利用される
final class LocationManager: NSObject, ObservableObject, LocationManagerProtocol {
    private let manager = CLLocationManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.sample.SkyView", category: "LocationManager")

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var locationError: Error?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        logger.debug("LocationManager initialized. Current auth status: \(self.authorizationStatus.rawValue)")
    }

    /// 位置情報利用の許可を要求する
    func requestAuthorization() {
        logger.debug("requestAuthorization() called. Current status: \(self.authorizationStatus.rawValue)")
        manager.requestWhenInUseAuthorization()
    }

    /// 単発の位置情報取得を要求する
    func requestLocationOnce() {
        logger.debug("requestLocationOnce() called. Requesting single location update.")
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    /// 認可状態の変更を受け取るデリゲートメソッド
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        logger.info("authorization changed: \(self.authorizationStatus.rawValue)")
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // すぐに取得を要求する
            logger.debug("authorized: requesting location")
            manager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            logger.warning("location authorization denied or restricted")
            // 明示的にエラーを流す
            let err = NSError(domain: kCLErrorDomain, code: CLError.denied.rawValue, userInfo: [NSLocalizedDescriptionKey: "位置情報が許可されていません。設定で許可してください。"])
            locationError = err
        }
    }

    /// 位置情報更新を受け取るデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
        locationError = nil
        if let loc = lastLocation {
            logger.info("didUpdateLocations: lat=\(loc.coordinate.latitude), lon=\(loc.coordinate.longitude)")
        } else {
            logger.debug("didUpdateLocations: no locations")
        }
    }

    /// 位置情報取得失敗を受け取るデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        // CLError があれば詳細にログ出力
        if let clError = error as? CLError {
            logger.error("location didFailWithError: CLError \(clError.errorCode) - \(clError.localizedDescription, privacy: .public)")
        } else {
            logger.error("location didFailWithError: \(error.localizedDescription, privacy: .public)")
        }

        // 追加で NSError の kCLErrorDomain を検査してユーザー向けメッセージを付与
        if let ns = error as NSError?, ns.domain == kCLErrorDomain {
            let code = ns.code
            let desc = Self.descriptionForCLError(code: code)
            logger.debug("kCLErrorDomain code: \(code) -> \(desc, privacy: .public)")
        }
    }

    /// kCLErrorDomain のエラーコードに対応する説明を返す
    /// - Parameters:
    ///   - code: CLError のコード値
    /// - Returns: ユーザー向けの説明文字列
    static func descriptionForCLError(code: Int) -> String {
        switch code {
        case CLError.denied.rawValue:
            return "位置情報が拒否されました（CLError.denied）。ユーザーが許可を拒否しているか、設定で制限されています"
        case CLError.locationUnknown.rawValue:
            return "位置情報が不明である（CLError.locationUnknown）。一時的な問題で取得できないことがあります"
        case CLError.network.rawValue:
            return "ネットワークエラー（CLError.network）"
        default:
            return "CLError code \(code)"
        }
    }
}
