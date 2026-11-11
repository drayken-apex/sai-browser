package org.ysai.saibrowser.preview;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.text.InputType;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.webkit.CookieManager;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.io.ByteArrayInputStream;
import java.util.Collections;

public final class BrowserActivity extends Activity {
    private WebView web;
    private EditText address;
    private Button back;
    private Button forward;
    private TextView status;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.rgb(24, 22, 33));
        root.setOnApplyWindowInsetsListener((view, insets) -> {
            if (android.os.Build.VERSION.SDK_INT >= 35) {
                android.graphics.Insets safe = insets.getInsets(
                    WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout() | WindowInsets.Type.ime());
                view.setPadding(safe.left, safe.top, safe.right, safe.bottom);
            }
            return insets;
        });

        LinearLayout bar = new LinearLayout(this);
        back = button("‹", "Back", () -> web.goBack());
        forward = button("›", "Forward", () -> web.goForward());
        bar.addView(back, controlLayout(48));
        bar.addView(forward, controlLayout(48));
        address = new EditText(this);
        address.setSingleLine(true);
        address.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        address.setImeOptions(EditorInfo.IME_ACTION_GO | EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING);
        address.setHint("Website address");
        address.setOnEditorActionListener((view, action, event) -> {
            if (action != EditorInfo.IME_ACTION_GO) return false;
            openAddress();
            return true;
        });
        bar.addView(address, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        bar.addView(button("Go", "Open address", this::openAddress), controlLayout(64));
        root.addView(bar);

        status = new TextView(this);
        status.setAccessibilityLiveRegion(TextView.ACCESSIBILITY_LIVE_REGION_POLITE);
        root.addView(status);
        web = new WebView(this);
        configureBrowser();
        root.addView(web, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));
        setContentView(root);
        if (state == null || web.restoreState(state) == null) {
            showStatus("Enter an HTTPS website to start.");
        }
        updateHistory();
    }

    private Button button(String label, String description, Runnable action) {
        Button control = new Button(this);
        control.setText(label);
        control.setContentDescription(description);
        control.setOnClickListener(view -> action.run());
        return control;
    }

    private LinearLayout.LayoutParams controlLayout(int widthDp) {
        int width = Math.round(widthDp * getResources().getDisplayMetrics().density);
        return new LinearLayout.LayoutParams(width, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    @SuppressWarnings("deprecation")
    private void configureBrowser() {
        WebSettings settings = web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setJavaScriptCanOpenWindowsAutomatically(false);
        settings.setSupportMultipleWindows(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        settings.setSafeBrowsingEnabled(true);
        CookieManager.getInstance().setAcceptThirdPartyCookies(web, false);

        web.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                if (WebAddress.allows(request.getUrl().toString())) return false;
                if (request.isForMainFrame()) showStatus("Navigation blocked. Use a public HTTPS address.");
                return true;
            }

            @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                if (WebAddress.allows(request.getUrl().toString())) return null;
                return new WebResourceResponse("text/plain", "UTF-8", 403, "Blocked",
                    Collections.emptyMap(), new ByteArrayInputStream(new byte[0]));
            }

            @Override public void onPageStarted(WebView view, String url, android.graphics.Bitmap icon) {
                if (!WebAddress.allows(url)) {
                    view.stopLoading();
                    showStatus("Navigation blocked. Use a public HTTPS address.");
                    return;
                }
                if (!address.hasFocus()) address.setText(url);
                showStatus("Loading…");
            }

            @Override public void onPageCommitVisible(WebView view, String url) {
                if (!address.hasFocus()) address.setText(url);
                showStatus("");
            }

            @Override public void doUpdateVisitedHistory(WebView view, String url, boolean reload) {
                updateHistory();
            }

            @Override public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                if (request.isForMainFrame()) showStatus("Could not load this page.");
            }

            @Override public boolean onRenderProcessGone(WebView view, android.webkit.RenderProcessGoneDetail detail) {
                ((ViewGroup) view.getParent()).removeView(view);
                view.destroy();
                web = null;
                recreate();
                return true;
            }
        });
        web.setDownloadListener((url, agent, disposition, type, length) ->
            showStatus("Downloads are disabled in this preview."));
    }

    private void openAddress() {
        try {
            String url = WebAddress.parse(address.getText().toString()).toASCIIString();
            address.setText(url);
            address.clearFocus();
            getSystemService(InputMethodManager.class).hideSoftInputFromWindow(address.getWindowToken(), 0);
            web.loadUrl(url);
        } catch (IllegalArgumentException invalid) {
            showStatus("Enter a public HTTPS website address.");
        }
    }

    private void showStatus(String message) {
        status.setText(message);
        status.setVisibility(message.isEmpty() ? TextView.GONE : TextView.VISIBLE);
    }

    private void updateHistory() {
        back.setEnabled(web.canGoBack());
        forward.setEnabled(web.canGoForward());
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        if (web != null) web.saveState(state);
    }

    @Override protected void onDestroy() {
        if (web != null) {
            ((ViewGroup) web.getParent()).removeView(web);
            web.destroy();
        }
        super.onDestroy();
    }
}
