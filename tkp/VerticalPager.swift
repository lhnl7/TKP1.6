import SwiftUI

struct VerticalPager<Item, Content: View>: View where Item: Hashable {
    let items: [Item]
    @Binding var currentIndex: Int
    let content: (Item) -> Content

    init(items: [Item], currentIndex: Binding<Int>, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self._currentIndex = currentIndex
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \ .offset) { idx, item in
                        content(item)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .id(idx)
                    }
                }
            }
        }
    }
}
