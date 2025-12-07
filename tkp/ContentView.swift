import SwiftUI

struct ContentView: View {
    @StateObject private var loader = NASLoader()
    @State private var showSettings = false
    @State private var currentIndex: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                if loader.videos.isEmpty {
                    Text("无视频 - 点击右上角选择视频")
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    VerticalPager(items: loader.videos, currentIndex: $currentIndex) { url in
                        VideoPlayerWithHUD(urlString: url)
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle("tkp")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") { showSettings = true }
                }
            }
            .sheet(isPresented: $showSettings) {
                WebDAVSetupView(loader: loader)
            }
            .onAppear {
                if let saved = UserDefaults.standard.string(forKey: "webdav_url") {
                    loader.load(from: saved)
                }
            }
        }
    }
}
