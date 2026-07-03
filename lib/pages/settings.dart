import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'team_management.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSaving        = false;
  bool _isSavingProfile = false;
  bool _isLoading       = true;
  bool _formulasLoading = true;

  Map<String, bool> toggleStates = {
    'Email Notifications':   true,
    'Push Notifications':    true,
    'Project Updates':       true,
    'Budget Alerts':         false,
    'Weekly Summary Report': true,
  };

  // Company settings
  String _currency          = 'INR';
  double _wastagePct        = 10.0;
  double _defaultWallHeight = 3.0;

  // Cement & Sand config
  String _defaultCementMix        = '1:4';
  String _defaultPlasterThickness = '18mm';
  String _defaultSandUnit         = 'tons';

  // Brick config
  String _brickFaceArea     = '0.75 * 0.25';
  String _bufferPct         = '10';
  String _redBrickThickness = '9';
  String _multiplier4inch   = '1.0';
  String _multiplier6inch   = '1.5';
  String _multiplier8inch   = '2.0';
  String _multiplier9inch   = '2.25';

  // Profile
  String _userId   = '';
  String _userRole = '';
  String _initials = '';

  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController  = TextEditingController();

  // Formulas
  List<Map<String, dynamic>> _formulas = [];
  final Map<String, TextEditingController> _formulaControllers = {};
  String? _editingFormulaId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    for (final c in _formulaControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSettings(), _loadFormulas()]);
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        ApiService.getSettings(),
        ApiService.getProfile(),
      ]);

      final settings = results[0] as Map<String, dynamic>;
      final profile  = results[1] as Map<String, dynamic>;

      final token = await ApiService.getToken();
      String userId = '';
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload    = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded    = utf8.decode(base64Url.decode(normalized));
          final data       = jsonDecode(decoded);
          userId = data['user_id'] ?? '';
        }
      }

      if (mounted) {
        setState(() {
          // Company settings
          _currency          = settings['currency']          ?? 'INR';
          _wastagePct        = _toDouble(settings['wastage_pct']);
          _defaultWallHeight = _toDouble(settings['default_wall_height']);

          // Cement & Sand config
          _defaultCementMix        = settings['default_cement_mix']        ?? '1:4';
          _defaultPlasterThickness = settings['default_plaster_thickness'] ?? '18mm';
          _defaultSandUnit         = settings['default_sand_unit']         ?? 'tons';

          _userId   = userId;
          _userRole = profile['role'] ?? 'admin';

          final email    = profile['email']     ?? '';
          final fullName = profile['full_name'] ?? '';
          final phone    = profile['phone']     ?? '';

          final displayName = fullName.isNotEmpty
              ? fullName
              : email.isNotEmpty
                  ? email.split('@').first
                  : 'User';

          _initials = displayName.isNotEmpty
              ? displayName[0].toUpperCase() : 'U';

          // ✅ All profile fields set from DB
          _nameController.text  = displayName;
          _emailController.text = email;
          _phoneController.text = phone;  // ← phone from DB
          _roleController.text  = _userRole == 'admin' ? 'Admin' : 'Architect';

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFormulas() async {
    try {
      final data = await ApiService.getFormulas();
      if (mounted) {
        setState(() {
          _formulas = data.cast<Map<String, dynamic>>();
          // Dispose any controllers from a previous load before recreating them,
          // otherwise each reload orphans the old TextEditingControllers.
          for (final c in _formulaControllers.values) {
            c.dispose();
          }
          _formulaControllers.clear();
          for (final f in _formulas) {
            final id   = f['id'] as String;
            final name = f['name'] as String;
            final expr = f['expression'] ?? '';
            _formulaControllers[id] =
                TextEditingController(text: expr);
            switch (name) {
              case 'brick_face_area':            _brickFaceArea     = expr; break;
              case 'buffer_percentage':          _bufferPct         = expr; break;
              case 'red_brick_thickness':        _redBrickThickness = expr; break;
              case 'thickness_multiplier_4inch': _multiplier4inch   = expr; break;
              case 'thickness_multiplier_6inch': _multiplier6inch   = expr; break;
              case 'thickness_multiplier_8inch': _multiplier8inch   = expr; break;
              case 'thickness_multiplier_9inch': _multiplier9inch   = expr; break;
            }
          }
          _formulasLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _formulasLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.updateSettings({
        'currency':                  _currency,
        'wastage_pct':               _wastagePct,
        'default_wall_height':       _defaultWallHeight,
        'default_cement_mix':        _defaultCementMix,
        'default_plaster_thickness': _defaultPlasterThickness,
        'default_sand_unit':         _defaultSandUnit,
        'updated_at':                DateTime.now().toIso8601String(),
      });
      if (mounted) _showSnackbar('Settings saved!', true);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to save: $e', false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveBrickConfig() async {
    final updates = {
      'brick_face_area':            _brickFaceArea,
      'buffer_percentage':          _bufferPct,
      'red_brick_thickness':        _redBrickThickness,
      'thickness_multiplier_4inch': _multiplier4inch,
      'thickness_multiplier_6inch': _multiplier6inch,
      'thickness_multiplier_8inch': _multiplier8inch,
      'thickness_multiplier_9inch': _multiplier9inch,
    };
    try {
      for (final f in _formulas) {
        final name = f['name'] as String;
        if (updates.containsKey(name)) {
          await ApiService.updateFormula(
              f['id'], updates[name]!, f['description'] ?? '');
        }
      }
      _showSnackbar('Brick configuration saved!', true);
      _loadFormulas();
    } catch (e) {
      _showSnackbar('Failed to save: $e', false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Name cannot be empty', false);
      return;
    }
    setState(() => _isSavingProfile = true);
    try {
      final result = await ApiService.updateProfile(
        fullName: _nameController.text.trim(),
        phone:    _phoneController.text.trim(),
      );
      if (result['success'] == true) {
        final name = _nameController.text.trim();
        setState(() {
          _initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        });
        _showSnackbar('Profile updated!', true);
      } else {
        _showSnackbar(result['error'] ?? 'Failed to update', false);
      }
    } catch (e) {
      _showSnackbar('Error: $e', false);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _saveFormula(String id, String name) async {
    final controller = _formulaControllers[id];
    if (controller == null) return;
    try {
      final formula = _formulas.firstWhere((f) => f['id'] == id);
      await ApiService.updateFormula(
          id, controller.text.trim(), formula['description'] ?? '');
      setState(() {
        final idx = _formulas.indexWhere((f) => f['id'] == id);
        if (idx != -1) {
          _formulas[idx] = {
            ..._formulas[idx],
            'expression': controller.text.trim(),
          };
        }
        _editingFormulaId = null;
      });
      _showSnackbar('Formula "$name" updated!', true);
    } catch (e) {
      _showSnackbar('Failed: $e', false);
    }
  }

  void _showSnackbar(String message, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? LucideIcons.circleCheck : LucideIcons.circleAlert,
          color: Colors.white, size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: success
          ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ));
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);

  final List<Map<String, dynamic>> quickLinks = const [
    {'label': 'Security & Privacy', 'icon': LucideIcons.shield,
     'description': 'Password, 2FA, session management'},
    {'label': 'Appearance',         'icon': LucideIcons.palette,
     'description': 'Theme, layout, display preferences'},
    {'label': 'Language & Region',  'icon': LucideIcons.globe,
     'description': 'Language, timezone, currency format'},
    {'label': 'Data & Storage',     'icon': LucideIcons.database,
     'description': 'Export data, storage usage, backups'},
    {'label': 'Email Templates',    'icon': LucideIcons.mail,
     'description': 'Customize notification templates'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E6FD9)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    SizedBox(height: 4),
                    Text(
                      'Manage your account preferences and application settings',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.save, size: 16),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6FD9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF1E6FD9).withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Company Settings ─────────────────────────────
          _sectionCard(
            icon: LucideIcons.settings,
            iconColor: const Color(0xFF1E6FD9),
            iconBg:    const Color(0xFFEFF6FF),
            title:     'Company Settings',
            child: Row(children: [
              Expanded(child: _fieldLabel('Currency',
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: _inputDec(),
                  items: const [
                    DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                  ],
                  onChanged: (v) => setState(() => _currency = v ?? 'INR'),
                ),
              )),
              const SizedBox(width: 20),
              Expanded(child: _fieldLabel('Wastage %',
                TextFormField(
                  initialValue: _wastagePct.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _inputDec(hint: 'e.g. 10'),
                  onChanged: (v) =>
                      _wastagePct = double.tryParse(v) ?? _wastagePct,
                ),
              )),
              const SizedBox(width: 20),
              Expanded(child: _fieldLabel('Default Wall Height (m)',
                TextFormField(
                  initialValue: _defaultWallHeight.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _inputDec(hint: 'e.g. 3.0'),
                  onChanged: (v) =>
                      _defaultWallHeight =
                          double.tryParse(v) ?? _defaultWallHeight,
                ),
              )),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Brick Configuration ──────────────────────────
          _sectionCard(
            icon:      LucideIcons.layers,
            iconColor: const Color(0xFFDC2626),
            iconBg:    const Color(0xFFFEF2F2),
            title:     'Brick Configuration',
            subtitle:  'Controls brick calculations for all projects',
            action: ElevatedButton.icon(
              onPressed: _formulasLoading ? null : _saveBrickConfig,
              icon: const Icon(LucideIcons.save, size: 14),
              label: const Text('Save Brick Config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            child: _formulasLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: Color(0xFF1E6FD9)),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: _fieldLabel(
                          'Brick Face Area (sqft)',
                          TextFormField(
                            initialValue: _brickFaceArea,
                            decoration: _inputDec(hint: '0.75 * 0.25'),
                            style: const TextStyle(fontFamily: 'monospace'),
                            onChanged: (v) => _brickFaceArea = v,
                          ),
                        )),
                        const SizedBox(width: 20),
                        Expanded(child: _fieldLabel(
                          'Buffer / Wastage %',
                          TextFormField(
                            initialValue: _bufferPct,
                            keyboardType: TextInputType.number,
                            decoration: _inputDec(hint: '10'),
                            onChanged: (v) => _bufferPct = v,
                          ),
                        )),
                        const SizedBox(width: 20),
                        Expanded(child: _fieldLabel(
                          'Red Brick Thickness (inch)',
                          TextFormField(
                            initialValue: _redBrickThickness,
                            keyboardType: TextInputType.number,
                            decoration: _inputDec(hint: '9'),
                            onChanged: (v) => _redBrickThickness = v,
                          ),
                        )),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Thickness Multipliers',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF475569))),
                      const SizedBox(height: 4),
                      const Text(
                        'Controls how many bricks are needed per sqft based on wall thickness',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _multiplierField(
                            '4" Wall', _multiplier4inch,
                            (v) => _multiplier4inch = v,
                            const Color(0xFF10B981))),
                        const SizedBox(width: 12),
                        Expanded(child: _multiplierField(
                            '6" Wall', _multiplier6inch,
                            (v) => _multiplier6inch = v,
                            const Color(0xFF0D9488))),
                        const SizedBox(width: 12),
                        Expanded(child: _multiplierField(
                            '8" Wall', _multiplier8inch,
                            (v) => _multiplier8inch = v,
                            const Color(0xFF1E6FD9))),
                        const SizedBox(width: 12),
                        Expanded(child: _multiplierField(
                            '9" Wall', _multiplier9inch,
                            (v) => _multiplier9inch = v,
                            const Color(0xFFDC2626))),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFDC2626)
                                  .withOpacity(0.2)),
                        ),
                        child: const Row(children: [
                          Icon(LucideIcons.info,
                              size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Red Brick Thickness: walls of this thickness (in inches) use Red Brick. '
                              'All other thicknesses use White Cement Block. '
                              'Multipliers control brick count per sqft of wall face.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF991B1B),
                                  height: 1.4),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // ── Cement & Sand Config ─────────────────────────
          _sectionCard(
            icon:      LucideIcons.flaskConical,
            iconColor: const Color(0xFF0D9488),
            iconBg:    const Color(0xFFF0FDFA),
            title:     'Cement & Sand Configuration',
            subtitle:  'Default mix ratio used in all calculations',
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _fieldLabel(
                    'Default Cement Mix',
                    DropdownButtonFormField<String>(
                      value: _defaultCementMix,
                      decoration: _inputDec(),
                      items: const [
                        DropdownMenuItem(value: '1:3', child: Text('1:3 CM (Rich mix)')),
                        DropdownMenuItem(value: '1:4', child: Text('1:4 CM (Standard) ★')),
                        DropdownMenuItem(value: '1:5', child: Text('1:5 CM (Medium)')),
                        DropdownMenuItem(value: '1:6', child: Text('1:6 CM (Lean mix)')),
                      ],
                      onChanged: (v) =>
                          setState(() => _defaultCementMix = v ?? '1:4'),
                    ),
                  )),
                  const SizedBox(width: 20),
                  Expanded(child: _fieldLabel(
                    'Plaster Thickness',
                    DropdownButtonFormField<String>(
                      value: _defaultPlasterThickness,
                      decoration: _inputDec(),
                      items: const [
                        DropdownMenuItem(value: '12mm', child: Text('12mm (Internal)')),
                        DropdownMenuItem(value: '18mm', child: Text('18mm (Standard) ★')),
                      ],
                      onChanged: (v) =>
                          setState(() => _defaultPlasterThickness = v ?? '18mm'),
                    ),
                  )),
                  const SizedBox(width: 20),
                  Expanded(child: _fieldLabel(
                    'Sand Unit',
                    DropdownButtonFormField<String>(
                      value: _defaultSandUnit,
                      decoration: _inputDec(),
                      items: const [
                        DropdownMenuItem(value: 'tons', child: Text('Tons (Weight) ★')),
                        DropdownMenuItem(value: 'cum',  child: Text('m³ (Volume)')),
                      ],
                      onChanged: (v) =>
                          setState(() => _defaultSandUnit = v ?? 'tons'),
                    ),
                  )),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF0D9488).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(LucideIcons.info,
                            size: 14, color: Color(0xFF0D9488)),
                        SizedBox(width: 6),
                        Text('Master Data Reference (Client BOQ)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF0D9488))),
                      ]),
                      const SizedBox(height: 10),
                      Table(
                        border: TableBorder.all(
                          color: const Color(0xFF0D9488).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        children: [
                          _tableHeaderRow(['Mix', '12mm\nBags/m³',
                              '18mm\nBags/m³', 'Sand\nm³/m³', 'Sand\nTons/m³']),
                          _tableDataRow(['1:3 CM', '2.6', '3.5', '1.25', '2.1'], false),
                          _tableDataRow(['1:4 CM ★', '2.0', '2.7', '1.35', '2.2'],
                              _defaultCementMix == '1:4'),
                          _tableDataRow(['1:5 CM', '1.7', '2.3', '1.40', '2.3'],
                              _defaultCementMix == '1:5'),
                          _tableDataRow(['1:6 CM', '1.5', '2.0', '1.50', '2.5'],
                              _defaultCementMix == '1:6'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Profile Settings ─────────────────────────────
          _sectionCard(
            icon:      LucideIcons.user,
            iconColor: const Color(0xFF1E6FD9),
            iconBg:    const Color(0xFFEFF6FF),
            title:     'Profile Settings',
            action: ElevatedButton.icon(
              onPressed: _isSavingProfile ? null : _saveProfile,
              icon: _isSavingProfile
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.save, size: 14),
              label: Text(_isSavingProfile ? 'Saving...' : 'Save Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(_initials,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E6FD9))),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_nameController.text,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _userRole == 'admin'
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _userRole == 'admin'
                                  ? const Color(0xFFBFDBFE)
                                  : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Text(
                            _userRole == 'admin' ? 'Admin' : 'Architect',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _userRole == 'admin'
                                    ? const Color(0xFF1E6FD9)
                                    : const Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_emailController.text,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B))),
                      ]),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 3.5,
                  children: [
                    _profileField('Full Name', _nameController),
                    _profileField('Email Address', _emailController,
                        readOnly: true),
                    _profileField('Phone Number', _phoneController,
                        hint: '+91 98765 43210',
                        keyboardType: TextInputType.phone),
                    _profileField('Role', _roleController,
                        readOnly: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Notification Preferences ─────────────────────
          _sectionCard(
            icon:      LucideIcons.bell,
            iconColor: const Color(0xFFD97706),
            iconBg:    const Color(0xFFFFFCF0),
            title:     'Notification Preferences',
            child: Column(
              children: toggleStates.entries.map((entry) =>
                InkWell(
                  onTap: () => setState(() =>
                      toggleStates[entry.key] = !entry.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                                fontSize: 14)),
                        _toggle(entry.value,
                            () => setState(() =>
                                toggleStates[entry.key] = !entry.value)),
                      ],
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Advanced Formulas ────────────────────────────
          _sectionCard(
            icon:      LucideIcons.calculator,
            iconColor: const Color(0xFF7C3AED),
            iconBg:    const Color(0xFFF5F3FF),
            title:     'Advanced Formulas',
            subtitle:  'Raw formula expressions — edit with caution',
            child: _formulasLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: Color(0xFF1E6FD9)),
                    ),
                  )
                : _formulas.isEmpty
                    ? _emptyFormulas()
                    : Column(
                        children: _formulas.map((f) {
                          final id        = f['id'] as String;
                          final name      = f['name'] as String;
                          final desc      = f['description'] ?? '';
                          final isEditing = _editingFormulaId == id;
                          final ctrl      = _formulaControllers[id]!;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isEditing
                                  ? const Color(0xFFF5F3FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isEditing
                                    ? const Color(0xFFC4B5FD)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF1E293B))),
                                    const SizedBox(height: 2),
                                    Text(desc,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              isEditing
                                  ? Row(children: [
                                      SizedBox(
                                        width: 160,
                                        child: TextFormField(
                                          controller: ctrl,
                                          autofocus: true,
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF7C3AED)),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFC4B5FD)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF7C3AED),
                                                  width: 2),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () =>
                                            _saveFormula(id, name),
                                        icon: const Icon(LucideIcons.check,
                                            size: 18,
                                            color: Color(0xFF10B981)),
                                        style: IconButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFECFDF5)),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed: () {
                                          ctrl.text =
                                              f['expression'] ?? '';
                                          setState(() =>
                                              _editingFormulaId = null);
                                        },
                                        icon: const Icon(LucideIcons.x,
                                            size: 18,
                                            color: Color(0xFFEF4444)),
                                        style: IconButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFFEF2F2)),
                                      ),
                                    ])
                                  : Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color:
                                                  const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          f['expression'] ?? '',
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E6FD9)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => setState(
                                            () => _editingFormulaId = id),
                                        icon: const Icon(LucideIcons.pencil,
                                            size: 16,
                                            color: Color(0xFF64748B)),
                                        style: IconButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFF1F5F9)),
                                      ),
                                    ]),
                            ]),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 24),

          // ── Team Management ──────────────────────────────
          TeamManagementCard(
            currentUserRole: _userRole,
            currentUserId:   _userId,
          ),
          const SizedBox(height: 24),

          // ── More Settings ────────────────────────────────
          _sectionCard(
            icon:      LucideIcons.layoutGrid,
            iconColor: const Color(0xFF64748B),
            iconBg:    const Color(0xFFF1F5F9),
            title:     'More Settings',
            child: Column(
              children: quickLinks.map((link) => InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(link['icon'],
                          size: 18, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(link['label'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text(link['description'],
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: Color(0xFF94A3B8)),
                  ]),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────

  Widget _multiplierField(
    String label, String value,
    Function(String) onChanged, Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            keyboardType: TextInputType.number,
            onChanged:    onChanged,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color, fontSize: 16),
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableHeaderRow(List<String> cells) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF0D9488)),
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 8),
        child: Text(c,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
      )).toList(),
    );
  }

  TableRow _tableDataRow(List<String> cells, bool highlight) {
    return TableRow(
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF0D9488).withOpacity(0.08)
            : Colors.white,
      ),
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 6),
        child: Text(c,
            style: TextStyle(
                fontSize: 11,
                fontWeight: highlight
                    ? FontWeight.bold : FontWeight.normal,
                color: highlight
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF475569))),
      )).toList(),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color    iconColor,
    required Color    iconBg,
    required String   title,
    String?           subtitle,
    Widget?           action,
    required Widget   child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B))),
                    ],
                  ],
                ),
              ),
              if (action != null) action,
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                fontSize: 14)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _profileField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          readOnly:     readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled:    readOnly,
            fillColor: readOnly ? const Color(0xFFF8FAFC) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD0DAE8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF1E6FD9), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _toggle(bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value
              ? const Color(0xFF1E6FD9) : const Color(0xFFCBD5E1),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: value ? 20 : 2, top: 2,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(
                    color: Colors.black12, blurRadius: 2)],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptyFormulas() {
    return Center(
      child: Column(children: [
        const Icon(LucideIcons.circleAlert,
            size: 32, color: Color(0xFF94A3B8)),
        const SizedBox(height: 8),
        const Text('No formulas found.',
            style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _seedFormulas,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6FD9),
              foregroundColor: Colors.white),
          child: const Text('Setup Default Formulas'),
        ),
      ]),
    );
  }

  Future<void> _seedFormulas() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/formulas/seed'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showSnackbar('Formulas setup successfully!', true);
        _loadFormulas();
      }
    } catch (e) {
      _showSnackbar('Failed: $e', false);
    }
  }

  InputDecoration _inputDec({String? hint}) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD0DAE8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
          color: Color(0xFF1E6FD9), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 12),
  );
}