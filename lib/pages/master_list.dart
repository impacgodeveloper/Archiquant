import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';

class MasterList extends StatefulWidget {
  const MasterList({super.key});

  @override
  State<MasterList> createState() => _MasterListState();
}

class _MasterListState extends State<MasterList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _rates    = [];
  bool          _loading  = true;
  String?       _editingId;
  bool          _showAddForm = false;

  // Edit controllers
  final _rateCtrl      = TextEditingController();
  final _gstCtrl       = TextEditingController();
  final _loadingCtrl   = TextEditingController();
  final _transportCtrl = TextEditingController();
  final _distanceCtrl  = TextEditingController();
  final _unloadingCtrl = TextEditingController();
  final _notesCtrl     = TextEditingController();

  // Add form controllers
  final _addMaterialCtrl  = TextEditingController();
  final _addCategoryCtrl  = TextEditingController();
  final _addRateCtrl      = TextEditingController();
  final _addUnitCtrl      = TextEditingController();
  final _addGstCtrl       = TextEditingController();
  String _addCategory     = 'Bricks';

  static const _categories = [
    'Bricks', 'Cement', 'Sand', 'Labour', 'Other'
  ];

  static const _categoryColors = {
    'Bricks': Color(0xFFDC2626),
    'Cement': Color(0xFF1E6FD9),
    'Sand':   Color(0xFF0D9488),
    'Labour': Color(0xFF7C3AED),
    'Other':  Color(0xFF64748B),
  };

  static const _categoryIcons = {
    'Bricks': LucideIcons.layers,
    'Cement': LucideIcons.package,
    'Sand':   LucideIcons.box,
    'Labour': LucideIcons.hardHat,
    'Other':  LucideIcons.list,
  };

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _categories.length, vsync: this);
    _loadRates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rateCtrl.dispose();
    _gstCtrl.dispose();
    _loadingCtrl.dispose();
    _transportCtrl.dispose();
    _distanceCtrl.dispose();
    _unloadingCtrl.dispose();
    _notesCtrl.dispose();
    _addMaterialCtrl.dispose();
    _addCategoryCtrl.dispose();
    _addRateCtrl.dispose();
    _addUnitCtrl.dispose();
    _addGstCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMasterRates();
      if (mounted) setState(() { _rates = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seedRates() async {
    try {
      await ApiService.seedMasterRates();
      _loadRates();
      if (mounted) _showSnack('Default rates loaded!', true);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', false);
    }
  }

  Future<void> _saveRate(String id) async {
    try {
      await ApiService.updateMasterRate(id, {
        'rate':         double.tryParse(_rateCtrl.text)      ?? 0,
        'gst_pct':      double.tryParse(_gstCtrl.text)       ?? 0,
        'loading':      double.tryParse(_loadingCtrl.text)   ?? 0,
        'transport_km': double.tryParse(_transportCtrl.text) ?? 0,
        'distance_km':  double.tryParse(_distanceCtrl.text)  ?? 0,
        'unloading':    double.tryParse(_unloadingCtrl.text) ?? 0,
        'notes':        _notesCtrl.text.trim(),
      });
      setState(() => _editingId = null);
      _loadRates();
      if (mounted) _showSnack('Rate updated!', true);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', false);
    }
  }

  Future<void> _addRate() async {
    if (_addMaterialCtrl.text.trim().isEmpty ||
        _addRateCtrl.text.trim().isEmpty ||
        _addUnitCtrl.text.trim().isEmpty) {
      _showSnack('Material, rate and unit are required', false);
      return;
    }
    try {
      await ApiService.addMasterRate({
        'material':  _addMaterialCtrl.text.trim(),
        'category':  _addCategory,
        'rate':      double.tryParse(_addRateCtrl.text)  ?? 0,
        'unit':      _addUnitCtrl.text.trim(),
        'gst_pct':   double.tryParse(_addGstCtrl.text)   ?? 0,
        'loading':   0,
        'transport_km': 0,
        'distance_km':  0,
        'unloading': 0,
        'active':    true,
      });
      setState(() => _showAddForm = false);
      _addMaterialCtrl.clear();
      _addRateCtrl.clear();
      _addUnitCtrl.clear();
      _addGstCtrl.clear();
      _loadRates();
      if (mounted) _showSnack('Rate added!', true);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', false);
    }
  }

  Future<void> _deleteRate(String id, String material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Rate',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('Delete "$material"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteMasterRate(id);
      _loadRates();
      if (mounted) _showSnack('$material deleted', false);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', false);
    }
  }

  void _startEdit(Map<String, dynamic> rate) {
    _rateCtrl.text      = '${rate['rate']      ?? 0}';
    _gstCtrl.text       = '${rate['gst_pct']   ?? 0}';
    _loadingCtrl.text   = '${rate['loading']   ?? 0}';
    _transportCtrl.text = '${rate['transport_km'] ?? 0}';
    _distanceCtrl.text  = '${rate['distance_km'] ?? 0}';
    _unloadingCtrl.text = '${rate['unloading'] ?? 0}';
    _notesCtrl.text     = rate['notes']        ?? '';
    setState(() => _editingId = rate['id']);
  }

  // Calculate total cost at site
  double _totalCostAtSite(Map<String, dynamic> r) {
    final rate      = _toDouble(r['rate']);
    final gst       = rate * _toDouble(r['gst_pct']) / 100;
    final loading   = _toDouble(r['loading']);
    final transport = _toDouble(r['transport_km']) *
        _toDouble(r['distance_km']);
    final unloading = _toDouble(r['unloading']);
    return rate + gst + loading + transport + unloading;
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ));
  }

  List<dynamic> _ratesForCategory(String category) =>
      _rates.where((r) => r['category'] == category).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Master List',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text(
                    'Manage material rates, GST and transport costs',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Row(children: [
              IconButton(
                onPressed: _loadRates,
                icon: const Icon(LucideIcons.refreshCw,
                    size: 18, color: Color(0xFF64748B)),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              if (_rates.isEmpty)
                ElevatedButton.icon(
                  onPressed: _seedRates,
                  icon: const Icon(LucideIcons.download,
                      size: 16),
                  label: const Text('Load Default Rates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _showAddForm = !_showAddForm),
                icon: Icon(
                  _showAddForm ? LucideIcons.x : LucideIcons.plus,
                  size: 16,
                ),
                label: Text(
                    _showAddForm ? 'Cancel' : 'Add Rate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showAddForm
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E6FD9),
                  foregroundColor: _showAddForm
                      ? const Color(0xFF475569)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 20),

        // ── Add Rate Form ───────────────────────────────
        if (_showAddForm)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1E6FD9)
                      .withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Rate',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _addField(
                      'Material Name *', _addMaterialCtrl,
                      'e.g. Red Brick (9")')),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _addCategory,
                        decoration: _dec(),
                        items: _categories.map((c) =>
                          DropdownMenuItem(
                              value: c, child: Text(c))).toList(),
                        onChanged: (v) =>
                            setState(() => _addCategory = v!),
                      ),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _addField(
                      'Rate *', _addRateCtrl, 'e.g. 8.20',
                      type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _addField(
                      'Unit *', _addUnitCtrl, 'piece / bag / ton')),
                  const SizedBox(width: 12),
                  Expanded(child: _addField(
                      'GST %', _addGstCtrl, 'e.g. 18',
                      type: TextInputType.number)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addRate,
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Rate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6FD9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Tab Bar ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E6FD9),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF1E6FD9),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: false,
            tabs: _categories.map((cat) {
              final count = _ratesForCategory(cat).length;
              return Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categoryIcons[cat] ??
                          LucideIcons.list,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(cat),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E6FD9)
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF1E6FD9),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // ── Tab Content ──────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1E6FD9)),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _categories.map((cat) =>
                    _buildCategoryTab(cat)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(String category) {
    final items = _ratesForCategory(category);
    final color = _categoryColors[category] ??
        const Color(0xFF64748B);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_categoryIcons[category] ?? LucideIcons.list,
                size: 40, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text('No $category rates yet',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            const Text('Click "Add Rate" to add one',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            if (_rates.isEmpty)
              ElevatedButton(
                onPressed: _seedRates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Load Default Rates'),
              ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(children: [

        // Summary strip
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(_categoryIcons[category] ?? LucideIcons.list,
                size: 20, color: color),
            const SizedBox(width: 10),
            Text('$category Materials',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14)),
            const Spacer(),
            Text('${items.length} items',
                style: TextStyle(
                    fontSize: 13, color: color)),
          ]),
        ),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(12)),
            border: Border(
                bottom: BorderSide(
                    color: Color(0xFFE2E8F0))),
          ),
          child: const Row(children: [
            Expanded(flex: 3,
                child: Text('Material',
                    style: _hStyle)),
            Expanded(child: Text('Rate',
                style: _hStyle,
                textAlign: TextAlign.center)),
            Expanded(child: Text('Unit',
                style: _hStyle,
                textAlign: TextAlign.center)),
            Expanded(child: Text('GST%',
                style: _hStyle,
                textAlign: TextAlign.center)),
            Expanded(child: Text('Transport',
                style: _hStyle,
                textAlign: TextAlign.center)),
            Expanded(child: Text('Total/unit',
                style: _hStyle,
                textAlign: TextAlign.center)),
            SizedBox(width: 80,
                child: Text('Actions',
                    style: _hStyle,
                    textAlign: TextAlign.center)),
          ]),
        ),

        // Rows
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12)),
            border: Border.all(
                color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: items.map((r) {
              final id        = r['id'] as String;
              final isEditing = _editingId == id;
              final total     = _totalCostAtSite(r);

              if (isEditing) {
                return _editRow(r, color);
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Color(0xFFF1F5F9)))),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(r['material'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B))),
                            if ((r['notes'] ?? '').isNotEmpty)
                              Text(r['notes'],
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color:
                                          Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: Text(
                      '₹${_toDouble(r['rate']).toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: color),
                    ),
                  ),
                  Expanded(
                    child: Text(r['unit'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B))),
                  ),
                  Expanded(
                    child: Text(
                      '${_toDouble(r['gst_pct']).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '₹${(_toDouble(r['transport_km']) * _toDouble(r['distance_km'])).toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '₹${total.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1E293B)),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _startEdit(r),
                          borderRadius:
                              BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFEFF6FF),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: const Icon(
                                LucideIcons.pencil,
                                size: 14,
                                color: Color(0xFF1E6FD9)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _deleteRate(
                              id, r['material'] ?? ''),
                          borderRadius:
                              BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFFEF2F2),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: const Icon(
                                LucideIcons.trash2,
                                size: 14,
                                color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _editRow(Map<String, dynamic> r, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E6FD9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(r['material'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B))),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  setState(() => _editingId = null),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _saveRate(r['id']),
              icon: const Icon(LucideIcons.check, size: 14),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _editField(
                'Rate (₹)', _rateCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _editField(
                'GST %', _gstCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _editField(
                'Loading/piece', _loadingCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _editField(
                'Transport ₹/km', _transportCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _editField(
                'Distance km', _distanceCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _editField(
                'Unloading', _unloadingCtrl)),
          ]),
          const SizedBox(height: 10),
          _editField('Notes (optional)', _notesCtrl),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.number}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569))),
        const SizedBox(height: 4),
        TextFormField(
          controller:   ctrl,
          keyboardType: type,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                  color: Color(0xFFD0DAE8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                  color: Color(0xFF1E6FD9), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _addField(String label,
      TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextFormField(
          controller:   ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFFD0DAE8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF1E6FD9), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  InputDecoration _dec() => InputDecoration(
    border: OutlineInputBorder(
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
        horizontal: 12, vertical: 10),
  );

  static const _hStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0xFF64748B));
}