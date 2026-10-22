# CocoaPods consumer demo

Run `pod install` in this directory, then open `LSToastDemo.xcworkspace`. Only the local `LSToast` pod is declared; CocoaPods automatically installs its `LSTPopView 0.3.10` and `LSTTimer` dependencies. App sources and hosted tests are shared with the main demo. The explicit `LSTOAST_COCOAPODS` condition selects the Objective-C popup module for both the demo and tests.

The post-install floor keeps legacy dependency targets compatible with modern SDKs while preserving their source versions. The library and app deploy to iOS 15; hosted Swift Testing cases require iOS 16 or later.
