import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/ocr_store.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────
class AppTheme {
  static const Color slate900      = Color(0xFF0F172A);
  static const Color slate800      = Color(0xFF1E293B);
  static const Color slate700      = Color(0xFF334155);
  static const Color slate600      = Color(0xFF475569);
  static const Color slate500      = Color(0xFF64748B);
  static const Color slate400      = Color(0xFF94A3B8);
  static const Color slate300      = Color(0xFFCBD5E1);
  static const Color slate200      = Color(0xFFE2E8F0);
  static const Color slate100      = Color(0xFFF1F5F9);
  static const Color slate50       = Color(0xFFF8FAFC);
  static const Color white         = Colors.white;
  static const Color primaryBlue   = Color(0xFF0891B2);
  static const Color teal400       = Color(0xFF2DD4BF);
  static const Color primaryOrange = Color(0xFFF97316);
}

// ─── Data models (shared with the results page) ────────────────────────────────
class WallItem {
  String room, component, material, position;
  double l, h;
  int w, nos;
  WallItem({required this.room, required this.component, required this.l,
      required this.h, required this.w, this.material = 'Brick', this.position = '',
      this.nos = 1});
  double get sft  => l * h * nos;
  double get cuft => l * h * (w / 12) * nos;
}

class OpeningItem {
  String room, component, type, material;
  double l, h;
  int w, nos;
  OpeningItem({required this.room, required this.component, required this.type,
      required this.l, required this.h, required this.w, this.material = 'Wood',
      this.nos = 1});
  double get sft  => l * h * nos;
  double get cuft => l * h * (w / 12) * nos;
}

class PointItem {
  String room, component, type;
  PointItem({required this.room, required this.component, required this.type});
}

class SimpleItem {
  String room, component, type, material;
  double l, h;
  int w;
  SimpleItem({required this.room, required this.component, required this.type,
      required this.l, required this.h, required this.w, this.material = ''});
  double get sft => l * h;
}

// ─── UPLOAD PAGE (upload only) ──────────────────────────────────────────────────
class PlanAnalyzerPage extends StatefulWidget {
  const PlanAnalyzerPage({super.key});
  @override
  State<PlanAnalyzerPage> createState() => _PlanAnalyzerPageState();
}

class _PlanAnalyzerPageState extends State<PlanAnalyzerPage> {
  bool _loading         = false;
  bool _loadingProjects = true;
  String? _errorMessage;

  List<dynamic> _projects      = [];
  String? _selectedProjectId;
  String? _selectedProjectName;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final dynamic raw = await ApiService.getProjects();
      List<dynamic> data;
      if (raw is List) {
        data = raw;
      } else if (raw is Map) {
        final val = raw['projects'] ?? raw['data'] ?? raw['items'];
        data = val is List ? val : [];
      } else {
        data = [];
      }
      final prefs   = await SharedPreferences.getInstance();
      final savedId = prefs.getString('current_project_id');
      setState(() {
        _projects        = data;
        _loadingProjects = false;
        if (savedId != null && _projects.any((p) => p['id'] == savedId)) {
          _selectedProjectId   = savedId;
          _selectedProjectName = _projects.firstWhere((p) => p['id'] == savedId)['name'];
        } else if (_projects.isNotEmpty) {
          _selectedProjectId   = _projects.first['id'];
          _selectedProjectName = _projects.first['name'];
        }
      });
    } catch (e) {
      setState(() { _loadingProjects = false; _errorMessage = 'Failed to load projects: $e'; });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      setState(() => _errorMessage = 'Please select a project first.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'], withData: true,
    );
    if (result == null) return;
    final bytes    = result.files.first.bytes;
    final fileName = result.files.first.name;
    if (bytes == null) { setState(() => _errorMessage = 'Could not read file bytes.'); return; }

    setState(() { _loading = true; _errorMessage = null; });

    try {
      final response = await ApiService.uploadBlueprint(_selectedProjectId!, bytes, fileName);
      if (response['success'] == false) throw Exception(response['error'] ?? 'Server error');

      final data = (response['data'] ?? {}) as Map<String, dynamic>;

      // Persist for the results page, then navigate there
      OcrStore.instance.save(data);

      if (mounted) {
        setState(() => _loading = false);
        context.go('/plan-result');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = e.toString(); _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Plan OCR Analyzer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text('Upload blueprints to extract dimensions, zones, doors, and windows',
              style: TextStyle(fontSize: 14, color: Colors.white70)),
        ]),
        const SizedBox(height: 16),
        _buildProjectSelector(),
        const SizedBox(height: 16),
        Expanded(child: _buildUploadView()),
      ]),
    );
  }

  Widget _buildProjectSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.slate200)),
      child: Row(children: [
        const Icon(LucideIcons.folder, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        const Text('Select Project:', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.slate700)),
        const SizedBox(width: 16),
        Expanded(
          child: _loadingProjects
              ? const Row(children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue)),
                  SizedBox(width: 8),
                  Text('Loading projects...', style: TextStyle(color: AppTheme.slate500)),
                ])
              : _projects.isEmpty
                  ? const Text('No projects found. Create one first.', style: TextStyle(color: AppTheme.slate500))
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProjectId,
                        isExpanded: true,
                        hint: const Text('Select a project'),
                        items: _projects.map((p) => DropdownMenuItem<String>(
                          value: p['id'] as String,
                          child: Row(children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(p['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Text(p['status'] ?? 'active', style: const TextStyle(fontSize: 12, color: AppTheme.slate400)),
                          ]),
                        )).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedProjectId   = value;
                            _selectedProjectName = _projects.firstWhere((p) => p['id'] == value)['name'];
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('current_project_id', value ?? '');
                        },
                      ),
                    ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppTheme.slate500),
          onPressed: _loadProjects, tooltip: 'Refresh projects',
        ),
      ]),
    );
  }

  Widget _buildUploadView() {
    final hasProject = _selectedProjectId != null && _selectedProjectId!.isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasProject ? AppTheme.slate200 : AppTheme.primaryOrange, width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(LucideIcons.upload, size: 40, color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: 24),
        const Text('Upload Blueprint or Floor Plan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
        const SizedBox(height: 12),
        if (hasProject)
          _pill(LucideIcons.folder, 'Project: $_selectedProjectName',
              const Color(0xFFECFEFF), const Color(0xFFA5F3FC), AppTheme.primaryBlue)
        else
          _pill(LucideIcons.circle, 'Please select a project above first',
              const Color(0xFFFFF7ED), const Color(0xFFFED7AA), AppTheme.primaryOrange),
        const SizedBox(height: 16),
        const Text(
          'Drag and drop your PDF, PNG, or JPG files here.\nOur system will automatically detect text and dimensions using OCR.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.slate600),
        ),
        const SizedBox(height: 32),
        if (_loading)
          const _LoadingHint(primary: 'Analyzing blueprint…', secondary: 'OCR processing may take 1-2 minutes')
        else
          ElevatedButton.icon(
            onPressed: hasProject ? _uploadFile : null,
            icon: const Icon(LucideIcons.upload, size: 16),
            label: const Text('Browse Files', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.slate300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        const SizedBox(height: 16),
        const Text('Maximum file size: 50 MB', style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.circle, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Flexible(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _pill(IconData icon, String text, Color bg, Color border, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg), const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg)),
      ]),
    );
  }
}

// ─── Loading hint (shared) ──────────────────────────────────────────────────────
class _LoadingHint extends StatelessWidget {
  final String primary, secondary;
  const _LoadingHint({required this.primary, required this.secondary});
  @override
  Widget build(BuildContext context) => Column(children: [
    const CircularProgressIndicator(color: AppTheme.primaryBlue),
    const SizedBox(height: 12),
    Text(primary,   style: const TextStyle(fontSize: 14, color: AppTheme.slate600)),
    const SizedBox(height: 4),
    Text(secondary, style: const TextStyle(fontSize: 12, color: AppTheme.slate400)),
  ]);
}

// ─── Floor plan painter (shared with results page) ──────────────────────────────
class FloorPlanPainter extends CustomPainter {
  final List<dynamic> zones;
  final Map<String, dynamic> ocrData;

  const FloorPlanPainter({required this.zones, required this.ocrData});

  static double _d(dynamic v) => v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (zones.isEmpty) { _drawEmpty(canvas, size); return; }

    final padding = 32.0;
    final drawW   = size.width  - padding * 2;
    final drawH   = size.height - padding * 2;

    final cols  = zones.length <= 3 ? zones.length : ((zones.length + 1) ~/ 2);
    final rows  = (zones.length / cols).ceil();
    final cellW = drawW / cols;
    final cellH = drawH / rows;

    final ewPaint     = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 4..style = PaintingStyle.stroke;
    final iwPaint     = Paint()..color = const Color(0xFF475569)..strokeWidth = 2..style = PaintingStyle.stroke;
    final zoneFill    = Paint()..style = PaintingStyle.fill;
    final doorPaint   = Paint()..color = AppTheme.primaryOrange..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final windowPaint = Paint()..color = AppTheme.primaryBlue..strokeWidth = 3..style = PaintingStyle.stroke;

    final zoneColors = [
      const Color(0xFFF0FDF4), const Color(0xFFEFF6FF), const Color(0xFFFFF7ED),
      const Color(0xFFFDF4FF), const Color(0xFFFFFBEB), const Color(0xFFF0FDFA),
      const Color(0xFFFEF2F2),
    ];

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < zones.length; i++) {
      final zone = zones[i] as Map;
      final col  = i % cols;
      final row  = i ~/ cols;

      final left = padding + col * cellW;
      final top  = padding + row * cellH;
      final rect = Rect.fromLTWH(left, top, cellW, cellH);

      zoneFill.color = zoneColors[i % zoneColors.length];
      canvas.drawRect(rect, zoneFill);

      final isTopEdge    = row == 0;
      final isBottomEdge = row == rows - 1;
      final isLeftEdge   = col == 0;
      final isRightEdge  = col == cols - 1;

      void drawSide(Offset a, Offset b, bool isOuter) =>
          canvas.drawLine(a, b, isOuter ? ewPaint : iwPaint);

      drawSide(Offset(left, top),         Offset(left + cellW, top),         isTopEdge);
      drawSide(Offset(left, top + cellH), Offset(left + cellW, top + cellH), isBottomEdge);
      drawSide(Offset(left, top),         Offset(left, top + cellH),         isLeftEdge);
      drawSide(Offset(left + cellW, top), Offset(left + cellW, top + cellH), isRightEdge);

      final label   = zone['label']?.toString() ?? zone['name']?.toString() ?? 'Zone ${i+1}';
      final wFt     = _d(zone['width_ft']);
      final lFt     = _d(zone['length_ft']);
      final dimText = (wFt > 0 && lFt > 0) ? '${wFt.toStringAsFixed(0)}\'×${lFt.toStringAsFixed(0)}\'' : '';
      final wallCnt = zone['total_walls_connected'] ?? 0;

      tp.text = TextSpan(children: [
        TextSpan(text: '$label\n',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        if (dimText.isNotEmpty)
          TextSpan(text: '$dimText\n',
              style: const TextStyle(fontSize: 9, color: Color(0xFF475569))),
        TextSpan(text: '$wallCnt walls',
            style: const TextStyle(fontSize: 9, color: Color(0xFF0891B2))),
      ]);
      tp.layout(maxWidth: cellW - 8);
      tp.paint(canvas, Offset(left + (cellW - tp.width) / 2, top + (cellH - tp.height) / 2));

      // Doors on bottom edge
      final zoneDoors = (zone['doors'] as List?)?.cast<String>() ?? [];
      for (int di = 0; di < zoneDoors.length; di++) {
        final dx    = left + cellW * (di + 1) / (zoneDoors.length + 1);
        final dy    = top + cellH;
        final doorW = (cellW * 0.12).clamp(12.0, 28.0);
        canvas.drawLine(Offset(dx - doorW / 2, dy), Offset(dx + doorW / 2, dy), doorPaint);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(dx - doorW / 2, dy), width: doorW, height: doorW),
          0, 1.57, false, doorPaint,
        );
      }

      // Windows on top edge
      final zoneWins = (zone['windows'] as List?)?.cast<String>() ?? [];
      for (int wi = 0; wi < zoneWins.length; wi++) {
        final wx   = left + cellW * (wi + 1) / (zoneWins.length + 1);
        final wy   = top;
        final winW = (cellW * 0.10).clamp(10.0, 24.0);
        canvas.drawLine(Offset(wx - winW / 2, wy - 2), Offset(wx + winW / 2, wy - 2), windowPaint);
        canvas.drawLine(Offset(wx - winW / 2, wy + 2), Offset(wx + winW / 2, wy + 2), windowPaint);
      }
    }

    _drawLegend(canvas, size);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final items = [
      (const Color(0xFF1E293B), 4.0, 'External Wall (EW)'),
      (const Color(0xFF475569), 2.0, 'Internal Wall (IW)'),
      (AppTheme.primaryOrange,  2.5, 'Door'),
      (AppTheme.primaryBlue,    3.0, 'Window'),
    ];
    double x = 12;
    final y = size.height - 18;
    for (final item in items) {
      canvas.drawLine(Offset(x, y), Offset(x + 18, y),
          Paint()..color = item.$1..strokeWidth = item.$2..style = PaintingStyle.stroke);
      x += 22;
      tp.text = TextSpan(text: item.$3,
          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)));
      tp.layout();
      tp.paint(canvas, Offset(x, y - 6));
      x += tp.width + 14;
    }
  }

  void _drawEmpty(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
      Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 2..style = PaintingStyle.stroke,
    );
    final tp = TextPainter(
      text: const TextSpan(text: 'Upload a floor plan to see the layout',
          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter old) =>
      old.zones != zones || old.ocrData != ocrData;
}
