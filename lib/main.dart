import 'package:archiquant_flutter/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'layout.dart';
import 'pages/dashboard.dart';
import 'pages/master_list.dart';
import 'pages/takeoff.dart';
import 'pages/costing.dart';
import 'pages/review_budget.dart';
import 'pages/project_creation.dart';
import 'pages/settings.dart';
import 'pages/login.dart';
import 'pages/upload_plan.dart';
import 'pages/ocr_result_page.dart';
import 'services/api_service.dart';
import 'services/project_store.dart';

// Pass at build time with --dart-define=SENTRY_DSN=https://...  (empty = off).
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore any saved session into the in-memory cache so the route guard can
  // decide synchronously whether to show the app or the login screen.
  await ApiService.loadToken();

  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 0.1;
      },
      appRunner: () => runApp(ArchiQuantApp()),
    );
  } else {
    runApp(ArchiQuantApp());
  }
}

class ArchiQuantApp extends StatelessWidget {
  ArchiQuantApp({super.key});

  final _router = GoRouter(
    initialLocation: '/login',
    // Re-run the redirect whenever the session expires (ApiService toggles
    // gSessionExpired on an unrecoverable 401) so the user is bounced to /login.
    refreshListenable: gSessionExpired,
    // Auth guard: unauthenticated users can only reach /login and /register;
    // everything else bounces to /login. Once logged in, the auth pages bounce
    // back to the dashboard.
    redirect: (context, state) {
      final loggedIn  = ApiService.isLoggedIn;
      final loc       = state.matchedLocation;
      final authRoute = loc == '/login' || loc == '/register';
      if (!loggedIn && !authRoute) return '/login';
      if (loggedIn && authRoute) return '/';
      return null;
    },
    routes: [

      // ── Auth pages (no sidebar) ──────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterPage()),
      ),

      // ── Main app (wrapped in Layout shell) ───────
      ShellRoute(
        builder: (context, state, child) =>
            AppLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: Dashboard()),
          ),
          GoRoute(
            path: '/upload',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlanAnalyzerPage()),
          ),
          GoRoute(
            path: '/plan-result',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OcrResultPage()),
          ),
          GoRoute(
            path: '/master-list',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MasterList()),
          ),
          GoRoute(
            path: '/takeoff',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: Takeoff()),
          ),
          GoRoute(
            path: '/costing',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: Costing()),
          ),
          GoRoute(
            path: '/review',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReviewBudget()),
          ),
          GoRoute(
            path: '/project-creation',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProjectCreation()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ArchiQuant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E6FD9),
          brightness: Brightness.light,
          surface: Colors.white,
          primary: const Color(0xFF1E6FD9),
        ),
        scaffoldBackgroundColor: const Color(0xFFEEF2F7),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFD0DAE8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A2332),
          elevation: 0,
          shadowColor: Color(0x08000000),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E6FD9),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E6FD9),
            side: const BorderSide(color: Color(0xFF1E6FD9)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E6FD9),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFFD0DAE8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFFD0DAE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Color(0xFF1E6FD9), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          hintStyle: const TextStyle(
              color: Color(0xFF9BAAB8), fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEEF2F7),
          selectedColor:
              const Color(0xFF1E6FD9).withOpacity(0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}