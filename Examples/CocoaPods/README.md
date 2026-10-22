# CocoaPods consumer demo

Run `pod install` in this directory, then open `LSToastDemo.xcworkspace`. Only the local `LSToast` pod is declared; CocoaPods automatically installs the independent native `LSTPopViewSwift 0.1.0` dependency. The app directly imports `LSTPopViewSwift` for its business popup and waiting queue, using the same module as the SPM and Carthage examples.

Use Xcode 26 or later with the Swift 6.2 compiler or later. The library and app deploy to iOS 15; hosted Swift Testing cases require an iOS 16 or later simulator. App sources and hosted tests are shared with the main demo.

The demo is LSToast 2.0 and retains the same controls, accessibility identifiers and approximately 18-second playback sequence as the main demo. See [the main demo instructions](../LSToastDemo/README.md) for controls and test guidance.
