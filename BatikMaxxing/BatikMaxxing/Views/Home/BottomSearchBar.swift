//
//  BottomSearchBar.swift
//  BatikMaxxing
//
//  Created by Liecardo on 04/07/26.
//

import SwiftUI

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

