//
//  CanvasCardView.swift
//  BatikMaxxing
//
//  Created by Liecardo on 04/07/26.
//
//

import SwiftUI

struct CanvasCardView: View {
    let project: CanvasModel

    var body: some View {
        VStack(spacing: 0) {
            thumbnailView
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemBackground))

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = project.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()
        } else {
            Image(systemName: "photo")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }

    // MARK: - Date formatting

    private var formattedDate: String {
        let formatter = DateFormatter()
        // Locale di-fix ke en_US_POSIX supaya format "AM/PM" konsisten
        // di semua perangkat, apapun region setting-nya.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yy, h.mm a"
        return formatter.string(from: project.updatedAt)
    }
}

#Preview {
    CanvasCardView(project: CanvasModel(name: "Untitled"))
        .frame(width: 170)
        .padding()
}
