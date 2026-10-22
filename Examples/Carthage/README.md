# Carthage consumer demo

From the repository root run `carthage bootstrap --use-xcframeworks --platform iOS --no-use-binaries`, then `carthage build --no-skip-current --use-xcframeworks --platform iOS --no-use-binaries`. Open `LSToastDemo.xcodeproj` in this directory. It links and embeds both `LSToast.xcframework` and the independent native `LSTPopViewSwift.xcframework` from the root `Carthage/Build` directory. The app directly imports `LSTPopViewSwift` for business popups and the waiting queue.

Use Xcode 26 or later with the Swift 6.2 compiler or later. The library and app deploy to iOS 15; hosted Swift Testing cases require an iOS 16 or later simulator. Demo app sources and hosted tests are shared with the main SPM demo; no Swift package is added to this consumer target.

The demo is LSToast 2.0 and retains the same controls, accessibility identifiers and approximately 18-second playback sequence as the main demo. See [the main demo instructions](../LSToastDemo/README.md) for controls and test guidance.
