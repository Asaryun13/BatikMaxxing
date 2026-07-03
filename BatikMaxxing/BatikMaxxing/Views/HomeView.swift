//
//  HomeView.swift
//  BatikMaxxing
//
//  Created by Joey Martin on 03/07/26.
//

import SwiftUI

struct HomeView: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<4, id: \.self) { _ in
                            OutfitCardView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 90)
                }
                .navigationTitle("All Outfit")
                BottomSearchBar(searchText: $searchText)
            }
        }
    }
}

struct OutfitCardView: View {
    var body: some View {
        VStack(spacing: 0) {
            // image placeholder
            // replace `Color.white` w/ Image() call
            ZStack {
                Color.white
                
                Image(systemName: "photo")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.largeTitle)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Untitled")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("03/07/26, 7.39 AM")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct BottomSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                
                TextField("Search", text: $searchText)
                    .foregroundColor(.primary)
                
                Image(systemName: "mic")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(24)
            
            Button(action: {
                // TODO: Add action logic
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(.body))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    HomeView()
}
