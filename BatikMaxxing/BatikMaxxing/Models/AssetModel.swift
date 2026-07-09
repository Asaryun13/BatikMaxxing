//
//  AssetModel.swift
//  BatikMaxxing
//
//  Created by Asaryun on 03/07/26.
//

import Foundation

struct AssetModel: Identifiable, Hashable {
    let id = UUID()

    let name: String
    let image: String

    var isFavorite: Bool = false
}
