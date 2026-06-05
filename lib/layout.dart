
 import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'services/api_service.dart';
import 'utils/app_colors.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      return Scaffold(
        backgroundColor: AppColors.pageBg,
        // On narrow screens the sidebar becomes a slide-out drawer
        drawer: wide ? null : const Drawer(width: 220, child: _Sidebar()),
        body: Row(
          children: [
            if (wide) const _Sidebar(),
            Expanded(
              child: Column(
                children: [
                  _TopBar(compact: !wide),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(wide ? 24 : 12),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Sidebar ──────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  static const _navItems = [
    {'label': 'Dashboard',         'icon': LucideIcons.layoutDashboard, 'route': '/'},
    {'label': 'Upload Plan',       'icon': LucideIcons.upload,          'route': '/upload'},
    {'label': 'Plan Result',       'icon': LucideIcons.scanLine,        'route': '/plan-result'},
    {'label': 'Master List',       'icon': LucideIcons.list,            'route': '/master-list'},
    {'label': 'Takeoff (QTO)',     'icon': LucideIcons.clipboardList,   'route': '/takeoff'},
    {'label': 'Costing & Analysis','icon': LucideIcons.calculator,      'route': '/costing'},
    {'label': 'Review & Budget',   'icon': LucideIcons.wallet,          'route': '/review'},
    {'label': 'Project Creation',  'icon': LucideIcons.folderPlus,      'route': '/project-creation'},
    {'label': 'Settings',          'icon': LucideIcons.settings,        'route': '/settings'},
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF0A1628)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Logo ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E6FD9), Color(0xFF00BCD4)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E6FD9).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('A',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ArchiQuant',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.3)),
                  Text('BUILDING CONSTRUCTION SUITE',
                      style: TextStyle(
                          color: Color(0xFF4A6FA8),
                          fontSize: 7,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Nav Items ────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              children: _navItems.map((item) {
                final route    = item['route'] as String;
                final isActive = location == route ||
                    (route != '/' && location.startsWith(route));
                return _NavItem(
                  label:    item['label'] as String,
                  icon:     item['icon'] as IconData,
                  route:    route,
                  isActive: isActive,
                );
              }).toList(),
            ),
          ),

          // ── Logout ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: InkWell(
              onTap: () async {
                await ApiService.logout();
                if (context.mounted) context.go('/login');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: const Row(children: [
                  Icon(LucideIcons.logOut,
                      size: 16, color: Color(0xFF4A6FA8)),
                  SizedBox(width: 10),
                  Text('Logout',
                      style: TextStyle(
                          color: Color(0xFF6B8BA4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String   label;
  final IconData icon;
  final String   route;
  final bool     isActive;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () {
          context.go(route);
          // if we're inside the slide-out drawer (narrow screens), close it
          final sc = Scaffold.maybeOf(context);
          if (sc?.isDrawerOpen ?? false) sc!.closeDrawer();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF1E6FD9), Color(0xFF1557B0)],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E6FD9).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : const Color(0xFF4A90B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF8BA8C0)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool compact;
  const _TopBar({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final title    = _getTitle(location);
    final icon     = _getIcon(location);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [

        // Hamburger (only on narrow screens → opens the drawer)
        if (compact)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(LucideIcons.menu, color: Color(0xFF1A2332)),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            ),
          ),

        // Page icon + title
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF1E6FD9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17,
              color: const Color(0xFF1E6FD9)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2332))),
        ),

        const Spacer(),

        // Search — hidden on narrow screens to save space
        if (!compact) ...[
          Container(
            width: 240, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD0DAE8)),
            ),
            child: const Row(children: [
              SizedBox(width: 12),
              Icon(LucideIcons.search,
                  size: 15, color: Color(0xFF9BAAB8)),
              SizedBox(width: 8),
              Text('Search...',
                  style: TextStyle(
                      color: Color(0xFF9BAAB8), fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 12),
        ],

        // Notification bell
        Stack(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD0DAE8)),
            ),
            child: const Icon(LucideIcons.bell,
                size: 17, color: Color(0xFF6B7A8D)),
          ),
          Positioned(
            right: 9, top: 9,
            child: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: Color(0xFF1E6FD9),
                  shape: BoxShape.circle),
            ),
          ),
        ]),
        const SizedBox(width: 8),

        // Settings
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD0DAE8)),
          ),
          child: const Icon(LucideIcons.settings,
              size: 17, color: Color(0xFF6B7A8D)),
        ),
        const SizedBox(width: 8),

        // User avatar
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E6FD9), Color(0xFF00BCD4)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E6FD9).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('A',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ]),
    );
  }

  String _getTitle(String location) {
    if (location == '/')               return 'Dashboard';
    if (location.contains('upload'))   return 'Upload Plan';
    if (location.contains('master'))   return 'Master List';
    if (location.contains('takeoff'))  return 'Takeoff (QTO)';
    if (location.contains('costing'))  return 'Costing & Analysis';
    if (location.contains('review'))   return 'Review & Budget';
    if (location.contains('project'))  return 'Project Creation';
    if (location.contains('settings')) return 'Settings';
    return 'ArchiQuant';
  }

  IconData _getIcon(String location) {
    if (location == '/')               return LucideIcons.layoutDashboard;
    if (location.contains('upload'))   return LucideIcons.upload;
    if (location.contains('master'))   return LucideIcons.list;
    if (location.contains('takeoff'))  return LucideIcons.clipboardList;
    if (location.contains('costing'))  return LucideIcons.calculator;
    if (location.contains('review'))   return LucideIcons.wallet;
    if (location.contains('project'))  return LucideIcons.folderPlus;
    if (location.contains('settings')) return LucideIcons.settings;
    return LucideIcons.layoutDashboard;
  }
}