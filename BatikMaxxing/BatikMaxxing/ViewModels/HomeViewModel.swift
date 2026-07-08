//
//  HomeViewModel.swift
//  BatikMaxxing
//
//  Created by Joey Martin on 03/07/26.
//

//  Semua state dan logic untuk HomeView dipindahkan ke sini:
//  search/filter, alur rename, alur delete, dan aksi create/duplicate.
//
//  Catatan arsitektur:
//  `@Query` dari SwiftData cuma bisa dipakai langsung di dalam View (dia
//  terikat ke lifecycle View lewat property wrapper khusus SwiftUI), jadi
//  data mentah `[CanvasModel]` tetap diambil di HomeView, lalu di-pass ke
//  `filteredCanvases(from:)`. `ModelContext` juga dikirim sebagai parameter
//  di tiap method yang butuh — bukan disimpan sebagai property tersimpan —
//  supaya tidak bergantung pada timing @Environment saat inisialisasi,
//  dan supaya ViewModel ini lebih gampang di-unit-test (tinggal pass
//  ModelContext in-memory tanpa perlu ada View sama sekali).
//

import Foundation
import SwiftData
import Observation

@Observable
final class HomeViewModel {

    // MARK: - Search

    var searchText: String = ""

    // MARK: - Rename flow

    var renamingProject: CanvasModel?
    var renameText: String = ""

    var isRenamePresented: Bool {
        get { renamingProject != nil }
        set { if !newValue { renamingProject = nil } }
    }

    // MARK: - Delete flow

    var projectPendingDelete: CanvasModel?

    var isDeleteConfirmationPresented: Bool {
        get { projectPendingDelete != nil }
        set { if !newValue { projectPendingDelete = nil } }
    }

    var deleteConfirmationTitle: String {
        guard let project = projectPendingDelete else { return "" }
        return "Delete \"\(project.name)\"?"
    }

    // MARK: - Derived data

    func filteredCanvases(from canvases: [CanvasModel]) -> [CanvasModel] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return canvases }
        return canvases.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    // MARK: - Create

    @discardableResult
    func createCanvas(in context: ModelContext) -> CanvasModel {
        let newProject = CanvasModel()
        context.insert(newProject)
        save(context)
        return newProject
    }

    // MARK: - Rename

    func beginRename(_ project: CanvasModel) {
        renamingProject = project
        renameText = project.name
    }

    func cancelRename() {
        renamingProject = nil
    }

    func commitRename(in context: ModelContext) {
        guard let project = renamingProject else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            project.name = trimmed
            project.updatedAt = .now
            save(context)
        }
        renamingProject = nil
    }

    // MARK: - Duplicate

    func duplicate(_ project: CanvasModel, in context: ModelContext) {
        let copy = CanvasModel(
            name: "\(project.name) copy",
            thumbnailData: project.thumbnailData
        )
        context.insert(copy)

        // Deep-copy semua layer (foto badan/atasan/bawahan/dll) supaya
        // hasil duplicate benar-benar identik, bukan cuma metadata-nya.
        for layer in project.layers {
            let layerCopy = CanvasLayerModel(
                kind: layer.kind,
                positionX: layer.positionX,
                positionY: layer.positionY,
                width: layer.width,
                height: layer.height,
                rotation: layer.rotation,
                zIndex: layer.zIndex,
                imageData: layer.imageData
            )
            context.insert(layerCopy)
            layerCopy.canvas = copy
        }

        save(context)
    }

    // MARK: - Delete

    func requestDelete(_ project: CanvasModel) {
        projectPendingDelete = project
    }

    func cancelDelete() {
        projectPendingDelete = nil
    }

    func commitDelete(in context: ModelContext) {
        guard let project = projectPendingDelete else { return }
        context.delete(project)
        save(context)
        projectPendingDelete = nil
    }

    // MARK: - Persistence helper

    /// Memaksa SwiftData menulis perubahan ke disk sekarang juga, dan
    /// melempar error ke console kalau gagal (alih-alih gagal diam-diam).
    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("⚠️ Failed to save CanvasModel changes: \(error)")
        }
    }
}
