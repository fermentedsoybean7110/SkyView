import Foundation
import SwiftData

/// 永続化用のサンプルモデル。
@Model
final class Item {
    /// 作成時刻
    var timestamp: Date

    /// 初期化。
    /// - Parameters:
    ///   - timestamp: アイテムのタイムスタンプ
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
