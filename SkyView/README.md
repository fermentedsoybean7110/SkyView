# SkyView

SkyView は OpenWeatherMap API を使って現在地の天気と5日予報を表示するシンプルな SwiftUI iOS アプリです。

## 要件
- Xcode 13 / iOS 15.0 以上（async/await 利用のため）

## APIキー設定 (xcconfig)
1. プロジェクトの `SkyView` フォルダに `Secrets.xcconfig` を作成します（このファイルは必ず .gitignore に追加してください）。
2. 以下を `Secrets.xcconfig` に追加します:

   OPENWEATHER_API_KEY = YOUR_API_KEY_HERE

3. Xcode のプロジェクト設定 -> 対象 -> Build Settings -> "Configurations" の Debug / Release に `Secrets.xcconfig` を適用します。
4. または、簡易的に `Info.plist` に `OPENWEATHER_API_KEY` キーを追加して値を `$(OPENWEATHER_API_KEY)` に設定してビルド設定から値を渡す手法もあります。

> 現在の実装では `Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY")` でキーを取得する想定です。

## 実行
1. `Secrets.xcconfig` に APIキーを設定
2. Xcode で開いてビルドして実行

## テスト
- Xcode の Test (Cmd+U) を使ってユニットテストを実行してください。

## 注意点
- APIキーはリポジトリに含めないでください。
- シミュレータで現在地をテストする場合は、Debug -> Location からカスタムの座標を指定できます。
