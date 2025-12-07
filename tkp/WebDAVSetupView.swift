import SwiftUI

struct WebDAVSetupView: View {
    @Environment(\ .presentationMode) var presentationMode
    @ObservedObject var loader: NASLoader
    @State private var urlString: String = UserDefaults.standard.string(forKey: "webdav_url") ?? ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WebDAV / HTTP URL")) {
                    TextField("http://192.168.1.202:5005/ddd4", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                Section {
                    Button("保存并扫描") {
                        UserDefaults.standard.set(urlString, forKey: "webdav_url")
                        loader.load(from: urlString)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}
