// The Swift Programming Language
// https://docs.swift.org/swift-book
#if os(iOS)
import UIKit

@MainActor
public protocol TabBarLongPressInteractionDelegate: AnyObject {
    func tabBarController(
        _ tbc: UITabBarController,
        didLongPress item: UITabBarItem,
        at index: Int
    )
}

@MainActor
public final class TabBarLongPressInteraction: NSObject {
    public weak var delegate: TabBarLongPressInteractionDelegate?
    public var minimumPressDuration: TimeInterval {
        didSet {
            longPress?.minimumPressDuration = minimumPressDuration
        }
    }

    private weak var controller: UITabBarController?
    private var longPress: UILongPressGestureRecognizer?
    private var onLongPress: ((_ tbc: UITabBarController, _ item: UITabBarItem, _ index: Int) -> Void)?

    public init(
        _ controller: UITabBarController,
        minimumPressDuration: TimeInterval = 0.5,
        onLongPress: ((_ tbc: UITabBarController, _ item: UITabBarItem, _ index: Int) -> Void)? = nil
    ) {
        self.controller = controller
        self.minimumPressDuration = minimumPressDuration
        self.onLongPress = onLongPress
        super.init()
        install()
    }
}

extension TabBarLongPressInteraction: UIGestureRecognizerDelegate {

    private func install() {
        guard let tabBar = controller?.tabBar else { return }
        let gr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gr.minimumPressDuration = minimumPressDuration
        gr.allowableMovement = 8
        gr.cancelsTouchesInView = false
        gr.requiresExclusiveTouchType = false
        gr.delegate = self
        tabBar.addGestureRecognizer(gr)
        self.longPress = gr
    }

    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began,
              let tbc = controller,
              let items = tbc.tabBar.items, !items.isEmpty else {
            return
        }
        guard let index = indexByGeometry(point: gr.location(in: tbc.tabBar), in: tbc.tabBar) else {
            return
        }
        let item = items[index]
        delegate?.tabBarController(tbc, didLongPress: item, at: index)
        onLongPress?(tbc, item, index)
    }
    
    private func indexByGeometry(point pt: CGPoint, in tabBar: UITabBar) -> Int? {
        guard let items = tabBar.items, !items.isEmpty else { return nil }
        let visible = items.count
        let bounds = tabBar.bounds.inset(by: tabBar.safeAreaInsets)
        guard bounds.contains(pt), bounds.width > 0 else { return nil }

        switch tabBar.itemPositioning {
        case .fill, .automatic:
            let w = max(bounds.width / CGFloat(visible), 1)
            let idx = Int(floor((pt.x - bounds.minX) / w))
            return (0..<visible).contains(idx) ? idx : nil
        case .centered:
            let itemW = (tabBar.itemWidth > 0) ? tabBar.itemWidth : bounds.width / CGFloat(visible)
            let spacing = tabBar.itemSpacing
            let total = CGFloat(visible) * itemW + CGFloat(max(visible - 1, 0)) * spacing
            let originX = bounds.midX - total / 2
            let unit = max(itemW + spacing, 1)
            let idx = Int(floor((pt.x - originX) / unit))
            return (0..<visible).contains(idx) ? idx : nil
        @unknown default:
            let w = max(bounds.width / CGFloat(visible), 1)
            let idx = Int(floor((pt.x - bounds.minX) / w))
            return (0..<visible).contains(idx) ? idx : nil
        }
    }
    private func isMoreSlot(_ index: Int, tabBar: UITabBar, totalTabs: Int) -> Bool {
        let visible = tabBar.items?.count ?? 0
        guard visible > 0 else { return false }
        let hasMore = totalTabs > visible
        return hasMore && index == visible - 1
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

#endif
