//
//  ZoomableScrollView.swift
//  BatikMaxxing
//
//  Created by Liecardo on 05/07/26.
//

//  Wrapper SwiftUI di atas UIScrollView native untuk pinch-to-zoom dan
//  drag-to-pan pada konten berukuran tetap (canvas). Dipakai sebagai
//  fondasi pengalaman "infinite canvas" ala FreeForm.
//
//  Kenapa UIScrollView (bukan gesture SwiftUI manual)?
//  UIScrollView sudah native menangani pinch-zoom + pan + momentum +
//  rubber-band bounce dengan sangat solid, termasuk kombinasi drag+pinch
//  secara simultan tanpa konflik gesture — persis behavior yang kita mau.
//
//  ScrollGestureController: di-inject ke environment konten yang di-host,
//  supaya SelectableCanvasLayerView bisa menonaktifkan panGestureRecognizer
//  milik UIScrollView ini secara LANGSUNG/synchronous (tanpa nunggu
//  propagasi @State lewat CanvasContentView -> CanvasView -> balik lagi ke
//  sini, yang walau cepat tetap ada celah waktu kecil). Ini memperkecil
//  risiko race antara gesture pan UIScrollView vs gesture layer di awal
//  sentuhan.
//

import SwiftUI
import UIKit

/// Pemegang referensi (weak) ke panGestureRecognizer milik UIScrollView,
/// di-inject lewat Environment supaya View manapun di dalam konten yang
/// di-host bisa langsung enable/disable pan tanpa round-trip state.
final class ScrollGestureController {
    weak var panGestureRecognizer: UIPanGestureRecognizer?

    func setPanEnabled(_ enabled: Bool) {
        panGestureRecognizer?.isEnabled = enabled
    }
}

private struct ScrollGestureControllerKey: EnvironmentKey {
    static let defaultValue: ScrollGestureController? = nil
}

extension EnvironmentValues {
    var scrollGestureController: ScrollGestureController? {
        get { self[ScrollGestureControllerKey.self] }
        set { self[ScrollGestureControllerKey.self] = newValue }
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let contentSize: CGSize
    let minZoom: CGFloat
    let maxZoom: CGFloat
    @Binding var currentZoom: CGFloat
    /// True selama ada layer yang sedang di-drag/resize/rotate — supaya
    /// UIScrollView berhenti "rebutan" gesture pan dengan gesture layer
    /// tersebut (ini akar penyebab reposition terasa buggy/glitching).
    /// Dipertahankan sebagai fallback/redundansi di samping
    /// ScrollGestureController yang lebih langsung.
    var isInteractionDisabled: Bool = false
    let content: Content

    init(
        contentSize: CGSize,
        minZoom: CGFloat = 0.1,
        maxZoom: CGFloat = 4.0,
        currentZoom: Binding<CGFloat>,
        isInteractionDisabled: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.contentSize = contentSize
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self._currentZoom = currentZoom
        self.isInteractionDisabled = isInteractionDisabled
        self.content = content()
    }

    private func wrappedContent(controller: ScrollGestureController) -> AnyView {
        AnyView(content.environment(\.scrollGestureController, controller))
    }

    func makeCoordinator() -> Coordinator {
        let controller = ScrollGestureController()
        return Coordinator(
            rootView: wrappedContent(controller: controller),
            currentZoomBinding: $currentZoom,
            scrollGestureController: controller
        )
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = CanvasHostingScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never

        // Sambungkan controller ke panGestureRecognizer yang sesungguhnya.
        context.coordinator.scrollGestureController.panGestureRecognizer = scrollView.panGestureRecognizer

        let hosted = context.coordinator.hostingController.view!
        hosted.backgroundColor = .clear
        hosted.frame = CGRect(origin: .zero, size: contentSize)
        scrollView.addSubview(hosted)
        scrollView.contentSize = contentSize

        // layoutSubviews UIKit dipanggil begitu bounds sudah pasti benar —
        // lebih reliable dibanding mengandalkan timing updateUIView SwiftUI.
        scrollView.onLayoutSubviews = { [weak scrollView, weak coordinator = context.coordinator] in
            guard let scrollView, let coordinator else { return }
            coordinator.fitToScreenIfNeeded(scrollView: scrollView, contentSize: contentSize)
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView =
            wrappedContent(controller: context.coordinator.scrollGestureController)

        // Fallback/redundansi: tetap sinkronkan lewat state juga, di luar
        // jalur langsung ScrollGestureController.
        scrollView.panGestureRecognizer.isEnabled = !isInteractionDisabled
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController: UIHostingController<AnyView>
        let scrollGestureController: ScrollGestureController
        private let currentZoomBinding: Binding<CGFloat>
        private var didFitInitially = false

        init(
            rootView: AnyView,
            currentZoomBinding: Binding<CGFloat>,
            scrollGestureController: ScrollGestureController
        ) {
            self.hostingController = UIHostingController(rootView: rootView)
            self.currentZoomBinding = currentZoomBinding
            self.scrollGestureController = scrollGestureController
            self.hostingController.view.backgroundColor = .clear
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(in: scrollView)
            currentZoomBinding.wrappedValue = scrollView.zoomScale
        }

        /// Pas-kan seluruh canvas ke layar (dengan sedikit margin) saat
        /// pertama kali muncul, mirip default view FreeForm.
        func fitToScreenIfNeeded(scrollView: UIScrollView, contentSize: CGSize) {
            guard !didFitInitially,
                  scrollView.bounds.width > 0,
                  scrollView.bounds.height > 0 else { return }

            let fitScale = min(
                scrollView.bounds.width / contentSize.width,
                scrollView.bounds.height / contentSize.height
            )
            let margin: CGFloat = 0.85
            let initialZoom = min(max(fitScale * margin, scrollView.minimumZoomScale), 1.0)

            scrollView.setZoomScale(initialZoom, animated: false)
            centerContent(in: scrollView)
            didFitInitially = true

            DispatchQueue.main.async { [currentZoomBinding] in
                currentZoomBinding.wrappedValue = initialZoom
            }
        }

        func centerContent(in scrollView: UIScrollView) {
            let boundsSize = scrollView.bounds.size
            var frame = hostingController.view.frame
            frame.origin.x = frame.width < boundsSize.width ? (boundsSize.width - frame.width) / 2 : 0
            frame.origin.y = frame.height < boundsSize.height ? (boundsSize.height - frame.height) / 2 : 0
            hostingController.view.frame = frame
        }
    }
}

/// Subclass kecil supaya kita bisa "nebeng" ke layoutSubviews UIKit,
/// yang jauh lebih reliable timing-nya dibanding updateUIView SwiftUI
/// untuk menghitung ukuran fit-to-screen awal.
private final class CanvasHostingScrollView: UIScrollView {
    var onLayoutSubviews: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews?()
    }
}
