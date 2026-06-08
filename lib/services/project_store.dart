import 'package:flutter/foundation.dart';

// Global current-project id. Changing it (from the top-bar dropdown) rebuilds
// the routed page via a KeyedSubtree in AppLayout, so every page (Dashboard,
// Costing, Review, Takeoff, Plan Result) reloads for the newly-selected project
// without re-uploading a plan.
final ValueNotifier<String?> gCurrentProject = ValueNotifier<String?>(null);
