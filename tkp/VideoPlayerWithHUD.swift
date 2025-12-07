import SwiftUI
import AVKit
import Combine

struct VideoPlayerWithHUD: View {
    let urlString: String
    @StateObject private var vm = VideoPlayerHUDViewModel()

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            if let player = vm.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { vm.playIfNeeded() }
                    .onDisappear { vm.pause() }
                    .gesture(LongPressGesture(minimumDuration: 0.25).onEnded { _ in vm.togglePause() })
            } else if vm.isLoading {
                VStack { ProgressView(vm.progress) { Text("加载中") } .progressViewStyle(LinearProgressViewStyle()) }
            } else if let err = vm.error {
                VStack { Text("加载失败: \(err.localizedDescription)") Button("重试") { vm.retry() } }
            } else {
                ProgressView()
                    .onAppear { vm.prepare(urlString: urlString) }
            }

            VStack {
                HStack {
                    Spacer()
                    Text(vm.durationText)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                Spacer()
                VideoControlsView(isPlaying: vm.isPlaying, onPlayPause: { vm.togglePause() }, progress: vm.playerProgress) 
                    .padding()
            }
        }
    }
}

struct VideoControlsView: View {
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let progress: Double

    var body: some View {
        HStack {
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .padding(8)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 10)
        }
    }
}

class VideoPlayerHUDViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = false
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var error: Error?
    @Published var playerProgress: Double = 0
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var urlStringSaved: String?

    var durationText: String {
        guard let t = player?.currentItem?.duration.seconds, t.isFinite else { return "--:--" }
        let current = player?.currentTime().seconds ?? 0
        return String(format: "%02d:%02d / %02d:%02d", Int(current)/60, Int(current)%60, Int(t)/60, Int(t)%60)
    }

    func prepare(urlString: String) {
        urlStringSaved = urlString
        Task { await load(urlString: urlString) }
    }

    private func load(urlString: String) async {
        await MainActor.run { isLoading = true; error = nil }
        do {
            if let local = await VideoCacheManager.shared.localURL(for: urlString) {
                await MainActor.run {
                    self.player = AVPlayer(url: local)
                    self.addObservers()
                    self.player?.play()
                    self.isPlaying = true
                    self.isLoading = false
                }
            } else if let url = URL(string: urlString) {
                let (data, response) = try await URLSession.shared.data(from: url)
                // write temp file
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try data.write(to: tmp, options: .atomic)
                await MainActor.run {
                    self.player = AVPlayer(url: tmp)
                    self.addObservers()
                    self.player?.play()
                    self.isPlaying = true
                    self.isLoading = false
                }
                Task { await VideoCacheManager.shared.cache(url: url) }
            }
        } catch {
            await MainActor.run { self.error = error; self.isLoading = false }
        }
    }

    func retry() { if let u = urlStringSaved { Task { await load(urlString: u) } } }

    func playIfNeeded() { player?.play(); isPlaying = true }
    func pause() { player?.pause(); isPlaying = false }
    func togglePause() { if isPlaying { pause() } else { playIfNeeded() } }

    var playerProgressPublisher: AnyPublisher<Double, Never> {
        Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().map { [weak self] _ in
            guard let self = self, let current = self.player?.currentTime().seconds, let dur = self.player?.currentItem?.duration.seconds, dur.isFinite else { return 0.0 }
            return current / dur
        }.eraseToAnyPublisher()
    }

    private func addObservers() {
        _ = player?.currentItem?.publisher(for: \ .status)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] t in
            guard let self = self, let dur = self.player?.currentItem?.duration.seconds, dur.isFinite else { return }
            let cur = self.player?.currentTime().seconds ?? 0
            self.playerProgress = cur / dur
            self.objectWillChange.send()
        }
    }
}
