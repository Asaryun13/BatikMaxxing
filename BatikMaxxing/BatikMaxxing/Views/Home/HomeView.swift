//
//  HomeView.swift
//  BatikMaxxing
//
//  Created by Joey Martin on 03/07/26.
//

import SwiftUI

//struct HomeView: View {
//    let columns = [
//        GridItem(.flexible(), spacing: 16),
//        GridItem(.flexible(), spacing: 16)
//    ]
//    
//    @State private var searchText = ""
//    
//    var body: some View {
//        NavigationStack {
//            ZStack(alignment: .bottom) {
//                ScrollView {
//                    LazyVGrid(columns: columns, spacing: 16) {
//                        ForEach(0..<4, id: \.self) { _ in
//                            OutfitCardView()
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.bottom, 90)
//                }
//                .navigationTitle("All Outfit")
//                BottomSearchBar(searchText: $searchText)
//            }
//        }
//    }
//}

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    // Otomatis ter-update setiap kali ada canvas baru/terhapus/terupdate.
    @Query(sort: \CanvasModel.updatedAt, order: .reverse)
    private var canvases: [CanvasModel]

    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var filteredCanvases: [CanvasModel] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return canvases }
        return canvases.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Text("All Outfit")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)

                    content
                }

                VStack {
                    Spacer()
                    bottomBar
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: CanvasModel.self) { project in
                CanvasView(project: project)
            }
        }
    }

    // MARK: - Content switch

    @ViewBuilder
    private var content: some View {
        if canvases.isEmpty {
            emptyStateView
        } else if filteredCanvases.isEmpty {
            noResultsView
        } else {
            canvasGridView
        }
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("You haven't created any canvas yet")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack {
            Spacer()
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var canvasGridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredCanvases) { project in
                    Button {
                        navigationPath.append(project)
                    } label: {
                        CanvasCardView(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110) // ruang untuk bottom bar yang mengambang
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Bottom bar (search + create)

    private var bottomBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search", text: $searchText)
                    .autocorrectionDisabled()

                Image(systemName: "mic.fill")
                    .foregroundStyle(.secondary)
                    .opacity(0.6) // dekoratif untuk saat ini
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button {
                createNewCanvas()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func createNewCanvas() {
        let newProject = CanvasModel()
        modelContext.insert(newProject)
        navigationPath.append(newProject)
    }
}

#Preview("Ada canvas") {
    let container = try! ModelContainer(
        for: CanvasModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    container.mainContext.insert(CanvasModel(name: "Untitled"))
    container.mainContext.insert(CanvasModel(name: "Untitled"))
    return HomeView()
        .modelContainer(container)
}

#Preview("Empty state") {
    HomeView()
        .modelContainer(for: CanvasModel.self, inMemory: true)
}


#Preview {
    HomeView()
}
