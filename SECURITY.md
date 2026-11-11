# Security

Use the current release and report suspected vulnerabilities privately to the repository owner. Include the build version and reproduction steps. Omit personal browsing data and credentials.

The app separates its controls from untrusted sites using sandboxed views, context isolation, and IPC sender checks. The URL filter blocks explicit private IPs and local names. DNS and the operating system still control network reachability. Keep the OS and browser runtime updated.

Release source is exported by allowlist with a fresh history. Electron and Chromium license notices are bundled with the executable distribution.
