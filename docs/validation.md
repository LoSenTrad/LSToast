# 2.0.0 validation

LSToast 2.0.0 unifies CocoaPods, SPM, and Carthage on the native Swift `LSTPopViewSwift` engine. The confirmed results below were collected for the 2.0.0 release candidate on 22 October 2026. Remaining checks and downstream publication are explicitly marked pending. Historical 1.0.0 evidence is preserved in [validation-1.0.0.md](validation-1.0.0.md); none of its test passes are carried forward as 2.0.0 results.

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
| Audited release candidate | `7836cf7d4d5a69526e536fcb8e2db4304ff43bbf`; final release tag commit PENDING |
| Production `Sources/LSToast/LSToast.swift` SHA-256 | `4df155f04f4fa49d2171effc97781f03c32db5752bdb019ac3cfa2f1dc69c199` |
| Runtime environment | Xcode 27.1 (27A9275), Swift 6.4, macOS 27.0; arm64 iPhone 17 simulator, iOS 27.0 (24A434) |
| SPM hosted isolation tests through the local demo | Passed: 11 test definitions, 16 executions including parameterized cases; 0 failures and 0 skipped |
| CocoaPods native consumer installation and hosted tests | Passed through the normal public index: 11 test definitions, 16 expanded executions; 0 failures and 0 skipped |
| Carthage clean framework build and consumer hosted tests | Passed: 11 test definitions, 16 executions including parameterized cases; 0 failures and 0 skipped |
| Native dependency public-index installation | Passed; the Demo Podfile declares only LSToast, and its lock contains LSToast 2.0.0 and LSTPopViewSwift 0.1.0 |
| Strict CocoaPods lint with the published native dependency supplied using `--external-podspecs` | Passed, exit 0; no warning allowance, skipped checks, or deployment-floor override |
| Strict CocoaPods lint through the normal public index | Passed, exit 0, after the official CDN version directory propagated; no overrides or weakened checks |
| Remote 2.0.0 SPM version installation and hosted tests | PENDING |
| Remote 2.0.0 CocoaPods Git-tag installation | PENDING |
| Remote 2.0.0 Carthage dependency resolution | PENDING |

The SPM, CocoaPods, and Carthage result bundles each report 11 test definitions and 16 executions after expanding the dynamic parameters, with no failures, skips, expected failures, or runtime warnings. They exercise the same suite through separate integrations, not 33 unique test definitions. The suite covers real UIKit windows and popup instances: business popup/waiting queue isolation, hit testing through the toast, input focus, key-window preservation, replacement, old handles and timers, independent windows, external removal, invalid input, safe-area layout, and release after expiry.

The Carthage source build produced both dynamic XCFrameworks with `ios-arm64` and `ios-arm64_x86_64-simulator` slices. The LSToast framework links `LSTPopViewSwift`; its production source hash matches the audited candidate above. Those actual frameworks were used by the Carthage consumer tests. A device slice does not establish physical-device execution or distribution signing.

The external-podspec lint downloaded the public native source tag and passed strict validation. It does not prove ordinary public-index resolution. The first ordinary-index attempt was blocked by the newly published Pod version directory propagating through the CDN; the final normal-index lint and hosted tests subsequently passed independently. No `--allow-warnings`, `--skip-import-validation`, or iOS target-floor workaround was used.

Reproduce the SPM run with `scripts/test-demo.sh`. For CocoaPods and Carthage, follow the corresponding example README and run the shared `LSToastDemo` scheme on an available iOS 16+ simulator with a fresh result directory. Hosted tests need iOS 16 for Swift Testing / ContinuousClock; the library and Demo App declare iOS 15 support.

## Publication status

| Publication or downstream check | Actual result |
| --- | --- |
| Upstream `LSTPopViewSwift 0.1.0` public Specs entry | Published; Trunk query, public Specs JSON, and canonical CDN JSON verified |
| LSToast remote `2.0.0` tag and GitHub Release | PENDING |
| LSToast `2.0.0` public Specs entry | PENDING |
| Fresh CocoaPods public-index installation and consumer build | PENDING |
| GitHub Actions for the release commit | PENDING |
| XCFramework assets, slices, and checksums | PENDING |

The independent native dependency is published as [`LSTPopViewSwift 0.1.0`](https://github.com/CocoaPods/Specs/blob/master/Specs/f/0/2/LSTPopViewSwift/0.1.0/LSTPopViewSwift.podspec.json). Its public specification matches the expected native specification, has no dependencies, and references the `swift-0.1.0` source tag. The upstream Swift source hashes were checked unchanged. Trunk push initially exited 1 after a GitHub commit API timeout; independent Trunk, Specs, and CDN reads confirmed that server-side publication subsequently completed, without a duplicate upload.

GitHub publication, public-index publication, successful installation, compilation, hosted tests, device execution, and signing are separate claims. Existing 1.0.0 source tags and CocoaPods specifications remain intact.

## Demo media and runtime boundaries

The [README GIF](images/demo.gif) was recorded again from the real 2.0.0 SPM demo for this release. Its source capture completed successfully, and the clip was trimmed to approximately 20.5 seconds at 360 pixels wide and 5 frames per second. It shows toast positioning, a business popup coexisting with a toast, toast dismissal while that popup stays visible, and a waiting popup appearing afterward. It is a new runtime recording, not the prior release's GIF.

The autoplay sets synthetic input text; the GIF alone does not establish first-responder preservation. The new hosted tests exercise and verify the first-responder behavior directly. Physical-device execution, distribution signing, manual VoiceOver behavior, the full Dynamic Type matrix, runtime rotation/scene transitions, and an already-visible keyboard before the first bottom toast remain unverified unless an explicit result is added here. See [architecture](architecture.md) for manager and keyboard boundaries.
