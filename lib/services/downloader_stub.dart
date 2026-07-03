// Non-web fallback. On mobile/desktop builds there's no browser download;
// this is intentionally a no-op so the app still compiles for those targets.
void downloadBytes(String filename, List<int> bytes, String mime) {
  // No-op on non-web platforms.
}
