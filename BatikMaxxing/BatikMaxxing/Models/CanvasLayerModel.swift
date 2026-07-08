//
//  CanvasLayerModel.swift
//  BatikMaxxing
//
//  Created by Liecardo on 05/07/26.
//

//  Merepresentasikan satu foto yang ditempel di atas canvas (foto badan,
//  atasan, bawahan, atau foto bebas hasil paste). Posisi/ukuran disimpan
//  dalam koordinat canvas (bukan koordinat layar), supaya konsisten di
//  semua level zoom.
//
//  NOTE: rotasi, resize, drag-reposition, duplicate, delete PER-LAYER
//  belum diimplementasikan di step ini — fokus saat ini baru sampai
//  menempatkan layer pertama kali (choose photo / paste). Field-field
//  di bawah sudah disiapkan supaya gesture editing itu tinggal
//  memodifikasi property yang sudah ada, tanpa perlu migrasi model lagi.
//

import Foundation
import SwiftData

enum CanvasLayerKind: String, Codable {
    case bodyReference
    case top
    case bottom
    case freeform
}

@Model
final class CanvasLayerModel {
    var id: UUID
    private var kindRaw: String

    /// Posisi titik tengah layer dalam koordinat canvas (bukan koordinat layar).
    var positionX: Double
    var positionY: Double

    var width: Double
    var height: Double

    /// Dalam derajat.
    var rotation: Double

    /// Urutan tumpukan (semakin besar semakin di depan).
    var zIndex: Int

    var createdAt: Date

    @Attribute(.externalStorage)
    var imageData: Data?

    /// Inverse dari relasi `CanvasModel.layers`.
    var canvas: CanvasModel?

    var kind: CanvasLayerKind {
        get { CanvasLayerKind(rawValue: kindRaw) ?? .freeform }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: CanvasLayerKind,
        positionX: Double,
        positionY: Double,
        width: Double,
        height: Double,
        rotation: Double = 0,
        zIndex: Int = 0,
        imageData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.rotation = rotation
        self.zIndex = zIndex
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
