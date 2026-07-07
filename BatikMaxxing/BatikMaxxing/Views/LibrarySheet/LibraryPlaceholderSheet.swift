//
//  LibraryPlaceholderSheet.swift
//  BatikMaxxing
//
//  Created by Liecardo on 05/07/26.
//

//  Placeholder visual untuk sheet library (koleksi atasan/bawahan).
//  Detail & fungsionalitasnya dibahas & dibangun di step terpisah.
//

import SwiftUI

struct LibraryPlaceholderSheet: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Library")
                .font(.title3.bold())

            Text("Koleksi atasan & bawahan akan tersedia di sini.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LibraryPlaceholderSheet()
}
