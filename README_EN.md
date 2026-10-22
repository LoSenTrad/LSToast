# LSToast

[中文](README.md) · [Installation details](docs/installation.md) · [Isolation design](docs/architecture.md) · [1.0.0 validation](docs/validation.md)

UIKit toast messages built on [LSTPopView](https://github.com/LoSenTrad/LSTPopView). Showing, replacing, or dismissing a toast operates on its own popup instance, preserving your application's dialogs, waiting queues, and input focus.

```swift
import LSToast

LSToast.show("Saved", in: view)
```

![LSToast running in the demo app](docs/images/demo.gif)

The [demo app](Examples/LSToastDemo) demonstrates coexistence with business popups, queued popups, input focus, replacement, and positioning.

| Example | Purpose |
| --- | --- |
| [SPM demo](Examples/LSToastDemo) | Open directly; only the LSToast product is selected |
| [CocoaPods demo](Examples/CocoaPods) | Install transitive dependencies with `pod install` |
| [Carthage demo](Examples/Carthage) | Link and embed the two dynamic XCFrameworks |
| [Quick-start code](Examples/QuickStart.swift) | Copy into your view controller |

## Features

- Two-second default lifetime; top, center, and bottom positions; multiline text.
- Independent state for each business window. A newer toast replaces the previous toast in that window.
- Every touch passes through, including touches inside the text area.
- No extra `UIWindow`, key-window changes, or `endEditing` calls.
- No global popup-removal calls. Each dismissal targets the saved toast instance.
- Weak, presentation-specific handles. Old handles and timers cannot dismiss a newer toast.
- Dynamic Type and safe-area layout.
- CocoaPods, Swift Package Manager, and Carthage automatically fetch LSTPopView as a **separate dependency**.

## Requirements

| Distribution | Minimum OS | Compiler / tools | Automatically installed popup dependency |
| --- | --- | --- | --- |
| CocoaPods | iOS 15 | Swift 5.9 or newer | Objective-C `LSTPopView ~> 0.3.10` and its `LSTTimer` dependency |
| Swift Package Manager | iOS 15 | Swift 6.2 / Xcode 26 or newer | The native Swift `LSTPopViewSwift` product, pinned to version [`1.0.0-lstoast.1`](https://github.com/LoSenTrad/LSTPopView/releases/tag/1.0.0-lstoast.1) (commit `a6099ec`) |
| Carthage | iOS 15 | Swift 6.2 / Xcode 26 or newer; Carthage 0.38+ | The separate `LSTPopViewSwift` dynamic framework at the same pinned revision |

LSToast's public API is the same for all three distributions. The popup module name and API differ by distribution; see [using the popup library directly](docs/installation.md#直接使用-lstpopview). Do not integrate the same LSToast target with more than one dependency manager.

## Installation

### CocoaPods

Add only LSToast to your `Podfile`:

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'LSToast', '~> 1.0'
end

post_install do |installer|
  minimum = Gem::Version.new('15.0')

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      current = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      next unless current.to_s.match?(/\A\d+(?:\.\d+)*\z/)
      next unless Gem::Version.new(current) < minimum

      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
```

The legacy popup dependency declares an older deployment target. With newer toolchains such as Xcode 27, the `post_install` block above raises Pod targets below iOS 15 to 15. It only adjusts the consumer project's build settings; upstream sources and versions remain unchanged. If your Podfile already has a `post_install` callback, merge the loop into it.

Run `pod install` and open the generated `.xcworkspace`. The podspec resolves `LSTPopView` and `LSTTimer`; you do not need to declare either separately.

**Version 1.0.0 is published in the CocoaPods public Specs repository; the version declaration above is ready to use.** Query `pod trunk info LSToast` for the publication record, or inspect the [public podspec](https://github.com/CocoaPods/Specs/blob/master/Specs/1/f/d/LSToast/1.0.0/LSToast.podspec.json).

To install directly from the Git tag instead, replace the Pod declaration with:

```ruby
pod 'LSToast', :git => 'https://github.com/LoSenTrad/LSToast.git', :tag => '1.0.0'
```

See the [1.0.0 validation record](docs/validation.md) for publication evidence and verification boundaries.

### Swift Package Manager

In Xcode, choose **File → Add Package Dependencies…** and enter:

```text
https://github.com/LoSenTrad/LSToast.git
```

Select a version starting at `1.0.0` and add only the `LSToast` product to your app target. Xcode automatically resolves the upstream LSTPopView package and its `LSTPopViewSwift` product. The SPM product uses static linkage and includes transitive dependency symbols: your app can directly `import LSTPopViewSwift` without adding or embedding that product again in the same app target.

For a Swift package, declare:

```swift
.package(url: "https://github.com/LoSenTrad/LSToast.git", from: "1.0.0")
```

Then add this dependency to your target:

```swift
.product(name: "LSToast", package: "LSToast")
```

### Carthage

Add this to your `Cartfile`:

```text
github "LoSenTrad/LSToast" ~> 1.0
```

Run:

```sh
carthage update --use-xcframeworks --platform iOS
```

Carthage follows the repository's `Cartfile` to fetch and build the upstream popup dependency. Add **both `LSToast.xcframework` and `LSTPopViewSwift.xcframework`** from `Carthage/Build` to your app target's **Frameworks, Libraries, and Embedded Content** and select **Embed & Sign** for both. Carthage does not edit your app project; embedding only LSToast leaves its runtime dependency missing. See the [official XCFramework integration guide](https://github.com/Carthage/Carthage#building-platform-independent-xcframeworks-xcode-12-and-above).

## Usage

All APIs are isolated to `MainActor`. UIKit interaction handlers can call them directly:

```swift
import UIKit
import LSToast

final class ProfileViewController: UIViewController {
    func didSave() {
        LSToast.show("Saved", in: view)
    }

    func showNetworkMessage() {
        LSToast.show("Network unavailable. Please try again.", in: view,
                    duration: 3, position: .bottom)
    }

    func dismissMessage() {
        LSToast.hide(in: view, animated: true)
    }
}
```

Hop to the main actor when calling from other tasks:

```swift
await MainActor.run {
    LSToast.show("Sync complete", in: view)
}
```

### Dismiss a particular presentation

```swift
let first = LSToast.show("First", in: view, duration: 5)
let second = LSToast.show("Second", in: view, duration: 5)

first?.hide()          // Refers only to the first toast; cannot close the second.
print(second?.isVisible == true)
second?.hide(animated: false)
```

`LSToast.hide(in:)` dismisses the current toast in the selected window. `handle.hide()` dismisses only that handle's presentation. Handles weakly reference the presenter and identify a particular request; you do not need to store a handle for automatic dismissal.

### Position and window selection

```swift
LSToast.show("Top", in: view, position: .top)
LSToast.show("Center", in: view, position: .center)
LSToast.show("Bottom", in: view, position: .bottom)
```

Pass the current page's view after it belongs to a window, or pass that page's `UIWindow`. Explicit window selection is recommended for multiple scenes. Omitting `in:` attempts to find an active key window; it cannot infer the intended business window when several are active.

`show` returns `nil` for whitespace-only text or when there is no usable visible window. Nonpositive, NaN, or infinite durations fall back to two seconds. Toasts are for brief messages; do not use an extremely long duration as a loading overlay.

## Popup isolation

LSToast creates its own transparent parent view in each business window. All presentation, replacement, timeout, and manual-dismissal paths operate on the popup instance it holds. It does not call `removeAllPopView`, `removeLastPopView`, or take over your business popup queue.

The popup library is installed separately and remains available to your app. Toasts remain visible to that library's global manager: application calls to `removeAllPopView` or `removeLastPopView` may remove a toast as well. LSToast does not intercept application-owned manager calls. See the [design notes](docs/architecture.md).

Toasts contain no interactive controls and do not automatically move accessibility focus. For messages requiring confirmation, longer reading, or guaranteed spoken delivery, provide an appropriate in-page state or accessible interaction.

## Demo and tests

```sh
git clone https://github.com/LoSenTrad/LSToast.git
cd LSToast
open Examples/LSToastDemo/LSToastDemo.xcodeproj
```

Select the **LSToastDemo** scheme and an iPhone simulator. The demo references the root LSToast package locally; SPM resolves the upstream popup package automatically. No `pod install` is needed for this demo.

The hosted test target requires **iOS 16** for Swift Testing / ContinuousClock; the library and demo app still support iOS 15. Run the tests on macOS with a supported Xcode:

```sh
./scripts/test-demo.sh
```

Or inspect devices with `xcrun simctl list devices available`, then choose an available iOS 16+ simulator explicitly:

```sh
SIMULATOR_UDID=YOUR_SIMULATOR_UDID OUTPUT_DIR=/tmp/LSToast-check ./scripts/test-demo.sh
```

Tests focus on queue isolation, touch routing, input focus, window ownership, replacement, old handles, and timed release. The CI configuration describes the checks; consult the Actions run and `.xcresult` for evidence about a particular commit.

## Contributing and license

When reporting an issue, include the dependency manager, Xcode / Swift / iOS versions, and a minimal reproduction. See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

LSToast is available under the [MIT License](LICENSE). LSTPopView and its dependencies retain their own licenses and copyright notices; see [NOTICE](NOTICE).
