import SwiftUI
import WebKit

@main
struct BrowserApp: App {
    var body: some Scene {
        WindowGroup {
            BrowserScreen()
        }
    }
}

struct BrowserScreen: View {
    @StateObject private var browser = Browser()
    @FocusState private var editingAddress: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Button { browser.webView.goBack() } label: {
                    Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Back")
                .disabled(!browser.canGoBack)
                Button { browser.webView.goForward() } label: {
                    Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Forward")
                .disabled(!browser.canGoForward)
                TextField("Website address", text: $browser.address)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($editingAddress)
                    .onChange(of: editingAddress) { browser.isEditing = $0 }
                    .onSubmit(open)
                Button("Go", action: open).frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Open address")
            }
            .padding(.horizontal, 8)
            .background(Color(red: 0.09, green: 0.08, blue: 0.13))
            .preferredColorScheme(.dark)
            if !browser.status.isEmpty {
                Text(browser.status)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            BrowserView(webView: browser.webView)
        }
    }

    private func open() {
        if browser.openAddress() { editingAddress = false }
    }
}

struct BrowserView: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ view: WKWebView, context: Context) {}
}

@MainActor
final class Browser: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var address = ""
    @Published private(set) var status = "Enter an HTTPS website to start."
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    var isEditing = false
    let webView: WKWebView

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences.isFraudulentWebsiteWarningEnabled = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    func openAddress() -> Bool {
        guard let url = WebAddress.parse(address) else {
            status = "Enter a public HTTPS website address."
            return false
        }
        address = url.absoluteString
        webView.load(URLRequest(url: url))
        return true
    }

    func webView(_ view: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url, WebAddress.allows(url), !action.shouldPerformDownload else {
            if action.targetFrame?.isMainFrame != false {
                status = "Navigation blocked. Use a public HTTPS address."
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(action.targetFrame == nil ? .cancel : .allow)
    }

    func webView(_ view: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let url = response.response.url, WebAddress.allows(url), response.canShowMIMEType else {
            if response.isForMainFrame { status = "Could not display this page." }
            decisionHandler(.cancel)
            return
        }
        if let http = response.response as? HTTPURLResponse,
           http.value(forHTTPHeaderField: "Content-Disposition")?
             .trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("attachment") == true {
            if response.isForMainFrame { status = "Downloads are disabled in this preview." }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ view: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.deny)
    }

    func webView(_ view: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        status = "Loading…"
    }

    func webView(_ view: WKWebView, didCommit navigation: WKNavigation!) {
        if !isEditing, let url = view.url { address = url.absoluteString }
        canGoBack = view.canGoBack
        canGoForward = view.canGoForward
        status = ""
    }

    func webView(_ view: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        reportFailure(error)
    }

    func webView(_ view: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        reportFailure(error)
    }

    func webViewWebContentProcessDidTerminate(_ view: WKWebView) {
        status = "The page stopped. Tap Go to reload."
    }

    private func reportFailure(_ error: Error) {
        let failure = error as NSError
        if failure.domain == NSURLErrorDomain && failure.code == NSURLErrorCancelled { return }
        status = "Could not load this page."
    }
}
