//
//  SheetView.swift
//  BatikMaxxing
//
//  Created by James Richard Renaldo on 03/07/26.
//
import SwiftUI

struct SheetView: View {

    @StateObject private var vm = SheetViewModel()

    var body: some View {

        VStack {

            if let selectedCard = vm.selectedCard {

                AssetGridView(
                    card: selectedCard,
                    onBack: {
                        vm.selectedCard = nil
                    }
                )

            } else {

                Picker("", selection: $vm.selectedTab) {
                    Text("MAN")
                        .tag(0)

                    Text("WOMAN")
                        .tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {

                    LazyVStack(spacing: 24) {

                        ForEach(currentCards) { card in

                            CardRowView(card: card)
                                .onTapGesture {
                                    vm.selectedCard = card
                                }

                        }

                    }
                    .padding()

                }

            }

        }

    }

    var currentCards: [CardModel] {
        vm.selectedTab == 0
        ? vm.sheet.menCards
        : vm.sheet.womenCards
    }

}

#Preview {
    SheetView()
}
