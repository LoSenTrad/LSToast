# Release checklist

This document describes the maintainer process. A checked-in manifest or CI workflow is not evidence that a version has been published.

## Prepare the native Swift dependency

1. Verify that the upstream native Swift snapshot is remotely available in [LoSenTrad/LSTPopView](https://github.com/LoSenTrad/LSTPopView). LSToast 2.0 uses commit `a6099ecf24177f264dccc617043dc5d505482a21` through all three package managers.
2. Publish and verify the independent CocoaPods specification `LSTPopViewSwift 0.1.0`, whose source is the upstream `swift-0.1.0` tag. The native Pod is distinct from the legacy Objective-C `LSTPopView` Pod. Do not change or republish old version specifications.
3. Confirm that the SPM semantic version `1.0.0-lstoast.1` and Carthage revision point to that same native source. A versioned Swift package must use a semantic-version dependency rather than a revision-only requirement.
4. Install `LSTPopViewSwift` from the public index in a fresh consumer before publishing LSToast's dependent CocoaPods version. Record source, compiler, deployment-target, and license checks.

## Prepare a source release

1. Review the exact release commit and confirm no application-private code, credentials, customer data, local paths, or build logs are included.
2. Keep the public module and type name `LSToast`, podspec version `2.0.0`, Git tag `2.0.0`, and changelog aligned. The major version records the CocoaPods module/backend and compiler-requirement change; keep existing `1.0.0` tags and specifications intact.
3. Resolve the declared upstream dependency from a clean checkout. Verify the referenced upstream tags and revision exist remotely before publishing the downstream tag. Inspect the complete dependency graph: LSToast 2.0 must transitively require `LSTPopViewSwift`, with no legacy `LSTPopView` or `LSTTimer` introduced by LSToast.
4. Run `python3 scripts/check-docs.py` and `git diff --check`. Check the real demo GIF and all local documentation links.
5. Run `scripts/test-demo.sh` with Swift 6.2+ / Xcode 26+ and an available iOS 16+ iPhone simulator (the library and demo app still support iOS 15). Retain the exact source SHA, command, exit code, test count, and `.xcresult` outside the source repository.
6. Run `pod lib lint LSToast.podspec --platforms=ios --verbose` and build a clean consumer that imports both `LSToast` and `LSTPopViewSwift`. Both native Pods declare iOS 15; the 1.0 legacy target-floor workaround is no longer part of this integration. Keep lint strict; report network validation warnings or upstream problems with their actual evidence rather than weakening the check.
7. Run hosted isolation tests through the CocoaPods consumer, using a new output directory. Merely resolving a podspec does not verify the runtime module, queue behavior, or lifecycle.
8. Run a clean Carthage consumer build using `--use-xcframeworks --platform iOS`; embed both `LSToast.xcframework` and `LSTPopViewSwift.xcframework` and run the consumer's hosted tests. Check device and simulator slices independently of actual runtime claims.
9. Record the actual tested Xcode, Swift, simulator/device, integrations, and unverified scopes in [validation.md](validation.md). Preserve [the 1.0.0 record](validation-1.0.0.md) as history; its results do not establish 2.0.0 readiness. Do not report simulator results as physical-device results.

## Publish source and package releases

Publishing the repository, pushing a version tag, creating a GitHub Release, and publishing to the CocoaPods index are separate actions. Complete each only within the maintainer's authorized release scope.

- The `2.0.0` Git tag enables the documented Git-tag CocoaPods, SPM, and Carthage installation paths once it is remotely available. Git-tag CocoaPods installation still requires the independently published `LSTPopViewSwift` specification.
- The public CocoaPods shorthand `pod 'LSToast', '~> 2.0'` requires the matching specification to be accepted by Trunk. Verify `pod trunk info LSToast`, the public Specs entry, and a fresh public-index consumer after publication.
- `pod lib lint` / `pod spec lint` validates a specification; neither command publishes it.
- A successful GitHub upload does not prove that a clean downstream consumer resolves, builds, or launches. Check a remote SPM version consumer and Carthage version resolution as well.
- Update the README and validation publication status only when those independent checks confirm it. Record any unsuccessful command and its actual limitation without presenting it as a pass.

Keep publication tokens in the appropriate secret store. Do not commit them or copy private local build logs into a public Release.

## Demo media

Keep `docs/images/demo.gif` small enough for a README and record it from the real sample app. Demonstrate toast appearance, disappearance, and replacement while an existing business popup stays in place. If the demo or UI changes, check that the GIF still represents the shipped example. State the capture version when reusing an earlier recording; a recording is not a substitute for the new version's runtime tests.
