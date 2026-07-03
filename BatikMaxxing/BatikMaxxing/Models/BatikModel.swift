//
//  BatikModel.swift
//  BatikMaxxing
//
//  Created by Joey Martin on 03/07/26.
//

import Foundation

struct Batik: Identifiable {
    let id: UUID = UUID()
    let name: String
    let origin: String
    let meaning: String
    let imageName: String
}

struct BatikDatabase {
    
    static let shared = BatikDatabase()
    
    let featuredBatiks: [Batik] = [
        Batik(
            name: "Megamendung",
            origin: "Cirebon, West Java",
            meaning: "Represents rain-bearing clouds, serving as a symbol of fertility, life-giving elements, and patience.",
            imageName: "batik_megamendung"
        ),
        Batik(
            name: "Parang Rusak",
            origin: "Yogyakarta",
            meaning: "Symbolizes internal struggle, bravery, and the fight against evil to control one's desires. Traditionally reserved for royalty.",
            imageName: "batik_parang"
        ),
        Batik(
            name: "Kawung",
            origin: "Central Java",
            meaning: "Inspired by the palm fruit, it symbolizes perfection, purity, and the emptiness of worldly desires.",
            imageName: "batik_kawung"
        ),
        Batik(
            name: "Truntum",
            origin: "Surakarta (Solo)",
            meaning: "Created by an empress, this star-like pattern symbolizes unconditional, everlasting love that continues to grow and blossom.",
            imageName: "batik_truntum"
        ),
        Batik(
            name: "Sidomukti",
            origin: "Surakarta (Solo)",
            meaning: "Derived from 'sido' (to become) and 'mukti' (prosperous). It is often worn at weddings to wish the couple a prosperous and happy future.",
            imageName: "batik_sidomukti"
        )
    ]
}
