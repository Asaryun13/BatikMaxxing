//
//  CardModel.swift
//  BatikMaxxing
//
//  Created by Asaryun on 03/07/26.
//

import Foundation

struct CardModel: Identifiable, Hashable {
    let id = UUID()

    let title: String

    let assets: [AssetModel]

    var previewAssets: [AssetModel] {
        Array(assets.prefix(5))
    }
}
