//
//  CanvasView.swift
//  BatikMaxxing
//
//  Created by Liecardo on 04/07/26.
//

import SwiftUI
import SwiftData

struct CanvasView: View {
    @Bindable var project: CanvasModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.dashed")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Canvas editor akan dibangun di sini")
                .font(.headline)

            Text("Project: \(project.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CanvasView(project: CanvasModel(name: "Untitled"))
    }
}
