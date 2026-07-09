//
//  SheetViewModel.swift
//  BatikMaxxing
//
//  Created by Asaryun on 03/07/26.
//

import Foundation
import SwiftUI
internal import Combine

final class SheetViewModel: ObservableObject {
    @Published var selectedCard: CardModel? = nil
    @Published var selectedTab = 0

    @Published var sheet: SheetModel

    init() {

        let batikAssets = [

            AssetModel(name: "Batik 1", image: "batik1"),
            AssetModel(name: "Batik 2", image: "batik2"),
            AssetModel(name: "Batik 3", image: "batik3"),
            AssetModel(name: "Batik 4", image: "batik4"),
            AssetModel(name: "Batik 5", image: "batik5"),
            AssetModel(name: "Batik 6", image: "batik6")

        ]

        sheet = SheetModel(

            menCards: [

                CardModel(
                    title: "Batik Shirts",
                    assets: batikAssets
                )

            ],

            womenCards: [

                CardModel(
                    title: "Batik Shirts",
                    assets: batikAssets
                )

            ]
        )
    }

}
