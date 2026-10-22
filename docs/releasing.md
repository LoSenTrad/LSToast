# Release checklist

This document describes the maintainer process. A checked-in manifest or CI workflow is not evidence that a version has been published.

## Prepare a source release

1. Review the exact release commit and confirm no application-private code, credentials, customer data, local paths, or build logs are included.
2. Keep the public module and type name `LSToast`, the podspec version, Git tag, and changelog aligned.
3. Resolve the declared upstream dependency from a clean checkout. Verify the referenced upstream tag or revision exists remotely before publishing the downstream tag.
4. Run `python3 scripts/check-docs.py` and `git diff --check`. Check the real demo GIF and all local documentation links.
5. Run `scripts/test-demo.sh` with a supported Xcode and an available iOS 16+ iPhone simulator (the library and demo app still support iOS 15). Retain the exact source SHA, command, exit code, test count, and `.xcresult` outside the source repository.
6. Run `XCODE_XCCONFIG_FILE="$PWD/Tools/iOS15.xcconfig" pod lib lint LSToast.podspec --platforms=ios --verbose` and build a consumer that imports both `LSToast` and `LSTPopView`. The xcconfig supplies the supported iOS 15 floor for historical Pod targets during lint. The consumer must include the documented `post_install` floor adjustment. Keep lint strict; report network validation warnings or upstream problems with their actual evidence rather than weakening the check. A dependency resolved on one developer's machine is not a clean consumer installation.
7. Run a clean Carthage consumer build using `--use-xcframeworks --platform iOS`; embed both `LSToast.xcframework` and `LSTPopViewSwift.xcframework` and check the app launches.
8. Record the actual tested Xcode, Swift, simulator/device, backends, and unverified scopes. Do not report simulator results as physical-device results.

## Publish source and package releases

Publishing the repository, pushing a version tag, creating a GitHub Release, and publishing to the CocoaPods index are separate actions. Complete each only within the maintainer's authorized release scope.

- The `1.0.0` Git tag enables the documented Git-tag CocoaPods, SPM, and Carthage installation paths once that tag is remotely available.
- The public CocoaPods shorthand `pod 'LSToast', '~> 1.0'` requires the matching specification to be accepted by Trunk. Verify the public index after publication.
- `pod lib lint` / `pod spec lint` validates a specification; neither command publishes it.
- A successful GitHub upload does not prove that a clean downstream consumer resolves or launches.

Keep publication tokens in the appropriate secret store. Do not commit them or copy private local build logs into a public Release.

## Demo media

Keep `docs/images/demo.gif` small enough for a README and record it from the real sample app. Demonstrate toast appearance, disappearance, and replacement while an existing business popup stays in place. If the demo or UI changes, check that the GIF still represents the shipped example.
