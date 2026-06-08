import 'package:archiquant_flutter/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── LOGIN PAGE BYPASS ────────────────────────────────────────────────
  // The login screen is currently disabled as the entry point (see the
  // commented `initialLocation: '/login'` below). Because every backend call
  // needs a JWT, we silently auto-login with a shared demo account on startup.
  // To RE-ENABLE login: restore `initialLocation: '/login'` and delete this block.
  final token = await ApiService.getToken();
  if (token == null || token.isEmpty) {
    try {
      await ApiService.login('adityaram@impacgo.com', 'demo1234', 'ipg');
    } catch (_) {/* offline → login page still reachable at /login */}
  }
  // ─────────────────────────────────────────────────────────────────────

  runApp(ArchiQuantApp());
}

class ArchiQuantApp extends StatelessWidget {
  ArchiQuantApp({super.key});

  final _router = GoRouter(
    // initialLocation: '/login',   // ← LOGIN PAGE COMMENTED OUT (bypassed)
    initialLocation: '/',           // open straight to the dashboard
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