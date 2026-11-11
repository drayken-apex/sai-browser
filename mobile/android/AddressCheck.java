package org.ysai.saibrowser.preview;

public final class AddressCheck {
    public static void main(String[] args) {
        if (!WebAddress.parse(" example.com/path ").toString().equals("https://example.com/path")) {
            throw new AssertionError("Bare domain was not upgraded");
        }
        if (!WebAddress.allows("https://www.example.com:443/?a=1#b")) {
            throw new AssertionError("Valid HTTPS address was blocked");
        }
        for (String url : new String[] {
            "http://example.com", "https://example.com:8888", "https://example.com:", "https://user@example.com",
            "https://localhost", "https://a.localhost", "https://yui.internal", "https://test.local",
            "https://127.0.0.1", "https://0177.1", "https://0x7f000001", "https://[::1]",
            "https://example.com.", "https://a%2elocal", "https://a.lan", "https://a.onion",
            "file:///data", "content://files/id", "intent://example.com", "javascript:alert(1)"
        }) {
            if (WebAddress.allows(url)) throw new AssertionError("Allowed " + url);
        }
        System.out.println("Android address policy: PASS");
    }
}
