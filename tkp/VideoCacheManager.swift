import Foundation

actor VideoCacheManager {
    static let shared = VideoCacheManager()
    private let cacheDir: URL

    init() {
        let fm = FileManager.default
        cacheDir = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("tkp_videos")
        try? fm.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func localURL(for urlString: String) async -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        let file = cacheDir.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: file.path) {
            return file
        }
        return nil
    }

    func cache(url: URL) async {
        let filename = url.lastPathComponent
        let file = cacheDir.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: file.path) { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: file, options: .atomic)
        } catch {
            // ignore
        }
    }
}
