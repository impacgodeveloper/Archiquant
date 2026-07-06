// Triggers a file download from in-memory bytes.
//
// Uses a conditional import so the app still compiles on non-web targets:
// on web it drives an <a download> click; elsewhere it's a no-op stub.
export 'downloader_stub.dart'
    if (dart.library.html) 'downloader_web.dart';
