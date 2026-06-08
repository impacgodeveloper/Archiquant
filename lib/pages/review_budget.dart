import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../services/api_service.dart';

class ReviewBudget extends StatefulWidget {
  const ReviewBudget({super.key});

  @override
  State<ReviewBudget> createState() => _ReviewBudgetState();
}

class _ReviewBudgetState extends State<ReviewBudget> {
  bool                   _loading = true;
  String?                _error;
  Map<String, dynamic>?  _data;
  String                 _projectName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs     = await SharedPreferences.getInstance();
      final projectId = prefs.getString('current_project_id') ?? '';
      _projectName    = prefs.getString('current_project_name') ?? 'Project';

      if (projectId.isEmpty) {
        setState(() {
          _error   = 'No project selected.\nPlease select a project first.';
          _loading = false;
        });
        return;
      }

      final result = await ApiService.getReviewBudget(projectId);
      if (result['success'] == true) {
        setState(() { _data = result; _loading = false; });
      } else {
        setState(() {
          _error   = result['error'] ?? 'Failed to load budget';
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

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  // ── Export ──────────────────────────────────────────────
  void _showExportMenu() async {
    final prefs     = await SharedPreferences.getInstance();
    final projectId = prefs.getString('current_project_id') ?? '';
    final token     = await ApiService.getToken() ?? '';

    if (projectId.isEmpty) return;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export BOQ',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            const Text('Choose export format',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14)),
            const SizedBox(height: 20),
            _exportOption(
              icon:  LucideIcons.fileText,
              color: const Color(0xFFEF4444),
              label: 'Export as PDF',
              sub:   'Full BOQ with rates and summary',
              onTap: () {
                Navigator.pop(context);
                _openUrl(
                  '${ApiService.baseUrl}/projects/$projectId/export/pdf?token=$token');
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon:  LucideIcons.table,
              color: const Color(0xFF10B981),
              label: 'Export as Excel',
              sub:   '4 sheets: BOQ, Bricks, Cement/Sand, Rates',
              onTap: () {
                Navigator.pop(context);
                _openUrl(
                  '${ApiService.baseUrl}/projects/$projectId/export/excel?token=$token');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openUrl(String urlStr) {
    try {
      html.window.open(urlStr, '_blank');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _exportOption({
    required IconData     icon,
    required Color        color,
    required String       label,
    required String       sub,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B))),
              ],
            ),
          ),
          Icon(LucideIcons.download, size: 18, color: color),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Review & Budget',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(_projectName,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B))),
                ],
              ),
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
                onPressed: _showExportMenu,
                icon: const Icon(LucideIcons.download,
                    size: 16),
                label: const Text('Export BOQ'),
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

        // ── Content ──────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: Color(0xFF1E6FD9)),
                      SizedBox(height: 16),
                      Text('Calculating budget...',
                          style: TextStyle(
                              color: Color(0xFF64748B))),
                    ],
                  ),
                )
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ],
    );
  }

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

  Widget _buildContent() {
    final summary    = _data!['cost_summary']  ?? {};
    final quantities = _data!['quantities']    ?? {};
    final ratesUsed  = _data!['rates_used']    ?? {};
    final breakdown  = (_data!['breakdown'] as List?) ?? [];
    final total      = _d(summary['total']);
    final materials  = _d(summary['materials']);
    final labour     = _d(summary['labour']);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Grand Total Banner ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E6FD9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MATERIAL COST ESTIMATE',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(_fmt(materials),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1)),
                const SizedBox(height: 4),
                Text(
                  '+ ${_fmt(labour)} labour (shown separately)   •   ${_fmt(total)} all-in',
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  _bannerStat('Bricks',
                      _fmt(_d(summary['bricks'])),
                      '${materials > 0 ? (_d(summary['bricks']) / materials * 100).toStringAsFixed(0) : 0}%'),
                  _vDivider(),
                  _bannerStat('Cement',
                      _fmt(_d(summary['cement'])),
                      '${materials > 0 ? (_d(summary['cement']) / materials * 100).toStringAsFixed(0) : 0}%'),
                  _vDivider(),
                  _bannerStat('Sand',
                      _fmt(_d(summary['sand'])),
                      '${materials > 0 ? (_d(summary['sand']) / materials * 100).toStringAsFixed(0) : 0}%'),
                  _vDivider(),
                  _bannerStat('Labour (sep.)', _fmt(labour), ''),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Summary Cards ───────────────────────────
          Row(children: [
            _summaryCard(
              'Red Bricks',
              '${_i(quantities['red_bricks'])}',
              'pieces',
              'Cost: ${_fmt(_d(summary['bricks']) * (_d(quantities['red_bricks']) / (_d(quantities['red_bricks']) + _d(quantities['white_bricks']) + 0.001)))}',
              const Color(0xFFDC2626),
              const Color(0xFFFEF2F2),
              LucideIcons.layers,
            ),
            const SizedBox(width: 12),
            _summaryCard(
              'White Cement Blocks',
              '${_i(quantities['white_bricks'])}',
              'pieces',
              'Cost: ${_fmt(_d(summary['bricks']) * (_d(quantities['white_bricks']) / (_d(quantities['red_bricks']) + _d(quantities['white_bricks']) + 0.001)))}',
              const Color(0xFF1E6FD9),
              const Color(0xFFEFF6FF),
              LucideIcons.square,
            ),
            const SizedBox(width: 12),
            _summaryCard(
              'Cement Bags',
              '${_d(quantities['cement_bags']).toStringAsFixed(1)}',
              'bags (1:4 CM)',
              'Cost: ${_fmt(_d(summary['cement']))}',
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
              LucideIcons.package,
            ),
            const SizedBox(width: 12),
            _summaryCard(
              'Sand',
              '${_d(quantities['sand_tons']).toStringAsFixed(2)}',
              'tons',
              'Cost: ${_fmt(_d(summary['sand']))}',
              const Color(0xFF0D9488),
              const Color(0xFFF0FDFA),
              LucideIcons.box,
            ),
            const SizedBox(width: 12),
            _summaryCard(
              'Labour',
              '${_i(quantities['mason_days']) + _i(quantities['helper_days'])}',
              'man-days',
              'Cost: ${_fmt(_d(summary['labour']))}',
              const Color(0xFFF59E0B),
              const Color(0xFFFFFBEB),
              LucideIcons.hardHat,
            ),
          ]),
          const SizedBox(height: 24),

          // ── Two column layout ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Left — BOQ + Rates
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('Bill of Quantities (BOQ)',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    _buildBOQTable(breakdown, materials),
                    const SizedBox(height: 20),
                    const Text('Rates Used',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    _buildRatesTable(ratesUsed),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Right — charts + labour + volume
              Expanded(
                flex: 2,
                child: Column(children: [
                  _buildCostBreakdownCard(breakdown, materials),
                  const SizedBox(height: 16),
                  _buildLabourCard(quantities, summary),
                  const SizedBox(height: 16),
                  _buildVolumeCard(quantities),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── BOQ Table ───────────────────────────────────────────
  Widget _buildBOQTable(List breakdown, double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
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
                child: Text('Description',
                    style: _hStyle)),
            Expanded(child: Text('Qty',
                style: _hStyle,
                textAlign: TextAlign.center)),
            Expanded(child: Text('Unit',
                style: _hStyle,
                textAlign: TextAlign.center)),
            Expanded(child: Text('Rate (₹)',
                style: _hStyle,
                textAlign: TextAlign.center)),
            Expanded(child: Text('Amount (₹)',
                style: _hStyle,
                textAlign: TextAlign.center)),
            SizedBox(width: 60,
                child: Text('%',
                    style: _hStyle,
                    textAlign: TextAlign.center)),
          ]),
        ),

        ...breakdown.map((item) {
          final color =
              _colorForItem(item['color'] ?? '');
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
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(item['category'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Color(0xFF1E293B))),
                ]),
              ),
              Expanded(
                child: Text(
                  '${_d(item['qty']).toStringAsFixed(1)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B)),
                ),
              ),
              Expanded(
                child: Text(item['unit'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B))),
              ),
              Expanded(
                child: Text(
                  '₹${_d(item['rate']).toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B)),
                ),
              ),
              Expanded(
                child: Text(
                  '₹${_d(item['total']).toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
              SizedBox(
                width: 60,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_d(item['pct']).toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ),
              ),
            ]),
          );
        }),

        // Total row
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12)),
          ),
          child: Row(children: [
            const Expanded(
              flex: 3,
              child: Text('MATERIAL TOTAL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
            Expanded(
              child: Text(
                '₹${total.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(
              width: 60,
              child: Text('100%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Rates Table ─────────────────────────────────────────
  Widget _buildRatesTable(Map ratesUsed) {
    final rateItems = [
      {'label': 'Red Brick',
       'value': ratesUsed['red_brick_per_piece'],
       'unit':  '/piece'},
      {'label': 'White Cement Block',
       'value': ratesUsed['white_brick_per_piece'],
       'unit':  '/piece'},
      {'label': 'Cement',
       'value': ratesUsed['cement_per_bag'],
       'unit':  '/bag'},
      {'label': 'Sand',
       'value': ratesUsed['sand_per_ton'],
       'unit':  '/ton'},
      {'label': 'Mason',
       'value': ratesUsed['mason_per_day'],
       'unit':  '/day'},
      {'label': 'Helper',
       'value': ratesUsed['helper_per_day'],
       'unit':  '/day'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(12)),
            border: Border(
                bottom: BorderSide(
                    color: Color(0xFFE2E8F0))),
          ),
          child: const Row(children: [
            Expanded(child: Text('Material',
                style: _hStyle)),
            Text(
              'Rate at Site (incl. GST + Transport)',
              style: _hStyle,
            ),
          ]),
        ),
        ...rateItems.map((item) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: Color(0xFFF1F5F9)))),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(item['label'] as String,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569))),
              Text(
                '₹${_d(item['value']).toStringAsFixed(2)}${item['unit']}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E6FD9)),
              ),
            ],
          ),
        )),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12)),
          ),
          child: const Row(children: [
            Icon(LucideIcons.info,
                size: 13, color: Color(0xFF94A3B8)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Rates from Master List — includes base rate + GST + loading + transport + unloading',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Cost Breakdown Card ─────────────────────────────────
  Widget _buildCostBreakdownCard(
      List breakdown, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cost Distribution',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ...breakdown.map((item) {
            final pct   = _d(item['pct']);
            final color =
                _colorForItem(item['color'] ?? '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(item['category'] ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFF475569))),
                      ]),
                      Text(
                        '${pct.toStringAsFixed(1)}%  '
                        '₹${_d(item['total']).toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor:
                          const Color(0xFFF1F5F9),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                              color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Labour Card ─────────────────────────────────────────
  Widget _buildLabourCard(Map quantities, Map summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.hardHat,
                  size: 16, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 10),
            const Text('Labour Estimate',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ]),
          const SizedBox(height: 14),
          _labourRow('Mason (Skilled)',
              '${_i(quantities['mason_days'])} days',
              const Color(0xFF7C3AED)),
          _labourRow('Helper (Unskilled)',
              '${_i(quantities['helper_days'])} days',
              const Color(0xFF0D9488)),
          const Divider(color: Color(0xFFF1F5F9)),
          _labourRow('Total Labour Cost',
              _fmt(_d(summary['labour'])),
              const Color(0xFFF59E0B),
              bold: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '📐 Estimated: 1 mason + 1 helper per 10m³ × 30 days',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Volume Card ─────────────────────────────────────────
  Widget _buildVolumeCard(Map quantities) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.box,
                  size: 16, color: Color(0xFF1E6FD9)),
            ),
            const SizedBox(width: 10),
            const Text('Volume Summary',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ]),
          const SizedBox(height: 14),
          _labourRow('Net Brickwork',
              '${_d(quantities['volume_cum'])} m³',
              const Color(0xFF1E6FD9)),
          _labourRow('Total Bricks',
              '${_i(quantities['red_bricks']) + _i(quantities['white_bricks'])} pcs',
              const Color(0xFFDC2626)),
          _labourRow('Cement Bags',
              '${_d(quantities['cement_bags']).toStringAsFixed(1)} bags',
              const Color(0xFF7C3AED)),
          _labourRow('Sand',
              '${_d(quantities['sand_tons']).toStringAsFixed(2)} tons',
              const Color(0xFF0D9488)),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  Widget _labourRow(String label, String value,
      Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF64748B),
                  fontWeight: bold
                      ? FontWeight.w600
                      : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _summaryCard(
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(unit,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _bannerStat(
      String label, String value, String pct) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(pct,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 50,
        margin:
            const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white24,
      );

  Color _colorForItem(String color) {
    switch (color) {
      case 'red':    return const Color(0xFFDC2626);
      case 'blue':   return const Color(0xFF1E6FD9);
      case 'teal':   return const Color(0xFF0D9488);
      case 'purple': return const Color(0xFF7C3AED);
      case 'yellow': return const Color(0xFFF59E0B);
      default:       return const Color(0xFF64748B);
    }
  }

  static const _hStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0xFF64748B));
}