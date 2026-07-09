//
//  AssetGridView.swift
//  BatikMaxxing
//
//  Created by Asaryun on 03/07/26.
//
import SwiftUI

struct AssetGridView: View {

    let card: CardModel
    let onBack: () -> Void

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {

        VStack(spacing: 16) {

            HStack {

                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }

                Spacer()

                Text(card.title)
                    .font(.headline)

                Spacer()

                // Keeps the title centered
                Image(systemName: "chevron.left")
                    .opacity(0)

            }
            .padding(.horizontal)

            ScrollView {

                LazyVGrid(columns: columns, spacing: 20) {

                    ForEach(card.assets) { asset in

                        VStack {

                            Image(asset.image)
                                .resizable()
                                .scaledToFit()

                        }
                        .frame(height: 150)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 2)

                    }

                }
                .padding()

            }

        }

    }

}
