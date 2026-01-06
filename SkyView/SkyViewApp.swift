//
//  SkyViewApp.swift
//  SkyView
//

import SwiftUI
import SwiftData

/// アプリのエントリポイント。
///
/// アプリ全体の共有 `ModelContainer` を初期化し、ルートビューに対して
/// 指定された背景色を適用して `ContentView` を表示します。
@main
struct SkyViewApp: App {
    /// 共有の ModelContainer を構築します。
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // ルートで背景色を適用して、View階層による背景の上書きを防ぎます。
            ZStack {
                Color(red: 210.0/255.0, green: 211.0/255.0, blue: 214.0/255.0)
                    .ignoresSafeArea()
                ContentView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
