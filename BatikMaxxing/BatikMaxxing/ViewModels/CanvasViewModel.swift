//
//  CanvasViewModel.swift
//  BatikMaxxing
//
//  Created by Liecardo on 05/07/26.
//  Edited by Asaryun on 09/07/26

//  State & logic untuk CanvasView: rename, tambah foto badan (choose
//  photo dari PhotosPicker), paste foto dari clipboard, dan buat canvas
//  baru dari dalam CanvasView. ModelContext dikirim sebagai parameter di
//  tiap method yang butuh — pola yang sama seperti HomeViewModel.
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI
import UIKit

@Observable
final class CanvasViewModel {

    // MARK: - Canvas dimension

    /// Ukuran canvas tetap untuk saat ini (dalam "poin" koordinat canvas,
    /// independen dari level zoom). Bisa diekspos jadi setting yang bisa
    /// diubah user kalau nanti dibutuhkan.
    let canvasWidth: Double = 1000
    let canvasHeight: Double = 1000

    var canvasSize: CGSize {
        CGSize(width: canvasWidth, height: canvasHeight)
    }

    // MARK: - Interactive View States (Moved from CanvasView for optimization)

    var zoomScale: CGFloat = 1.0
    var selectedLayerID: UUID?
    
    /// True persis selama ada layer yang sedang di-drag/resize/rotate.
    /// Dipakai untuk menonaktifkan sementara pan gesture ZoomableScrollView
    /// (lihat komentar di ZoomableScrollView.swift untuk alasannya).
    var isInteractingWithLayer = false

    // MARK: - Rename flow

    var isRenamePresented = false
    var renameText: String = ""

    // MARK: - Choose photo flow (foto badan)

    var isPhotoPickerPresented = false
    var selectedPhotoItem: PhotosPickerItem?

    // MARK: - Library sheet (visual placeholder untuk saat ini)

    var isLibrarySheetPresented = false

    // MARK: - Rename

    func beginRename(current name: String) {
        renameText = name
        isRenamePresented = true
    }

    func commitRename(on project: CanvasModel, in context: ModelContext) {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            project.name = trimmed
            project.updatedAt = .now
            save(context)
        }
        isRenamePresented = false
    }

    // MARK: - Buat canvas baru dari dalam CanvasView

    @discardableResult
    func createNewCanvas(in context: ModelContext) -> CanvasModel {
        let newProject = CanvasModel()
        context.insert(newProject)
        save(context)
        return newProject
    }

    // MARK: - Foto badan (via PhotosPicker)

    func handlePickedPhoto(_ item: PhotosPickerItem?, on project: CanvasModel, in context: ModelContext) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    setBodyReferenceLayer(imageData: data, on: project, in: context)
                    selectedPhotoItem = nil
                }
            }
        }
    }

    private func setBodyReferenceLayer(imageData: Data, on project: CanvasModel, in context: ModelContext) {
        // Hanya boleh ada satu foto badan aktif — kalau sudah ada, ganti yang lama.
        if let existing = project.layers.first(where: { $0.kind == .bodyReference }) {
            context.delete(existing)
        }

        let defaultHeight = canvasHeight * 0.7
        let aspect: Double = {
            guard let uiImage = UIImage(data: imageData), uiImage.size.height > 0 else { return 0.45 }
            return uiImage.size.width / uiImage.size.height
        }()

        let layer = CanvasLayerModel(
            kind: .bodyReference,
            positionX: canvasWidth / 2,
            positionY: canvasHeight / 2,
            width: defaultHeight * aspect,
            height: defaultHeight,
            zIndex: 0,
            imageData: imageData
        )
        context.insert(layer)
        layer.canvas = project
        project.updatedAt = .now
        save(context)
        
        // Layer yang baru saja ditambahkan (choose photo / paste) langsung
        // auto-select, supaya handle resize/rotate langsung kelihatan.
        selectedLayerID = layer.id
    }

    // MARK: - Paste dari clipboard (copy foto dari galeri, paste ke canvas)

    func pasteImageFromClipboard(to project: CanvasModel, in context: ModelContext) {
        guard let uiImage = UIPasteboard.general.image else { return }
        addPastedLayer(uiImage: uiImage, to: project, in: context)
    }

    private func addPastedLayer(uiImage: UIImage, to project: CanvasModel, in context: ModelContext) {
        guard let data = uiImage.pngData() else { return }

        let maxDimension = canvasWidth * 0.4
        let aspect = uiImage.size.height > 0 ? uiImage.size.width / uiImage.size.height : 1
        let width = aspect >= 1 ? maxDimension : maxDimension * aspect
        let height = aspect >= 1 ? maxDimension / aspect : maxDimension
        let nextZ = (project.layers.map(\.zIndex).max() ?? 0) + 1

        let layer = CanvasLayerModel(
            kind: .freeform,
            positionX: canvasWidth / 2,
            positionY: canvasHeight / 2,
            width: width,
            height: height,
            zIndex: nextZ,
            imageData: data
        )
        context.insert(layer)
        layer.canvas = project
        project.updatedAt = .now
        save(context)
        
        // Layer yang baru saja ditambahkan (choose photo / paste) langsung
        // auto-select, supaya handle resize/rotate langsung kelihatan.
        selectedLayerID = layer.id
    }

    // MARK: - Persist perubahan dari gesture (resize/rotate/reposition)

    /// Dipanggil dari `SelectableCanvasLayerView` setiap kali sebuah gesture
    /// (drag/resize/rotate) selesai. Publik (bukan `private`) karena dipanggil
    /// langsung dari View, bukan dari method lain di ViewModel ini.
    ///
    /// NOTE: sengaja ditunda satu tick lewat `Task { @MainActor in }`
    /// (bukan dipanggil langsung/synchronous). `context.save()` melakukan
    /// disk write + registrasi Undo (karena `isUndoEnabled: true`), yang
    /// kalau dipanggil PERSIS di frame yang sama dengan akhir gesture bisa
    /// menahan main thread sesaat — dirasakan user sebagai "glitch"/kedipan
    /// tepat saat gesture selesai. Menunda ke tick berikutnya (tetap di
    /// main thread, BUKAN background thread) membiarkan UI dulu selesai
    /// menggambar posisi/rotasi/ukuran final dengan mulus, baru
    /// persist-nya menyusul.
    func persistLayerChanges(in context: ModelContext) {
        Task { @MainActor in
            save(context)
        }
    }

    // MARK: - Persistence helper

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("⚠️ Failed to save canvas changes: \(error)")
        }
    }
}
