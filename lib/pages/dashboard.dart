// // // import 'package:flutter/material.dart';
// // // import 'package:fl_chart/fl_chart.dart';
// // // import 'package:lucide_icons_flutter/lucide_icons.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import '../services/api_service.dart';

// // // // ─── Breakpoint helpers ───────────────────────────────────────────────────────
// // // class _Screen {
// // //   static bool isMobile(BuildContext ctx) =>
// // //       MediaQuery.of(ctx).size.width < 600;
// // //   static bool isTablet(BuildContext ctx) {
// // //     final w = MediaQuery.of(ctx).size.width;
// // //     return w >= 600 && w < 1024;
// // //   }
// // //   static bool isDesktop(BuildContext ctx) =>
// // //       MediaQuery.of(ctx).size.width >= 1024;
// // // }

// // // // ─── Helper ───────────────────────────────────────────────────────────────────
// // // String _cap(String s) =>
// // //     s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// // // String _formatDate(String dateStr) {
// // //   final dt = DateTime.tryParse(dateStr);
// // //   if (dt == null) return '—';
// // //   return '${dt.day}/${dt.month}/${dt.year}';
// // // }

// // // // ─── Dashboard ────────────────────────────────────────────────────────────────
// // // class Dashboard extends StatefulWidget {
// // //   const Dashboard({super.key});

// // //   @override
// // //   State<Dashboard> createState() => _DashboardState();
// // // }

// // // class _DashboardState extends State<Dashboard> {
// // //   bool _loading = true;
// // //   String? _error;

// // //   List<dynamic> _projects       = [];
// // //   Map<String, dynamic> _settings = {};
// // //   Map<String, dynamic>? _calcData;
// // //   String _currentProjectName    = '';

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadDashboard();
// // //   }

// // //   Future<void> _loadDashboard() async {
// // //     setState(() { _loading = true; _error = null; });
// // //     try {
// // //       final prefs     = await SharedPreferences.getInstance();
// // //       final projectId = prefs.getString('current_project_id') ?? '';

// // //       final results = await Future.wait([
// // //         ApiService.getProjects(),
// // //         ApiService.getSettings(),
// // //       ]);

// // //       final projects = results[0] as List<dynamic>;
// // //       final settings = results[1] as Map<String, dynamic>;

// // //       Map<String, dynamic>? calcData;
// // //       if (projectId.isNotEmpty && projects.isNotEmpty) {
// // //         try {
// // //           calcData = await ApiService.calculateBricksWithTypes(
// // //             projectId,
// // //             brickTypeMap: {
// // //               "9": "red_brick",
// // //               "6": "white_cement",
// // //               "4": "white_cement",
// // //             },
// // //           );
// // //         } catch (_) {}
// // //       }

// // //       String projectName = '';
// // //       if (projectId.isNotEmpty && projects.isNotEmpty) {
// // //         final current =
// // //             projects.where((p) => p['id'] == projectId);
// // //         if (current.isNotEmpty) {
// // //           projectName = current.first['name'] ?? '';
// // //         }
// // //       }

// // //       if (mounted) {
// // //         setState(() {
// // //           _projects           = projects;
// // //           _settings           = settings;
// // //           _calcData           = calcData;
// // //           _currentProjectName = projectName;
// // //           _loading            = false;
// // //         });
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         setState(() { _error = e.toString(); _loading = false; });
// // //       }
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isMobile = _Screen.isMobile(context);
// // //     final isTablet = _Screen.isTablet(context);

// // //     if (_loading) {
// // //       return const Center(
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             CircularProgressIndicator(color: Color(0xFF0891B2)),
// // //             SizedBox(height: 16),
// // //             Text('Loading dashboard...',
// // //                 style: TextStyle(color: Color(0xFF64748B))),
// // //           ],
// // //         ),
// // //       );
// // //     }

// // //     if (_error != null) {
// // //       return Center(
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             const Icon(LucideIcons.circle,
// // //                 size: 40, color: Color(0xFF94A3B8)),
// // //             const SizedBox(height: 12),
// // //             Text(_error!,
// // //                 textAlign: TextAlign.center,
// // //                 style: const TextStyle(
// // //                     color: Color(0xFF64748B))),
// // //             const SizedBox(height: 16),
// // //             ElevatedButton(
// // //               onPressed: _loadDashboard,
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: const Color(0xFF0891B2),
// // //                 foregroundColor: Colors.white,
// // //               ),
// // //               child: const Text('Retry'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //     }

// // //     return SingleChildScrollView(
// // //       physics: const AlwaysScrollableScrollPhysics(),
// // //       padding: EdgeInsets.all(isMobile ? 12 : 24),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [

// // //           // ── Active Project Banner ──────────────────────
// // //           if (_currentProjectName.isNotEmpty)
// // //             Container(
// // //               width: double.infinity,
// // //               margin: const EdgeInsets.only(bottom: 20),
// // //               padding: const EdgeInsets.symmetric(
// // //                   horizontal: 20, vertical: 14),
// // //               decoration: BoxDecoration(
// // //                 gradient: const LinearGradient(
// // //                   colors: [Color(0xFF0F172A), Color(0xFF0891B2)],
// // //                 ),
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               child: Row(children: [
// // //                 const Icon(LucideIcons.folder,
// // //                     size: 18, color: Colors.white70),
// // //                 const SizedBox(width: 10),
// // //                 Text(
// // //                   'Active Project: $_currentProjectName',
// // //                   style: const TextStyle(
// // //                       color: Colors.white,
// // //                       fontWeight: FontWeight.w600,
// // //                       fontSize: 14),
// // //                 ),
// // //                 const Spacer(),
// // //                 Container(
// // //                   padding: const EdgeInsets.symmetric(
// // //                       horizontal: 10, vertical: 4),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.white.withOpacity(0.15),
// // //                     borderRadius: BorderRadius.circular(12),
// // //                   ),
// // //                   child: Text(
// // //                     '${_projects.length} project${_projects.length != 1 ? 's' : ''} total',
// // //                     style: const TextStyle(
// // //                         color: Colors.white70, fontSize: 12),
// // //                   ),
// // //                 ),
// // //               ]),
// // //             ),

// // //           // ── Overview Cards ─────────────────────────────
// // //           _OverviewCards(
// // //             projects: _projects,
// // //             calcData: _calcData,
// // //             settings: _settings,
// // //           ),
// // //           const SizedBox(height: 24),

// // //           // ── Charts Row ─────────────────────────────────
// // //           if (isMobile) ...[
// // //             SizedBox(
// // //                 height: 300,
// // //                 child: _ActiveProjectsChart(
// // //                     projects: _projects)),
// // //             const SizedBox(height: 16),
// // //             _MaterialInventory(calcData: _calcData),
// // //           ] else ...[
// // //             SizedBox(
// // //               height: isTablet ? 360 : 400,
// // //               child: Row(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Expanded(
// // //                     flex: isTablet ? 3 : 2,
// // //                     child: _ActiveProjectsChart(
// // //                         projects: _projects),
// // //                   ),
// // //                   const SizedBox(width: 16),
// // //                   Expanded(
// // //                     flex: isTablet ? 2 : 1,
// // //                     child: _MaterialInventory(
// // //                         calcData: _calcData),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ],

// // //           const SizedBox(height: 24),
// // //           _RecentProjectsTable(projects: _projects),
// // //           const SizedBox(height: 16),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─── Overview Cards ───────────────────────────────────────────────────────────
// // // class _OverviewCards extends StatelessWidget {
// // //   final List<dynamic> projects;
// // //   final Map<String, dynamic>? calcData;
// // //   final Map<String, dynamic> settings;

// // //   const _OverviewCards({
// // //     required this.projects,
// // //     required this.calcData,
// // //     required this.settings,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isMobile       = _Screen.isMobile(context);
// // //     final totalProjects  = projects.length;
// // //     final activeProjects =
// // //         projects.where((p) => p['status'] == 'active').length;
// // //     final completedProjects =
// // //         projects.where((p) => p['status'] == 'completed').length;

// // //     final grand       = calcData?['grand_total'] ?? {};
// // //     final totalBricks = grand['final_bricks']        ?? 0;
// // //     final redBricks   = grand['red_bricks']           ?? 0;
// // //     final whiteBricks = grand['white_cement_blocks']  ?? 0;
// // //     final currency    = settings['currency']          ?? 'INR';

// // //     final stats = [
// // //       {'label': 'Total Projects',  'value': '$totalProjects',   'trend': '$activeProjects active',    'up': true},
// // //       {'label': 'Active Projects', 'value': '$activeProjects',  'trend': '$completedProjects completed','up': true},
// // //       {'label': 'Total Bricks',    'value': totalBricks > 0 ? '$totalBricks' : '—', 'trend': 'incl. 10% buffer', 'up': true},
// // //       {'label': 'Red Bricks',      'value': redBricks > 0   ? '$redBricks'   : '—', 'trend': '9" walls',         'up': true},
// // //       {'label': 'Cement Blocks',   'value': whiteBricks > 0 ? '$whiteBricks' : '—', 'trend': '4"/6" walls',      'up': true},
// // //       {'label': 'Currency',        'value': currency,            'trend': 'company default',           'up': true},
// // //       {'label': 'Wastage %',       'value': '${settings['wastage_pct'] ?? 10}%', 'trend': 'buffer rate', 'up': true},
// // //       {'label': 'Wall Height',     'value': '${settings['default_wall_height'] ?? 3}m', 'trend': 'default', 'up': true},
// // //     ];

// // //     return Container(
// // //       padding: EdgeInsets.all(isMobile ? 16 : 24),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: const Color(0xFFE2E8F0)),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Row(
// // //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //             children: [
// // //               Text('Overview',
// // //                   style: TextStyle(
// // //                       fontSize: isMobile ? 15 : 18,
// // //                       fontWeight: FontWeight.w600,
// // //                       color: const Color(0xFF1E293B))),
// // //               IconButton(
// // //                   icon: const Icon(Icons.more_vert, size: 20),
// // //                   onPressed: () {}),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 16),
// // //           LayoutBuilder(builder: (context, constraints) {
// // //             final w = constraints.maxWidth;
// // //             int cols = w < 400 ? 2 : w < 700 ? 3 : 4;
// // //             return GridView.builder(
// // //               shrinkWrap: true,
// // //               physics: const NeverScrollableScrollPhysics(),
// // //               gridDelegate:
// // //                   SliverGridDelegateWithFixedCrossAxisCount(
// // //                 crossAxisCount: cols,
// // //                 childAspectRatio: w < 400 ? 1.2 : 1.5,
// // //                 crossAxisSpacing: isMobile ? 10 : 16,
// // //                 mainAxisSpacing:  isMobile ? 10 : 16,
// // //               ),
// // //               itemCount: stats.length,
// // //               itemBuilder: (_, i) =>
// // //                   _StatCard(stat: stats[i], compact: isMobile),
// // //             );
// // //           }),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _StatCard extends StatelessWidget {
// // //   final Map<String, dynamic> stat;
// // //   final bool compact;
// // //   const _StatCard({required this.stat, this.compact = false});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final bool up = stat['up'] as bool;
// // //     return Container(
// // //       padding: EdgeInsets.all(compact ? 10 : 12),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFFF8FAFC),
// // //         borderRadius: BorderRadius.circular(8),
// // //         border: Border.all(color: const Color(0xFFF1F5F9)),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Text(stat['label'],
// // //               style: TextStyle(
// // //                   fontSize: compact ? 10 : 12,
// // //                   color: const Color(0xFF64748B)),
// // //               overflow: TextOverflow.ellipsis,
// // //               maxLines: 1),
// // //           const SizedBox(height: 4),
// // //           FittedBox(
// // //             fit: BoxFit.scaleDown,
// // //             alignment: Alignment.centerLeft,
// // //             child: Text(stat['value'],
// // //                 style: TextStyle(
// // //                     fontSize: compact ? 15 : 18,
// // //                     fontWeight: FontWeight.w600,
// // //                     color: const Color(0xFF1E293B))),
// // //           ),
// // //           const Spacer(),
// // //           Row(children: [
// // //             Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
// // //                 size: 11,
// // //                 color: up
// // //                     ? const Color(0xFF10B981)
// // //                     : const Color(0xFFEF4444)),
// // //             const SizedBox(width: 3),
// // //             Expanded(
// // //               child: Text(stat['trend'],
// // //                   style: TextStyle(
// // //                       fontSize: compact ? 9 : 11,
// // //                       color: up
// // //                           ? const Color(0xFF10B981)
// // //                           : const Color(0xFFEF4444)),
// // //                   overflow: TextOverflow.ellipsis),
// // //             ),
// // //           ]),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─── Active Projects Chart ────────────────────────────────────────────────────
// // // class _ActiveProjectsChart extends StatelessWidget {
// // //   final List<dynamic> projects;
// // //   const _ActiveProjectsChart({required this.projects});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isMobile = _Screen.isMobile(context);

// // //     final Map<int, int> monthCount = {};
// // //     for (final p in projects) {
// // //       final created = DateTime.tryParse(p['created_at'] ?? '');
// // //       if (created != null) {
// // //         monthCount[created.month] =
// // //             (monthCount[created.month] ?? 0) + 1;
// // //       }
// // //     }

// // //     final now   = DateTime.now();
// // //     final spots = List.generate(7, (i) {
// // //       final month = ((now.month - 6 + i) % 12) + 1;
// // //       return FlSpot(
// // //           i.toDouble(), (monthCount[month] ?? 0).toDouble());
// // //     });

// // //     return Container(
// // //       padding: EdgeInsets.all(isMobile ? 16 : 24),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: const Color(0xFFE2E8F0)),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Row(
// // //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //             children: [
// // //               Text('Project Activity',
// // //                   style: TextStyle(
// // //                       fontSize: isMobile ? 15 : 18,
// // //                       fontWeight: FontWeight.w600,
// // //                       color: const Color(0xFF1E293B))),
// // //               Container(
// // //                 padding: const EdgeInsets.symmetric(
// // //                     horizontal: 10, vertical: 4),
// // //                 decoration: BoxDecoration(
// // //                   color: const Color(0xFFECFEFF),
// // //                   borderRadius: BorderRadius.circular(12),
// // //                 ),
// // //                 child: Text('${projects.length} total',
// // //                     style: const TextStyle(
// // //                         fontSize: 12,
// // //                         color: Color(0xFF0891B2),
// // //                         fontWeight: FontWeight.w500)),
// // //               ),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 16),
// // //           Expanded(
// // //             child: projects.isEmpty
// // //                 ? const Center(
// // //                     child: Text('No projects yet',
// // //                         style: TextStyle(
// // //                             color: Color(0xFF94A3B8))))
// // //                 : LineChart(LineChartData(
// // //                     gridData: FlGridData(
// // //                       show: true,
// // //                       drawVerticalLine: false,
// // //                       getDrawingHorizontalLine: (_) => FlLine(
// // //                           color: const Color(0xFFE2E8F0),
// // //                           strokeWidth: 1,
// // //                           dashArray: [3, 3]),
// // //                     ),
// // //                     titlesData: FlTitlesData(
// // //                       topTitles: const AxisTitles(
// // //                           sideTitles:
// // //                               SideTitles(showTitles: false)),
// // //                       rightTitles: const AxisTitles(
// // //                           sideTitles:
// // //                               SideTitles(showTitles: false)),
// // //                       leftTitles: AxisTitles(
// // //                         sideTitles: SideTitles(
// // //                           showTitles: true,
// // //                           reservedSize: isMobile ? 28 : 40,
// // //                           getTitlesWidget: (v, _) =>
// // //                               Text('${v.toInt()}',
// // //                                   style: TextStyle(
// // //                                       fontSize:
// // //                                           isMobile ? 10 : 12,
// // //                                       color: const Color(
// // //                                           0xFF64748B))),
// // //                         ),
// // //                       ),
// // //                       bottomTitles: AxisTitles(
// // //                         sideTitles: SideTitles(
// // //                           showTitles: true,
// // //                           reservedSize: 28,
// // //                           getTitlesWidget: (value, _) {
// // //                             const months = [
// // //                               'Jan','Feb','Mar','Apr',
// // //                               'May','Jun','Jul','Aug',
// // //                               'Sep','Oct','Nov','Dec'
// // //                             ];
// // //                             final idx = ((DateTime.now().month -
// // //                                         6 +
// // //                                         value.toInt()) %
// // //                                     12);
// // //                             return Padding(
// // //                               padding: const EdgeInsets.only(
// // //                                   top: 8),
// // //                               child: Text(months[idx],
// // //                                   style: TextStyle(
// // //                                       fontSize:
// // //                                           isMobile ? 10 : 12,
// // //                                       color: const Color(
// // //                                           0xFF64748B))),
// // //                             );
// // //                           },
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     borderData: FlBorderData(show: false),
// // //                     lineBarsData: [
// // //                       LineChartBarData(
// // //                         spots: spots,
// // //                         isCurved: true,
// // //                         color: const Color(0xFF0891B2),
// // //                         barWidth: 2,
// // //                         belowBarData: BarAreaData(
// // //                           show: true,
// // //                           gradient: LinearGradient(
// // //                             begin: Alignment.topCenter,
// // //                             end: Alignment.bottomCenter,
// // //                             colors: [
// // //                               const Color(0xFF0891B2)
// // //                                   .withOpacity(0.3),
// // //                               const Color(0xFF0891B2)
// // //                                   .withOpacity(0.0),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                         dotData: const FlDotData(show: false),
// // //                       ),
// // //                     ],
// // //                   )),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─── Material Inventory ───────────────────────────────────────────────────────
// // // class _MaterialInventory extends StatelessWidget {
// // //   final Map<String, dynamic>? calcData;
// // //   const _MaterialInventory({required this.calcData});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isMobile = _Screen.isMobile(context);
// // //     final grand    = calcData?['grand_total']  ?? {};
// // //     final red      = calcData?['red_brick']    ?? {};
// // //     final white    = calcData?['white_cement'] ?? {};

// // //     final List<Map<String, dynamic>> items = calcData != null
// // //         ? [
// // //             {'name': 'Red Bricks (9")',  'value': '${red['final_with_10pct']   ?? 0} nos', 'percent': 'Final', 'color': const Color(0xFFDC2626)},
// // //             {'name': 'Cement Blocks',    'value': '${white['final_with_10pct'] ?? 0} nos', 'percent': 'Final', 'color': const Color(0xFF0891B2)},
// // //             {'name': 'Total Bricks',     'value': '${grand['final_bricks']     ?? 0} nos', 'percent': '+10%',  'color': const Color(0xFF0F172A)},
// // //             {'name': 'Deducted',         'value': '${grand['total_deducted']   ?? 0} nos', 'percent': 'openings','color': const Color(0xFF64748B)},
// // //           ]
// // //         : [
// // //             {'name': 'Steel',            'percent': '—', 'value': 'No data', 'color': const Color(0xFF3B82F6)},
// // //             {'name': 'Cement',           'percent': '—', 'value': 'No data', 'color': const Color(0xFF0891B2)},
// // //             {'name': 'Sand/Aggregates',  'percent': '—', 'value': 'No data', 'color': const Color(0xFF14B8A6)},
// // //             {'name': 'Bricks',           'percent': '—', 'value': 'No data', 'color': const Color(0xFFDC2626)},
// // //           ];

// // //     Widget buildItem(Map<String, dynamic> item) {
// // //       return Padding(
// // //         padding: EdgeInsets.symmetric(
// // //             vertical: isMobile ? 8 : 10),
// // //         child: Row(children: [
// // //           Container(
// // //             width: 8, height: 8,
// // //             decoration: BoxDecoration(
// // //                 color: item['color'],
// // //                 borderRadius: BorderRadius.circular(4)),
// // //           ),
// // //           const SizedBox(width: 10),
// // //           Expanded(
// // //             child: Text(item['name'],
// // //                 style: TextStyle(
// // //                     fontSize: isMobile ? 12 : 13,
// // //                     fontWeight: FontWeight.w500,
// // //                     color: const Color(0xFF334155)),
// // //                 overflow: TextOverflow.ellipsis),
// // //           ),
// // //           Text(item['percent'],
// // //               style: TextStyle(
// // //                   fontSize: isMobile ? 11 : 12,
// // //                   color: const Color(0xFF64748B))),
// // //           const SizedBox(width: 10),
// // //           Text(item['value'],
// // //               style: TextStyle(
// // //                   fontSize: isMobile ? 11 : 12,
// // //                   fontWeight: FontWeight.w600,
// // //                   color: const Color(0xFF1E293B))),
// // //         ]),
// // //       );
// // //     }

// // //     return Container(
// // //       padding: EdgeInsets.all(isMobile ? 16 : 20),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: const Color(0xFFE2E8F0)),
// // //       ),
// // //       child: isMobile
// // //           ? Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 _invHeader(isMobile),
// // //                 const SizedBox(height: 8),
// // //                 ListView.separated(
// // //                   shrinkWrap: true,
// // //                   physics: const NeverScrollableScrollPhysics(),
// // //                   itemCount: items.length,
// // //                   separatorBuilder: (_, __) => const Divider(
// // //                       color: Color(0xFFF1F5F9), height: 1),
// // //                   itemBuilder: (_, i) => buildItem(items[i]),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 _viewBtn(isMobile),
// // //               ],
// // //             )
// // //           : Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 _invHeader(isMobile),
// // //                 const SizedBox(height: 8),
// // //                 Expanded(
// // //                   child: ListView.separated(
// // //                     physics: const ClampingScrollPhysics(),
// // //                     itemCount: items.length,
// // //                     separatorBuilder: (_, __) => const Divider(
// // //                         color: Color(0xFFF1F5F9), height: 1),
// // //                     itemBuilder: (_, i) => buildItem(items[i]),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 10),
// // //                 _viewBtn(isMobile),
// // //               ],
// // //             ),
// // //     );
// // //   }

// // //   Widget _invHeader(bool isMobile) => Row(
// // //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //     children: [
// // //       Expanded(
// // //         child: Text(
// // //           calcData != null ? 'Latest Calculation' : 'Material Overview',
// // //           style: TextStyle(
// // //               fontSize: isMobile ? 14 : 15,
// // //               fontWeight: FontWeight.w600,
// // //               color: const Color(0xFF1E293B)),
// // //           overflow: TextOverflow.ellipsis),
// // //       ),
// // //       IconButton(
// // //           icon: const Icon(Icons.more_vert, size: 20),
// // //           onPressed: () {}),
// // //     ],
// // //   );

// // //   Widget _viewBtn(bool isMobile) => SizedBox(
// // //     width: double.infinity,
// // //     child: TextButton(
// // //       onPressed: () {},
// // //       style: TextButton.styleFrom(
// // //         backgroundColor: const Color(0xFFECFEFF),
// // //         foregroundColor: const Color(0xFF0891B2),
// // //         padding: EdgeInsets.symmetric(
// // //             vertical: isMobile ? 10 : 11),
// // //         shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(8)),
// // //       ),
// // //       child: Text(
// // //         calcData != null
// // //             ? 'View Full Calculation'
// // //             : 'Upload Plan to Calculate',
// // //         style: TextStyle(fontSize: isMobile ? 12 : 13)),
// // //     ),
// // //   );
// // // }

// // // // ─── Recent Projects Table ────────────────────────────────────────────────────
// // // class _RecentProjectsTable extends StatelessWidget {
// // //   final List<dynamic> projects;
// // //   const _RecentProjectsTable({required this.projects});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isMobile = _Screen.isMobile(context);
// // //     final recent   = projects.take(5).toList();

// // //     return Container(
// // //       padding: EdgeInsets.all(isMobile ? 16 : 24),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: const Color(0xFFE2E8F0)),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Row(
// // //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //             children: [
// // //               Text('Recent Projects',
// // //                   style: TextStyle(
// // //                       fontSize: isMobile ? 15 : 18,
// // //                       fontWeight: FontWeight.w600,
// // //                       color: const Color(0xFF1E293B))),
// // //               TextButton(
// // //                   onPressed: () {},
// // //                   child: const Text('View All',
// // //                       style: TextStyle(
// // //                           color: Color(0xFF0891B2)))),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 16),
// // //           if (recent.isEmpty)
// // //             Center(
// // //               child: Padding(
// // //                 padding: const EdgeInsets.all(24),
// // //                 child: Column(children: [
// // //                   const Icon(LucideIcons.folderOpen,
// // //                       size: 40, color: Color(0xFF94A3B8)),
// // //                   const SizedBox(height: 8),
// // //                   const Text('No projects yet',
// // //                       style: TextStyle(
// // //                           color: Color(0xFF64748B))),
// // //                   const SizedBox(height: 4),
// // //                   const Text('Create a project to get started',
// // //                       style: TextStyle(
// // //                           fontSize: 12,
// // //                           color: Color(0xFF94A3B8))),
// // //                 ]),
// // //               ),
// // //             )
// // //           else if (isMobile)
// // //             _MobileProjectList(projects: recent)
// // //           else
// // //             _DesktopProjectTable(projects: recent),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─── Mobile card list ─────────────────────────────────────────────────────────
// // // class _MobileProjectList extends StatelessWidget {
// // //   final List<dynamic> projects;
// // //   const _MobileProjectList({required this.projects});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       children: projects.map((p) {
// // //         final status = p['status'] ?? 'active';
// // //         final statusColor = status == 'active'
// // //             ? const Color(0xFF10B981)
// // //             : status == 'completed'
// // //                 ? const Color(0xFF2563EB)
// // //                 : const Color(0xFFF59E0B);
// // //         final statusBg = status == 'active'
// // //             ? const Color(0xFFD1FAE5)
// // //             : status == 'completed'
// // //                 ? const Color(0xFFDBEAFE)
// // //                 : const Color(0xFFFEF3C7);

// // //         return Container(
// // //           margin: const EdgeInsets.only(bottom: 12),
// // //           padding: const EdgeInsets.all(14),
// // //           decoration: BoxDecoration(
// // //             color: const Color(0xFFF8FAFC),
// // //             borderRadius: BorderRadius.circular(10),
// // //             border: Border.all(color: const Color(0xFFE2E8F0)),
// // //           ),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Row(children: [
// // //                 Container(
// // //                   padding: const EdgeInsets.all(8),
// // //                   decoration: BoxDecoration(
// // //                       color: const Color(0xFFF1F5F9),
// // //                       borderRadius: BorderRadius.circular(8)),
// // //                   child: const Icon(LucideIcons.building2,
// // //                       size: 18, color: Color(0xFF475569)),
// // //                 ),
// // //                 const SizedBox(width: 10),
// // //                 Expanded(
// // //                   child: Text(p['name'] ?? 'Unnamed',
// // //                       style: const TextStyle(
// // //                           fontWeight: FontWeight.w600,
// // //                           color: Color(0xFF1E293B),
// // //                           fontSize: 13),
// // //                       overflow: TextOverflow.ellipsis),
// // //                 ),
// // //                 Container(
// // //                   padding: const EdgeInsets.symmetric(
// // //                       horizontal: 8, vertical: 3),
// // //                   decoration: BoxDecoration(
// // //                       color: statusBg,
// // //                       borderRadius: BorderRadius.circular(999)),
// // //                   child: Text(
// // //                     _cap(status),
// // //                     style: TextStyle(
// // //                         fontSize: 11,
// // //                         fontWeight: FontWeight.w500,
// // //                         color: statusColor),
// // //                   ),
// // //                 ),
// // //               ]),
// // //               const SizedBox(height: 10),
// // //               Row(children: [
// // //                 _InfoChip(
// // //                     label: 'Description',
// // //                     value: p['description'] ?? '—'),
// // //                 const SizedBox(width: 16),
// // //                 _InfoChip(
// // //                     label: 'Created',
// // //                     value: _formatDate(p['created_at'] ?? '')),
// // //               ]),
// // //             ],
// // //           ),
// // //         );
// // //       }).toList(),
// // //     );
// // //   }
// // // }

// // // class _InfoChip extends StatelessWidget {
// // //   final String label;
// // //   final String value;
// // //   const _InfoChip({required this.label, required this.value});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(label,
// // //             style: const TextStyle(
// // //                 fontSize: 10, color: Color(0xFF94A3B8))),
// // //         Text(value,
// // //             style: const TextStyle(
// // //                 fontSize: 12,
// // //                 fontWeight: FontWeight.w600,
// // //                 color: Color(0xFF1E293B))),
// // //       ],
// // //     );
// // //   }
// // // }

// // // // ─── Desktop table ────────────────────────────────────────────────────────────
// // // class _DesktopProjectTable extends StatelessWidget {
// // //   final List<dynamic> projects;
// // //   const _DesktopProjectTable({required this.projects});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isTablet = _Screen.isTablet(context);

// // //     return SingleChildScrollView(
// // //       scrollDirection: Axis.horizontal,
// // //       child: Theme(
// // //         data: Theme.of(context)
// // //             .copyWith(dividerColor: const Color(0xFFE2E8F0)),
// // //         child: DataTable(
// // //           headingRowColor:
// // //               WidgetStateProperty.all(const Color(0xFFF8FAFC)),
// // //           columnSpacing: isTablet ? 16 : 24,
// // //           dataRowMinHeight: 52,
// // //           dataRowMaxHeight: 64,
// // //           columns: const [
// // //             DataColumn(label: Text('Project',    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
// // //             DataColumn(label: Text('Description',style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
// // //             DataColumn(label: Text('Status',     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
// // //             DataColumn(label: Text('Created',    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
// // //             DataColumn(label: Text('Owner',      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
// // //           ],
// // //           rows: projects.map((p) {
// // //             final status = p['status'] ?? 'active';
// // //             final statusColor = status == 'active'
// // //                 ? const Color(0xFF10B981)
// // //                 : status == 'completed'
// // //                     ? const Color(0xFF2563EB)
// // //                     : const Color(0xFFF59E0B);
// // //             final statusBg = status == 'active'
// // //                 ? const Color(0xFFD1FAE5)
// // //                 : status == 'completed'
// // //                     ? const Color(0xFFDBEAFE)
// // //                     : const Color(0xFFFEF3C7);

// // //             return DataRow(cells: [
// // //               DataCell(Row(children: [
// // //                 Container(
// // //                     padding: const EdgeInsets.all(7),
// // //                     decoration: BoxDecoration(
// // //                         color: const Color(0xFFF1F5F9),
// // //                         borderRadius: BorderRadius.circular(8)),
// // //                     child: const Icon(LucideIcons.building2,
// // //                         size: 18, color: Color(0xFF475569))),
// // //                 const SizedBox(width: 10),
// // //                 Text(p['name'] ?? 'Unnamed',
// // //                     style: const TextStyle(
// // //                         fontWeight: FontWeight.w500,
// // //                         color: Color(0xFF1E293B),
// // //                         fontSize: 13)),
// // //               ])),
// // //               DataCell(Text(p['description'] ?? '—',
// // //                   style: const TextStyle(
// // //                       color: Color(0xFF64748B), fontSize: 13),
// // //                   overflow: TextOverflow.ellipsis)),
// // //               DataCell(Container(
// // //                 padding: const EdgeInsets.symmetric(
// // //                     horizontal: 10, vertical: 4),
// // //                 decoration: BoxDecoration(
// // //                     color: statusBg,
// // //                     borderRadius: BorderRadius.circular(999)),
// // //                 child: Text(
// // //                   _cap(status),
// // //                   style: TextStyle(
// // //                       fontSize: 12,
// // //                       fontWeight: FontWeight.w500,
// // //                       color: statusColor),
// // //                 ),
// // //               )),
// // //               DataCell(Text(_formatDate(p['created_at'] ?? ''),
// // //                   style: const TextStyle(
// // //                       color: Color(0xFF64748B), fontSize: 13))),
// // //               DataCell(Text(
// // //                 p['owner_id'] != null ? 'Admin' : '—',
// // //                 style: const TextStyle(
// // //                     color: Color(0xFF64748B), fontSize: 13),
// // //               )),
// // //             ]);
// // //           }).toList(),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:lucide_icons_flutter/lucide_icons.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:fl_chart/fl_chart.dart';
// // import '../services/api_service.dart';

// // class Dashboard extends StatefulWidget {
// //   const Dashboard({super.key});

// //   @override
// //   State<Dashboard> createState() => _DashboardState();
// // }

// // class _DashboardState extends State<Dashboard> {
// //   bool                       _loading    = true;
// //   List<dynamic>              _projects   = [];
// //   Map<String, dynamic>?      _settings;
// //   Map<String, dynamic>?      _selected;
// //   Map<String, dynamic>?      _estimation;
// //   bool                       _loadingEst = false;
// //   List<Map<String, dynamic>> _allEstimations = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _load();
// //   }

// //   Future<void> _load() async {
// //     setState(() => _loading = true);
// //     try {
// //       final results = await Future.wait([
// //         ApiService.getProjects(),
// //         ApiService.getSettings(),
// //       ]);
// //       final projects = results[0] as List<dynamic>;
// //       final settings = results[1] as Map<String, dynamic>;

// //       final allEsts = <Map<String, dynamic>>[];
// //       for (final p in projects) {
// //         try {
// //           final ests = await ApiService.getEstimations(p['id']);
// //           if (ests.isNotEmpty) {
// //             allEsts.add({
// //               'project_id':   p['id'],
// //               'project_name': p['name'] ?? 'Unnamed',
// //               'status':       p['status'] ?? 'active',
// //               'estimation':   ests.last,
// //             });
// //           }
// //         } catch (_) {}
// //       }

// //       if (mounted) {
// //         setState(() {
// //           _projects       = projects;
// //           _settings       = settings;
// //           _allEstimations = allEsts;
// //           _loading        = false;
// //         });
// //       }
// //     } catch (e) {
// //       if (mounted) setState(() => _loading = false);
// //     }
// //   }

// //   Future<void> _selectProject(Map<String, dynamic> project) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setString('current_project_id',   project['id']);
// //     await prefs.setString('current_project_name', project['name'] ?? '');
// //     setState(() { _selected = project; _loadingEst = true; });
// //     try {
// //       final ests = await ApiService.getEstimations(project['id']);
// //       if (mounted) {
// //         setState(() {
// //           _estimation = ests.isNotEmpty ? ests.last : null;
// //           _loadingEst = false;
// //         });
// //       }
// //     } catch (e) {
// //       if (mounted) setState(() { _estimation = null; _loadingEst = false; });
// //     }
// //   }

// //   static double _d(dynamic v) =>
// //       v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);
// //   static int _i(dynamic v) =>
// //       v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

// //   String _fmt(double v) {
// //     if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
// //     if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)} L';
// //     if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
// //     return '₹${v.toStringAsFixed(0)}';
// //   }

// //   double _projectCost(Map<String, dynamic> est) {
// //     final snap = est['estimation']['formula_snapshot'];
// //     double cost = _d(snap?['cost_summary']?['total']);
// //     if (cost == 0) cost = _i(est['estimation']['total_bricks']) * 10.35;
// //     return cost;
// //   }

// //   Map<String, dynamic> get _combinedMaterials {
// //     int    redBricks   = 0;
// //     int    whiteBricks = 0;
// //     double cementBags  = 0;
// //     double sandTons    = 0;
// //     for (final e in _allEstimations) {
// //       final snap = e['estimation']['formula_snapshot'];
// //       redBricks   += _i(snap?['red_brick']?['final_with_10pct']);
// //       whiteBricks += _i(snap?['white_cement']?['final_with_10pct']);
// //       cementBags  += _d(snap?['cement']?['total_bags']);
// //       sandTons    += _d(snap?['sand']?['total_tons']);
// //     }
// //     return {
// //       'red_bricks':    redBricks,
// //       'white_bricks':  whiteBricks,
// //       'total_bricks':  redBricks + whiteBricks,
// //       'cement_bags':   cementBags,
// //       'sand_tons':     sandTons,
// //     };
// //   }

// //   double get _grandTotalCost =>
// //       _allEstimations.fold(0.0, (s, e) => s + _projectCost(e));

// //   // ── Bar chart colors ─────────────────────────────────────
// //   final _barColors = const [
// //     Color(0xFF1E6FD9),
// //     Color(0xFF10B981),
// //     Color(0xFFF59E0B),
// //     Color(0xFF7C3AED),
// //     Color(0xFFDC2626),
// //     Color(0xFF0D9488),
// //     Color(0xFFF97316),
// //     Color(0xFF06B6D4),
// //   ];

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_loading) {
// //       return const Center(
// //           child: CircularProgressIndicator(color: Color(0xFF1E6FD9)));
// //     }

// //     final totalProjects  = _projects.length;
// //     final activeProjects = _projects.where((p) => p['status'] == 'active').length;
// //     final combined       = _combinedMaterials;

// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [

// //         // ── Header ──────────────────────────────────────────
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             const Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text('Dashboard',
// //                     style: TextStyle(
// //                         fontSize: 24,
// //                         fontWeight: FontWeight.bold,
// //                         color: Color(0xFF1E293B))),
// //                 SizedBox(height: 4),
// //                 Text('Overview of all your projects',
// //                     style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
// //               ],
// //             ),
// //             Row(children: [
// //               IconButton(
// //                 onPressed: _load,
// //                 icon: const Icon(LucideIcons.refreshCw,
// //                     size: 18, color: Color(0xFF64748B)),
// //               ),
// //               const SizedBox(width: 8),
// //               ElevatedButton.icon(
// //                 onPressed: () => context.go('/project-creation'),
// //                 icon: const Icon(LucideIcons.plus, size: 16),
// //                 label: const Text('New Project'),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: const Color(0xFF1E6FD9),
// //                   foregroundColor: Colors.white,
// //                   shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8)),
// //                 ),
// //               ),
// //             ]),
// //           ],
// //         ),
// //         const SizedBox(height: 20),

// //         // ── Top 3 stat cards ─────────────────────────────────
// //         Row(children: [
// //           _topCard('Total Projects', '$totalProjects',
// //               'All projects',
// //               const Color(0xFF1E6FD9), const Color(0xFFEFF6FF),
// //               LucideIcons.folder),
// //           const SizedBox(width: 16),
// //           _topCard('Active Projects', '$activeProjects',
// //               'Currently active',
// //               const Color(0xFF10B981), const Color(0xFFECFDF5),
// //               LucideIcons.activity),
// //           const SizedBox(width: 16),
// //           _topCard('Grand Total Est.',
// //               _allEstimations.isEmpty ? 'No data' : _fmt(_grandTotalCost),
// //               'Across all projects',
// //               const Color(0xFFF59E0B), const Color(0xFFFFFBEB),
// //               LucideIcons.indianRupee),
// //         ]),
// //         const SizedBox(height: 20),

// //         // ── Main 3-column layout ─────────────────────────────
// //         Expanded(
// //           child: Row(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [

// //               // ── LEFT: Project List ──────────────────────────
// //               SizedBox(
// //                 width: 230,
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         const Text('Projects',
// //                             style: TextStyle(
// //                                 fontSize: 15,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Color(0xFF1E293B))),
// //                         Text('${_projects.length} total',
// //                             style: const TextStyle(
// //                                 fontSize: 12,
// //                                 color: Color(0xFF64748B))),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 10),
// //                     Expanded(
// //                       child: _projects.isEmpty
// //                           ? _emptyProjects()
// //                           : ListView.separated(
// //                               itemCount: _projects.length,
// //                               separatorBuilder: (_, __) =>
// //                                   const SizedBox(height: 6),
// //                               itemBuilder: (_, i) {
// //                                 final p = _projects[i];
// //                                 final isSelected =
// //                                     _selected?['id'] == p['id'];
// //                                 final ests = _allEstimations
// //                                     .where((e) => e['project_id'] == p['id'])
// //                                     .toList();
// //                                 return _projectTile(
// //                                     p, isSelected, ests);
// //                               },
// //                             ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               const SizedBox(width: 16),

// //               // ── MIDDLE: Bar Chart ───────────────────────────
// //               Expanded(
// //                 flex: 2,
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text('Project Cost Overview',
// //                         style: TextStyle(
// //                             fontSize: 15,
// //                             fontWeight: FontWeight.w600,
// //                             color: Color(0xFF1E293B))),
// //                     const SizedBox(height: 10),
// //                     Expanded(
// //                       child: _allEstimations.isEmpty
// //                           ? _noData()
// //                           : _buildBarChart(),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               const SizedBox(width: 16),

// //               // ── RIGHT: Materials Summary ────────────────────
// //               SizedBox(
// //                 width: 210,
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text('Combined Materials',
// //                         style: TextStyle(
// //                             fontSize: 15,
// //                             fontWeight: FontWeight.w600,
// //                             color: Color(0xFF1E293B))),
// //                     const SizedBox(height: 4),
// //                     Text('All ${_allEstimations.length} projects',
// //                         style: const TextStyle(
// //                             fontSize: 11,
// //                             color: Color(0xFF94A3B8))),
// //                     const SizedBox(height: 10),
// //                     Expanded(
// //                       child: _allEstimations.isEmpty
// //                           ? _noData()
// //                           : _buildMaterialsSummary(combined),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),

// //         // ── Bottom: Project Detail Panel ─────────────────────
// //         if (_selected != null) ...[
// //           const SizedBox(height: 16),
// //           _buildDetailPanel(),
// //         ],
// //       ],
// //     );
// //   }

// //   // ── Top Stat Card ────────────────────────────────────────
// //   Widget _topCard(String label, String value, String sub,
// //       Color color, Color bg, IconData icon) {
// //     return Expanded(
// //       child: Container(
// //         padding: const EdgeInsets.all(20),
// //         decoration: BoxDecoration(
// //           color: bg,
// //           borderRadius: BorderRadius.circular(12),
// //           border: Border.all(color: color.withOpacity(0.2)),
// //         ),
// //         child: Row(children: [
// //           Container(
// //             padding: const EdgeInsets.all(12),
// //             decoration: BoxDecoration(
// //               color: color.withOpacity(0.1),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Icon(icon, size: 22, color: color),
// //           ),
// //           const SizedBox(width: 14),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(label,
// //                     style: TextStyle(
// //                         fontSize: 12, color: color.withOpacity(0.8))),
// //                 const SizedBox(height: 4),
// //                 Text(value,
// //                     style: TextStyle(
// //                         fontSize: 22,
// //                         fontWeight: FontWeight.bold,
// //                         color: color)),
// //                 Text(sub,
// //                     style: TextStyle(
// //                         fontSize: 11, color: color.withOpacity(0.6))),
// //               ],
// //             ),
// //           ),
// //         ]),
// //       ),
// //     );
// //   }

// //   // ── Project Tile ─────────────────────────────────────────
// //   Widget _projectTile(
// //     Map<String, dynamic> project,
// //     bool isSelected,
// //     List<Map<String, dynamic>> ests,
// //   ) {
// //     final name     = project['name']   ?? 'Unnamed';
// //     final status   = project['status'] ?? 'active';
// //     final hasCost  = ests.isNotEmpty;
// //     final cost     = hasCost ? _projectCost(ests.first) : 0.0;

// //     return InkWell(
// //       onTap: () => _selectProject(project),
// //       borderRadius: BorderRadius.circular(10),
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 200),
// //         padding: const EdgeInsets.all(12),
// //         decoration: BoxDecoration(
// //           color: isSelected
// //               ? const Color(0xFFEFF6FF) : Colors.white,
// //           borderRadius: BorderRadius.circular(10),
// //           border: Border.all(
// //             color: isSelected
// //                 ? const Color(0xFF1E6FD9)
// //                 : const Color(0xFFE2E8F0),
// //             width: isSelected ? 2 : 1,
// //           ),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(children: [
// //               Container(
// //                 width: 32, height: 32,
// //                 decoration: BoxDecoration(
// //                   color: isSelected
// //                       ? const Color(0xFF1E6FD9)
// //                       : const Color(0xFFF1F5F9),
// //                   borderRadius: BorderRadius.circular(8),
// //                 ),
// //                 child: Icon(LucideIcons.building2,
// //                     size: 16,
// //                     color: isSelected
// //                         ? Colors.white
// //                         : const Color(0xFF64748B)),
// //               ),
// //               const SizedBox(width: 8),
// //               Expanded(
// //                 child: Text(name,
// //                     style: TextStyle(
// //                         fontWeight: FontWeight.w600,
// //                         fontSize: 13,
// //                         color: isSelected
// //                             ? const Color(0xFF1E6FD9)
// //                             : const Color(0xFF1E293B)),
// //                     overflow: TextOverflow.ellipsis),
// //               ),
// //             ]),
// //             const SizedBox(height: 6),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Container(
// //                   padding: const EdgeInsets.symmetric(
// //                       horizontal: 6, vertical: 2),
// //                   decoration: BoxDecoration(
// //                     color: status == 'active'
// //                         ? const Color(0xFFECFDF5)
// //                         : const Color(0xFFF1F5F9),
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                   child: Text(status,
// //                       style: TextStyle(
// //                           fontSize: 10,
// //                           fontWeight: FontWeight.w600,
// //                           color: status == 'active'
// //                               ? const Color(0xFF10B981)
// //                               : const Color(0xFF64748B))),
// //                 ),
// //                 Text(
// //                   hasCost ? _fmt(cost) : 'No est.',
// //                   style: TextStyle(
// //                       fontSize: 12,
// //                       fontWeight: FontWeight.w600,
// //                       color: hasCost
// //                           ? const Color(0xFF1E6FD9)
// //                           : const Color(0xFF94A3B8)),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ── Bar Chart (Vertical) ─────────────────────────────────
// //   Widget _buildBarChart() {
// //     final chartData = _allEstimations.asMap().entries.map((e) {
// //       return {
// //         'index': e.key,
// //         'name':  e.value['project_name'] as String,
// //         'cost':  _projectCost(e.value),
// //       };
// //     }).toList();

// //     double maxCost = chartData.fold(
// //         0.0, (m, e) => (e['cost'] as double) > m ? e['cost'] as double : m);
// //     if (maxCost == 0) maxCost = 100000;
// //     final maxY = maxCost * 1.35;

// //     return Container(
// //       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: const Color(0xFFE2E8F0)),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               const Text('Estimated Cost per Project',
// //                   style: TextStyle(
// //                       fontSize: 13,
// //                       fontWeight: FontWeight.w600,
// //                       color: Color(0xFF475569))),
// //               Container(
// //                 padding: const EdgeInsets.symmetric(
// //                     horizontal: 8, vertical: 4),
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFFEFF6FF),
// //                   borderRadius: BorderRadius.circular(6),
// //                 ),
// //                 child: Text(
// //                   'Total: ${_fmt(_grandTotalCost)}',
// //                   style: const TextStyle(
// //                       fontSize: 11,
// //                       fontWeight: FontWeight.w600,
// //                       color: Color(0xFF1E6FD9)),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Expanded(
// //             child: BarChart(
// //               BarChartData(
// //                 alignment: BarChartAlignment.spaceAround,
// //                 maxY: maxY,
// //                 minY: 0,
// //                 barTouchData: BarTouchData(
// //                   enabled: true,
// //                   touchTooltipData: BarTouchTooltipData(
// //                     getTooltipColor: (_) =>
// //                         const Color(0xFF0F172A),
// //                     tooltipPadding: const EdgeInsets.symmetric(
// //                         horizontal: 12, vertical: 8),
// //                     getTooltipItem: (group, gi, rod, ri) {
// //                       final item = chartData[gi];
// //                       return BarTooltipItem(
// //                         '${item['name']}\n',
// //                         const TextStyle(
// //                             color: Colors.white60,
// //                             fontSize: 11),
// //                         children: [
// //                           TextSpan(
// //                             text: _fmt(item['cost'] as double),
// //                             style: const TextStyle(
// //                                 color: Colors.white,
// //                                 fontWeight: FontWeight.bold,
// //                                 fontSize: 13),
// //                           ),
// //                         ],
// //                       );
// //                     },
// //                   ),
// //                   touchCallback: (event, response) {
// //                     if (event is FlTapUpEvent &&
// //                         response?.spot != null) {
// //                       final idx =
// //                           response!.spot!.touchedBarGroupIndex;
// //                       if (idx >= 0 && idx < _projects.length) {
// //                         _selectProject(_projects[idx]);
// //                       }
// //                     }
// //                   },
// //                 ),
// //                 titlesData: FlTitlesData(
// //                   show: true,
// //                   bottomTitles: AxisTitles(
// //                     sideTitles: SideTitles(
// //                       showTitles: true,
// //                       reservedSize: 40,
// //                       getTitlesWidget: (value, meta) {
// //                         final idx = value.toInt();
// //                         if (idx < 0 || idx >= chartData.length) {
// //                           return const SizedBox();
// //                         }
// //                         final name =
// //                             chartData[idx]['name'] as String;
// //                         final isSelected =
// //                             _selected?['name'] == name;
// //                         return Padding(
// //                           padding: const EdgeInsets.only(top: 6),
// //                           child: Column(
// //                             mainAxisSize: MainAxisSize.min,
// //                             children: [
// //                               if (isSelected)
// //                                 Container(
// //                                   width: 6, height: 6,
// //                                   decoration: const BoxDecoration(
// //                                     color: Color(0xFF1E6FD9),
// //                                     shape: BoxShape.circle,
// //                                   ),
// //                                 ),
// //                               Text(
// //                                 name.length > 9
// //                                     ? '${name.substring(0, 9)}..'
// //                                     : name,
// //                                 style: TextStyle(
// //                                     fontSize: 10,
// //                                     fontWeight: isSelected
// //                                         ? FontWeight.w700
// //                                         : FontWeight.normal,
// //                                     color: isSelected
// //                                         ? const Color(0xFF1E6FD9)
// //                                         : const Color(0xFF94A3B8)),
// //                               ),
// //                             ],
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                   leftTitles: AxisTitles(
// //                     sideTitles: SideTitles(
// //                       showTitles: true,
// //                       reservedSize: 56,
// //                       interval: maxY / 4,
// //                       getTitlesWidget: (value, meta) {
// //                         if (value == 0) return const SizedBox();
// //                         return Padding(
// //                           padding: const EdgeInsets.only(right: 4),
// //                           child: Text(
// //                             _fmt(value),
// //                             style: const TextStyle(
// //                                 fontSize: 9,
// //                                 color: Color(0xFF94A3B8)),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                   topTitles: const AxisTitles(
// //                       sideTitles: SideTitles(showTitles: false)),
// //                   rightTitles: const AxisTitles(
// //                       sideTitles: SideTitles(showTitles: false)),
// //                 ),
// //                 gridData: FlGridData(
// //                   show: true,
// //                   drawVerticalLine: false,
// //                   horizontalInterval: maxY / 4,
// //                   getDrawingHorizontalLine: (_) => const FlLine(
// //                     color: Color(0xFFF1F5F9),
// //                     strokeWidth: 1,
// //                   ),
// //                 ),
// //                 borderData: FlBorderData(
// //                   show: true,
// //                   border: const Border(
// //                     bottom: BorderSide(
// //                         color: Color(0xFFE2E8F0), width: 1),
// //                     left: BorderSide(
// //                         color: Color(0xFFE2E8F0), width: 1),
// //                   ),
// //                 ),
// //                 barGroups: chartData.asMap().entries.map((e) {
// //                   final idx       = e.key;
// //                   final item      = e.value;
// //                   final cost      = item['cost'] as double;
// //                   final name      = item['name'] as String;
// //                   final isSelected = _selected?['name'] == name;
// //                   final color     = _barColors[idx % _barColors.length];

// //                   return BarChartGroupData(
// //                     x: idx,
// //                     barRods: [
// //                       BarChartRodData(
// //                         toY: cost,
// //                         width: chartData.length <= 3
// //                             ? 50
// //                             : chartData.length <= 6
// //                                 ? 36
// //                                 : 24,
// //                         borderRadius: const BorderRadius.vertical(
// //                             top: Radius.circular(6)),
// //                         gradient: LinearGradient(
// //                           begin: Alignment.bottomCenter,
// //                           end: Alignment.topCenter,
// //                           colors: isSelected
// //                               ? [
// //                                   const Color(0xFF1D4ED8),
// //                                   const Color(0xFF3B82F6),
// //                                   const Color(0xFF93C5FD),
// //                                 ]
// //                               : [
// //                                   color.withOpacity(0.6),
// //                                   color,
// //                                   color.withOpacity(0.85),
// //                                 ],
// //                         ),
// //                         backDrawRodData: BackgroundBarChartRodData(
// //                           show: true,
// //                           toY: maxY,
// //                           color: const Color(0xFFF8FAFC),
// //                         ),
// //                       ),
// //                     ],
// //                     showingTooltipIndicators:
// //                         isSelected ? [0] : [],
// //                   );
// //                 }).toList(),
// //               ),
// //               swapAnimationDuration:
// //                   const Duration(milliseconds: 400),
// //               swapAnimationCurve: Curves.easeInOut,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ── Materials Summary ────────────────────────────────────
// //   Widget _buildMaterialsSummary(Map<String, dynamic> combined) {
// //     final items = [
// //       {
// //         'label': 'Red Bricks',
// //         'value': '${combined['red_bricks']} pcs',
// //         'color': const Color(0xFFDC2626),
// //         'bg':    const Color(0xFFFEF2F2),
// //         'icon':  LucideIcons.layers,
// //       },
// //       {
// //         'label': 'White Blocks',
// //         'value': '${combined['white_bricks']} pcs',
// //         'color': const Color(0xFF1E6FD9),
// //         'bg':    const Color(0xFFEFF6FF),
// //         'icon':  LucideIcons.square,
// //       },
// //       {
// //         'label': 'Total Bricks',
// //         'value': '${combined['total_bricks']} pcs',
// //         'color': const Color(0xFF7C3AED),
// //         'bg':    const Color(0xFFF5F3FF),
// //         'icon':  LucideIcons.package,
// //       },
// //       {
// //         'label': 'Cement',
// //         'value':
// //             '${(_d(combined['cement_bags'])).toStringAsFixed(1)} bags',
// //         'color': const Color(0xFF0D9488),
// //         'bg':    const Color(0xFFF0FDFA),
// //         'icon':  LucideIcons.box,
// //       },
// //       {
// //         'label': 'Sand',
// //         'value':
// //             '${(_d(combined['sand_tons'])).toStringAsFixed(2)} tons',
// //         'color': const Color(0xFFF59E0B),
// //         'bg':    const Color(0xFFFFFBEB),
// //         'icon':  LucideIcons.mountain,
// //       },
// //     ];

// //     return SingleChildScrollView(
// //       child: Column(
// //         children: [
// //           // Total cost banner
// //           Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.all(14),
// //             decoration: BoxDecoration(
// //               gradient: const LinearGradient(
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //                 colors: [Color(0xFF0F172A), Color(0xFF1E6FD9)],
// //               ),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Text('TOTAL ESTIMATION',
// //                     style: TextStyle(
// //                         color: Colors.white60,
// //                         fontSize: 10,
// //                         letterSpacing: 1.2)),
// //                 const SizedBox(height: 4),
// //                 Text(_fmt(_grandTotalCost),
// //                     style: const TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 22,
// //                         fontWeight: FontWeight.bold)),
// //                 const SizedBox(height: 2),
// //                 Text(
// //                   '${_allEstimations.length} project${_allEstimations.length != 1 ? 's' : ''}',
// //                   style: const TextStyle(
// //                       color: Colors.white54, fontSize: 11),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(height: 10),
// //           ...items.map((item) => Container(
// //             margin: const EdgeInsets.only(bottom: 8),
// //             padding: const EdgeInsets.all(10),
// //             decoration: BoxDecoration(
// //               color: item['bg'] as Color,
// //               borderRadius: BorderRadius.circular(8),
// //               border: Border.all(
// //                   color: (item['color'] as Color).withOpacity(0.15)),
// //             ),
// //             child: Row(children: [
// //               Icon(item['icon'] as IconData,
// //                   size: 16, color: item['color'] as Color),
// //               const SizedBox(width: 8),
// //               Expanded(
// //                 child: Text(item['label'] as String,
// //                     style: TextStyle(
// //                         fontSize: 11,
// //                         color: (item['color'] as Color)
// //                             .withOpacity(0.8))),
// //               ),
// //               Text(item['value'] as String,
// //                   style: TextStyle(
// //                       fontSize: 12,
// //                       fontWeight: FontWeight.bold,
// //                       color: item['color'] as Color)),
// //             ]),
// //           )),
// //         ],
// //       ),
// //     );
// //   }

// //   // ── Project Detail Panel ─────────────────────────────────
// //   Widget _buildDetailPanel() {
// //     final p    = _selected!;
// //     final name = p['name'] ?? 'Project';
// //     final snap = _estimation?['formula_snapshot'];

// //     final redBricks   = _i(snap?['red_brick']?['final_with_10pct']);
// //     final whiteBricks = _i(snap?['white_cement']?['final_with_10pct']);
// //     final cementBags  = _d(snap?['cement']?['total_bags']);
// //     final sandTons    = _d(snap?['sand']?['total_tons']);
// //     final totalBricks = _i(snap?['grand_total']?['final_bricks']);
// //     final volCuM      = _d(snap?['volume_summary']?['net_volume_cum']);
// //     final floorArea = _d(snap?['ocr_summary']?['total_area_sqft'] ??
// //                      snap?['summary']?['total_area_sqft'] ??
// //                      snap?['zone_summary'] != null
// //                        ? (snap?['zone_summary'] as List?)
// //                            ?.fold(0.0, (s, z) => s + _d(z['area_sqft']))
// //                        : 0.0);
// //     double cost       = _d(snap?['cost_summary']?['total']);
// //     if (cost == 0 && _estimation != null) {
// //       cost = _i(_estimation?['total_bricks']) * 10.35;
// //     }

// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: const Color(0xFFE2E8F0)),
// //         boxShadow: [
// //           BoxShadow(
// //             color: const Color(0xFF1E6FD9).withOpacity(0.06),
// //             blurRadius: 12,
// //             offset: const Offset(0, -2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Row(children: [
// //             Container(
// //               padding: const EdgeInsets.all(8),
// //               decoration: BoxDecoration(
// //                 gradient: const LinearGradient(
// //                   colors: [Color(0xFF0F172A), Color(0xFF1E6FD9)],
// //                 ),
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: const Icon(LucideIcons.building2,
// //                   size: 16, color: Colors.white),
// //             ),
// //             const SizedBox(width: 10),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(name,
// //                       style: const TextStyle(
// //                           fontWeight: FontWeight.bold,
// //                           fontSize: 15,
// //                           color: Color(0xFF1E293B))),
// //                   Text(
// //                     cost > 0
// //                         ? 'Estimated: ${_fmt(cost)}'
// //                         : 'No estimation yet',
// //                     style: TextStyle(
// //                         fontSize: 12,
// //                         color: cost > 0
// //                             ? const Color(0xFF1E6FD9)
// //                             : const Color(0xFF94A3B8)),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             // Action buttons
// //             Wrap(
// //               spacing: 8,
// //               children: [
// //                 _actionChip('Upload Plan', LucideIcons.upload,
// //                     const Color(0xFF1E6FD9),
// //                     () => context.go('/upload')),
// //                 _actionChip('Costing', LucideIcons.calculator,
// //                     const Color(0xFF7C3AED),
// //                     () => context.go('/costing')),
// //                 _actionChip('BOQ Report', LucideIcons.fileText,
// //                     const Color(0xFF0D9488),
// //                     () => context.go('/review')),
// //                 _actionChip('Takeoff', LucideIcons.clipboardList,
// //                     const Color(0xFFF59E0B),
// //                     () => context.go('/takeoff')),
// //               ],
// //             ),
// //             const SizedBox(width: 8),
// //             IconButton(
// //               onPressed: () => setState(() {
// //                 _selected   = null;
// //                 _estimation = null;
// //               }),
// //               icon: const Icon(LucideIcons.x,
// //                   size: 16, color: Color(0xFF94A3B8)),
// //               tooltip: 'Close',
// //             ),
// //           ]),

// //           if (_loadingEst)
// //             const Padding(
// //               padding: EdgeInsets.symmetric(vertical: 12),
// //               child: Center(
// //                   child: CircularProgressIndicator(
// //                       color: Color(0xFF1E6FD9), strokeWidth: 2)),
// //             )
// //           else if (snap == null)
// //             Container(
// //               margin: const EdgeInsets.only(top: 12),
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFFFFFBEB),
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(
// //                     color: const Color(0xFFFDE68A)),
// //               ),
// //               child: Row(children: [
// //                 const Icon(LucideIcons.info,
// //                     size: 16, color: Color(0xFFF59E0B)),
// //                 const SizedBox(width: 8),
// //                 const Expanded(
// //                   child: Text(
// //                     'No estimation yet. Upload a floor plan and run Costing.',
// //                     style: TextStyle(
// //                         fontSize: 12,
// //                         color: Color(0xFF92400E)),
// //                   ),
// //                 ),
// //                 TextButton(
// //                   onPressed: () => context.go('/upload'),
// //                   child: const Text('Upload Now',
// //                       style: TextStyle(
// //                           color: Color(0xFFF59E0B),
// //                           fontWeight: FontWeight.w600)),
// //                 ),
// //               ]),
// //             )
// //           else ...[
// //             const SizedBox(height: 12),
// //             Row(children: [
// //               _detailStat('Floor Area',
// //                   '${floorArea.toStringAsFixed(0)} sqft',
// //                   const Color(0xFF1E6FD9),
// //                   LucideIcons.layoutDashboard),
// //               const SizedBox(width: 8),
// //               _detailStat('Total Bricks',
// //                   '$totalBricks pcs',
// //                   const Color(0xFFDC2626),
// //                   LucideIcons.layers),
// //               const SizedBox(width: 8),
// //               _detailStat('Red Bricks',
// //                   '$redBricks pcs',
// //                   const Color(0xFFDC2626),
// //                   LucideIcons.square),
// //               const SizedBox(width: 8),
// //               _detailStat('White Blocks',
// //                   '$whiteBricks pcs',
// //                   const Color(0xFF1E6FD9),
// //                   LucideIcons.square),
// //               const SizedBox(width: 8),
// //               _detailStat('Cement',
// //                   '${cementBags.toStringAsFixed(1)} bags',
// //                   const Color(0xFF7C3AED),
// //                   LucideIcons.package),
// //               const SizedBox(width: 8),
// //               _detailStat('Sand',
// //                   '${sandTons.toStringAsFixed(2)} tons',
// //                   const Color(0xFF0D9488),
// //                   LucideIcons.box),
// //               const SizedBox(width: 8),
// //               _detailStat('Volume',
// //                   '${volCuM.toStringAsFixed(2)} m³',
// //                   const Color(0xFFF59E0B),
// //                   LucideIcons.square),
// //             ]),
// //           ],
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _actionChip(String label, IconData icon,
// //       Color color, VoidCallback onTap) {
// //     return InkWell(
// //       onTap: onTap,
// //       borderRadius: BorderRadius.circular(8),
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(
// //             horizontal: 10, vertical: 6),
// //         decoration: BoxDecoration(
// //           color: color.withOpacity(0.08),
// //           borderRadius: BorderRadius.circular(8),
// //           border: Border.all(color: color.withOpacity(0.2)),
// //         ),
// //         child: Row(mainAxisSize: MainAxisSize.min, children: [
// //           Icon(icon, size: 13, color: color),
// //           const SizedBox(width: 4),
// //           Text(label,
// //               style: TextStyle(
// //                   fontSize: 11,
// //                   fontWeight: FontWeight.w600,
// //                   color: color)),
// //         ]),
// //       ),
// //     );
// //   }

// //   Widget _detailStat(String label, String value,
// //       Color color, IconData icon) {
// //     return Expanded(
// //       child: Container(
// //         padding: const EdgeInsets.all(10),
// //         decoration: BoxDecoration(
// //           color: color.withOpacity(0.05),
// //           borderRadius: BorderRadius.circular(8),
// //           border: Border.all(color: color.withOpacity(0.15)),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Icon(icon, size: 14, color: color),
// //             const SizedBox(height: 4),
// //             Text(value,
// //                 style: TextStyle(
// //                     fontSize: 12,
// //                     fontWeight: FontWeight.bold,
// //                     color: color),
// //                 overflow: TextOverflow.ellipsis),
// //             Text(label,
// //                 style: const TextStyle(
// //                     fontSize: 10,
// //                     color: Color(0xFF94A3B8))),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _emptyProjects() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           const Icon(LucideIcons.folderOpen,
// //               size: 36, color: Color(0xFF94A3B8)),
// //           const SizedBox(height: 8),
// //           const Text('No projects yet',
// //               style: TextStyle(
// //                   fontWeight: FontWeight.w600,
// //                   color: Color(0xFF64748B))),
// //           const SizedBox(height: 12),
// //           ElevatedButton.icon(
// //             onPressed: () => context.go('/project-creation'),
// //             icon: const Icon(LucideIcons.plus, size: 14),
// //             label: const Text('Create Project'),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF1E6FD9),
// //               foregroundColor: Colors.white,
// //               shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(8)),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _noData() {
// //     return Container(
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: const Color(0xFFE2E8F0)),
// //       ),
// //       child: const Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(LucideIcons.chartBar200,
// //                 size: 32, color: Color(0xFF94A3B8)),
// //             SizedBox(height: 8),
// //             Text('No estimations yet',
// //                 style: TextStyle(
// //                     color: Color(0xFF64748B),
// //                     fontWeight: FontWeight.w500)),
// //             SizedBox(height: 4),
// //             Text('Upload floor plans and run Costing',
// //                 style: TextStyle(
// //                     fontSize: 11, color: Color(0xFF94A3B8))),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:go_router/go_router.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../services/api_service.dart';

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   bool                       _loading    = true;
//   List<dynamic>              _projects   = [];
//   Map<String, dynamic>?      _settings;
//   Map<String, dynamic>?      _selected;
//   Map<String, dynamic>?      _estimation;
//   bool                       _loadingEst = false;
//   List<Map<String, dynamic>> _allEstimations = [];

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final results = await Future.wait([
//         ApiService.getProjects(),
//         ApiService.getSettings(),
//       ]);
//       final projects = results[0] as List<dynamic>;
//       final settings = results[1] as Map<String, dynamic>;

//       final allEsts = <Map<String, dynamic>>[];
//       for (final p in projects) {
//         try {
//           final ests = await ApiService.getEstimations(p['id']);
//           if (ests.isNotEmpty) {
//             allEsts.add({
//               'project_id':   p['id'],
//               'project_name': p['name'] ?? 'Unnamed',
//               'status':       p['status'] ?? 'active',
//               'estimation':   ests.last,
//             });
//           }
//         } catch (_) {}
//       }

//       if (mounted) {
//         setState(() {
//           _projects       = projects;
//           _settings       = settings;
//           _allEstimations = allEsts;
//           _loading        = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _selectProject(Map<String, dynamic> project) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('current_project_id',   project['id']);
//     await prefs.setString('current_project_name', project['name'] ?? '');
//     setState(() { _selected = project; _loadingEst = true; });
//     try {
//       final ests = await ApiService.getEstimations(project['id']);
//       if (mounted) {
//         setState(() {
//           _estimation = ests.isNotEmpty ? ests.last : null;
//           _loadingEst = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() { _estimation = null; _loadingEst = false; });
//     }
//   }

//   static double _d(dynamic v) =>
//       v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);
//   static int _i(dynamic v) =>
//       v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

//   String _fmt(double v) {
//     if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
//     if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)} L';
//     if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
//     return '₹${v.toStringAsFixed(0)}';
//   }

//   double _projectCost(Map<String, dynamic> est) {
//     final snap = est['estimation']['formula_snapshot'];
//     double cost = _d(snap?['cost_summary']?['total']);
//     if (cost == 0) cost = _i(est['estimation']['total_bricks']) * 10.35;
//     return cost;
//   }

//   Map<String, dynamic> get _combinedMaterials {
//     int    redBricks   = 0;
//     int    whiteBricks = 0;
//     double cementBags  = 0;
//     double sandTons    = 0;
//     for (final e in _allEstimations) {
//       final snap = e['estimation']['formula_snapshot'];
//       redBricks   += _i(snap?['red_brick']?['final_with_10pct']);
//       whiteBricks += _i(snap?['white_cement']?['final_with_10pct']);
//       cementBags  += _d(snap?['cement']?['total_bags']);
//       sandTons    += _d(snap?['sand']?['total_tons']);
//     }
//     return {
//       'red_bricks':   redBricks,
//       'white_bricks': whiteBricks,
//       'total_bricks': redBricks + whiteBricks,
//       'cement_bags':  cementBags,
//       'sand_tons':    sandTons,
//     };
//   }

//   double get _grandTotalCost =>
//       _allEstimations.fold(0.0, (s, e) => s + _projectCost(e));

//   final _chartColors = const [
//     Color(0xFF38BDF8),
//     Color(0xFF34D399),
//     Color(0xFFFBBF24),
//     Color(0xFFA78BFA),
//     Color(0xFFF87171),
//     Color(0xFF60A5FA),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Center(
//           child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
//     }

//     final combined      = _combinedMaterials;
//     final totalProjects = _projects.length;
//     final activeProjects =
//         _projects.where((p) => p['status'] == 'active').length;
//     final totalBricks   = combined['total_bricks'] as int;
//     final totalCement   = _d(combined['cement_bags']);
//     final totalSand     = _d(combined['sand_tons']);

//     return Container(
//       color: const Color(0xFF0F172A),
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [

//             // ── Header ────────────────────────────────────
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Overview',
//                         style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white)),
//                     SizedBox(height: 4),
//                     Text('All projects at a glance',
//                         style: TextStyle(
//                             fontSize: 13,
//                             color: Color(0xFF64748B))),
//                   ],
//                 ),
//                 Row(children: [
//                   IconButton(
//                     onPressed: _load,
//                     icon: const Icon(LucideIcons.refreshCw,
//                         size: 16, color: Color(0xFF64748B)),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton.icon(
//                     onPressed: () => context.go('/project-creation'),
//                     icon: const Icon(LucideIcons.plus, size: 14),
//                     label: const Text('New Project',
//                         style: TextStyle(fontSize: 12)),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF1E6FD9),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 10),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8)),
//                     ),
//                   ),
//                 ]),
//               ],
//             ),
//             const SizedBox(height: 20),

//             // ── Top stat cards row ─────────────────────────
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(children: [
//                 _statCard('Total Projects', '$totalProjects',
//                     null, const Color(0xFF38BDF8), LucideIcons.folder),
//                 const SizedBox(width: 12),
//                 _statCard('Active Projects', '$activeProjects',
//                     null, const Color(0xFF34D399), LucideIcons.activity),
//                 const SizedBox(width: 12),
//                 _statCard('Grand Total',
//                     _allEstimations.isEmpty ? '—' : _fmt(_grandTotalCost),
//                     null, const Color(0xFFFBBF24), LucideIcons.indianRupee),
//                 const SizedBox(width: 12),
//                 _statCard('Total Bricks', '$totalBricks',
//                     'pieces', const Color(0xFFA78BFA), LucideIcons.layers),
//                 const SizedBox(width: 12),
//                 _statCard('Cement',
//                     totalCement.toStringAsFixed(1),
//                     'bags', const Color(0xFF60A5FA), LucideIcons.package),
//                 const SizedBox(width: 12),
//                 _statCard('Sand',
//                     totalSand.toStringAsFixed(1),
//                     'tons', const Color(0xFFF87171), LucideIcons.box),
//                 const SizedBox(width: 12),
//                 _statCard('With Estimation',
//                     '${_allEstimations.length}',
//                     'projects', const Color(0xFF34D399),
//                     LucideIcons.clipboardCheck),
//                 const SizedBox(width: 12),
//                 _statCard('No Estimation',
//                     '${totalProjects - _allEstimations.length}',
//                     'projects', const Color(0xFFF87171),
//                     LucideIcons.clipboardX),
//               ]),
//             ),
//             const SizedBox(height: 20),

//             // ── Middle row: Chart + Materials ──────────────
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [

//                 // Chart
//                 Expanded(
//                   flex: 3,
//                   child: _buildChartCard(),
//                 ),
//                 const SizedBox(width: 16),

//                 // Material Inventory
//                 SizedBox(
//                   width: 240,
//                   child: _buildMaterialInventory(combined),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),

//             // ── Recent Projects ────────────────────────────
//             _buildRecentProjects(),

//             // ── Detail Panel ───────────────────────────────
//             if (_selected != null) ...[
//               const SizedBox(height: 16),
//               _buildDetailPanel(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Stat Card ──────────────────────────────────────────
//   Widget _statCard(String label, String value,
//       String? unit, Color color, IconData icon) {
//     return Container(
//       width: 150,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E293B),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(label,
//                   style: TextStyle(
//                       fontSize: 11,
//                       color: color.withOpacity(0.8))),
//               Icon(icon, size: 14, color: color.withOpacity(0.7)),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(value,
//               style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: color)),
//           if (unit != null)
//             Text(unit,
//                 style: const TextStyle(
//                     fontSize: 10, color: Color(0xFF475569))),
//         ],
//       ),
//     );
//   }

//   // ── Chart Card ─────────────────────────────────────────
//   Widget _buildChartCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E293B),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF334155)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('Active Projects',
//                   style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white)),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF0F172A),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Text(
//                   'Total: ${_fmt(_grandTotalCost)}',
//                   style: const TextStyle(
//                       fontSize: 11,
//                       color: Color(0xFF38BDF8),
//                       fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           if (_allEstimations.isEmpty)
//             const SizedBox(
//               height: 200,
//               child: Center(
//                 child: Text('No estimations yet',
//                     style: TextStyle(color: Color(0xFF475569))),
//               ),
//             )
//           else
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Chart
//                 Expanded(
//                   child: SizedBox(
//                     height: 220,
//                     child: _buildLineBarChart(),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 // Legend
//                 _buildChartLegend(),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   // ── Line + Bar Chart ────────────────────────────────────
//   Widget _buildLineBarChart() {
//     final data = _allEstimations.asMap().entries.map((e) {
//       final snap = e.value['estimation']['formula_snapshot'];
//       final cost = _projectCost(e.value);
//       final bricks = _i(snap?['grand_total']?['final_bricks']);
//       final cement = _d(snap?['cement']?['total_bags']);
//       return {
//         'index':   e.key,
//         'name':    e.value['project_name'] as String,
//         'cost':    cost,
//         'bricks':  bricks,
//         'cement':  cement,
//       };
//     }).toList();

//     double maxCost = data.fold(0.0,
//         (m, e) => (e['cost'] as double) > m ? e['cost'] as double : m);
//     if (maxCost == 0) maxCost = 100000;
//     final maxY = maxCost * 1.4;

//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: maxY,
//         minY: 0,
//         barTouchData: BarTouchData(
//           enabled: true,
//           touchTooltipData: BarTouchTooltipData(
//             getTooltipColor: (_) => const Color(0xFF0F172A),
//             getTooltipItem: (group, gi, rod, ri) {
//               final item = data[gi];
//               return BarTooltipItem(
//                 '${item['name']}\n',
//                 const TextStyle(
//                     color: Color(0xFF94A3B8), fontSize: 10),
//                 children: [
//                   TextSpan(
//                     text: _fmt(item['cost'] as double),
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13),
//                   ),
//                 ],
//               );
//             },
//           ),
//           touchCallback: (event, response) {
//             if (event is FlTapUpEvent &&
//                 response?.spot != null) {
//               final idx =
//                   response!.spot!.touchedBarGroupIndex;
//               if (idx >= 0 && idx < _projects.length) {
//                 _selectProject(_projects[idx]);
//               }
//             }
//           },
//         ),
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 32,
//               getTitlesWidget: (value, meta) {
//                 final idx = value.toInt();
//                 if (idx < 0 || idx >= data.length) {
//                   return const SizedBox();
//                 }
//                 final name = data[idx]['name'] as String;
//                 final isSelected = _selected?['name'] == name;
//                 return Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: Text(
//                     name.length > 8
//                         ? '${name.substring(0, 8)}..'
//                         : name,
//                     style: TextStyle(
//                         fontSize: 9,
//                         fontWeight: isSelected
//                             ? FontWeight.w700 : FontWeight.normal,
//                         color: isSelected
//                             ? const Color(0xFF38BDF8)
//                             : const Color(0xFF64748B)),
//                   ),
//                 );
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 48,
//               interval: maxY / 4,
//               getTitlesWidget: (value, meta) {
//                 if (value == 0) return const SizedBox();
//                 return Text(
//                   _fmt(value),
//                   style: const TextStyle(
//                       fontSize: 8, color: Color(0xFF475569)),
//                 );
//               },
//             ),
//           ),
//           topTitles: const AxisTitles(
//               sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(
//               sideTitles: SideTitles(showTitles: false)),
//         ),
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: false,
//           horizontalInterval: maxY / 4,
//           getDrawingHorizontalLine: (_) => const FlLine(
//             color: Color(0xFF1E293B),
//             strokeWidth: 1,
//           ),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: const Border(
//             bottom: BorderSide(color: Color(0xFF334155)),
//             left:   BorderSide(color: Color(0xFF334155)),
//           ),
//         ),
//         barGroups: data.asMap().entries.map((e) {
//           final idx  = e.key;
//           final item = e.value;
//           final cost = item['cost'] as double;
//           final name = item['name'] as String;
//           final isSelected = _selected?['name'] == name;
//           final color = _chartColors[idx % _chartColors.length];

//           return BarChartGroupData(
//             x: idx,
//             barRods: [
//               BarChartRodData(
//                 toY: cost,
//                 width: data.length <= 3 ? 48 : data.length <= 6 ? 36 : 24,
//                 borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(4)),
//                 gradient: LinearGradient(
//                   begin: Alignment.bottomCenter,
//                   end:   Alignment.topCenter,
//                   colors: isSelected
//                       ? [
//                           const Color(0xFF1D4ED8),
//                           const Color(0xFF38BDF8),
//                         ]
//                       : [
//                           color.withOpacity(0.3),
//                           color.withOpacity(0.8),
//                         ],
//                 ),
//                 backDrawRodData: BackgroundBarChartRodData(
//                   show: true,
//                   toY: maxY,
//                   color: const Color(0xFF0F172A).withOpacity(0.5),
//                 ),
//               ),
//             ],
//             showingTooltipIndicators: isSelected ? [0] : [],
//           );
//         }).toList(),
//       ),
//       swapAnimationDuration: const Duration(milliseconds: 400),
//       swapAnimationCurve: Curves.easeInOut,
//     );
//   }

//   // ── Chart Legend ────────────────────────────────────────
//   Widget _buildChartLegend() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text('Projects',
//             style: TextStyle(
//                 fontSize: 11,
//                 color: Color(0xFF64748B),
//                 fontWeight: FontWeight.w600)),
//         const SizedBox(height: 8),
//         ..._allEstimations.asMap().entries.map((e) {
//           final idx   = e.key;
//           final item  = e.value;
//           final color = _chartColors[idx % _chartColors.length];
//           final cost  = _projectCost(item);
//           final name  = item['project_name'] as String;
//           final isSelected = _selected?['name'] == name;

//           return InkWell(
//             onTap: () {
//               final proj = _projects.firstWhere(
//                   (p) => p['name'] == name,
//                   orElse: () => _projects.first);
//               _selectProject(proj);
//             },
//             child: Container(
//               margin: const EdgeInsets.only(bottom: 8),
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 8, vertical: 6),
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? color.withOpacity(0.1)
//                     : Colors.transparent,
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(
//                   color: isSelected
//                       ? color.withOpacity(0.4)
//                       : Colors.transparent,
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 10, height: 10,
//                     decoration: BoxDecoration(
//                         color: color, shape: BoxShape.circle),
//                   ),
//                   const SizedBox(width: 6),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name.length > 12
//                             ? '${name.substring(0, 12)}..'
//                             : name,
//                         style: TextStyle(
//                             fontSize: 11,
//                             color: isSelected
//                                 ? color : const Color(0xFF94A3B8),
//                             fontWeight: isSelected
//                                 ? FontWeight.w600 : FontWeight.normal),
//                       ),
//                       Text(
//                         _fmt(cost),
//                         style: TextStyle(
//                             fontSize: 10,
//                             color: color,
//                             fontWeight: FontWeight.w600),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   // ── Material Inventory ──────────────────────────────────
//   Widget _buildMaterialInventory(Map<String, dynamic> combined) {
//     final totalBricks = (combined['total_bricks'] as int).toDouble();
//     final cement      = _d(combined['cement_bags']);
//     final sand        = _d(combined['sand_tons']);
//     final red         = (combined['red_bricks'] as int).toDouble();
//     final white       = (combined['white_bricks'] as int).toDouble();

//     final maxVal = [totalBricks, cement * 100, sand * 100, red, white]
//         .reduce((a, b) => a > b ? a : b);

//     final items = [
//       {
//         'label': 'Red Bricks',
//         'value': '${combined['red_bricks']} pcs',
//         'pct':   maxVal > 0 ? red / maxVal : 0.0,
//         'color': const Color(0xFFF87171),
//         'icon':  LucideIcons.layers,
//       },
//       {
//         'label': 'White Blocks',
//         'value': '${combined['white_bricks']} pcs',
//         'pct':   maxVal > 0 ? white / maxVal : 0.0,
//         'color': const Color(0xFF60A5FA),
//         'icon':  LucideIcons.square,
//       },
//       {
//         'label': 'Cement',
//         'value': '${cement.toStringAsFixed(1)} bags',
//         'pct':   maxVal > 0 ? (cement * 100) / maxVal : 0.0,
//         'color': const Color(0xFF34D399),
//         'icon':  LucideIcons.package,
//       },
//       {
//         'label': 'Sand',
//         'value': '${sand.toStringAsFixed(1)} tons',
//         'pct':   maxVal > 0 ? (sand * 100) / maxVal : 0.0,
//         'color': const Color(0xFFFBBF24),
//         'icon':  LucideIcons.box,
//       },
//       {
//         'label': 'Total Bricks',
//         'value': '${combined['total_bricks']} pcs',
//         'pct':   maxVal > 0 ? totalBricks / maxVal : 0.0,
//         'color': const Color(0xFFA78BFA),
//         'icon':  LucideIcons.grid2x2,
//       },
//     ];

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E293B),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF334155)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Material Inventory Overview',
//               style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white)),
//           const SizedBox(height: 4),
//           Text('${_allEstimations.length} projects combined',
//               style: const TextStyle(
//                   fontSize: 11, color: Color(0xFF475569))),
//           const SizedBox(height: 16),
//           ...items.map((item) => Padding(
//             padding: const EdgeInsets.only(bottom: 14),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(children: [
//                       Icon(item['icon'] as IconData,
//                           size: 12,
//                           color: item['color'] as Color),
//                       const SizedBox(width: 6),
//                       Text(item['label'] as String,
//                           style: const TextStyle(
//                               fontSize: 11,
//                               color: Color(0xFF94A3B8))),
//                     ]),
//                     Text(item['value'] as String,
//                         style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: item['color'] as Color)),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: LinearProgressIndicator(
//                     value: (item['pct'] as double).clamp(0.0, 1.0),
//                     minHeight: 6,
//                     backgroundColor: const Color(0xFF0F172A),
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                         item['color'] as Color),
//                   ),
//                 ),
//               ],
//             ),
//           )),

//           // Total estimation banner
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
//               ),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('TOTAL ESTIMATION',
//                     style: TextStyle(
//                         color: Colors.white60,
//                         fontSize: 9,
//                         letterSpacing: 1.2)),
//                 const SizedBox(height: 4),
//                 Text(_fmt(_grandTotalCost),
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Recent Projects ─────────────────────────────────────
//   Widget _buildRecentProjects() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text('Recent Projects',
//                 style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white)),
//             TextButton.icon(
//               onPressed: () => context.go('/project-creation'),
//               icon: const Icon(LucideIcons.plus,
//                   size: 12, color: Color(0xFF38BDF8)),
//               label: const Text('Add New',
//                   style: TextStyle(
//                       fontSize: 11, color: Color(0xFF38BDF8))),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         if (_projects.isEmpty)
//           _emptyProjects()
//         else
//           ...(_projects.take(5).map((p) {
//             final ests = _allEstimations
//                 .where((e) => e['project_id'] == p['id'])
//                 .toList();
//             final hasCost  = ests.isNotEmpty;
//             final cost     = hasCost ? _projectCost(ests.first) : 0.0;
//             final snap     = hasCost
//                 ? ests.first['estimation']['formula_snapshot'] : null;
//             final bricks   = _i(snap?['grand_total']?['final_bricks']);
//             final cement   = _d(snap?['cement']?['total_bags']);
//             final sand     = _d(snap?['sand']?['total_tons']);
//             final status   = p['status'] ?? 'active';
//             final isSelected = _selected?['id'] == p['id'];

//             return InkWell(
//               onTap: () => _selectProject(p),
//               borderRadius: BorderRadius.circular(10),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? const Color(0xFF1D4ED8).withOpacity(0.15)
//                       : const Color(0xFF1E293B),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: isSelected
//                         ? const Color(0xFF38BDF8).withOpacity(0.4)
//                         : const Color(0xFF334155),
//                   ),
//                 ),
//                 child: Row(children: [
//                   // Icon
//                   Container(
//                     width: 40, height: 40,
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? const Color(0xFF1D4ED8)
//                           : const Color(0xFF0F172A),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(LucideIcons.building2,
//                         size: 18,
//                         color: isSelected
//                             ? Colors.white
//                             : const Color(0xFF64748B)),
//                   ),
//                   const SizedBox(width: 12),

//                   // Name + status
//                   Expanded(
//                     flex: 2,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(p['name'] ?? 'Unnamed',
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 13,
//                                 color: Colors.white)),
//                         const SizedBox(height: 2),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: status == 'active'
//                                 ? const Color(0xFF064E3B)
//                                 : const Color(0xFF1E293B),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(status,
//                               style: TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w600,
//                                   color: status == 'active'
//                                       ? const Color(0xFF34D399)
//                                       : const Color(0xFF64748B))),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Bricks
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(hasCost ? '$bricks' : '—',
//                             style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFFA78BFA))),
//                         const Text('bricks',
//                             style: TextStyle(
//                                 fontSize: 9,
//                                 color: Color(0xFF475569))),
//                       ],
//                     ),
//                   ),

//                   // Cement
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(hasCost
//                             ? cement.toStringAsFixed(1) : '—',
//                             style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF34D399))),
//                         const Text('bags',
//                             style: TextStyle(
//                                 fontSize: 9,
//                                 color: Color(0xFF475569))),
//                       ],
//                     ),
//                   ),

//                   // Sand
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(hasCost
//                             ? sand.toStringAsFixed(1) : '—',
//                             style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFFFBBF24))),
//                         const Text('tons',
//                             style: TextStyle(
//                                 fontSize: 9,
//                                 color: Color(0xFF475569))),
//                       ],
//                     ),
//                   ),

//                   // Cost
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(hasCost ? _fmt(cost) : 'No est.',
//                             style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: hasCost
//                                     ? const Color(0xFF38BDF8)
//                                     : const Color(0xFF475569))),
//                         const Text('estimated',
//                             style: TextStyle(
//                                 fontSize: 9,
//                                 color: Color(0xFF475569))),
//                       ],
//                     ),
//                   ),

//                   // Actions
//                   const SizedBox(width: 12),
//                   Row(children: [
//                     _miniBtn(LucideIcons.upload,
//                         const Color(0xFF38BDF8),
//                         () => context.go('/upload')),
//                     const SizedBox(width: 4),
//                     _miniBtn(LucideIcons.calculator,
//                         const Color(0xFF34D399),
//                         () => context.go('/costing')),
//                     const SizedBox(width: 4),
//                     _miniBtn(LucideIcons.fileText,
//                         const Color(0xFFFBBF24),
//                         () => context.go('/review')),
//                   ]),
//                 ]),
//               ),
//             );
//           })),
//       ],
//     );
//   }

//   Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(6),
//       child: Container(
//         padding: const EdgeInsets.all(6),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Icon(icon, size: 12, color: color),
//       ),
//     );
//   }

//   // ── Detail Panel ────────────────────────────────────────
//   Widget _buildDetailPanel() {
//     final p    = _selected!;
//     final name = p['name'] ?? 'Project';
//     final snap = _estimation?['formula_snapshot'];

//     final redBricks   = _i(snap?['red_brick']?['final_with_10pct']);
//     final whiteBricks = _i(snap?['white_cement']?['final_with_10pct']);
//     final cementBags  = _d(snap?['cement']?['total_bags']);
//     final sandTons    = _d(snap?['sand']?['total_tons']);
//     final totalBricks = _i(snap?['grand_total']?['final_bricks']);
//     final volCuM      = _d(snap?['volume_summary']?['net_volume_cum']);
//     final zones       = snap?['zone_summary'] as List? ?? [];
//     final floorArea   = zones.fold<double>(
//         0.0, (s, z) => s + _d(z['area_sqft']));
//     double cost = _d(snap?['cost_summary']?['total']);
//     if (cost == 0 && _estimation != null) {
//       cost = _i(_estimation?['total_bricks']) * 10.35;
//     }

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E293B),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//             color: const Color(0xFF38BDF8).withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                     colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)]),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(LucideIcons.building2,
//                   size: 16, color: Colors.white),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(name,
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 15,
//                           color: Colors.white)),
//                   Text(
//                     cost > 0
//                         ? 'Estimated: ${_fmt(cost)}'
//                         : 'No estimation yet',
//                     style: TextStyle(
//                         fontSize: 12,
//                         color: cost > 0
//                             ? const Color(0xFF38BDF8)
//                             : const Color(0xFF475569)),
//                   ),
//                 ],
//               ),
//             ),
//             Wrap(spacing: 6, children: [
//               _actionChip('Upload', LucideIcons.upload,
//                   const Color(0xFF38BDF8),
//                   () => context.go('/upload')),
//               _actionChip('Costing', LucideIcons.calculator,
//                   const Color(0xFF34D399),
//                   () => context.go('/costing')),
//               _actionChip('BOQ', LucideIcons.fileText,
//                   const Color(0xFFFBBF24),
//                   () => context.go('/review')),
//               _actionChip('Takeoff', LucideIcons.clipboardList,
//                   const Color(0xFFA78BFA),
//                   () => context.go('/takeoff')),
//             ]),
//             const SizedBox(width: 8),
//             IconButton(
//               onPressed: () =>
//                   setState(() { _selected = null; _estimation = null; }),
//               icon: const Icon(LucideIcons.x,
//                   size: 16, color: Color(0xFF475569)),
//             ),
//           ]),

//           if (_loadingEst)
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 12),
//               child: Center(child: CircularProgressIndicator(
//                   color: Color(0xFF38BDF8), strokeWidth: 2)),
//             )
//           else if (snap == null)
//             Container(
//               margin: const EdgeInsets.only(top: 12),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF451A03).withOpacity(0.4),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                     color: const Color(0xFFFBBF24).withOpacity(0.3)),
//               ),
//               child: Row(children: [
//                 const Icon(LucideIcons.info,
//                     size: 16, color: Color(0xFFFBBF24)),
//                 const SizedBox(width: 8),
//                 const Expanded(
//                   child: Text(
//                     'No estimation yet. Upload a floor plan and run Costing.',
//                     style: TextStyle(
//                         fontSize: 12, color: Color(0xFFFBBF24)),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () => context.go('/upload'),
//                   child: const Text('Upload Now',
//                       style: TextStyle(
//                           color: Color(0xFFFBBF24),
//                           fontWeight: FontWeight.w600)),
//                 ),
//               ]),
//             )
//           else ...[
//             const SizedBox(height: 12),
//             Row(children: [
//               _detailStat('Floor Area',
//                   '${floorArea.toStringAsFixed(0)} sqft',
//                   const Color(0xFF38BDF8),
//                   LucideIcons.layoutDashboard),
//               const SizedBox(width: 8),
//               _detailStat('Total Bricks', '$totalBricks pcs',
//                   const Color(0xFFF87171), LucideIcons.layers),
//               const SizedBox(width: 8),
//               _detailStat('Red Bricks', '$redBricks pcs',
//                   const Color(0xFFF87171), LucideIcons.square),
//               const SizedBox(width: 8),
//               _detailStat('White Blocks', '$whiteBricks pcs',
//                   const Color(0xFF60A5FA), LucideIcons.square),
//               const SizedBox(width: 8),
//               _detailStat('Cement',
//                   '${cementBags.toStringAsFixed(1)} bags',
//                   const Color(0xFF34D399), LucideIcons.package),
//               const SizedBox(width: 8),
//               _detailStat('Sand',
//                   '${sandTons.toStringAsFixed(2)} tons',
//                   const Color(0xFFFBBF24), LucideIcons.box),
//               const SizedBox(width: 8),
//               _detailStat('Volume',
//                   '${volCuM.toStringAsFixed(2)} m³',
//                   const Color(0xFFA78BFA), LucideIcons.square200Dir),
//             ]),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _actionChip(String label, IconData icon,
//       Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(6),
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//             horizontal: 8, vertical: 5),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: color.withOpacity(0.25)),
//         ),
//         child: Row(mainAxisSize: MainAxisSize.min, children: [
//           Icon(icon, size: 12, color: color),
//           const SizedBox(width: 4),
//           Text(label,
//               style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w600,
//                   color: color)),
//         ]),
//       ),
//     );
//   }

//   Widget _detailStat(String label, String value,
//       Color color, IconData icon) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.07),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withOpacity(0.15)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, size: 13, color: color),
//             const SizedBox(height: 4),
//             Text(value,
//                 style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: color),
//                 overflow: TextOverflow.ellipsis),
//             Text(label,
//                 style: const TextStyle(
//                     fontSize: 9, color: Color(0xFF475569))),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _emptyProjects() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E293B),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFF334155)),
//       ),
//       child: Center(
//         child: Column(
//           children: [
//             const Icon(LucideIcons.folderOpen,
//                 size: 32, color: Color(0xFF475569)),
//             const SizedBox(height: 8),
//             const Text('No projects yet',
//                 style: TextStyle(
//                     color: Color(0xFF64748B),
//                     fontWeight: FontWeight.w500)),
//             const SizedBox(height: 12),
//             ElevatedButton.icon(
//               onPressed: () => context.go('/project-creation'),
//               icon: const Icon(LucideIcons.plus, size: 13),
//               label: const Text('Create Project',
//                   style: TextStyle(fontSize: 12)),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1D4ED8),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool                       _loading    = true;
  List<dynamic>              _projects   = [];
  Map<String, dynamic>?      _settings;
  Map<String, dynamic>?      _selected;
  Map<String, dynamic>?      _estimation;
  bool                       _loadingEst = false;
  List<Map<String, dynamic>> _allEstimations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getProjects(),
        ApiService.getSettings(),
      ]);
      final projects = results[0] as List<dynamic>;
      final settings = results[1] as Map<String, dynamic>;

      final allEsts = <Map<String, dynamic>>[];
      for (final p in projects) {
        try {
          final ests = await ApiService.getEstimations(p['id']);
          if (ests.isNotEmpty) {
            allEsts.add({
              'project_id':   p['id'],
              'project_name': p['name'] ?? 'Unnamed',
              'status':       p['status'] ?? 'active',
              'estimation':   ests.last,
            });
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _projects       = projects;
          _settings       = settings;
          _allEstimations = allEsts;
          _loading        = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectProject(Map<String, dynamic> project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_project_id',   project['id']);
    await prefs.setString('current_project_name', project['name'] ?? '');
    setState(() { _selected = project; _loadingEst = true; });
    try {
      final ests = await ApiService.getEstimations(project['id']);
      if (mounted) {
        setState(() {
          _estimation = ests.isNotEmpty ? ests.last : null;
          _loadingEst = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _estimation = null; _loadingEst = false; });
    }
  }

  static double _d(dynamic v) =>
      v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);
  static int _i(dynamic v) =>
      v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  double _projectCost(Map<String, dynamic> est) {
    final snap = est['estimation']['formula_snapshot'];
    double cost = _d(snap?['cost_summary']?['total']);
    if (cost == 0) cost = _i(est['estimation']['total_bricks']) * 10.35;
    return cost;
  }

  Map<String, dynamic> get _combinedMaterials {
    int    redBricks   = 0;
    int    whiteBricks = 0;
    double cementBags  = 0;
    double sandTons    = 0;
    for (final e in _allEstimations) {
      final snap = e['estimation']['formula_snapshot'];
      redBricks   += _i(snap?['red_brick']?['final_with_10pct']);
      whiteBricks += _i(snap?['white_cement']?['final_with_10pct']);
      cementBags  += _d(snap?['cement']?['total_bags']);
      sandTons    += _d(snap?['sand']?['total_tons']);
    }
    return {
      'red_bricks':   redBricks,
      'white_bricks': whiteBricks,
      'total_bricks': redBricks + whiteBricks,
      'cement_bags':  cementBags,
      'sand_tons':    sandTons,
    };
  }

  double get _grandTotalCost =>
      _allEstimations.fold(0.0, (s, e) => s + _projectCost(e));

  final _chartColors = const [
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFA78BFA),
    Color(0xFFF87171),
    Color(0xFF60A5FA),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }

    final combined       = _combinedMaterials;
    final totalProjects  = _projects.length;
    final activeProjects = _projects.where((p) => p['status'] == 'active').length;
    final totalBricks    = combined['total_bricks'] as int;
    final totalCement    = _d(combined['cement_bags']);
    final totalSand      = _d(combined['sand_tons']);

    return Container(
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overview',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 4),
                    Text('All projects at a glance',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B))),
                  ],
                ),
                Row(children: [
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(LucideIcons.refreshCw,
                        size: 16, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/project-creation'),
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('New Project',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 20),

            // ── Stat Cards ───────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _statCard('Total Projects', '$totalProjects',
                    null, const Color(0xFF38BDF8), LucideIcons.folder),
                const SizedBox(width: 12),
                _statCard('Active Projects', '$activeProjects',
                    null, const Color(0xFF34D399), LucideIcons.activity),
                const SizedBox(width: 12),
                _statCard('Grand Total',
                    _allEstimations.isEmpty ? '—' : _fmt(_grandTotalCost),
                    null, const Color(0xFFFBBF24), LucideIcons.indianRupee),
                const SizedBox(width: 12),
                _statCard('Total Bricks', '$totalBricks',
                    'pieces', const Color(0xFFA78BFA), LucideIcons.layers),
                const SizedBox(width: 12),
                _statCard('Cement',
                    totalCement.toStringAsFixed(1),
                    'bags', const Color(0xFF60A5FA), LucideIcons.package),
                const SizedBox(width: 12),
                _statCard('Sand',
                    totalSand.toStringAsFixed(1),
                    'tons', const Color(0xFFF87171), LucideIcons.box),
                const SizedBox(width: 12),
                _statCard('With Estimation',
                    '${_allEstimations.length}',
                    'projects', const Color(0xFF34D399),
                    LucideIcons.clipboardCheck),
                const SizedBox(width: 12),
                _statCard('No Estimation',
                    '${totalProjects - _allEstimations.length}',
                    'projects', const Color(0xFFF87171),
                    LucideIcons.clipboardX),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Chart + Materials ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildChartCard()),
                const SizedBox(width: 16),
                SizedBox(
                    width: 240,
                    child: _buildMaterialInventory(combined)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Recent Projects ──────────────────────────────
            _buildRecentProjects(),

            // ── Detail Panel ─────────────────────────────────
            if (_selected != null) ...[
              const SizedBox(height: 16),
              _buildDetailPanel(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Stat Card ────────────────────────────────────────────
  Widget _statCard(String label, String value,
      String? unit, Color color, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.8)),
                    overflow: TextOverflow.ellipsis),
              ),
              Icon(icon, size: 14, color: color.withOpacity(0.7)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          if (unit != null)
            Text(unit,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  // ── Chart Card ───────────────────────────────────────────
  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Projects',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${_fmt(_grandTotalCost)}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_allEstimations.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.chartBarBig,
                        size: 32, color: Color(0xFF334155)),
                    SizedBox(height: 8),
                    Text('No estimations yet',
                        style: TextStyle(color: Color(0xFF475569))),
                  ],
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 260,
                    child: _buildBarChart(),
                  ),
                ),
                const SizedBox(width: 16),
                _buildChartLegend(),
              ],
            ),
        ],
      ),
    );
  }

  // ── Bar Chart ────────────────────────────────────────────
  Widget _buildBarChart() {
    final data = _allEstimations.asMap().entries.map((e) {
      return {
        'index': e.key,
        'name':  e.value['project_name'] as String,
        'cost':  _projectCost(e.value),
      };
    }).toList();

    double maxCost = data.fold(0.0,
        (m, e) => (e['cost'] as double) > m ? e['cost'] as double : m);
    if (maxCost == 0) maxCost = 100000;
    final maxY = maxCost * 1.4;

    final barWidth = data.length == 1 ? 80.0
        : data.length == 2 ? 100.0
        : data.length <= 4 ? 60.0
        : data.length <= 6 ? 44.0
        : 32.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A),
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            getTooltipItem: (group, gi, rod, ri) {
              final item = data[gi];
              return BarTooltipItem(
                '${item['name']}\n',
                const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 10),
                children: [
                  TextSpan(
                    text: _fmt(item['cost'] as double),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response?.spot != null) {
              final idx = response!.spot!.touchedBarGroupIndex;
              if (idx >= 0 && idx < _projects.length) {
                _selectProject(_projects[idx]);
              }
            }
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final name = data[idx]['name'] as String;
                final isSelected = _selected?['name'] == name;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          width: 5, height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        name.length > 10
                            ? '${name.substring(0, 10)}..'
                            : name,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _fmt(value),
                    style: const TextStyle(
                        fontSize: 8, color: Color(0xFF475569)),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFF1E293B),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFF334155), width: 1),
            left:   BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        barGroups: data.asMap().entries.map((e) {
          final idx        = e.key;
          final item       = e.value;
          final cost       = item['cost'] as double;
          final name       = item['name'] as String;
          final isSelected = _selected?['name'] == name;
          final color      = _chartColors[idx % _chartColors.length];

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: cost,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: isSelected
                      ? [
                          const Color(0xFF1D4ED8),
                          const Color(0xFF38BDF8),
                        ]
                      : [
                          color.withOpacity(0.3),
                          color.withOpacity(0.9),
                        ],
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFF0F172A).withOpacity(0.4),
                ),
              ),
            ],
            showingTooltipIndicators: isSelected ? [0] : [],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 500),
      swapAnimationCurve: Curves.easeInOut,
    );
  }

  // ── Chart Legend ─────────────────────────────────────────
  Widget _buildChartLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Projects',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._allEstimations.asMap().entries.map((e) {
          final idx        = e.key;
          final item       = e.value;
          final color      = _chartColors[idx % _chartColors.length];
          final cost       = _projectCost(item);
          final name       = item['project_name'] as String;
          final isSelected = _selected?['name'] == name;

          return InkWell(
            onTap: () {
              final proj = _projects.firstWhere(
                  (p) => p['name'] == name,
                  orElse: () => _projects.first);
              _selectProject(proj);
            },
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.length > 12
                            ? '${name.substring(0, 12)}..'
                            : name,
                        style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? color
                                : const Color(0xFF94A3B8),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                      Text(
                        _fmt(cost),
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Material Inventory ───────────────────────────────────
  Widget _buildMaterialInventory(Map<String, dynamic> combined) {
    final totalBricks = (combined['total_bricks'] as int).toDouble();
    final cement      = _d(combined['cement_bags']);
    final sand        = _d(combined['sand_tons']);
    final red         = (combined['red_bricks'] as int).toDouble();
    final white       = (combined['white_bricks'] as int).toDouble();
    final maxVal      = [totalBricks, red, white, cement * 300, sand * 300]
        .reduce((a, b) => a > b ? a : b);

    final items = [
      {
        'label': 'Red Bricks',
        'value': '${combined['red_bricks']} pcs',
        'pct':   maxVal > 0 ? (red / maxVal).clamp(0.0, 1.0) : 0.0,
        'color': const Color(0xFFF87171),
        'icon':  LucideIcons.layers,
      },
      {
        'label': 'White Blocks',
        'value': '${combined['white_bricks']} pcs',
        'pct':   maxVal > 0 ? (white / maxVal).clamp(0.0, 1.0) : 0.0,
        'color': const Color(0xFF60A5FA),
        'icon':  LucideIcons.square,
      },
      {
        'label': 'Cement',
        'value': '${cement.toStringAsFixed(1)} bags',
        'pct':   maxVal > 0 ? ((cement * 300) / maxVal).clamp(0.0, 1.0) : 0.0,
        'color': const Color(0xFF34D399),
        'icon':  LucideIcons.package,
      },
      {
        'label': 'Sand',
        'value': '${sand.toStringAsFixed(1)} tons',
        'pct':   maxVal > 0 ? ((sand * 300) / maxVal).clamp(0.0, 1.0) : 0.0,
        'color': const Color(0xFFFBBF24),
        'icon':  LucideIcons.box,
      },
      {
        'label': 'Total Bricks',
        'value': '${combined['total_bricks']} pcs',
        'pct':   maxVal > 0 ? (totalBricks / maxVal).clamp(0.0, 1.0) : 0.0,
        'color': const Color(0xFFA78BFA),
        'icon':  LucideIcons.layoutGrid,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Material Inventory Overview',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text('${_allEstimations.length} projects combined',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF475569))),
          const SizedBox(height: 16),

          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(item['icon'] as IconData,
                          size: 12, color: item['color'] as Color),
                      const SizedBox(width: 6),
                      Text(item['label'] as String,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8))),
                    ]),
                    Text(item['value'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item['color'] as Color)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item['pct'] as double,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        item['color'] as Color),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 4),
          // Total banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL ESTIMATION',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(_fmt(_grandTotalCost),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Projects ──────────────────────────────────────
  Widget _buildRecentProjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Projects',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            TextButton.icon(
              onPressed: () => context.go('/project-creation'),
              icon: const Icon(LucideIcons.plus,
                  size: 12, color: Color(0xFF38BDF8)),
              label: const Text('Add New',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF38BDF8))),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_projects.isEmpty)
          _emptyProjects()
        else ...[
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            child: Row(children: const [
              SizedBox(width: 52),
              Expanded(flex: 2,
                  child: Text('Project',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600))),
              Expanded(child: Text('Bricks',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, color: Color(0xFF475569),
                      fontWeight: FontWeight.w600))),
              Expanded(child: Text('Cement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, color: Color(0xFF475569),
                      fontWeight: FontWeight.w600))),
              Expanded(child: Text('Sand',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, color: Color(0xFF475569),
                      fontWeight: FontWeight.w600))),
              Expanded(child: Text('Est. Cost',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 10, color: Color(0xFF475569),
                      fontWeight: FontWeight.w600))),
              SizedBox(width: 90),
            ]),
          ),

          ..._projects.map((p) {
            final ests = _allEstimations
                .where((e) => e['project_id'] == p['id'])
                .toList();
            final hasCost  = ests.isNotEmpty;
            final cost     = hasCost ? _projectCost(ests.first) : 0.0;
            final snap     = hasCost
                ? ests.first['estimation']['formula_snapshot'] : null;
            final bricks   = _i(snap?['grand_total']?['final_bricks']);
            final cement   = _d(snap?['cement']?['total_bags']);
            final sand     = _d(snap?['sand']?['total_tons']);
            final status   = p['status'] ?? 'active';
            final isSelected = _selected?['id'] == p['id'];

            return InkWell(
              onTap: () => _selectProject(p),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1D4ED8).withOpacity(0.12)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF38BDF8).withOpacity(0.4)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Row(children: [
                  // Icon
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.building2,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 10),

                  // Name + status
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] ?? 'Unnamed',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'active'
                                ? const Color(0xFF064E3B)
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: status == 'active'
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ),

                  // Bricks
                  Expanded(
                    child: Column(
                      children: [
                        Text(hasCost ? '$bricks' : '—',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA78BFA))),
                        const Text('pcs',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF475569))),
                      ],
                    ),
                  ),

                  // Cement
                  Expanded(
                    child: Column(
                      children: [
                        Text(hasCost
                            ? cement.toStringAsFixed(1) : '—',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF34D399))),
                        const Text('bags',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF475569))),
                      ],
                    ),
                  ),

                  // Sand
                  Expanded(
                    child: Column(
                      children: [
                        Text(hasCost
                            ? sand.toStringAsFixed(1) : '—',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFBBF24))),
                        const Text('tons',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF475569))),
                      ],
                    ),
                  ),

                  // Cost
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(hasCost ? _fmt(cost) : 'No est.',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasCost
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF475569))),
                        const Text('estimated',
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF475569))),
                      ],
                    ),
                  ),

                  // Action buttons
                  const SizedBox(width: 10),
                  Row(children: [
                    _miniBtn(LucideIcons.upload,
                        const Color(0xFF38BDF8),
                        () => context.go('/upload')),
                    const SizedBox(width: 4),
                    _miniBtn(LucideIcons.calculator,
                        const Color(0xFF34D399),
                        () => context.go('/costing')),
                    const SizedBox(width: 4),
                    _miniBtn(LucideIcons.fileText,
                        const Color(0xFFFBBF24),
                        () => context.go('/review')),
                  ]),
                ]),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }

  // ── Detail Panel ─────────────────────────────────────────
  Widget _buildDetailPanel() {
    final p    = _selected!;
    final name = p['name'] ?? 'Project';
    final snap = _estimation?['formula_snapshot'];

    final redBricks   = _i(snap?['red_brick']?['final_with_10pct']);
    final whiteBricks = _i(snap?['white_cement']?['final_with_10pct']);
    final cementBags  = _d(snap?['cement']?['total_bags']);
    final sandTons    = _d(snap?['sand']?['total_tons']);
    final totalBricks = _i(snap?['grand_total']?['final_bricks']);
    final volCuM      = _d(snap?['volume_summary']?['net_volume_cum']);
    final zones       = snap?['zone_summary'] as List? ?? [];
    final floorArea   = zones.fold<double>(
        0.0, (s, z) => s + _d(z['area_sqft']));
    double cost = _d(snap?['cost_summary']?['total']);
    if (cost == 0 && _estimation != null) {
      cost = _i(_estimation?['total_bricks']) * 10.35;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.building2,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
                  Text(
                    cost > 0
                        ? 'Estimated: ${_fmt(cost)}'
                        : 'No estimation yet',
                    style: TextStyle(
                        fontSize: 12,
                        color: cost > 0
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            Wrap(spacing: 6, children: [
              _actionChip('Upload', LucideIcons.upload,
                  const Color(0xFF38BDF8),
                  () => context.go('/upload')),
              _actionChip('Costing', LucideIcons.calculator,
                  const Color(0xFF34D399),
                  () => context.go('/costing')),
              _actionChip('BOQ', LucideIcons.fileText,
                  const Color(0xFFFBBF24),
                  () => context.go('/review')),
              _actionChip('Takeoff', LucideIcons.clipboardList,
                  const Color(0xFFA78BFA),
                  () => context.go('/takeoff')),
            ]),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() {
                _selected   = null;
                _estimation = null;
              }),
              icon: const Icon(LucideIcons.x,
                  size: 16, color: Color(0xFF475569)),
            ),
          ]),

          if (_loadingEst)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(
                  color: Color(0xFF38BDF8), strokeWidth: 2)),
            )
          else if (snap == null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF451A03).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFBBF24).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(LucideIcons.info,
                    size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No estimation yet. Upload a floor plan and run Costing.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFFFBBF24)),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/upload'),
                  child: const Text('Upload Now',
                      style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            )
          else ...[
            const SizedBox(height: 12),
            Row(children: [
              _detailStat('Floor Area',
                  '${floorArea.toStringAsFixed(0)} sqft',
                  const Color(0xFF38BDF8),
                  LucideIcons.layoutDashboard),
              const SizedBox(width: 8),
              _detailStat('Total Bricks',
                  '$totalBricks pcs',
                  const Color(0xFFF87171),
                  LucideIcons.layers),
              const SizedBox(width: 8),
              _detailStat('Red Bricks',
                  '$redBricks pcs',
                  const Color(0xFFF87171),
                  LucideIcons.square),
              const SizedBox(width: 8),
              _detailStat('White Blocks',
                  '$whiteBricks pcs',
                  const Color(0xFF60A5FA),
                  LucideIcons.square),
              const SizedBox(width: 8),
              _detailStat('Cement',
                  '${cementBags.toStringAsFixed(1)} bags',
                  const Color(0xFF34D399),
                  LucideIcons.package),
              const SizedBox(width: 8),
              _detailStat('Sand',
                  '${sandTons.toStringAsFixed(2)} tons',
                  const Color(0xFFFBBF24),
                  LucideIcons.box),
              const SizedBox(width: 8),
              _detailStat('Volume',
                  '${volCuM.toStringAsFixed(2)} m³',
                  const Color(0xFFA78BFA),
                  LucideIcons.maximize2),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _actionChip(String label, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }

  Widget _detailStat(String label, String value,
      Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color),
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _emptyProjects() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.folderOpen,
                size: 32, color: Color(0xFF475569)),
            const SizedBox(height: 8),
            const Text('No projects yet',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/project-creation'),
              icon: const Icon(LucideIcons.plus, size: 13),
              label: const Text('Create Project',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}