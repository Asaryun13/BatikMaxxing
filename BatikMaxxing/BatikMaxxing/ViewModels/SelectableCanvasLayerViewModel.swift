//
//  SelectableCanvasLayerViewModel.swift
//  BatikMaxxing
//
//  Created by Asaryun on 09/07/26.
//

import Foundation
import SwiftUI

@Observable
final class SelectableCanvasLayerViewModel {

    // MARK: - Interactive State

    // Live/interactive state — cuma visual, belum ditulis ke model.
    // Sengaja @State biasa (sekarang properti @Observable), bukan @GestureState (lihat catatan di atas).
    var liveDrag: CGSize = .zero
    var liveScale: CGFloat = 1.0

    // Guard supaya onSelect() cuma dipanggil SEKALI per gesture drag,
    // walau propagasi `isSelected` dari parent belum tentu instan.
    var didSelectInCurrentDrag = false

    // Snapshot nilai model di awal gesture resize (untuk hitung scale factor).
    var resizeBaseSize: CGSize?

    // Snapshot di awal gesture rotate: rotasi model + sudut jari (global)
    // relatif terhadap titik tengah layer, keduanya diperlukan untuk
    // menghitung delta rotasi yang presisi sepanjang gesture.
    var rotationStartAngle: Double?
    var rotationStartFingerAngle: Double?

    /// Titik tengah layer dalam koordinat GLOBAL (layar), dilacak lewat
    /// GeometryReader supaya rotateGesture bisa hitung sudut jari yang
    /// akurat — lihat catatan fix rotate di atas.
    var layerCenter: CGPoint = .zero

    // MARK: - Configuration Constants

    let minLayerSize: Double = 32
}
