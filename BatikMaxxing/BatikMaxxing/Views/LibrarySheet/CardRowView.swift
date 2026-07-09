//
//  CardRowView.swift
//  BatikMaxxing
//
//  Created by Asaryun on 03/07/26.
//

import SwiftUI

struct CardRowView: View {

    let card: CardModel

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text(card.title)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.blue)

            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(card.previewAssets) { asset in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray)
                            .frame(width: 120, height: 120)
                    }
                }
            }
            .frame(height: 130)

        }

    }

}
