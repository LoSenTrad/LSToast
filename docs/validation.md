# 1.0.0 validation

Validated on 22 October 2026 with Xcode 27.1 (27A9275), macOS 27.0, and an arm64 iPhone 17 simulator running iOS 27.0. These are simulator results; physical-device execution and developer/distribution signing were not tested.

## Consumer results

| Integration | Actual consumer | Result |
| --- | --- | --- |
| Swift Package Manager | [SPM example](../Examples/LSToastDemo), selecting only the LSToast static product | 11 tests passed; 16 executions including parameterized cases |
| CocoaPods 1.17.0 | [CocoaPods example](../Examples/CocoaPods), declaring only LSToast | 11 tests passed; 16 executions including parameterized cases |
| Carthage 0.40.0 | [Carthage example](../Examples/Carthage), linking and embedding both dynamic frameworks | 11 tests passed; 16 executions including parameterized cases |

Both App backends directly import and use the automatically fetched popup module. CocoaPods resolved LSTPopView 0.3.10 and LSTTimer 0.2.10. SPM pins semantic version `1.0.0-lstoast.1`; Carthage pins the same upstream source revision `a6099ecf24177f264dccc617043dc5d505482a21`. A versioned Swift package must use semantic-version dependencies rather than revision-only requirements.

The hosted tests exercise real UIKit windows and popup instances: business popup/waiting queue isolation, hit testing through the toast text and background, `UITextField.isFirstResponder`, key-window preservation, replacement, old handles and timers, independent windows, external removal, invalid input, safe-area layout, and release of presentation objects after expiry. All three test runs had zero failures and zero skipped tests. This is the same test suite exercised through three integration paths, not 33 distinct test definitions.

A clean Carthage source build produced `LSToast.xcframework` and `LSTPopViewSwift.xcframework`, each with `ios-arm64` and `ios-arm64_x86_64-simulator` slices. The downstream Carthage App launched these actual dynamic frameworks during its hosted tests. Building a device slice does not establish physical-device execution or distribution signing.

Reproduce the SPM run with `scripts/test-demo.sh`. For the other consumers, follow their READMEs, then run the shared `LSToastDemo` scheme's tests on an iOS 16+ simulator with a fresh result directory. The library and Demo App declare iOS 15 support; runtime tests on iOS 15 and older supported toolchains have not been performed.

## CocoaPods publication boundary

The Git-tag installation is the supported initial distribution path. Version 1.0.0 has not been published to the CocoaPods Trunk public index; the release machine has no authenticated Trunk session. The shorthand `pod 'LSToast', '~> 1.0'` must wait for an actual Trunk publication.

Strict local `pod lib lint`, with the documented iOS 15 deployment-floor override, compiled successfully (`BUILD SUCCEEDED`) but exited 1 because this machine could not validate the GitHub homepage URL. The warning was retained, and `--allow-warnings` was not used. The complete CocoaPods consumer's build and hosted tests passed independently. CI includes strict lint; a checked-in workflow is not evidence of a successful Actions run.

## Demo media and remaining boundaries

The [README GIF](images/demo.gif) is approximately 20 seconds of real simulator capture, reduced to 360 pixels wide at 5 frames per second. It shows positions, a business popup coexisting with a toast, toast dismissal while the business popup stays visible, and the waiting popup appearing after the business popup is closed. The autoplay sets synthetic input text; input-focus preservation is established by the hosted first-responder test, not by the GIF alone.

Manual VoiceOver behavior, the full Dynamic Type matrix, runtime rotation/scene transitions, an already-visible keyboard before the first bottom toast, and physical devices remain outside this release's verified runtime scope. See [architecture](architecture.md) for the popup manager and keyboard boundaries.
