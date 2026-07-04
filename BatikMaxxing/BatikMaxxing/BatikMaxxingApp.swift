//
//  BatikMaxxingApp.swift
//  BatikMaxxing
//
//  Created by Liecardo on 03/07/26.
//

import SwiftUI
import SwiftData

@main
struct BatikMaxxingApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: CanvasModel.self)
    }
}
