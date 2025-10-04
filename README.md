# TabBarLongPress

TabBarLongPress adds a long-press gesture recognizer to `UITabBarController`, delivering per-tab callbacks without subclassing or juggling gesture recognizer wiring yourself.

## Features
- Maps long presses to the corresponding `UITabBarItem` index and notifies both a delegate and optional closure handlers.
- Exposes gesture configuration (`minimumPressDuration`, `allowableMovement`, `cancelsTouchesInView`, `requiresExclusiveTouchType`) so you can match the feel of the rest of your app.
- Ignores the system "More" tab gracefully by handing back `nil` for the item when appropriate.
- Surfaces iOS 18 `UITab` instances when available, enabling modern tab customization APIs alongside legacy support.

## Installation
Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/lynnswap/TabBarLongPress.git", from: "1.0.0")
```

Then add `TabBarLongPress` to the target that hosts your tab bar controller.
The first public release ships as version `1.0.0`.

## Usage

```swift
import UIKit
import TabBarLongPress

final class TimelineTabBarController: UITabBarController {
    private var longPressInteraction: TabBarLongPressInteraction?

    override func viewDidLoad() {
        super.viewDidLoad()

        longPressInteraction = TabBarLongPressInteraction(
            self
        ) { [weak self] controller, item, index in
            guard let self else { return }
            self.presentContextMenu(for: item, at: index)
        }

        longPressInteraction?.delegate = self
    }

    private func presentContextMenu(for item: UITabBarItem?, at index: Int) {
        // Show quick actions for the tab...
    }
}

extension TimelineTabBarController: TabBarLongPressInteractionDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        didLongPress item: UITabBarItem?,
        at index: Int
    ) {
        // Respond to the legacy UITabBarItem callback.
    }

    @available(iOS 18.0, *)
    func tabBarController(
        _ tabBarController: UITabBarController,
        didLongPressTab tab: UITab?,
        at index: Int
    ) {
        // Use the modern UITab API when available.
    }
}
```

The initializer accepts an optional trailing closure if you prefer not to adopt the delegate protocol. Both the closure and delegate fire for each gesture, so you can mix them for lightweight and structured handling as needed.
If you want to fine-tune the gesture feel, adjust properties such as `minimumPressDuration` or `allowableMovement` on `longPressInteraction` after initialization.

## Requirements
- Swift tools 6.2 or later
- iOS 17.0 or later
- iOS 18.0 unlocks the `UITab`-backed delegate method.

## License
TabBarLongPress is available under the terms of the MIT License. See the `LICENSE` file for details.
