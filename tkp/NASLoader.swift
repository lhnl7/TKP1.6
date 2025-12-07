import Foundation

@MainActor class NASLoader: ObservableObject {
    @Published var videos: [String] = []

    func load(from urlString: String?) {
        guard let urlString = urlString, let base = URL(string: urlString) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: base)
                if let arr = try? JSONSerialization.jsonObject(with: data) as? [String] {
                    self.videos = arr.map { URL(string: $0, relativeTo: base)?.absoluteString ?? $0 }
                    return
                }
                if let html = String(data: data, encoding: .utf8) {
                    var results: [String] = []
                    let pattern = "<a[^>]*href=\\\"([^\\\"]+)\\\""
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                        let ns = NSString(string: html)
                        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: ns.length))
                        for m in matches {
                            if m.numberOfRanges > 1 {
                                let r = m.range(at: 1)
                                let s = ns.substring(with: r)
                                if s.lowercased().hasSuffix(".mp4") || s.lowercased().hasSuffix(".mov") {
                                    let absolute = URL(string: s, relativeTo: base)?.absoluteString ?? s
                                    results.append(absolute)
                                }
                            }
                        }
                    }
                    self.videos = results
                }
            } catch {
                self.videos = []
            }
        }
    }
}
