//
//  CanvasView.swift
//  BatikMaxxing
//
//  Created by Liecardo on 04/07/26.
//

//  Editor canvas utama, mirip FreeForm. Fitur di step ini:
//  - Navigasi canvas: zoom (10%–400%) & pan lewat ZoomableScrollView
//  - Choose photo untuk foto badan, copy & paste foto dari galeri
//  - Semua object di canvas (foto badan/atasan/bawahan/bebas) bisa
//    di-select, di-resize, di-rotate, di-reposition (lewat
//    SelectableCanvasLayerView)
//  - Undo & Redo via toolbar kanan atas — pakai UndoManager native yang
//    otomatis terhubung ke SwiftData lewat `isUndoEnabled: true`
//  - Toolbar kanan atas: rename & share
//  - Tombol kiri bawah: buka library sheet (visual saja untuk saat ini)
//  - Tombol kanan bawah: buat canvas baru
//
//  Hide/unhide, duplicate, bring to front/back, lock, delete PER-LAYER
//  sengaja belum diimplementasikan — menyusul setelah fundamental ini
//  stabil, sesuai kesepakatan.
//

import SwiftUI
import SwiftData
import PhotosUI

struct CanvasView: View {
    @Bindable var project: CanvasModel
    @Binding var navigationPath: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.undoManager) private var undoManager

    @State private var viewModel = CanvasViewModel()
    @State private var zoomScale: CGFloat = 1.0
    @State private var selectedLayerID: UUID?
    /// True persis selama ada layer yang sedang di-drag/resize/rotate.
    /// Dipakai untuk menonaktifkan sementara pan gesture ZoomableScrollView
    /// (lihat komentar di ZoomableScrollView.swift untuk alasannya).
    @State private var isInteractingWithLayer = false

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)
                .ignoresSafeArea()

            ZoomableScrollView(
                contentSize: viewModel.canvasSize,
                minZoom: 0.1,
                maxZoom: 4.0,
                currentZoom: $zoomScale,
                isInteractionDisabled: isInteractingWithLayer
            ) {
                CanvasContentView(
                    canvasSize: viewModel.canvasSize,
                    layers: project.layers,
                    selectedLayerID: selectedLayerID,
                    onChoosePhoto: {
                        viewModel.isPhotoPickerPresented = true
                    },
                    onPaste: {
                        viewModel.pasteImageFromClipboard(to: project, in: modelContext)
                    },
                    onSelectLayer: { id in
                        selectedLayerID = id
                    },
                    onDeselect: {
                        selectedLayerID = nil
                    },
                    onLayerGestureEnd: {
                        project.updatedAt = .now
                        viewModel.persistLayerChanges(in: modelContext)
                    },
                    onLayerInteractionChange: { isInteracting in
                        isInteractingWithLayer = isInteracting
                    }
                )
            }
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .photosPicker(
            isPresented: $viewModel.isPhotoPickerPresented,
            selection: $viewModel.selectedPhotoItem,
            matching: .images
        )
        .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
            viewModel.handlePickedPhoto(newItem, on: project, in: modelContext)
        }
        // Layer yang baru saja ditambahkan (choose photo / paste) langsung
        // auto-select, supaya handle resize/rotate langsung kelihatan.
        .onChange(of: viewModel.lastAddedLayerID) { _, newID in
            selectedLayerID = newID
        }
        .alert("Rename Canvas", isPresented: $viewModel.isRenamePresented) {
            TextField("Name", text: $viewModel.renameText)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.commitRename(on: project, in: modelContext)
            }
        }
        .sheet(isPresented: $viewModel.isLibrarySheetPresented) {
            LibraryPlaceholderSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            HStack(spacing: 0) {
                // Undo & Redo — didukung UndoManager native yang otomatis
                // terhubung ke SwiftData (lihat isUndoEnabled di
                // App/BatikMaxxing.swift). Tidak ada undo-stack manual.
                Button {
                    undoManager?.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .frame(width: 40, height: 44)
                }
                .disabled(!(undoManager?.canUndo ?? false))

                Button {
                    undoManager?.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .frame(width: 40, height: 44)
                }
                .disabled(!(undoManager?.canRedo ?? false))

                Divider().frame(height: 20)

                Menu {
                    Button {
                        viewModel.beginRename(current: project.name)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    ShareLink(item: project.name) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                }
            }
            .background(.thinMaterial)
            .clipShape(Capsule())
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack {
            Button {
                viewModel.isLibrarySheetPresented = true
            } label: {
                Image(systemName: "square.stack")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 48, height: 48)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            Button {
                let newProject = viewModel.createNewCanvas(in: modelContext)
                navigationPath.append(newProject)
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 48, height: 48)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack {
        CanvasView(project: previewProject, navigationPath: .constant(NavigationPath()))
    }
    .modelContainer(previewContainerWithSampleProject())
}

private let previewProject = CanvasModel(name: "Untitled")

/// Terpisah dari closure `#Preview` karena `#Preview` pakai `@ViewBuilder`
/// juga (seperti `body`) — tidak boleh ada statement biasa yang me-return
/// `Void` (mis. `context.insert(...)`) langsung di dalamnya.
private func previewContainerWithSampleProject() -> ModelContainer {
    let container = try! ModelContainer(
        for: CanvasModel.self, CanvasLayerModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    container.mainContext.insert(previewProject)
    return container
}
