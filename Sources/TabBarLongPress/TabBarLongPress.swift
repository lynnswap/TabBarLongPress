// The Swift Programming Language
// https://docs.swift.org/swift-book
#if os(iOS)
import UIKit

@MainActor
@objc
public protocol TabBarLongPressInteractionDelegate: AnyObject {
    @objc optional func tabBarController(
        _ tabBarController: UITabBarController,
        didLongPressItem item: UITabBarItem?,
        at index: Int
    )
    
    @available(iOS 18.0, *)
    @objc optional func tabBarController(
        _ tabBarController: UITabBarController,
        didLongPressTab tab: UITab?,
        at index: Int
    )
}

@MainActor
public final class TabBarLongPressInteraction: NSObject {
    public typealias TabBarLongPressHandler = (
        _ tabBarController: UITabBarController,
        _ item: UITabBarItem?,
        _ index: Int
    ) -> Void

    @available(iOS 18.0, *)
    public typealias TabBarTabLongPressHandler = (
        _ tabBarController: UITabBarController,
        _ tab: UITab?,
        _ index: Int
    ) -> Void
    
    public weak var delegate: TabBarLongPressInteractionDelegate?
    public var minimumPressDuration: TimeInterval {
        didSet {
            longPress?.minimumPressDuration = minimumPressDuration
        }
    }
    public var totalTabs:Int

    private weak var controller: UITabBarController?
    private var longPress: UILongPressGestureRecognizer?
    private var onLongPress: TabBarLongPressHandler?
    private var onLongPressTabBox: Any?

    @available(iOS 18.0, *)
    private var onLongPressTab: TabBarTabLongPressHandler? {
        get { onLongPressTabBox as? TabBarTabLongPressHandler }
        set { onLongPressTabBox = newValue }
    }

    public init(
        _ controller: UITabBarController,
        minimumPressDuration: TimeInterval = 0.5,
        totalTabs: Int = 5,
        onLongPress: TabBarLongPressHandler? = nil
    ) {
        self.controller = controller
        self.minimumPressDuration = minimumPressDuration
        self.totalTabs = totalTabs
        self.onLongPress = onLongPress
        super.init()
        install()
    }

    @available(iOS 18.0, *)
    public convenience init(
        _ controller: UITabBarController,
        minimumPressDuration: TimeInterval = 0.5,
        totalTabs: Int = 5,
        onLongPress: TabBarLongPressHandler? = nil,
        onLongPressTab: TabBarTabLongPressHandler? = nil
    ) {
        self.init(
            controller,
            minimumPressDuration: minimumPressDuration,
            totalTabs: totalTabs,
            onLongPress: onLongPress
        )
        self.onLongPressTab = onLongPressTab
    }

    @available(iOS 18.0, *)
    public func setOnLongPressTab(_ handler: TabBarTabLongPressHandler?) {
        onLongPressTab = handler
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
        let visible = tbc.tabBar.items?.count ?? 0
        let isMoreByIdentity: Bool = {
            guard index == visible - 1 else { return false }
            return items[index] === tbc.moreNavigationController.tabBarItem
        }()
        
        if let delegate{
            delegate.tabBarController?(tbc, didLongPressItem: isMoreByIdentity ? nil : items[index], at: index)
            if #available(iOS 18.0, *){
                delegate.tabBarController?(tbc, didLongPressTab: isMoreByIdentity ? nil : tbc.tabs[index], at: index)
            }
        }
        onLongPress?(tbc, isMoreByIdentity ? nil : items[index], index)
        if #available(iOS 18.0, *), let onLongPressTab {
            onLongPressTab(tbc, isMoreByIdentity ? nil : tbc.tabs[index], index)
        }
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
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

#endif
