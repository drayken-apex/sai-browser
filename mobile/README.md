# SAI Browser phone previews

Android uses the device's Android System WebView (Android 9+). iPhone uses the system WKWebView (iOS 16+). These native apps start with an empty page and offer HTTPS address navigation and back/forward history. Desktop research tools, tab groups, default-browser registration, and local SearXNG search are outside this slice.

## Network and dependency review

The app code depends on platform APIs and includes the existing SAI Browser artwork. The APK build uses JDK and Google Android SDK tools. The iOS build uses Xcode. There are no third-party app libraries, npm/Gradle/Swift package resolution, app analytics endpoints, built-in search endpoints, or Core/Mail clients in either build.

User-entered websites, links, and page resources make network requests. Platform WebViews can perform platform security lookups, and sites can contact other servers and use JavaScript. Android explicitly blocks cleartext, mixed content, third-party cookies, file/content access, and the download handoff. Its package requests only Internet access. iOS uses normal App Transport Security, nonpersistent website data, and explicitly denies WebKit media-capture requests. Both have no native JavaScript bridge, custom certificate bypass, or deep-link intent dispatch.

Both restrict address entry and frame navigation to domain-based HTTPS URLs. Android also filters requests delivered to its WebView interception callback. These checks do not provide a DNS/IP firewall. DNS can resolve a permitted name to a private address, Android's request callback does not cover every request or redirect, and WebKit navigation delegates do not inspect all subresources. Keep the YSAI Core bound to loopback with its existing authentication and isolation.

[Android WebView file access](https://developer.android.com/privacy-and-security/risks/webview-unsafe-file-inclusion) · [Android WebView bridges](https://developer.android.com/privacy-and-security/risks/insecure-webview-native-bridges) · [Apple WebKit](https://developer.apple.com/documentation/webkit/wkwebview)

## Android review build

Use JDK 21, the Android 35 platform jar and Google Build Tools 35.0.0. Add the JDK bin directory to PATH. Use a private PKCS12 preview keystore with alias `sai-preview`, outside the checkout. Provide its password in `SAI_PREVIEW_KEY_PASSWORD` for the build session.

```powershell
./mobile/android/Build-Preview.ps1 -PlatformJar '<android-35/android.jar>' -BuildTools '<build-tools/35.0.0>' -KeyStore '<review.p12>' -OutputDirectory '<review output>'
```

The script compiles and exercises the address rules, builds and aligns the APK, signs it, verifies signature/alignment, and writes the SHA-256. Verify the hash before opening the APK or using `adb install <file.apk>`. This build uses the preview application ID `org.ysai.saibrowser.preview` and a private local review key. Preserve the key for compatible preview updates. Public distribution should use an owner-controlled release identity and key. Check device/region rules before wider direct APK delivery.

[Android APK signing](https://developer.android.com/tools/apksigner) · [Direct APK distribution](https://developer.android.com/distribute/marketing-tools/alternative-distribution) · [Developer verification](https://developer.android.com/developer-verification)

## iPhone and the next apps

See [iPhone build and TestFlight](ios/README.md). The project contains no team credentials or provisioning profiles.

- **Axiom Mail**. Build a separate native client against the intended TLS mail and identity service. Use system-browser OAuth authorization code with PKCE and platform-protected token storage. Start with read-only JMAP inbox and account isolation. Verify real mailbox identity and keep owner enrollment separate. Require a user send gesture before implementing outgoing mail, and keep mail HTML and attachments isolated from credentials and native permissions.
- **YSAI**. Start with a phone-local client and assess on-device model support against real memory and performance constraints. A later desktop companion needs a separate pairing boundary and narrow, authenticated, revocable contracts for business-scoped reads and explicitly approved actions. Preserve local inference and keep the loopback Core off LAN and public interfaces.
