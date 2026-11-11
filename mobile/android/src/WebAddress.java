package org.ysai.saibrowser.preview;

import java.net.URI;
import java.util.Locale;
import java.util.regex.Pattern;

final class WebAddress {
    private static final Pattern DOMAIN = Pattern.compile(
        "(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}"
    );

    static URI parse(String text) {
        String address = text.trim();
        if (!address.contains("://")) {
            address = "https://" + address;
        }
        if (address.length() > 2000) {
            throw new IllegalArgumentException("Address is too long.");
        }
        URI url = URI.create(address);
        if (!allows(url)) {
            throw new IllegalArgumentException("Enter an HTTPS website with a public domain name.");
        }
        return url;
    }

    static boolean allows(URI url) {
        if (!"https".equalsIgnoreCase(url.getScheme()) || url.getRawUserInfo() != null
            || url.getHost() == null || (url.getPort() != -1 && url.getPort() != 443)) {
            return false;
        }
        String host = url.getHost().toLowerCase(Locale.ROOT);
        String authority = url.getPort() == -1 ? host : host + ":443";
        if (!authority.equalsIgnoreCase(url.getRawAuthority())) return false;
        return host.length() <= 253 && DOMAIN.matcher(host).matches()
            && !host.endsWith(".localhost") && !host.endsWith(".local")
            && !host.endsWith(".internal") && !host.endsWith(".test")
            && !host.endsWith(".lan") && !host.endsWith(".onion")
            && !host.endsWith(".arpa");
    }

    static boolean allows(String address) {
        try {
            return allows(URI.create(address));
        } catch (IllegalArgumentException invalid) {
            return false;
        }
    }
}
