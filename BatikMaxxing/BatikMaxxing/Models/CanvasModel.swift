//
//  CanvasModel.swift
//  BatikMaxxing
//
//  Created by Liecardo on 04/07/26.
//

//  Model persisten untuk satu "canvas" (project outfit) yang dibuat user.
//  Menggunakan SwiftData supaya list canvas otomatis ter-update di UI (via @Query)
//  setiap kali ada perubahan (create/update/delete) tanpa perlu ViewModel manual.
//

import Foundation
import SwiftData

@Model
final class CanvasModel {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    // Thumbnail disimpan sebagai Data (PNG/JPEG render dari canvas).
    // .externalStorage supaya SwiftData otomatis menyimpannya sebagai file terpisah
    // (bukan di dalam database), jadi tidak membebani query list.
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    /// Semua foto (badan, atasan, bawahan, dll) yang ditempel di canvas ini.
    /// `.cascade` supaya menghapus CanvasModel otomatis menghapus semua
    /// layer-nya juga (tidak ada layer yatim tersisa di database).
    @Relationship(deleteRule: .cascade, inverse: \CanvasLayerModel.canvas)
    var layers: [CanvasLayerModel] = []

    init(
        id: UUID = UUID(),
        name: String = "Untitled",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailData = thumbnailData
        self.layers = []
    }
}
