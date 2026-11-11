# SAI Browser

Standalone Chromium browser for Windows with tab groups, split view, bookmarks, reading lists, private profiles, and a local research notebook.

## Install on Windows

Download the x64 installer or portable executable from Releases and compare its SHA-256 with SHA256SUMS.txt. The early-access Windows build is unsigned.

## Build

Use Node.js 24 and run `npm ci`, `npm run check`, then `npm run dist`. The Windows workflow builds both executable formats, verifies output, and generates SHA-256 checksums. A macOS ZIP build is available as a manual CI job for testing.

## Search and privacy

Enter a website URL to navigate directly. Public search uses a local SearXNG instance at 127.0.0.1:8888 and depends on that instance's upstream indexes. Saved-page search stays in the local browser profile. Browser research features operate independently of a Core service.

Visited pages run in sandboxed Chromium views with no Node.js bridge. Downloads require a local save decision. Browser profile data uses OS-protected storage. A private session limits persistent local browsing data. Websites and network operators can still observe connections.

This early-access browser uses Chromium. A macOS build needs Mac testing and distribution signing. iOS and Android builds require separate mobile implementations.
