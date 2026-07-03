
 import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/project_store.dart';
import 'services/ocr_store.dart';
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
                      // Pages are designed for a desktop width. On smaller
                      // screens, render at that width and let the content
                      // scroll horizontally instead of overflowing.
                      child: LayoutBuilder(builder: (ctx, c) {
                        const designMin = 1024.0;
                        // Re-key the page on project switch so it reloads fresh.
                        final page = ValueListenableBuilder<String?>(
                          valueListenable: gCurrentProject,
                          builder: (_, pid, __) =>
                              KeyedSubtree(key: ValueKey('proj-$pid'), child: child),
                        );
                        if (c.maxWidth >= designMin) return page;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(width: designMin, child: page),
                        );
                      }),
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
                // Clear ALL app state so the next user on this machine never
                // sees the previous user's cached project/plan data.
                await ApiService.logout();
                OcrStore.instance.clear();
                gCurrentProject.value = null;
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('current_project_id');
                await prefs.remove('current_project_name');
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

        // Global project selector — pick a saved project (no re-upload needed)
        const _ProjectSelector(),
        const SizedBox(width: 12),

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
        InkWell(
          onTap: () => context.go('/settings'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD0DAE8)),
            ),
            child: const Icon(LucideIcons.settings,
                size: 17, color: Color(0xFF6B7A8D)),
          ),
        ),
        const SizedBox(width: 8),

        // User avatar → profile/settings
        InkWell(
          onTap: () => context.go('/settings'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
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

// ─── Global project selector (top bar) ────────────────────────
class _ProjectSelector extends StatefulWidget {
  const _ProjectSelector();
  @override
  State<_ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends State<_ProjectSelector> {
  List<dynamic> _projects = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
    gCurrentProject.addListener(_onGlobalChange);
  }

  @override
  void dispose() {
    gCurrentProject.removeListener(_onGlobalChange);
    super.dispose();
  }

  void _onGlobalChange() {
    if (mounted && gCurrentProject.value != _selectedId) {
      setState(() => _selectedId = gCurrentProject.value);
    }
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cur = prefs.getString('current_project_id') ?? '';
      final projects = await ApiService.getProjects();
      if ((gCurrentProject.value == null || gCurrentProject.value!.isEmpty) && cur.isNotEmpty) {
        gCurrentProject.value = cur;
      }
      if (mounted) {
        setState(() {
          _projects = projects;
          _selectedId = cur.isNotEmpty
              ? cur
              : (projects.isNotEmpty ? projects.first['id'] as String? : null);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_project_id', id);
    setState(() => _selectedId = id);
    gCurrentProject.value = id; // rebuilds the routed page → reloads data
  }

  @override
  Widget build(BuildContext context) {
    final name = _projects.firstWhere(
      (p) => p['id'] == _selectedId,
      orElse: () => {'name': _loading ? 'Loading…' : 'Select Project'},
    )['name']?.toString() ?? 'Project';

    return PopupMenuButton<String>(
      tooltip: 'Switch project',
      onSelected: _select,
      itemBuilder: (_) => [
        if (_projects.isEmpty)
          const PopupMenuItem<String>(enabled: false, child: Text('No projects yet')),
        ..._projects.map((p) => PopupMenuItem<String>(
          value: p['id'] as String,
          child: Row(children: [
            Icon(p['id'] == _selectedId ? LucideIcons.check : LucideIcons.folder,
                size: 15,
                color: p['id'] == _selectedId
                    ? const Color(0xFF1E6FD9) : const Color(0xFF9BAAB8)),
            const SizedBox(width: 8),
            Flexible(child: Text(p['name']?.toString() ?? 'Unnamed',
                overflow: TextOverflow.ellipsis)),
          ]),
        )),
      ],
      child: Container(
        height: 38,
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD0DAE8)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.folderOpen, size: 15, color: Color(0xFF1E6FD9)),
          const SizedBox(width: 8),
          Flexible(child: Text(name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF1A2332), fontSize: 13, fontWeight: FontWeight.w500))),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronDown, size: 15, color: Color(0xFF6B7A8D)),
        ]),
      ),
    );
  }
}