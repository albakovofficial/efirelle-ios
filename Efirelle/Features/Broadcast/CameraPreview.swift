import HaishinKit
import SwiftUI

/// Картинка с камеры во весь экран — то, что видят зрители.
struct CameraPreview: UIViewRepresentable {
    let session: BroadcastSession

    func makeUIView(context: Context) -> MTHKView {
        let view = MTHKView(frame: .zero)
        view.videoGravity = .resizeAspectFill
        session.attach(view)
        return view
    }

    func updateUIView(_ uiView: MTHKView, context: Context) {}
}
