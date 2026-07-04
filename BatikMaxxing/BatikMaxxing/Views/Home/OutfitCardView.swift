//
//  OutfitCardView.swift
//  BatikMaxxing
//
//  Created by Liecardo on 04/07/26.
//

import SwiftUI

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
