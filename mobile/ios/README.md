# SAI Browser for iPhone

The preview is a native iPhone app for iOS 16 or later. It uses SwiftUI and the system WKWebView. It opens to an empty page with address entry and back/forward navigation. WebKit uses an in-memory website data store for this preview.

## Build and archive

Use a Mac with an App Store Connect-supported release of Xcode (Xcode 26 with the iOS 26 SDK or later under the current minimum). Open `SAIBrowser.xcodeproj` and select the shared **SAIBrowser** scheme.

1. In the **SAIBrowser** target's **Signing & Capabilities**, select your existing Apple developer team. Use `org.ysai.saibrowser` if it is available to your team, or set the bundle identifier to the identifier registered for your App Store Connect app. Leave automatic signing enabled. The initial marketing version is `0.1.0` and build number is `1`. Increase the build number if that combination was already uploaded.
2. Build for an iPhone simulator and exercise the smoke checks below. The command below builds the same project for a generic simulator without signing.
3. Select **Any iOS Device (arm64)** and choose **Product → Archive**. In Organizer, validate the archive. Use **Distribute App → App Store Connect** for TestFlight and start with internal testing.

```sh
xcodebuild -project SAIBrowser.xcodeproj -scheme SAIBrowser \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

For App Store Connect, this is an unrestricted web browsing app. Review the age-rating and privacy questions against the actual build and any changes you make. The project uses system TLS for HTTPS and declares no non-exempt encryption; recheck the declaration if you add other encryption.

## Smoke checks

- Start the app and confirm a blank page and no default website. Open `example.com`; confirm HTTPS, then open a second HTTPS site and try Back and Forward.
- Confirm explicit cleartext, local addresses, and non-web schemes show a rejection. Check a site with an invalid certificate fails. Use a trusted fixture for redirects, pop-ups, downloads, and camera/microphone requests.
- Check orientation, keyboard Go, editable address behavior, and VoiceOver on a real iPhone. Relaunch and confirm the preview starts blank.

[Upload requirements](https://developer.apple.com/news/upcoming-requirements/) · [Apple TestFlight](https://developer.apple.com/testflight/) · [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
