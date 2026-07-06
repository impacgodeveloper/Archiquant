import 'package:flutter/foundation.dart';

// Global current-project id. Changing it (from the top-bar dropdown) rebuilds
// the routed page via a KeyedSubtree in AppLayout, so every page (Dashboard,
// Costing, Review, Takeoff, Plan Result) reloads for the newly-selected project
// without re-uploading a plan.
final ValueNotifier<String?> gCurrentProject = ValueNotifier<String?>(null);

// Session-expiry signal. ApiService toggles this when the backend rejects the
// session (a 401 that even a token refresh can't recover). The GoRouter watches
// it via refreshListenable and bounces the user to /login. It's a pure trigger —
// the value itself is meaningless, only the change notification matters.
final ValueNotifier<bool> gSessionExpired = ValueNotifier<bool>(false);

