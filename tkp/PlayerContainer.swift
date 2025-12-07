import SwiftUI
import AVKit

struct PlayerContainer: UIViewControllerRepresentable {
    let videoURLs: [URL]
    @Binding var currentIndex: Int

    func makeUIViewController(context: Context) -> PlayerViewController {
        let vc = PlayerViewController(videoURLs: videoURLs)
        vc.onIndexChanged = { index in
            DispatchQueue.main.async {
                self.currentIndex = index
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: PlayerViewController, context: Context) {
        uiViewController.updateVideoList(videoURLs)
    }
}
