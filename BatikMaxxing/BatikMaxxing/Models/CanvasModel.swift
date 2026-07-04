//
//  CanvasModel.swift
//  BatikMaxxing
//
//  Created by Liecardo on 04/07/26.
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

    // NOTE: Di step berikutnya (saat membangun CanvasView), kita akan tambahkan
    // relasi ke layer-layer gambar (foto badan, atasan, bawahan) beserta
    // posisi/rotasi/skala masing-masing. Untuk saat ini model hanya menyimpan
    // metadata yang dibutuhkan halaman utama.

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
    }
}
