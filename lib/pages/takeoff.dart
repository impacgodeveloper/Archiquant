import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class Takeoff extends StatefulWidget {
  const Takeoff({super.key});

  @override
  State<Takeoff> createState() => _TakeoffState();
}

class _TakeoffState extends State<Takeoff>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool                  _loading = true;
  String?               _error;
  Map<String, dynamic>? _data;

  static const _tabs = [
    {'label': 'Brickwork', 'icon': LucideIcons.layers},
    {'label': 'Sitework',  'icon': LucideIcons.shovel},
    {'label': 'Structure', 'icon': LucideIcons.building2},
    {'label': 'Finishing', 'icon': LucideIcons.paintbrush},
    {'label': 'MEP',       'icon': LucideIcons.zap},
    {'label': 'Openings',  'icon': LucideIcons.doorOpen},
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs     = await SharedPreferences.getInstance();
      final projectId = prefs.getString('current_project_id') ?? '';

      if (projectId.isEmpty) {
        setState(() {
          _error   = 'No project selected.\nPlease select a project first.';
          _loading = false;
        });
        return;
      }

      final result = await ApiService.getTakeoff(projectId);
      if (result['success'] == true) {
        setState(() { _data = result; _loading = false; });
      } else {
        setState(() {
          _error   = result['error'] ?? 'Failed to load takeoff data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  static double _d(dynamic v) =>
      v == null ? 0.0
          : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);

  static int _i(dynamic v) =>
      v == null ? 0
          : (v is int ? v : int.tryParse(v.toString()) ?? 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Material Quantity Takeoff (QTO)',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                SizedBox(height: 4),
                Text('Quantities extracted from OCR floor plan',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B))),
              ],
            ),
            Row(children: [
              IconButton(
                onPressed: _load,
                icon: const Icon(LucideIcons.refreshCw,
                    size: 18, color: Color(0xFF64748B)),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Export QTO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 20),

        if (_loading)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      color: Color(0xFF1E6FD9)),
                  SizedBox(height: 16),
                  Text('Loading takeoff data...',
                      style: TextStyle(
                          color: Color(0xFF64748B))),
                ],
              ),
            ),
          )
        else if (_error != null)
          Expanded(child: _buildError())
        else ...[

          // ── Summary Cards ──────────────────────────
          _buildSummaryCards(),
          const SizedBox(height: 16),

          // ── Tab Bar ────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E6FD9),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1E6FD9),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              isScrollable: false,
              tabs: _tabs.map((t) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t['icon'] as IconData, size: 15),
                    const SizedBox(width: 6),
                    Text(t['label'] as String,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab Content ────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBrickworkTab(),
                _buildGenericTab('sitework'),
                _buildGenericTab('structure'),
                _buildGenericTab('finishing'),
                _buildMEPTab(),
                _buildOpeningsTab(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Summary Cards ──────────────────────────────────────
  Widget _buildSummaryCards() {
    final s = _data!['summary'] ?? {};
    return Row(children: [
      _card('Floor Area',
          '${_d(s['total_area_sqft']).toStringAsFixed(0)}',
          'Sqft',
          '${_d(s['total_area_sqm'])} m²',
          const Color(0xFF1E6FD9),
          const Color(0xFFEFF6FF),
          LucideIcons.layoutDashboard),
      const SizedBox(width: 12),
      _card('Total Walls',
          '${_i(s['total_walls'])}',
          'walls',
          'Ext + Int',
          const Color(0xFFDC2626),
          const Color(0xFFFEF2F2),
          LucideIcons.layers),
      const SizedBox(width: 12),
      _card('Windows',
          '${_i(s['total_windows'])}',
          'types',
          'From OCR',
          const Color(0xFF0D9488),
          const Color(0xFFF0FDFA),
          LucideIcons.appWindow),
      const SizedBox(width: 12),
      _card('Doors',
          '${_i(s['total_doors'])}',
          'types',
          'From OCR',
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
          LucideIcons.doorOpen),
      const SizedBox(width: 12),
      _card('Zones',
          '${_i(s['total_zones'])}',
          'rooms',
          'Detected',
          const Color(0xFFF59E0B),
          const Color(0xFFFFFBEB),
          LucideIcons.box),
      const SizedBox(width: 12),
      _card('Perimeter',
          '${_d(s['perimeter_m']).toStringAsFixed(1)}',
          'm',
          'Est. perimeter',
          const Color(0xFF64748B),
          const Color(0xFFF8FAFC),
          LucideIcons.move),
    ]);
  }

  // ── Brickwork Tab ──────────────────────────────────────
  Widget _buildBrickworkTab() {
    final bw   = _data!['tabs']['brickwork'] ?? {};
    final rows = (bw['rows'] as List?) ?? [];
    final tots = bw['totals'] ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((_data!['zones'] as List?)?.isNotEmpty == true)
            _buildZoneCards(),
          const SizedBox(height: 16),
          _buildTable(
            title:    'Gross Quantity of Brick Work',
            subtitle: 'Formula: L × B × H × Nos = Cu.Ft',
            color:    const Color(0xFFDC2626),
            headers: const [
              'Description', 'Nos', 'L (ft)',
              'B (ft)', 'H (ft)', 'Qty (Cu.Ft)',
              'Qty (m³)', 'Type',
            ],
            rows: rows.map<List<String>>((r) => [
              r['description'] ?? '',
              '${r['nos'] ?? 1}',
              _d(r['L']).toStringAsFixed(2),
              '${r['B'] ?? 0}',
              '${r['H'] ?? 0}',
              _d(r['qty_cuft']).toStringAsFixed(3),
              _d(r['qty_cum']).toStringAsFixed(4),
              r['type'] ?? '',
            ]).toList(),
            footer: 'Total Brickwork: '
                '${_d(tots['total_cuft']).toStringAsFixed(3)} Cu.Ft'
                ' = ${_d(tots['total_cum']).toStringAsFixed(4)} m³',
            footerColor: const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  // ── Zone Cards ─────────────────────────────────────────
  Widget _buildZoneCards() {
    final zones = (_data!['zones'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Zone / Room Areas',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:  5,
            crossAxisSpacing: 10,
            mainAxisSpacing:  10,
            childAspectRatio: 2.0,
          ),
          itemCount: zones.length,
          itemBuilder: (_, i) {
            final z = zones[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(z['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${_d(z['area_sqft']).toStringAsFixed(0)} sqft',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E6FD9)),
                  ),
                  Text(
                    '${_d(z['pct_of_total'])}% of total',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Generic Tab (Sitework / Structure / Finishing) ─────
  Widget _buildGenericTab(String tabKey) {
    final tab  = _data!['tabs'][tabKey] ?? {};
    final rows = (tab['rows'] as List?) ?? [];

    final colors = {
      'sitework':  const Color(0xFF0D9488),
      'structure': const Color(0xFF1E6FD9),
      'finishing': const Color(0xFF7C3AED),
    };
    final color = colors[tabKey] ?? const Color(0xFF64748B);

    return SingleChildScrollView(
      child: _buildTable(
        title:    tab['label'] ?? tabKey,
        subtitle: 'Estimated from floor plan data',
        color:    color,
        headers: const [
          'Description', 'Nos', 'Qty', 'Unit', 'Notes',
        ],
        rows: rows.map<List<String>>((r) => [
          r['description'] ?? '',
          '${r['nos'] ?? 1}',
          _d(r['qty']).toStringAsFixed(3),
          r['unit']  ?? '',
          r['notes'] ?? '',
        ]).toList(),
        footer:      '${rows.length} items',
        footerColor: color,
      ),
    );
  }

  // ── MEP Tab ────────────────────────────────────────────
  Widget _buildMEPTab() {
    final tab  = _data!['tabs']['mep'] ?? {};
    final rows = (tab['rows'] as List?) ?? [];

    return SingleChildScrollView(
      child: _buildTable(
        title:    'MEP — Mechanical, Electrical & Plumbing',
        subtitle: 'Estimated from floor area',
        color:    const Color(0xFFF59E0B),
        headers: const [
          'Description', 'Nos', 'Qty', 'Unit', 'Notes',
        ],
        rows: rows.map<List<String>>((r) => [
          r['description'] ?? '',
          '${r['nos'] ?? 1}',
          '${_i(r['qty'])}',
          r['unit']  ?? '',
          r['notes'] ?? '',
        ]).toList(),
        footer:      '${rows.length} items',
        footerColor: const Color(0xFFF59E0B),
      ),
    );
  }

  // ── Openings Tab ───────────────────────────────────────
  Widget _buildOpeningsTab() {
    final tab     = _data!['tabs']['openings'] ?? {};
    final windows = (tab['windows'] as List?) ?? [];
    final doors   = (tab['doors']   as List?) ?? [];
    final totals  = tab['totals'] ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _miniCard(
              'Windows Area',
              '${_d(totals['window_area_sqft']).toStringAsFixed(1)} sqft',
              const Color(0xFF0D9488),
            ),
            const SizedBox(width: 12),
            _miniCard(
              'Doors Area',
              '${_d(totals['door_area_sqft']).toStringAsFixed(1)} sqft',
              const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 12),
            _miniCard(
              'Total Openings',
              '${_d(totals['total_area_sqft']).toStringAsFixed(1)} sqft',
              const Color(0xFF1E6FD9),
            ),
          ]),
          const SizedBox(height: 16),

          // Windows table
          _buildTable(
            title:    'Windows & Ventilators',
            subtitle: 'Schedule of Openings — L × H × Nos',
            color:    const Color(0xFF0D9488),
            headers: const [
              'Description', 'Nos',
              'Width (ft)', 'Height (ft)', 'Area (Sqft)',
            ],
            rows: windows.map<List<String>>((w) => [
              w['description'] ?? '',
              '${w['nos'] ?? 1}',
              '${w['width_ft']  ?? 0}',
              '${w['height_ft'] ?? 0}',
              _d(w['area_sqft']).toStringAsFixed(2),
            ]).toList(),
            footer:
                'Total Window Area: '
                '${_d(totals['window_area_sqft']).toStringAsFixed(2)} Sqft',
            footerColor: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 16),

          // Doors table
          _buildTable(
            title:    'Doors',
            subtitle: 'Schedule of Openings — L × H × Nos',
            color:    const Color(0xFF7C3AED),
            headers: const [
              'Description', 'Nos',
              'Width (ft)', 'Height (ft)', 'Area (Sqft)',
            ],
            rows: doors.map<List<String>>((d) => [
              d['description'] ?? '',
              '${d['nos'] ?? 1}',
              '${d['width_ft']  ?? 0}',
              '${d['height_ft'] ?? 0}',
              _d(d['area_sqft']).toStringAsFixed(2),
            ]).toList(),
            footer:
                'Total Door Area: '
                '${_d(totals['door_area_sqft']).toStringAsFixed(2)} Sqft',
            footerColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  // ── Reusable Table ─────────────────────────────────────
  Widget _buildTable({
    required String        title,
    required String        subtitle,
    required Color         color,
    required List<String>  headers,
    required List<List<String>> rows,
    required String        footer,
    required Color         footerColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [

        // Title bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12)),
            border: Border(
                bottom: BorderSide(
                    color: color.withOpacity(0.2))),
          ),
          child: Row(children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8))),
              ],
            ),
          ]),
        ),

        // Header row
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
                bottom: BorderSide(
                    color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: headers.map((h) => Expanded(
              child: Text(h,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B))),
            )).toList(),
          ),
        ),

        // Data rows
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text('No data available',
                  style: TextStyle(
                      color: Color(0xFF94A3B8))),
            ),
          )
        else
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: i.isEven
                    ? Colors.white
                    : const Color(0xFFFAFAFA),
                border: const Border(
                    bottom: BorderSide(
                        color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: r.asMap().entries.map((e) =>
                  Expanded(
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 12,
                            color: e.key == 0
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF64748B),
                            fontWeight: e.key == 0
                                ? FontWeight.w500
                                : FontWeight.normal)),
                  ),
                ).toList(),
              ),
            );
          }),

        // Footer
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: footerColor,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(footer,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Icon(LucideIcons.circleCheck,
                  size: 16, color: Colors.white70),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Error Screen ───────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle),
            child: const Icon(LucideIcons.circleAlert,
                size: 40, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(LucideIcons.refreshCw,
                size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6FD9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────
  Widget _card(
    String label,
    String value,
    String unit,
    String sub,
    Color color,
    Color bg,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color)),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(width: 3),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 2),
                  child: Text(unit,
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.7))),
                ),
              ],
            ),
            Text(sub,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _miniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}