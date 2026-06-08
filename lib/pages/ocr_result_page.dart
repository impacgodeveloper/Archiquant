import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ocr_store.dart';
import '../services/api_service.dart';
import 'upload_plan.dart' show AppTheme, WallItem, OpeningItem, PointItem, SimpleItem, FloorPlanPainter;

// ─── RESULTS PAGE (room editor) ─────────────────────────────────────────────────
class OcrResultPage extends StatefulWidget {
  const OcrResultPage({super.key});
  @override
  State<OcrResultPage> createState() => _OcrResultPageState();
}

class _OcrResultPageState extends State<OcrResultPage> {
  bool _isSaving   = false;
  bool _metricMode = false;          // false = ft/in, true = m/mm
  String activeTool = 'measure';
  String _selectedCategory = 'Walls';

  List<dynamic> zones   = [];
  List<dynamic> doors   = [];
  List<dynamic> windows = [];
  Map<String, dynamic> _ocrData = {};

  final List<WallItem>    _walls       = [];
  final List<OpeningItem> _doorItems   = [];
  final List<OpeningItem> _windowItems = [];
  final List<PointItem>   _electrical  = [];
  final List<PointItem>   _plumbing    = [];
  final List<SimpleItem>  _ceiling     = [];
  final List<SimpleItem>  _flooring    = [];
  final List<SimpleItem>  _finishes    = [];
  final List<SimpleItem>  _furniture   = [];
  final List<SimpleItem>  _others      = [];

  static const List<Map<String, dynamic>> _categories = [
    {'id': 'Walls',      'icon': LucideIcons.building2,       'color': Color(0xFF0891B2)},
    {'id': 'Windows',    'icon': LucideIcons.appWindow,       'color': Color(0xFF8B5CF6)},
    {'id': 'Doors',      'icon': LucideIcons.doorOpen,        'color': Color(0xFF2DD4BF)},
    {'id': 'Electrical', 'icon': LucideIcons.zap,             'color': Color(0xFFF59E0B)},
    {'id': 'Plumbing',   'icon': LucideIcons.droplets,        'color': Color(0xFF3B82F6)},
    {'id': 'Ceiling',    'icon': LucideIcons.arrowUp,         'color': Color(0xFF6B7280)},
    {'id': 'Flooring',   'icon': LucideIcons.layers,          'color': Color(0xFF92400E)},
    {'id': 'Finishes',   'icon': LucideIcons.paintbrush,      'color': Color(0xFFEC4899)},
    {'id': 'Furniture',  'icon': LucideIcons.armchair,        'color': Color(0xFF059669)},
    {'id': 'Others',     'icon': LucideIcons.flipHorizontal2, 'color': Color(0xFF64748B)},
  ];

  static int    _toInt(dynamic v)    => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
  static double _toDouble(dynamic v) => v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);
  static double _sqrt(double v)      { double x = v / 2; for (int i = 0; i < 20; i++) x = (x + v / x) / 2; return x; }

  String _fmtL(double ft)   => _metricMode ? '${(ft * 0.3048).toStringAsFixed(2)} m'  : '${ft.toStringAsFixed(2)} ft';
  String _fmtH(double ft)   => _metricMode ? '${(ft * 0.3048).toStringAsFixed(2)} m'  : '${ft.toStringAsFixed(2)} ft';
  String _fmtW(int inch)    => _metricMode ? '${(inch * 25.4).toStringAsFixed(0)} mm' : '$inch in';
  String _fmtA(double sqft) => _metricMode ? '${(sqft * 0.0929).toStringAsFixed(2)} m²' : '${sqft.toStringAsFixed(2)} ft²';

  double _parseL(String s) { final v = double.tryParse(s) ?? 0; return _metricMode ? v / 0.3048 : v; }
  int    _parseW(String s) { final v = double.tryParse(s) ?? 0; return _metricMode ? (v / 25.4).round() : v.round(); }

  String get _lengthLabel => _metricMode ? 'Length (m)'  : 'Length (ft)';
  String get _heightLabel => _metricMode ? 'Height (m)'  : 'Height (ft)';
  String get _widthLabel  => _metricMode ? 'Width (mm)'  : 'Width (in)';

  @override
  void initState() {
    super.initState();
    final data = OcrStore.instance.data;
    if (data != null) {
      _ocrData = data;
      final z = data['zones'], d = data['doors'], w = data['windows'];
      zones   = z is Map ? z.values.toList() : (z is List ? z : []);
      doors   = d is Map ? d.values.toList() : (d is List ? d : []);
      windows = w is Map ? w.values.toList() : (w is List ? w : []);
      _buildComponentsFromOcr();
      // If the user already edited & saved this room, show their edits (not raw OCR)
      final edited = OcrStore.instance.editedComponents;
      if (edited != null) _buildComponentsFromEdited(edited);
    }
  }

  // Rebuild editor lists from a previously-saved _componentsJson (user edits).
  void _buildComponentsFromEdited(Map<String, dynamic> j) {
    List<T> parse<T>(String key, T Function(Map m) make) {
      final raw = j[key];
      if (raw is! List) return <T>[];
      return raw.whereType<Map>().map(make).toList();
    }
    int wi(dynamic v) => _toInt(v);
    double dd(dynamic v) => _toDouble(v);
    String ss(dynamic v) => v?.toString() ?? '';

    final walls = parse<WallItem>('walls', (m) => WallItem(
        room: ss(m['room']), component: ss(m['component']),
        l: dd(m['l']), h: dd(m['h']), w: wi(m['w']),
        material: ss(m['material']).isEmpty ? 'Brick' : ss(m['material']),
        position: ss(m['position']), nos: m['nos'] == null ? 1 : wi(m['nos'])));
    final doorsL = parse<OpeningItem>('doors', (m) => OpeningItem(
        room: ss(m['room']), component: ss(m['component']), type: 'Door',
        l: dd(m['l']), h: dd(m['h']), w: wi(m['w']),
        material: ss(m['material']).isEmpty ? 'Wood' : ss(m['material']),
        nos: m['nos'] == null ? 1 : wi(m['nos'])));
    final winsL = parse<OpeningItem>('windows', (m) => OpeningItem(
        room: ss(m['room']), component: ss(m['component']), type: 'Window',
        l: dd(m['l']), h: dd(m['h']), w: wi(m['w']),
        material: ss(m['material']).isEmpty ? 'Aluminum' : ss(m['material']),
        nos: m['nos'] == null ? 1 : wi(m['nos'])));
    SimpleItem mkSimple(String type, Map m) => SimpleItem(
        room: ss(m['room']), component: ss(m['component']), type: type,
        l: dd(m['l']), h: dd(m['h']), w: wi(m['w']),
        material: ss(m['material']));
    PointItem mkPoint(Map m) => PointItem(
        room: ss(m['room']), component: ss(m['component']), type: ss(m['type']));

    if (walls.isNotEmpty || j['walls'] is List) { _walls..clear()..addAll(walls); }
    if (j['doors'] is List)   { _doorItems..clear()..addAll(doorsL); }
    if (j['windows'] is List) { _windowItems..clear()..addAll(winsL); }
    if (j['electrical'] is List) { _electrical..clear()..addAll(parse('electrical', mkPoint)); }
    if (j['plumbing'] is List)   { _plumbing..clear()..addAll(parse('plumbing', mkPoint)); }
    if (j['ceiling'] is List)    { _ceiling..clear()..addAll(parse('ceiling', (m)=>mkSimple('Ceiling', m))); }
    if (j['flooring'] is List)   { _flooring..clear()..addAll(parse('flooring', (m)=>mkSimple('Flooring', m))); }
    if (j['finishes'] is List)   { _finishes..clear()..addAll(parse('finishes', (m)=>mkSimple('Finish', m))); }
    if (j['furniture'] is List)  { _furniture..clear()..addAll(parse('furniture', (m)=>mkSimple('Furniture', m))); }
    if (j['others'] is List)     { _others..clear()..addAll(parse('others', (m)=>mkSimple('Other', m))); }
  }

  int _countFor(String cat) {
    switch (cat) {
      case 'Walls':      return _walls.length;
      case 'Windows':    return _windowItems.length;
      case 'Doors':      return _doorItems.length;
      case 'Electrical': return _electrical.length;
      case 'Plumbing':   return _plumbing.length;
      case 'Ceiling':    return _ceiling.length;
      case 'Flooring':   return _flooring.length;
      case 'Finishes':   return _finishes.length;
      case 'Furniture':  return _furniture.length;
      case 'Others':     return _others.length;
      default:           return 0;
    }
  }

  double get _floorArea {
    if (zones.isNotEmpty) return zones.fold<double>(0, (s, z) => s + _toDouble(z['area_sqft']));
    if (_walls.length >= 2) {
      final lengths = _walls.map((w) => w.l).toList()..sort();
      return lengths.first * lengths.last;
    }
    return 0;
  }
  double get _perimeter   => _walls.fold<double>(0, (s, w) => s + w.l * 2);
  double get _wallArea    => _walls.fold<double>(0, (s, w) => s + w.sft);
  double get _openingArea =>
      _doorItems.fold<double>(0, (s, d) => s + d.sft) +
      _windowItems.fold<double>(0, (s, w) => s + w.sft);
  double get _netWallArea => _wallArea - _openingArea;

  // ── Build components from OCR result ──────────────────────────────────────
  void _buildComponentsFromOcr() {
    _walls.clear(); _doorItems.clear(); _windowItems.clear();
    final Set<String> addedWallIds = {};

    for (final zone in zones) {
      final name   = zone['label']?.toString() ?? zone['name']?.toString() ?? 'Room';
      final area   = _toDouble(zone['area_sqft']);
      final wFt    = _toDouble(zone['width_ft']);
      final lFt    = _toDouble(zone['length_ft']);
      final width  = wFt > 0 ? wFt : (area > 0 ? _sqrt(area) : 10.0);
      final length = lFt > 0 ? lFt : (area > 0 ? _sqrt(area) : 10.0);

      final extWalls = (zone['connected_external_walls'] as List?)?.cast<String>() ?? [];
      final intWalls = (zone['connected_internal_walls'] as List?)?.cast<String>() ?? [];

      for (final ewId in extWalls) {
        if (addedWallIds.contains(ewId)) continue;
        addedWallIds.add(ewId);
        final ewData = (_ocrData['external_walls'] ?? {})[ewId] as Map?;
        final wallL  = _toDouble(ewData?['length_ft']) > 0
            ? _toDouble(ewData?['length_ft'])
            : (ewId.contains('1') || ewId.contains('3') ? length : width);
        final wallH  = _toDouble(ewData?['height_ft']) > 0 ? _toDouble(ewData?['height_ft']) : 10.0;
        final wallT  = _toInt(ewData?['thickness_in']) > 0 ? _toInt(ewData?['thickness_in']) : 9;
        final wallP  = ewData?['position']?.toString() ?? '';
        _walls.add(WallItem(room: name, component: ewId.toUpperCase(),
            l: wallL, h: wallH, w: wallT, material: 'Brick', position: wallP));
      }

      for (final iwId in intWalls) {
        if (addedWallIds.contains(iwId)) continue;
        addedWallIds.add(iwId);
        final iwData = (_ocrData['internal_walls'] ?? {})[iwId] as Map?;
        final wallL  = _toDouble(iwData?['length_ft']) > 0
            ? _toDouble(iwData?['length_ft'])
            : (iwId.contains('1') || iwId.contains('3') ? length : width);
        final wallH  = _toDouble(iwData?['height_ft']) > 0 ? _toDouble(iwData?['height_ft']) : 10.0;
        final wallT  = _toInt(iwData?['thickness_in']) > 0 ? _toInt(iwData?['thickness_in']) : 4;
        final wallP  = iwData?['position']?.toString() ?? '';
        _walls.add(WallItem(room: name, component: iwId.toUpperCase(),
            l: wallL, h: wallH, w: wallT, material: 'Brick', position: wallP));
      }
    }

    final doorsMap = (_ocrData['doors'] ?? {}) as Map<String, dynamic>;
    for (final entry in doorsMap.entries) {
      final dId   = entry.key;
      final dData = entry.value as Map?;
      final dL    = _toDouble(dData?['width_ft'])  > 0 ? _toDouble(dData?['width_ft'])  : 3.0;
      final dH    = _toDouble(dData?['height_ft']) > 0 ? _toDouble(dData?['height_ft']) : 7.0;
      final onW   = dData?['on_wall']?.toString() ?? 'unknown';
      _doorItems.add(OpeningItem(
        room: _roomForOpening(dId, 'doors'),
        component: '$dId (${onW.toUpperCase()})',
        type: 'Door', l: dL, h: dH, w: 6,
      ));
    }

    final windowsMap = (_ocrData['windows'] ?? {}) as Map<String, dynamic>;
    for (final entry in windowsMap.entries) {
      final wId   = entry.key;
      final wData = entry.value as Map?;
      final wL    = _toDouble(wData?['width_ft'])  > 0 ? _toDouble(wData?['width_ft'])  : 4.0;
      final wH    = _toDouble(wData?['height_ft']) > 0 ? _toDouble(wData?['height_ft']) : 4.0;
      final onW   = wData?['on_wall']?.toString() ?? 'unknown';
      _windowItems.add(OpeningItem(
        room: _roomForOpening(wId, 'windows'),
        component: '$wId (${onW.toUpperCase()})',
        type: 'Window', l: wL, h: wH, w: 4, material: 'Aluminum',
      ));
    }
  }

  String _roomForOpening(String openingId, String type) {
    for (final zone in zones) {
      final list = (zone[type == 'doors' ? 'doors' : 'windows'] as List?)?.cast<String>() ?? [];
      if (list.contains(openingId)) {
        return zone['label']?.toString() ?? zone['name']?.toString() ?? 'Room';
      }
    }
    return 'Common';
  }

  // Serialise the full editor state for the backend (JSON blob + rows)
  Map<String, dynamic> _componentsJson() {
    Map<String, dynamic> dim(dynamic c) => {
          'component': c.component, 'l': c.l, 'h': c.h, 'w': c.w,
          'material': c.material, 'room': c.room,
          if (c is WallItem || c is OpeningItem) 'nos': c.nos,
          if (c is WallItem) 'position': c.position,
        };
    Map<String, dynamic> pt(PointItem c) =>
        {'component': c.component, 'type': c.type, 'room': c.room};
    return {
      'walls':      _walls.map(dim).toList(),
      'doors':      _doorItems.map(dim).toList(),
      'windows':    _windowItems.map(dim).toList(),
      'ceiling':    _ceiling.map(dim).toList(),
      'flooring':   _flooring.map(dim).toList(),
      'finishes':   _finishes.map(dim).toList(),
      'furniture':  _furniture.map(dim).toList(),
      'others':     _others.map(dim).toList(),
      'electrical': _electrical.map(pt).toList(),
      'plumbing':   _plumbing.map(pt).toList(),
    };
  }

  Future<void> _saveRoom() async {
    setState(() => _isSaving = true);
    try {
      final prefs     = await SharedPreferences.getInstance();
      final projectId = prefs.getString('current_project_id') ?? '';
      if (projectId.isEmpty) throw Exception('No project selected');

      final payload = _componentsJson();
      final res = await ApiService.saveRoomComponents(projectId, payload);
      if (res['success'] != true) throw Exception(res['error'] ?? 'Save failed');
      // Remember edits so returning to this page shows them (not raw OCR)
      OcrStore.instance.editedComponents = payload;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Room saved — ${res['saved'] ?? 0} components persisted '
              '(${_walls.length} walls • ${_doorItems.length} doors • ${_windowItems.length} windows)',
              style: const TextStyle(fontSize: 13, color: Colors.white)),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e',
              style: const TextStyle(fontSize: 13, color: Colors.white)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!OcrStore.instance.hasData) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(LucideIcons.fileX, size: 48, color: AppTheme.slate400),
            const SizedBox(height: 16),
            const Text('No plan analyzed yet.',
                style: TextStyle(fontSize: 16, color: AppTheme.slate500)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/upload'),
              icon: const Icon(LucideIcons.upload, size: 16),
              label: const Text('Upload a Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ]),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plan Analysis Results',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 4),
              Text('Detected zones, walls, doors and windows — review, edit, then cost it',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
            ]),
          ),
          TextButton.icon(
            onPressed: () => context.go('/upload'),
            icon: const Icon(LucideIcons.upload, size: 16, color: Colors.white70),
            label: const Text('New Plan', style: TextStyle(color: Colors.white70)),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _buildRoomEditor()),
      ]),
    );
  }

  Widget _buildRoomEditor() {
    return LayoutBuilder(builder: (ctx, c) {
      final wide = c.maxWidth >= 1000;
      if (wide) {
        // ── Wide (laptop/desktop): 3 columns side-by-side ──
        return Column(children: [
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 200, child: _categoryListCard()),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: _floorPlanCard()),
              const SizedBox(width: 12),
              SizedBox(width: 340, child: _detailsCard()),
            ]),
          ),
          const SizedBox(height: 12),
          _buildBottomBar(),
        ]);
      }
      // ── Narrow (mobile/tablet): stacked + scroll ──
      return SingleChildScrollView(
        child: Column(children: [
          _categoryBar(),
          const SizedBox(height: 12),
          SizedBox(height: 340, child: _floorPlanCard()),
          const SizedBox(height: 12),
          SizedBox(height: 380, child: _detailsCard()),
          const SizedBox(height: 12),
          _buildBottomBar(),
        ]),
      );
    });
  }

  // Horizontal category selector for narrow screens
  Widget _categoryBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categories.map((cat) {
          final id       = cat['id'] as String;
          final icon     = cat['icon'] as IconData;
          final color    = cat['color'] as Color;
          final count    = _countFor(id);
          final selected = _selectedCategory == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppTheme.primaryBlue : AppTheme.slate200),
                ),
                child: Row(children: [
                  Icon(icon, size: 14, color: selected ? Colors.white : color),
                  const SizedBox(width: 6),
                  Text(id, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.slate700)),
                  const SizedBox(width: 6),
                  Text('$count', style: TextStyle(fontSize: 11,
                      color: selected ? Colors.white70 : AppTheme.slate400)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _categoryListCard() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.slate200)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.slate200))),
          child: const Row(children: [
            Icon(LucideIcons.layoutList, size: 16, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Room Components', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate800)),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _categories.map((cat) {
              final id       = cat['id'] as String;
              final icon     = cat['icon'] as IconData;
              final color    = cat['color'] as Color;
              final count    = _countFor(id);
              final selected = _selectedCategory == id;
              return InkWell(
                onTap: () => setState(() => _selectedCategory = id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.transparent,
                    border: selected
                        ? const Border(left: BorderSide(color: AppTheme.primaryBlue, width: 3))
                        : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
                  ),
                  child: Row(children: [
                    Icon(icon, size: 16, color: selected ? AppTheme.primaryBlue : color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(id,
                        style: TextStyle(fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? AppTheme.primaryBlue : AppTheme.slate700))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryBlue : AppTheme.slate100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppTheme.slate500)),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _floorPlanCard() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.slate200)),
      child: Column(children: [
        _buildToolbar(),
        Expanded(
          child: Container(
            color: AppTheme.slate100,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.slate800, width: 3),
                      color: AppTheme.white,
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                    ),
                    child: SizedBox(
                      width: 520, height: 400,
                      child: CustomPaint(
                        painter: FloorPlanPainter(zones: zones, ocrData: _ocrData),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
  }

  Widget _buildToolbar() {
    final tools = [
      ('select',  LucideIcons.mousePointer, 'Select'),
      ('measure', LucideIcons.ruler,        'Measure'),
      ('draw',    LucideIcons.penTool,      'Draw'),
      ('zoomIn',  LucideIcons.zoomIn,       'Zoom In'),
      ('zoomOut', LucideIcons.zoomOut,      'Zoom Out'),
      ('pan',     LucideIcons.move,         'Pan'),
      ('reset',   LucideIcons.rotateCcw,    'Reset'),
    ];
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppTheme.slate200)),
      ),
      child: Row(children: [
        ...tools.map((t) => _buildToolButton(t.$1, t.$2, t.$3)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3))),
          child: const Row(children: [
            Icon(LucideIcons.hash, size: 14, color: AppTheme.primaryBlue),
            SizedBox(width: 4),
            Text('Scale: 1:100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primaryBlue)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildToolButton(String id, IconData icon, String label) {
    final isActive = activeTool == id;
    return InkWell(
      onTap: () => setState(() => activeTool = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: isActive ? AppTheme.primaryBlue : AppTheme.slate600),
          if (isActive) ...[
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primaryBlue)),
          ],
        ]),
      ),
    );
  }

  Widget _detailsCard() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.slate200)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: AppTheme.slate200)),
          ),
          child: Row(children: [
            Text(_selectedCategory, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
            const Spacer(),
            Container(
              decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _unitChip('ft', !_metricMode),
                _unitChip('m',   _metricMode),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Icon(LucideIcons.check, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text('Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.green)),
              ]),
            ),
          ]),
        ),
        Expanded(child: _buildComponentTable()),
      ]),
    );
  }

  Widget _unitChip(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _metricMode = label == 'm'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.slate500)),
      ),
    );
  }

  Widget _buildComponentTable() {
    final rows = _rowsForCategory(_selectedCategory);
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tableHeader(),
        if (rows.isEmpty)
          Padding(padding: const EdgeInsets.all(20),
            child: Text('No ${_selectedCategory.toLowerCase()} added yet.',
                style: const TextStyle(fontSize: 13, color: AppTheme.slate400)))
        else
          ...rows.asMap().entries.map((e) => _tableRow(e.key, e.value)),
        InkWell(
          onTap: () => _showAddDialog(_selectedCategory),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.slate100))),
            child: Row(children: [
              const Icon(LucideIcons.plus, size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Text('Add ${_selectedCategory.replaceAll(RegExp(r's$'), '')}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tableHeader() {
    final cols = _columnsForCategory(_selectedCategory);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.slate50,
      child: Row(children: [
        const SizedBox(width: 24, child: Text('No', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate500))),
        ...cols.map((c) => Expanded(child: Text(c, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate500)))),
        const SizedBox(width: 48, child: Text('Actions', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate500))),
      ]),
    );
  }

  List<String> _columnsForCategory(String cat) {
    if (cat == 'Electrical' || cat == 'Plumbing') return ['Component', 'Type'];
    final l = _metricMode ? 'L(m)'  : 'L(ft)';
    final h = _metricMode ? 'H(m)'  : 'H(ft)';
    final w = _metricMode ? 'W(mm)' : 'W(in)';
    final a = _metricMode ? 'Sqm'   : 'Sft';
    if (cat == 'Walls') return ['Component', 'Nos', 'Pos', l, h, w, a, 'Material'];
    if (cat == 'Doors' || cat == 'Windows') return ['Component', 'Nos', l, h, w, a, 'Material'];
    return ['Component', l, h, a, 'Material'];
  }

  List<List<String>> _rowsForCategory(String cat) {
    switch (cat) {
      case 'Walls':
        return _walls.map((w) => [w.component, '×${w.nos}', w.position.isEmpty ? '—' : w.position, _fmtL(w.l), _fmtH(w.h), _fmtW(w.w), _fmtA(w.sft), w.material]).toList();
      case 'Doors':
        return _doorItems.map((d) => [d.component, '×${d.nos}', _fmtL(d.l), _fmtH(d.h), _fmtW(d.w), _fmtA(d.sft), d.material]).toList();
      case 'Windows':
        return _windowItems.map((w) => [w.component, '×${w.nos}', _fmtL(w.l), _fmtH(w.h), _fmtW(w.w), _fmtA(w.sft), w.material]).toList();
      case 'Electrical': return _electrical.map((e) => [e.component, e.type]).toList();
      case 'Plumbing':   return _plumbing.map((p)   => [p.component, p.type]).toList();
      case 'Ceiling':    return _ceiling.map((c)    => [c.component, _fmtL(c.l), _fmtH(c.h), _fmtA(c.sft), c.material]).toList();
      case 'Flooring':   return _flooring.map((f)   => [f.component, _fmtL(f.l), _fmtH(f.h), _fmtA(f.sft), f.material]).toList();
      case 'Finishes':   return _finishes.map((f)   => [f.component, _fmtL(f.l), _fmtH(f.h), _fmtA(f.sft), f.material]).toList();
      case 'Furniture':  return _furniture.map((f)  => [f.component, _fmtL(f.l), _fmtH(f.h), _fmtA(f.sft), f.material]).toList();
      case 'Others':     return _others.map((o)     => [o.component, _fmtL(o.l), _fmtH(o.h), _fmtA(o.sft), o.material]).toList();
      default:           return [];
    }
  }

  Widget _tableRow(int index, List<String> values) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : AppTheme.slate50,
        border: const Border(bottom: BorderSide(color: AppTheme.slate100)),
      ),
      child: Row(children: [
        SizedBox(width: 24, child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: AppTheme.slate400))),
        ...values.map((v) => Expanded(child: Text(v, style: const TextStyle(fontSize: 11, color: AppTheme.slate700), overflow: TextOverflow.ellipsis))),
        SizedBox(width: 48, child: Row(children: [
          InkWell(onTap: () => _showEditDialog(_selectedCategory, index),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.pencil, size: 13, color: AppTheme.slate400))),
          InkWell(onTap: () => _deleteRow(_selectedCategory, index),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.trash2, size: 13, color: Color(0xFFEF4444)))),
        ])),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4, runSpacing: 8,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text('Room Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
            ),
            _summaryChip('Floor Area',    _metricMode ? '${(_floorArea   * 0.0929).toStringAsFixed(2)} m²' : '${_floorArea.toStringAsFixed(2)} ft²'),
            _summaryChip('Perimeter',     _metricMode ? '${(_perimeter   * 0.3048).toStringAsFixed(2)} m'  : '${_perimeter.toStringAsFixed(2)} ft'),
            _summaryChip('Wall Area',     _metricMode ? '${(_wallArea    * 0.0929).toStringAsFixed(2)} m²' : '${_wallArea.toStringAsFixed(2)} ft²'),
            _summaryChip('Opening Area',  _metricMode ? '${(_openingArea * 0.0929).toStringAsFixed(2)} m²' : '${_openingArea.toStringAsFixed(2)} ft²'),
            _summaryChip('Net Wall Area', _metricMode ? '${(_netWallArea * 0.0929).toStringAsFixed(2)} m²' : '${_netWallArea.toStringAsFixed(2)} ft²'),
            TextButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(LucideIcons.refreshCw, size: 13),
              label: const Text('Recalculate', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.slate50,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          border: Border(
            left:   BorderSide(color: AppTheme.slate200),
            right:  BorderSide(color: AppTheme.slate200),
            bottom: BorderSide(color: AppTheme.slate200),
          ),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4, runSpacing: 8,
          children: [
          _actionBtn(LucideIcons.building2, '+ Add Wall',       () => _showAddDialog('Walls')),
          _actionBtn(LucideIcons.appWindow, '+ Add Window',     () => _showAddDialog('Windows')),
          _actionBtn(LucideIcons.doorOpen,  '+ Add Door',       () => _showAddDialog('Doors')),
          _actionBtn(LucideIcons.zap,       '+ Add Electrical', () => _showAddDialog('Electrical')),
          _actionBtn(LucideIcons.droplets,  '+ Add Plumbing',   () => _showAddDialog('Plumbing')),
          _actionBtn(LucideIcons.plus,      '+ Add Other',      () => _showAddDialog('Others')),
          _actionBtn(LucideIcons.trash2,    'Clear All', _confirmClearAll, color: const Color(0xFFEF4444)),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveRoom,
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.save, size: 14),
            label: Text(_isSaving ? 'Saving…' : 'Save Room',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.slate300,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => context.go('/costing'),
            icon: const Icon(LucideIcons.arrowRight, size: 14),
            label: const Text('Go to Costing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _summaryChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.w500)),
        Text(value,  style: const TextStyle(fontSize: 12, color: AppTheme.slate800, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13, color: color ?? AppTheme.slate600),
      label: Text(label, style: TextStyle(fontSize: 12, color: color ?? AppTheme.slate600)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
    );
  }

  void _showAddDialog(String category) {
    setState(() => _selectedCategory = category);
    _openItemDialog(category, null, null);
  }

  void _showEditDialog(String category, int index) {
    _openItemDialog(category, index, _getItemAt(category, index));
  }

  Map<String, dynamic>? _getItemAt(String category, int index) {
    switch (category) {
      case 'Walls':      { final w = _walls[index];       return {'component': w.component, 'l': w.l, 'h': w.h, 'w': w.w, 'material': w.material, 'nos': w.nos}; }
      case 'Doors':      { final d = _doorItems[index];   return {'component': d.component, 'l': d.l, 'h': d.h, 'w': d.w, 'material': d.material, 'nos': d.nos}; }
      case 'Windows':    { final w = _windowItems[index]; return {'component': w.component, 'l': w.l, 'h': w.h, 'w': w.w, 'material': w.material, 'nos': w.nos}; }
      case 'Electrical': { final e = _electrical[index];  return {'component': e.component, 'type': e.type}; }
      case 'Plumbing':   { final p = _plumbing[index];    return {'component': p.component, 'type': p.type}; }
      default: return null;
    }
  }

  void _openItemDialog(String category, int? editIndex, Map<String, dynamic>? existing) {
    final compCtrl = TextEditingController(text: existing?['component'] ?? '');
    final lCtrl    = TextEditingController(text: existing?['l']?.toString() ?? '');
    final hCtrl    = TextEditingController(text: existing?['h']?.toString() ?? '');
    final wCtrl    = TextEditingController(text: existing?['w']?.toString() ?? '');
    final matCtrl  = TextEditingController(text: existing?['material'] ?? '');
    final typeCtrl = TextEditingController(text: existing?['type'] ?? '');
    final nosCtrl  = TextEditingController(text: existing?['nos']?.toString() ?? '1');
    final isPoint  = category == 'Electrical' || category == 'Plumbing';
    final hasNos   = category == 'Walls' || category == 'Doors' || category == 'Windows';
    final roomName = zones.isNotEmpty ? (zones.first['label']?.toString() ?? zones.first['name']?.toString() ?? 'Room') : 'Room';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${editIndex == null ? "Add" : "Edit"} ${category.replaceAll(RegExp(r's$'), '')}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: SizedBox(width: 320, child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field('Component Name', compCtrl),
          if (isPoint)
            _field('Type (e.g. Switch, Fan)', typeCtrl)
          else ...[
            Row(children: [
              Expanded(child: _field(_lengthLabel, lCtrl, num: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_heightLabel, hCtrl, num: true)),
            ]),
            Row(children: [
              Expanded(child: _field(_widthLabel, wCtrl, num: true)),
              const SizedBox(width: 8),
              Expanded(child: _field('Material', matCtrl)),
            ]),
            if (hasNos)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _field('Nos (count, e.g. 3 identical)', nosCtrl, num: true),
              ),
          ],
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final comp = compCtrl.text.isNotEmpty ? compCtrl.text : category;
                final l    = _parseL(lCtrl.text.isNotEmpty ? lCtrl.text : '10');
                final h    = _parseL(hCtrl.text.isNotEmpty ? hCtrl.text : '9');
                final w    = _parseW(wCtrl.text.isNotEmpty ? wCtrl.text : '9');
                final mat  = matCtrl.text.isNotEmpty ? matCtrl.text : 'Brick';
                final nos  = (int.tryParse(nosCtrl.text.trim()) ?? 1).clamp(1, 999);
                switch (category) {
                  case 'Walls':
                    // Guard thickness: a real brick wall is >= 3". If a too-thin
                    // value slips in, default by type (IW 4", EW/other 9").
                    final wallW = w >= 3
                        ? w
                        : (comp.toUpperCase().startsWith('IW') ? 4 : 9);
                    final item = WallItem(room: roomName, component: comp, l: l, h: h, w: wallW, material: mat, nos: nos);
                    editIndex != null ? _walls[editIndex] = item : _walls.add(item); break;
                  case 'Doors':
                    final item = OpeningItem(room: roomName, component: comp, type: 'Door', l: l, h: h, w: w, material: mat, nos: nos);
                    editIndex != null ? _doorItems[editIndex] = item : _doorItems.add(item); break;
                  case 'Windows':
                    final item = OpeningItem(room: roomName, component: comp, type: 'Window', l: l, h: h, w: w, material: mat, nos: nos);
                    editIndex != null ? _windowItems[editIndex] = item : _windowItems.add(item); break;
                  case 'Electrical':
                    final item = PointItem(room: roomName, component: comp, type: typeCtrl.text.isNotEmpty ? typeCtrl.text : 'Switch');
                    editIndex != null ? _electrical[editIndex] = item : _electrical.add(item); break;
                  case 'Plumbing':
                    final item = PointItem(room: roomName, component: comp, type: typeCtrl.text.isNotEmpty ? typeCtrl.text : 'Pipe');
                    editIndex != null ? _plumbing[editIndex] = item : _plumbing.add(item); break;
                  case 'Ceiling':
                    final item = SimpleItem(room: roomName, component: comp, type: 'Ceiling', l: l, h: h, w: w, material: mat);
                    editIndex != null ? _ceiling[editIndex] = item : _ceiling.add(item); break;
                  case 'Flooring':
                    final item = SimpleItem(room: roomName, component: comp, type: 'Flooring', l: l, h: h, w: w, material: mat);
                    editIndex != null ? _flooring[editIndex] = item : _flooring.add(item); break;
                  case 'Finishes':
                    final item = SimpleItem(room: roomName, component: comp, type: 'Finish', l: l, h: h, w: w, material: mat);
                    editIndex != null ? _finishes[editIndex] = item : _finishes.add(item); break;
                  case 'Furniture':
                    final item = SimpleItem(room: roomName, component: comp, type: 'Furniture', l: l, h: h, w: w, material: mat);
                    editIndex != null ? _furniture[editIndex] = item : _furniture.add(item); break;
                  case 'Others':
                    final item = SimpleItem(room: roomName, component: comp, type: 'Other', l: l, h: h, w: w, material: mat);
                    editIndex != null ? _others[editIndex] = item : _others.add(item); break;
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            child: Text(editIndex == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool num = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  void _deleteRow(String category, int index) {
    setState(() {
      switch (category) {
        case 'Walls':      _walls.removeAt(index);       break;
        case 'Doors':      _doorItems.removeAt(index);   break;
        case 'Windows':    _windowItems.removeAt(index); break;
        case 'Electrical': _electrical.removeAt(index);  break;
        case 'Plumbing':   _plumbing.removeAt(index);    break;
        case 'Ceiling':    _ceiling.removeAt(index);     break;
        case 'Flooring':   _flooring.removeAt(index);    break;
        case 'Finishes':   _finishes.removeAt(index);    break;
        case 'Furniture':  _furniture.removeAt(index);   break;
        case 'Others':     _others.removeAt(index);      break;
      }
    });
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will remove all components. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _walls.clear(); _doorItems.clear(); _windowItems.clear();
                _electrical.clear(); _plumbing.clear(); _ceiling.clear();
                _flooring.clear(); _finishes.clear(); _furniture.clear(); _others.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
