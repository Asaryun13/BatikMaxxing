//
//  CanvasContentView.swift
//  BatikMaxxing
//
//  Created by Liecardo on 05/07/26.
//

//  Konten canvas yang sesungguhnya (ukuran tetap, misal 1000x1000) yang
//  dirender di dalam ZoomableScrollView. Berisi background dot-grid,
//  layer-layer foto yang sudah ditempatkan (interaktif: select, drag,
//  resize, rotate lewat SelectableCanvasLayerView), dan placeholder untuk
//  upload foto badan pertama kali.
//

import SwiftUI

struct CanvasContentView: View {
    let canvasSize: CGSize
    let layers: [CanvasLayerModel]
    let selectedLayerID: UUID?
    let onChoosePhoto: () -> Void
    let onPaste: () -> Void
    let onSelectLayer: (UUID) -> Void
    let onDeselect: () -> Void
    let onLayerGestureEnd: () -> Void
    let onLayerInteractionChange: (Bool) -> Void

    private var hasBodyReference: Bool {
        layers.contains { $0.kind == .bodyReference }
    }

    /// Urutan ARRAY di ForEach SENGAJA dibuat stabil (cuma sort by zIndex,
    /// tidak bergantung pada selection). Sebelumnya kode ini me-reorder
    /// array berdasarkan selectedLayerID supaya layer terpilih render di
    /// atas — TAPI itu penyebab utama bug "reposition glitching": begitu
    /// user mulai drag layer yang belum selected, di tengah gesture itu
    /// terjadi seleksi -> reorder array -> merusak gesture recognizer yang
    /// lagi aktif di tengah touch. Fix: urutan array tetap stabil, stacking
    /// visual "layer terpilih di atas" cukup pakai modifier `.zIndex()`
    /// (murni urutan render, tidak mengubah struktur array/View identity).
    private var zIndexSortedLayers: [CanvasLayerModel] {
        layers.sorted { $0.zIndex < $1.zIndex }
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ForEach(zIndexSortedLayers) { layer in
                SelectableCanvasLayerView(
                    layer: layer,
                    isSelected: layer.id == selectedLayerID,
                    onSelect: { onSelectLayer(layer.id) },
                    onGestureEnd: onLayerGestureEnd,
                    onInteractionChange: onLayerInteractionChange
                )
                .zIndex(layer.id == selectedLayerID ? 10_000 : Double(layer.zIndex))
            }

            if !hasBodyReference {
                Menu {
                    Button {
                        // Take Photo — menyusul setelah alur dasar canvas stabil.
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    .disabled(true)

                    Button {
                        onChoosePhoto()
                    } label: {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    BodyPhotoPlaceholderView()
                }
                .position(x: canvasSize.width / 2, y: canvasSize.height / 2)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
    }

    /// Background terpisah dari layer-layer interaktif supaya gesture
    /// tap-to-deselect & long-press-to-paste di sini tidak bentrok dengan
    /// gesture drag/resize/rotate milik masing-masing layer.
    private var backgroundLayer: some View {
        ZStack {
            Color(.systemBackground)
            DotGridBackground(size: canvasSize)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .contentShape(Rectangle())
        .onTapGesture {
            onDeselect()
        }
        // Long-press di area canvas kosong akan memunculkan opsi "Paste".
        //
        // NOTE: awalnya pakai `.onPasteCommand`, tapi ternyata overload
        // berbasis NSItemProvider itu tidak tersedia di iOS sama sekali
        // (nampaknya khusus macOS). Jadi dibuat manual lewat `.contextMenu`
        // + baca `UIPasteboard.general` langsung — lebih sederhana dan
        // sepenuhnya di bawah kendali kita.
        .contextMenu {
            if UIPasteboard.general.hasImages {
                Button {
                    onPaste()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
            }
        }
    }
}

// MARK: - Placeholder foto badan

struct BodyPhotoPlaceholderView: View {
    var body: some View {
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 240, height: 480)
            .foregroundStyle(Color(.systemGray5))
            .overlay(alignment: .center) {
                VStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 26))
                    Text("Upload your full body photo")
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .frame(width: 130)
                }
                .foregroundStyle(Color(.systemGray2))
                .offset(y: 16)
            }
            .contentShape(Rectangle())
    }
}

// MARK: - Background dot-grid

struct DotGridBackground: View {
    let size: CGSize
    private let spacing: CGFloat = 24
    private let dotRadius: CGFloat = 1.2
    private let dotColor = Color(.systemGray4)

    var body: some View {
        Canvas { context, canvasSize in
            var x: CGFloat = 0
            while x <= canvasSize.width {
                var y: CGFloat = 0
                while y <= canvasSize.height {
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                    y += spacing
                }
                x += spacing
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

#Preview {
    CanvasContentView(
        canvasSize: CGSize(width: 1000, height: 1000),
        layers: [],
        selectedLayerID: nil,
        onChoosePhoto: {},
        onPaste: {},
        onSelectLayer: { _ in },
        onDeselect: {},
        onLayerGestureEnd: {},
        onLayerInteractionChange: { _ in }
    )
    .frame(width: 380, height: 380)
    .scaleEffect(0.38)
}
