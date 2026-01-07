SkyView
======

このリポジトリはセットアップ手順と開発者向けガイドを含む

概要
---
SkyView は現在地の天気を表示する SwiftUI iOS アプリである

ローカル開発セットアップ（SwiftLint / pre-commit）
---
開発者間でコードのスタイルとドキュメントコメントルールを統一するため、`SwiftLint` と Git の `pre-commit` フックを導入する

1) SwiftLint の導入
- 推奨手順（Homebrew）

```bash
brew install swiftlint
```

- 提供スクリプトでインストールする場合

```bash
# プロジェクトルートから実行
bash Tools/install_swiftlint.sh
```

2) リポジトリルートの設定ファイル
- `.swiftlint.yml` をプロジェクトルートに配置している。主な設定は以下である
  - ドキュメントコメントの各行末に全角句点「。」があった場合はエラーとするカスタムルールを追加している（Private.instructions.md のルールに準拠）
  - `/**` ブロックコメントの使用は警告とするカスタムルールを追加している

3) pre-commit フック
- `.git/hooks/pre-commit` を用意している（実行権限を付与済み）
- 挙動は次のとおりである
  - ステージされた `.swift` ファイルを検出する
  - Xcode の自動生成ヘッダ（"Created by" を含む先頭の `//` ブロック）を自動で削除し、修正ファイルを再ステージする
  - その後 `swiftlint` を各ステージ済みファイルに対して実行する
  - SwiftLint がエラーを返した場合はコミットを中止する

注意点と運用
---
- すべての開発者に `swiftlint` のインストールを依頼すること（Homebrew 推奨）
- pre-commit フックはローカルの Git フックであるため、新しい開発者がクローンした際は `.git/hooks/pre-commit` を手動でコピーするか、セットアップスクリプトを実行して配置すること
- 既存のコードベースに多数の SwiftLint 違反がある場合は、まず `swiftlint autocorrect` を実行して対応可能なルールを自動修正し、その後手動で残りを修正すること

Xcode への組み込み（任意）
---
Xcode のターゲットの "Build Phases" に Run Script を追加してビルド時にも SwiftLint を実行できる

例（Run Script）:

```bash
if which swiftlint >/dev/null 2>&1; then
  swiftlint lint --config "$SRCROOT/.swiftlint.yml"
else
  echo "warning: SwiftLint not installed, install via Homebrew or Tools/install_swiftlint.sh"
fi
```

CI (GitHub Actions) での実行例
---
PR や push の際に SwiftLint を実行するワークフローを作成すると品質ゲートになる
- 実装例: `/.github/workflows/lint.yml` を作り、macOS ランナー上で `brew install swiftlint` して `swiftlint lint --config .swiftlint.yml` を実行する

公開後のクローン手順（外部開発者向け）
---
以下の手順でクローン後のセットアップを行えば、ローカルでアプリをビルド・実行できる

1) リポジトリのクローン
```bash
git clone https://github.com/fermentedsoybean7110/SkyView.git
cd SkyView
```

2) Secrets の設定（必須）
- 本リポジトリでは API キーを `SkyView/Secrets.xcconfig` で管理する仕様である。本ファイルはリポジトリに含めていないため、クローン後に自分の環境で作成する必要がある
- テンプレートを用意している場合はそれをコピーして編集する（もし `Secrets.xcconfig.example` がある場合）

例: `Secrets.xcconfig` を作成する
```bash
# プロジェクトルートで
cat > SkyView/Secrets.xcconfig <<EOL
OPENWEATHER_API_KEY = YOUR_OPENWEATHER_API_KEY_HERE
EOL
```

- `YOUR_OPENWEATHER_API_KEY_HERE` は OpenWeather のダッシュボードで発行した API キーに置き換えること
- このファイルは必ず `.gitignore` に含まれているためコミットされない

3) SwiftLint のインストール
- Homebrew がある場合（推奨）
```bash
brew install swiftlint
```
- 付属のインストールスクリプトを使う場合
```bash
bash Tools/install_swiftlint.sh
```

4) pre-commit フックの設置（任意だが推奨）
- リポジトリにフックのテンプレートが含まれている場合はそれをコピーして有効化する
```bash
# テンプレが .githooks/pre-commit にある場合（例）
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```
- もしテンプレートがない場合は、プロジェクトの `README.md` の "pre-commit フック" 節を参照して手動でセットアップすること

5) Xcode での起動と実行
- `SkyView.xcodeproj` を Xcode で開き、ターゲット `SkyView` を選択してシミュレータを指定し実行する
- またはコマンドラインでビルド/テストを実行する
```bash
# ビルド
xcodebuild -scheme SkyView -destination 'platform=iOS Simulator,name=iPhone 17' build
# テスト
xcodebuild -scheme SkyView -destination 'platform=iOS Simulator,name=iPhone 17' test
```

6) API キーの取得方法（OpenWeather）
- OpenWeather のサイトに登録して API キーを取得する
- 取得したキーは `SkyView/Secrets.xcconfig` に設定し、決してリポジトリにコミットしないこと

セキュリティ上の重要事項
---
- 本リポジトリは公開前に履歴から `Secrets.xcconfig` を削除済であるが、万一キーが流出した可能性を考慮し、公開前後に API キーを必ずローテーション（無効化 → 新規発行）すること
- CI（GitHub Actions 等）で API キーを使う場合は GitHub Secrets を利用し、workflow 内で動的に `Secrets.xcconfig` を生成する運用を推奨する

サポート
---
不明点や誤検知の報告は Issue を立てること

---
本 README を基に CI ワークフローの追加やルール調整を行うことを推奨する
