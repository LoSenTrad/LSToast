# 2.0.0 validation

LSToast 2.0.0 unifies CocoaPods, SPM, and Carthage on the native Swift `LSTPopViewSwift` engine. This record is being prepared for that release. **The 2.0.0 checks and publication entries below are pending; the passing 1.0.0 results do not establish a pass for 2.0.0.** Historical evidence is preserved in [validation-1.0.0.md](validation-1.0.0.md).

## Dependency identity

| Integration | Required native dependency | Expected upstream source |
| --- | --- | --- |
| CocoaPods | `LSTPopViewSwift ~> 0.1.0`, source tag `swift-0.1.0` | `a6099ecf24177f264dccc617043dc5d505482a21` |
| Swift Package Manager | `LSTPopViewSwift` product at exact semantic version `1.0.0-lstoast.1` | Same commit |
| Carthage | `LSTPopViewSwift` framework at the pinned revision | Same commit |

All integrations require an iOS 15+ deployment target and a Swift 6.2+ compiler / Xcode 26+. LSToast uses Swift 5 language mode, and the native dependency uses Swift 6 language mode. LSToast 2.0 must not introduce the legacy Objective-C `LSTPopView` or `LSTTimer` transitively. An application may separately declare an old engine for its own business code; that does not change LSToast's selected engine.

## Consumer results

| Check | Actual result |
| --- | --- |
| Release source commit and production source hash | PENDING |
| Runtime environment: Xcode / Swift / OS / simulator or device | PENDING |
| SPM hosted isolation tests through the local demo | PENDING |
| CocoaPods native consumer installation and hosted tests | PENDING |
| Carthage clean framework build and consumer hosted tests | PENDING |
| Native dependency public-index installation | PENDING |
| Strict CocoaPods lint | PENDING |
| Remote 2.0.0 SPM version installation and hosted tests | PENDING |
| Remote 2.0.0 CocoaPods Git-tag installation | PENDING |
| Remote 2.0.0 Carthage dependency resolution | PENDING |

The suite covers real UIKit windows and popup instances: business popup/waiting queue isolation, hit testing through the toast, input focus, key-window preservation, replacement, old handles and timers, independent windows, external removal, invalid input, safe-area layout, and release after expiry. The actual definition/execution counts, failures, skipped tests, commands, and result bundles must be filled from the new runs; no count is inferred from the prior release.

Reproduce the SPM run with `scripts/test-demo.sh`. For CocoaPods and Carthage, follow the corresponding example README and run the shared `LSToastDemo` scheme on an available iOS 16+ simulator with a fresh result directory. Hosted tests need iOS 16 for Swift Testing / ContinuousClock; the library and Demo App declare iOS 15 support.

## Publication status

| Publication or downstream check | Actual result |
| --- | --- |
| Upstream `LSTPopViewSwift 0.1.0` public Specs entry | PENDING |
| LSToast remote `2.0.0` tag and GitHub Release | PENDING |
| LSToast `2.0.0` public Specs entry | PENDING |
| Fresh CocoaPods public-index installation and consumer build | PENDING |
| GitHub Actions for the release commit | PENDING |
| XCFramework assets, slices, and checksums | PENDING |

GitHub publication, public-index publication, successful installation, compilation, hosted tests, device execution, and signing are separate claims. Existing 1.0.0 source tags and CocoaPods specifications remain intact.

## Demo media and runtime boundaries

The [README GIF](images/demo.gif) was recorded from the real SPM demo for 1.0.0, which already used the native Swift engine. It is approximately 20 seconds, 360 pixels wide at 5 frames per second. It shows toast positioning, a business popup coexisting with a toast, toast dismissal while that popup stays visible, and a waiting popup appearing afterward. The 2.0.0 release must confirm that the recording still represents the shipped example or replace it.

The autoplay sets synthetic input text; it does not establish first-responder preservation. That behavior requires the new hosted first-responder test. Physical-device execution, distribution signing, manual VoiceOver behavior, the full Dynamic Type matrix, runtime rotation/scene transitions, and an already-visible keyboard before the first bottom toast remain unverified unless an explicit result is added here. See [architecture](architecture.md) for manager and keyboard boundaries.
