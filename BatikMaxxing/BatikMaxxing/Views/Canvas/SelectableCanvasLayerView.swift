//
//  SelectableCanvasLayerView.swift
//  BatikMaxxing
//
//  Created by Liecardo on 05/07/26.
//  Edited by Asaryun on 09/07/26

//  Satu layer (foto) di canvas yang bisa di-tap untuk select, di-drag untuk
//  reposition, di-resize lewat 4 handle pojok (proporsional, menjaga aspect
//  ratio), dan di-rotate lewat 1 handle di atas.
//
//  Geometri: seluruh view ini (termasuk margin untuk handle) dibungkus
//  dalam SATU frame simetris (margin sama di semua sisi = ruang yang
//  dibutuhkan handle rotate + touch target-nya). Ini penting supaya titik
//  pusat frame SELALU sama dengan titik pusat foto, sehingga `.position()`
//  di paling luar dan `.rotationEffect` (anchor default .center) tetap
//  presisi tanpa perlu hitung offset tambahan.
//
//  Touch target: lingkaran VISUAL handle sengaja dibuat kecil (biar tidak
//  norak di canvas), tapi area yang bisa DISENTUH dibuat 44x44pt (standar
//  minimum Apple HIG) lewat frame tak terlihat di sekeliling lingkaran.
//
//  Live gesture state (liveDrag/liveScale) SEMUANYA `@State` biasa (BUKAN
//  `@GestureState`), dan di-reset MANUAL di baris yang SAMA dengan commit
//  ke model di `.onEnded` — supaya urutannya pasti atomic.
//
//  KUNCI fix reposition (smooth): `dragGesture` ditempel PALING LUAR,
//  SETELAH `.rotationEffect` dan `.position()` — jadi `value.translation`
//  otomatis dilaporkan dalam koordinat parent/canvas, tanpa perlu konversi
//  trigonometri manual sama sekali.
//
//  KUNCI fix rotate (smooth): rotateGesture pakai
//  `DragGesture(coordinateSpace: .global)`, supaya `value.location`/
//  `startLocation` langsung dalam koordinat global asli — bisa
//  dibandingkan langsung dengan `layerCenter` (dilacak via
//  `geo.frame(in: .global)`) tanpa aproksimasi apa pun. Sebelumnya kode
//  mencoba mengaproksimasi posisi jari global dengan menjumlahkan
//  `value.startLocation` (koordinat LOKAL milik handle kecil, rentang
//  ~0-44pt) ke `layerCenter` — itu salah secara geometris dan errornya
//  signifikan karena skalanya sama order dengan `rotateHandleDistance`.
//
//  NOTE: resizeGesture MASIH pakai konversi trigonometri manual (global ->
//  local) karena gesture-nya tetap ditempel di dalam hierarchy yang kena
//  `.rotationEffect` (lewat handle di corner). Ini sudah dikonfirmasi jalan
//  dengan benar sebelumnya — sengaja tidak diubah supaya tidak ada regresi.
//
import SwiftUI

struct SelectableCanvasLayerView: View {

    let layer: CanvasLayerModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onGestureEnd: () -> Void
    /// Dipanggil `true` PERSIS saat drag/resize/rotate mulai dikenali, dan
    /// `false` begitu selesai. Dipertahankan sebagai fallback di samping
    /// `scrollGestureController` (yang lebih langsung/synchronous).
    let onInteractionChange: (Bool) -> Void

    /// Jalur LANGSUNG (synchronous, tanpa round-trip @State) untuk
    /// menonaktifkan pan gesture UIScrollView begitu gesture layer mulai.
    @Environment(\.scrollGestureController) private var scrollGestureController

    @State private var viewModel = SelectableCanvasLayerViewModel()

    private let handleVisualSize: CGFloat = 26
    private let handleTouchSize: CGFloat = 44
    private let rotateHandleDistance: CGFloat = 44

    /// Margin SIMETRIS di semua sisi (lihat catatan geometri di atas).
    private var margin: CGFloat { rotateHandleDistance + handleTouchSize }

    var body: some View {

        let width = CGFloat(layer.width)
        let height = CGFloat(layer.height)

        GeometryReader { proxy in

            ZStack {

                imageView
                    .frame(width: width, height: height)
                    .scaleEffect(viewModel.liveScale)

                if isSelected {

                    Rectangle()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                        .frame(
                            width: width * viewModel.liveScale,
                            height: height * viewModel.liveScale
                        )
                        .allowsHitTesting(false)

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 1, height: rotateHandleDistance)
                        .offset(
                            y: -(height * viewModel.liveScale)/2 - rotateHandleDistance/2
                        )
                        .allowsHitTesting(false)

                    rotateHandleView
                        .offset(
                            y: -(height * viewModel.liveScale)/2 - rotateHandleDistance
                        )

                    cornerHandleView(sx: -1, sy: -1)
                        .offset(
                            x: -(width * viewModel.liveScale)/2,
                            y: -(height * viewModel.liveScale)/2
                        )

                    cornerHandleView(sx: 1, sy: -1)
                        .offset(
                            x: (width * viewModel.liveScale)/2,
                            y: -(height * viewModel.liveScale)/2
                        )

                    cornerHandleView(sx: -1, sy: 1)
                        .offset(
                            x: -(width * viewModel.liveScale)/2,
                            y: (height * viewModel.liveScale)/2
                        )

                    cornerHandleView(sx: 1, sy: 1)
                        .offset(
                            x: (width * viewModel.liveScale)/2,
                            y: (height * viewModel.liveScale)/2
                        )
                }

            }
            .frame(
                width: width + margin * 2,
                height: height + margin * 2
            )
            .background {

                GeometryReader { geo in

                    Color.clear
                        .onAppear {

                            let frame = geo.frame(in: .global)

                            viewModel.layerCenter = CGPoint(
                                x: frame.midX,
                                y: frame.midY
                            )
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in

                            viewModel.layerCenter = CGPoint(
                                x: newFrame.midX,
                                y: newFrame.midY
                            )
                        }

                }

            }
            .contentShape(Rectangle())
            .rotationEffect(
                Angle(degrees: layer.rotation)
            )
            .position(
                x: CGFloat(layer.positionX) + viewModel.liveDrag.width,
                y: CGFloat(layer.positionY) + viewModel.liveDrag.height
            )
            .gesture(dragGesture)

        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let data = layer.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        }
    }

    /// Dipanggil PERSIS saat gesture (drag/resize/rotate) mulai dikenali.
    /// Menonaktifkan pan UIScrollView lewat DUA jalur sekaligus: langsung
    /// via `scrollGestureController` (synchronous, tanpa delay), dan lewat
    /// `onInteractionChange` (fallback berbasis @State) untuk redundansi.
    private func beginInteraction() {
        scrollGestureController?.setPanEnabled(false)
        onInteractionChange(true)
    }

    private func endInteraction() {
        scrollGestureController?.setPanEnabled(true)
        onInteractionChange(false)
    }

    // MARK: - Reposition (drag body) — select + drag jadi SATU gesture,
    // minimumDistance 0 supaya langsung merespons sejak sentuhan pertama.

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !viewModel.didSelectInCurrentDrag {
                    viewModel.didSelectInCurrentDrag = true
                    if !isSelected {
                        onSelect()
                    }
                    beginInteraction()
                }

                viewModel.liveDrag = value.translation
            }
            .onEnded { value in
                layer.positionX += Double(value.translation.width)
                layer.positionY += Double(value.translation.height)
                viewModel.liveDrag = .zero
                viewModel.didSelectInCurrentDrag = false
                endInteraction()
                onGestureEnd()
            }
    }

    // MARK: - Handle views

    private func handleDot<Content: View>(@ViewBuilder icon: () -> Content) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
                .frame(width: handleVisualSize, height: handleVisualSize)
            icon()
        }
        // Frame lebih besar dari lingkaran visual = area sentuh 44x44pt,
        // sesuai standar minimum Apple HIG, tanpa bikin handle keliatan
        // kebesaran secara visual.
        .frame(width: handleTouchSize, height: handleTouchSize)
        .contentShape(Rectangle())
    }

    private var rotateHandleView: some View {
        handleDot {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
        .gesture(rotateGesture())
    }

    private func cornerHandleView(sx: Double, sy: Double) -> some View {
        handleDot { EmptyView() }
            .gesture(resizeGesture(sx: sx, sy: sy))
    }

    // MARK: - Resize (drag salah satu handle pojok, proporsional)
    //
    // Masih pakai konversi trigonometri manual (global -> local) karena
    // gesture ini tetap ditempel di dalam hierarchy yang kena
    // `.rotationEffect`. Sudah dikonfirmasi jalan benar — tidak diubah.

    private func resizeGesture(sx: Double, sy: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if viewModel.resizeBaseSize == nil {
                    viewModel.resizeBaseSize = CGSize(width: layer.width, height: layer.height)
                    beginInteraction()
                }
                guard let base = viewModel.resizeBaseSize else { return }

                let radians = layer.rotation * .pi / 180
                let cosT = cos(radians)
                let sinT = sin(radians)
                let tx = Double(value.translation.width)
                let ty = Double(value.translation.height)
                let localDx = tx * cosT + ty * sinT
                let localDy = -tx * sinT + ty * cosT

                let hw = base.width / 2
                let hh = base.height / 2
                let startDistance = sqrt(hw * hw + hh * hh)
                guard startDistance > 0 else { return }

                let newCornerX = sx * hw + localDx
                let newCornerY = sy * hh + localDy
                let newDistance = sqrt(newCornerX * newCornerX + newCornerY * newCornerY)

                viewModel.liveScale = max(CGFloat(newDistance / startDistance), 0.15)
            }
            .onEnded { _ in
                guard let base = viewModel.resizeBaseSize else { return }
                layer.width = max(viewModel.minLayerSize, base.width * Double(viewModel.liveScale))
                layer.height = max(viewModel.minLayerSize, base.height * Double(viewModel.liveScale))
                viewModel.liveScale = 1.0
                viewModel.resizeBaseSize = nil
                endInteraction()
                onGestureEnd()
            }
    }

    // MARK: - Rotate (drag handle di atas)
    //
    // FIX: pakai coordinateSpace .global, supaya value.location/
    // startLocation adalah posisi jari SESUNGGUHNYA di layar — tinggal
    // dibandingkan langsung dengan layerCenter (juga global). Tidak ada
    // lagi pendekatan/aproksimasi koordinat.

    private func rotateGesture() -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if viewModel.rotationStartAngle == nil {
                    viewModel.rotationStartAngle = layer.rotation
                    viewModel.rotationStartFingerAngle = atan2(
                        value.startLocation.y - viewModel.layerCenter.y,
                        value.startLocation.x - viewModel.layerCenter.x
                    )
                    beginInteraction()
                }

                guard
                    let startRotation = viewModel.rotationStartAngle,
                    let startFingerAngle = viewModel.rotationStartFingerAngle
                else {
                    return
                }

                let currentFingerAngle = atan2(
                    value.location.y - viewModel.layerCenter.y,
                    value.location.x - viewModel.layerCenter.x
                )

                let delta = currentFingerAngle - startFingerAngle
                layer.rotation = startRotation + delta * 180 / .pi
            }
            .onEnded { _ in
                viewModel.rotationStartAngle = nil
                viewModel.rotationStartFingerAngle = nil

                endInteraction()
                onGestureEnd()
            }
    }
}
