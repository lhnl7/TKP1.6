import UIKit
import AVKit

class PlayerViewController: UIViewController, UIScrollViewDelegate {

    private var scrollView = UIScrollView()
    private var players: [AVPlayerLayer] = []
    private var videoURLs: [URL] = []

    private var currentIndex: Int = 0
    var onIndexChanged: ((Int) -> Void)?

    init(videoURLs: [URL]) {
        self.videoURLs = videoURLs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        loadPlayers()
    }

    func updateVideoList(_ urls: [URL]) {
        if urls.count != videoURLs.count {
            videoURLs = urls
            reloadPlayers()
        }
    }

    // MARK: - Scroll View
    private func setupScrollView() {
        scrollView.frame = view.bounds
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)
    }

    // MARK: - Load Players
    private func loadPlayers() {
        scrollView.contentSize = CGSize(width: view.frame.width,
                                        height: view.frame.height * CGFloat(videoURLs.count))

        players.removeAll()

        for (i, url) in videoURLs.enumerated() {
            let player = AVPlayer(url: url)
            let layer = AVPlayerLayer(player: player)
            layer.frame = CGRect(x: 0,
                                 y: view.frame.height * CGFloat(i),
                                 width: view.frame.width,
                                 height: view.frame.height)
            layer.videoGravity = .resizeAspectFill
            scrollView.layer.addSublayer(layer)
            players.append(layer)
        }

        play(index: 0)
    }

    private func reloadPlayers() {
        scrollView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        loadPlayers()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.y / scrollView.frame.height)
        if page != currentIndex {
            currentIndex = page
            onIndexChanged?(page)
            play(index: page)
            preload(index: page + 1)
        }
    }

    // MARK: - Video Controls
    private func play(index: Int) {
        players.enumerated().forEach { i, layer in
            if i == index {
                layer.player?.seek(to: .zero)
                layer.player?.play()
            } else {
                layer.player?.pause()
            }
        }
    }

    private func preload(index: Int) {
        guard index < players.count else { return }
        players[index].player?.currentItem?.preferredForwardBufferDuration = 5
    }
}
