// import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/api_service.dart';
// import 'upload_plan.dart' show AppTheme;

// class Costing extends StatefulWidget {
//   const Costing({super.key});

//   @override
//   State<Costing> createState() => _CostingState();
// }

// class _CostingState extends State<Costing>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool _loading = false;
//   String? _error;
//   Map<String, dynamic>? _calcData;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _loadCalculation();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadCalculation() async {
//     setState(() {
//       _loading = true;
//       _error   = null;
//     });
//     try {
//       final prefs     = await SharedPreferences.getInstance();
//       final projectId = prefs.getString('current_project_id') ?? '';

//       if (projectId.isEmpty) {
//         setState(() {
//           _error   = 'No project selected.\nPlease create or select a project first.';
//           _loading = false;
//         });
//         return;
//       }

//       final token = await ApiService.getToken();
//       if (token == null) {
//         setState(() {
//           _error   = 'Session expired. Please login again.';
//           _loading = false;
//         });
//         return;
//       }

//       final result = await ApiService.calculateBricksWithTypes(
//         projectId,
//         brickTypeMap: {
//           "9": "red_brick",
//           "6": "white_cement",
//           "4": "white_cement",
//         },
//       );

//       if (result['success'] == true) {
//         setState(() {
//           _calcData = result;
//           _loading  = false;
//         });
//       } else {
//         setState(() {
//           _error   = result['error'] ?? 'Calculation failed. Please upload a floor plan first.';
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error   = 'Error: $e';
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [

//         // ── Header ───────────────────────────────────────
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Costing & Analysis',
//                     style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1E293B))),
//                 SizedBox(height: 4),
//                 Text('Material quantities and cost breakdown',
//                     style: TextStyle(
//                         fontSize: 14,
//                         color: Color(0xFF64748B))),
//               ],
//             ),
//             Row(children: [
//               IconButton(
//                 onPressed: _loadCalculation,
//                 icon: const Icon(LucideIcons.refreshCw,
//                     size: 18, color: AppTheme.slate500),
//                 tooltip: 'Refresh',
//               ),
//               const SizedBox(width: 8),
//               ElevatedButton.icon(
//                 onPressed: () {},
//                 icon: const Icon(LucideIcons.download,
//                     size: 16),
//                 label: const Text('Export Report'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E293B),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//             ]),
//           ],
//         ),
//         const SizedBox(height: 20),

//         // ── Tab Bar ──────────────────────────────────────
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppTheme.slate200),
//           ),
//           child: TabBar(
//             controller: _tabController,
//             labelColor: AppTheme.primaryBlue,
//             unselectedLabelColor: AppTheme.slate500,
//             indicatorColor: AppTheme.primaryBlue,
//             indicatorSize: TabBarIndicatorSize.tab,
//             dividerColor: Colors.transparent,
//             tabs: const [
//               Tab(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(LucideIcons.toyBrick, size: 16),
//                     SizedBox(width: 6),
//                     Text('Bricks'),
//                   ],
//                 ),
//               ),
//               Tab(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(LucideIcons.layers, size: 16),
//                     SizedBox(width: 6),
//                     Text('Cement'),
//                   ],
//                 ),
//               ),
//               Tab(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(LucideIcons.box, size: 16),
//                     SizedBox(width: 6),
//                     Text('Sand'),
//                   ],
//                 ),
//               ),
//               Tab(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(LucideIcons.wrench, size: 16),
//                     SizedBox(width: 6),
//                     Text('Iron'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),

//         // ── Tab Content ──────────────────────────────────
//         Expanded(
//           child: _loading
//               ? const Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircularProgressIndicator(
//                           color: AppTheme.primaryBlue),
//                       SizedBox(height: 16),
//                       Text('Loading calculation...',
//                           style: TextStyle(
//                               fontSize: 14,
//                               color: AppTheme.slate500)),
//                       SizedBox(height: 6),
//                       Text('This may take a moment',
//                           style: TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.slate400)),
//                     ],
//                   ),
//                 )
//               : _error != null
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment:
//                             MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFFEF2F2),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                                 LucideIcons.circle,
//                                 size: 40,
//                                 color: Color(0xFFEF4444)),
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             _error!,
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                                 fontSize: 15,
//                                 color: AppTheme.slate600,
//                                 height: 1.5),
//                           ),
//                           const SizedBox(height: 20),
//                           ElevatedButton.icon(
//                             onPressed: _loadCalculation,
//                             icon: const Icon(
//                                 LucideIcons.refreshCw,
//                                 size: 16),
//                             label: const Text('Retry'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor:
//                                   AppTheme.primaryBlue,
//                               foregroundColor: Colors.white,
//                               padding:
//                                   const EdgeInsets.symmetric(
//                                       horizontal: 24,
//                                       vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                   borderRadius:
//                                       BorderRadius.circular(8)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : TabBarView(
//                       controller: _tabController,
//                       children: [
//                         // Tab 1 — Bricks
//                         _calcData != null
//                             ? _BricksTab(data: _calcData!)
//                             : const _ComingSoon('Bricks'),

//                         // Tab 2 — Cement
//                         const _ComingSoon('Cement'),

//                         // Tab 3 — Sand
//                         const _ComingSoon('Sand'),

//                         // Tab 4 — Iron
//                         const _ComingSoon('Iron'),
//                       ],
//                     ),
//         ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  BRICKS TAB
// // ─────────────────────────────────────────────────────────────
// class _BricksTab extends StatelessWidget {
//   final Map<String, dynamic> data;
//   const _BricksTab({required this.data});

//   static int _toInt(dynamic v) =>
//       v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

//   @override
//   Widget build(BuildContext context) {
//     final grand = data['grand_total']  ?? {};
//     final red   = data['red_brick']    ?? {};
//     final white = data['white_cement'] ?? {};
//     final deds  = data['deductions']   ?? {};
//     final zones = data['zone_summary'] ?? [];

//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [

//           // ── Formula Banner ──────────────────────────────
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(colors: [
//                 Color(0xFF0F172A),
//                 Color(0xFF0891B2),
//               ]),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('FORMULA',
//                     style: TextStyle(
//                         color: Colors.white54,
//                         fontSize: 11,
//                         letterSpacing: 1.2)),
//                 const SizedBox(height: 6),
//                 const Text(
//                   'Bricks = (L × H ÷ Brick face area) × Thickness multiplier × 1.10',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 8),
//                 Wrap(spacing: 8, runSpacing: 6, children: const [
//                   _Chip('4" → ×1.0'),
//                   _Chip('6" → ×1.5'),
//                   _Chip('8" → ×2.0'),
//                   _Chip('9" → ×2.25'),
//                   _Chip('+10% buffer'),
//                 ]),
//                 const SizedBox(height: 8),
//                 Text(
//                   grand['formula'] ?? '',
//                   style: const TextStyle(
//                       color: Colors.white60,
//                       fontSize: 11,
//                       fontFamily: 'monospace'),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),

//           // ── Zone Summary ────────────────────────────────
//           if ((zones as List).isNotEmpty) ...[
//             const Text('Zone Areas',
//                 style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: AppTheme.slate800)),
//             const SizedBox(height: 10),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate:
//                   const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 4,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//                 childAspectRatio: 2.2,
//               ),
//               itemCount: zones.length,
//               itemBuilder: (_, i) {
//                 final z = zones[i];
//                 return Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border:
//                         Border.all(color: AppTheme.slate200),
//                   ),
//                   child: Column(
//                     crossAxisAlignment:
//                         CrossAxisAlignment.start,
//                     mainAxisAlignment:
//                         MainAxisAlignment.center,
//                     children: [
//                       Text(z['name'] ?? '',
//                           style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 12,
//                               color: AppTheme.slate700),
//                           overflow: TextOverflow.ellipsis),
//                       const SizedBox(height: 2),
//                       Text(
//                           '${z['area_sqft'] ?? 0} sqft',
//                           style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: AppTheme.primaryBlue)),
//                       Text(
//                           '${z['size']?['length_ft'] ?? '?'}×${z['size']?['width_ft'] ?? '?'} ft',
//                           style: const TextStyle(
//                               fontSize: 10,
//                               color: AppTheme.slate400)),
//                     ],
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 16),
//           ],

//           // ── Grand Total Cards ───────────────────────────
//           Row(children: [
//             _statCard(
//               'Total Bricks',
//               '${grand['final_bricks'] ?? 0}',
//               'incl. 10% buffer',
//               AppTheme.slate900,
//               const Color(0xFFF1F5F9),
//             ),
//             const SizedBox(width: 12),
//             _statCard(
//               'Red Bricks',
//               '${red['final_with_10pct'] ?? 0}',
//               '9" walls',
//               const Color(0xFFDC2626),
//               const Color(0xFFFEF2F2),
//             ),
//             const SizedBox(width: 12),
//             _statCard(
//               'Cement Blocks',
//               '${white['final_with_10pct'] ?? 0}',
//               '4" / 6" walls',
//               const Color(0xFF0891B2),
//               const Color(0xFFECFEFF),
//             ),
//             const SizedBox(width: 12),
//             _statCard(
//               'Deducted',
//               '${grand['total_deducted'] ?? 0}',
//               'doors + windows',
//               AppTheme.slate400,
//               const Color(0xFFF8FAFC),
//             ),
//           ]),
//           const SizedBox(height: 20),

//           // ── Red Brick Section ───────────────────────────
//           _sectionLabel('RED BRICK WORK',
//               const Color(0xFFDC2626), LucideIcons.toyBrick),
//           const SizedBox(height: 10),
//           _wallTable(
//             walls:       red['walls']            ?? [],
//             color:       const Color(0xFFDC2626),
//             grossBricks: _toInt(red['gross_bricks']),
//             deducted:    _toInt(red['deducted']),
//             netBricks:   _toInt(red['net_bricks']),
//             finalBricks: _toInt(red['final_with_10pct']),
//           ),
//           const SizedBox(height: 20),

//           // ── White Cement Section ────────────────────────
//           _sectionLabel('WHITE CEMENT BLOCK WORK',
//               const Color(0xFF0891B2), LucideIcons.square),
//           const SizedBox(height: 10),
//           _wallTable(
//             walls:       white['walls']            ?? [],
//             color:       const Color(0xFF0891B2),
//             grossBricks: _toInt(white['gross_bricks']),
//             deducted:    _toInt(white['deducted']),
//             netBricks:   _toInt(white['net_bricks']),
//             finalBricks: _toInt(white['final_with_10pct']),
//           ),
//           const SizedBox(height: 20),

//           // ── Deductions ──────────────────────────────────
//           _sectionLabel('DEDUCTIONS — OPENINGS',
//               AppTheme.slate600, LucideIcons.minus),
//           const SizedBox(height: 10),
//           _deductionCard(
//             title: 'Windows & Ventilators',
//             items: (deds['windows']?['items'] as List?) ?? [],
//             total: _toInt(deds['windows']?['total_bricks']),
//             color: const Color(0xFF0D9488),
//           ),
//           const SizedBox(height: 10),
//           _deductionCard(
//             title: 'Doors',
//             items: (deds['doors']?['items'] as List?) ?? [],
//             total: _toInt(deds['doors']?['total_bricks']),
//             color: AppTheme.primaryOrange,
//           ),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   // ── Stat Card ─────────────────────────────────────────────
//   Widget _statCard(String label, String value, String sub,
//       Color textColor, Color bgColor) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: AppTheme.slate200),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label,
//                 style: const TextStyle(
//                     fontSize: 12, color: AppTheme.slate500)),
//             const SizedBox(height: 6),
//             Text(value,
//                 style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: textColor)),
//             Text(sub,
//                 style: const TextStyle(
//                     fontSize: 11, color: AppTheme.slate400)),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Section Label ─────────────────────────────────────────
//   Widget _sectionLabel(
//       String title, Color color, IconData icon) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(
//               horizontal: 10, vertical: 6),
//           decoration: BoxDecoration(
//               color: color,
//               borderRadius: BorderRadius.circular(6)),
//           child: Row(children: [
//             Icon(icon, size: 13, color: Colors.white),
//             const SizedBox(width: 6),
//             Text(title,
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 11,
//                     letterSpacing: 0.5)),
//           ]),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//             child: Divider(color: color.withOpacity(0.3))),
//       ],
//     );
//   }

//   // ── Wall Table ────────────────────────────────────────────
//   Widget _wallTable({
//     required List walls,
//     required Color color,
//     required int grossBricks,
//     required int deducted,
//     required int netBricks,
//     required int finalBricks,
//   }) {
//     if (walls.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: AppTheme.slate200),
//         ),
//         child: Center(
//           child: Text(
//             'No walls of this type detected in floor plan',
//             style: TextStyle(
//                 fontSize: 13, color: AppTheme.slate400),
//           ),
//         ),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppTheme.slate200),
//       ),
//       child: Column(
//         children: [
//           // Table header
//           Container(
//             padding: const EdgeInsets.symmetric(
//                 horizontal: 14, vertical: 10),
//             decoration: const BoxDecoration(
//               color: AppTheme.slate50,
//               borderRadius: BorderRadius.vertical(
//                   top: Radius.circular(12)),
//               border: Border(
//                   bottom:
//                       BorderSide(color: AppTheme.slate200)),
//             ),
//             child: const Row(children: [
//               Expanded(
//                   flex: 3,
//                   child: Text('Wall', style: _hStyle)),
//               Expanded(
//                   child:
//                       Text('L×H sqft', style: _hStyle)),
//               Expanded(
//                   child: Text('Multiplier', style: _hStyle)),
//               Expanded(
//                   child: Text('Nos', style: _hStyle)),
//               Expanded(
//                   child: Text('Gross', style: _hStyle)),
//               Expanded(
//                   child: Text('+10%', style: _hStyle)),
//             ]),
//           ),

//           // Table rows
//           ...walls.map((w) => Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 14, vertical: 10),
//                 decoration: const BoxDecoration(
//                     border: Border(
//                         bottom: BorderSide(
//                             color: AppTheme.slate100))),
//                 child: Row(children: [
//                   Expanded(
//                     flex: 3,
//                     child: Row(children: [
//                       Container(
//                           width: 8,
//                           height: 8,
//                           decoration: BoxDecoration(
//                               color: color,
//                               shape: BoxShape.circle)),
//                       const SizedBox(width: 6),
//                       Text(w['description'] ?? '',
//                           style: const TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: AppTheme.slate700)),
//                     ]),
//                   ),
//                   Expanded(
//                       child: Text(
//                           '${w['wall_face_sqft'] ?? 0}',
//                           style: const TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.slate600))),
//                   Expanded(
//                       child: Text(
//                           '×${w['multiplier'] ?? 1}',
//                           style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: color))),
//                   Expanded(
//                       child: Text('${w['nos'] ?? 1}',
//                           style: const TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.slate600))),
//                   Expanded(
//                       child: Text(
//                           '${w['bricks_raw'] ?? 0}',
//                           style: const TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.slate600))),
//                   Expanded(
//                       child: Text(
//                           '${w['bricks_with_10pct'] ?? 0}',
//                           style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold,
//                               color: color))),
//                 ]),
//               )),

//           // Summary rows
//           _sumRow('Gross Bricks', grossBricks,
//               AppTheme.slate600),
//           _sumRow('(−) Openings Deducted', deducted,
//               const Color(0xFFEF4444)),
//           _sumRow('Net Bricks', netBricks,
//               AppTheme.slate700),

//           // Final row
//           Container(
//             padding: const EdgeInsets.symmetric(
//                 horizontal: 14, vertical: 14),
//             decoration: BoxDecoration(
//               color: color,
//               borderRadius: const BorderRadius.vertical(
//                   bottom: Radius.circular(12)),
//             ),
//             child: Row(
//               mainAxisAlignment:
//                   MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('FINAL  (Net + buffer)',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13)),
//                 Text('$finalBricks bricks',
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _sumRow(String label, int value, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//           horizontal: 14, vertical: 8),
//       decoration: const BoxDecoration(
//           border: Border(
//               bottom:
//                   BorderSide(color: AppTheme.slate100))),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style:
//                   TextStyle(fontSize: 12, color: color)),
//           Text('$value',
//               style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: color)),
//         ],
//       ),
//     );
//   }

//   // ── Deduction Card ────────────────────────────────────────
//   Widget _deductionCard({
//     required String title,
//     required List items,
//     required int total,
//     required Color color,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppTheme.slate200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(14),
//             child: Row(
//               mainAxisAlignment:
//                   MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(title,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                         color: AppTheme.slate800)),
//                 Text('$total bricks deducted',
//                     style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                         color: color)),
//               ],
//             ),
//           ),
//           const Divider(height: 1, color: AppTheme.slate100),
//           if (items.isEmpty)
//             const Padding(
//               padding: EdgeInsets.all(14),
//               child: Text('No items',
//                   style: TextStyle(
//                       fontSize: 12,
//                       color: AppTheme.slate400)),
//             )
//           else
//             ...items.map((item) => Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 14, vertical: 8),
//                   child: Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(item['description'] ?? '',
//                           style: const TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.slate600)),
//                       Text(
//                         '${item['nos'] ?? 1} nos  •  '
//                         '${item['face_sqft'] ?? 0} sqft  •  '
//                         '${item['bricks_deducted'] ?? 0} bricks',
//                         style: const TextStyle(
//                             fontSize: 11,
//                             color: AppTheme.slate500),
//                       ),
//                     ],
//                   ),
//                 )),
//         ],
//       ),
//     );
//   }

//   static const _hStyle = TextStyle(
//       fontSize: 11,
//       fontWeight: FontWeight.w600,
//       color: AppTheme.slate500);
// }

// // ─────────────────────────────────────────────────────────────
// //  COMING SOON TAB
// // ─────────────────────────────────────────────────────────────
// class _ComingSoon extends StatelessWidget {
//   final String label;
//   const _ComingSoon(this.label);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: AppTheme.slate100,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(LucideIcons.clock,
//                 size: 36, color: AppTheme.slate400),
//           ),
//           const SizedBox(height: 16),
//           Text('$label calculation coming soon',
//               style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: AppTheme.slate500)),
//           const SizedBox(height: 6),
//           const Text(
//             'Upload a floor plan to enable this section',
//             style: TextStyle(
//                 fontSize: 13, color: AppTheme.slate400),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  FORMULA CHIP
// // ─────────────────────────────────────────────────────────────
// class _Chip extends StatelessWidget {
//   final String label;
//   const _Chip(this.label);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//           horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(
//             color: Colors.white.withOpacity(0.2)),
//       ),
//       child: Text(label,
//           style: const TextStyle(
//               color: Colors.white,
//               fontSize: 11,
//               fontWeight: FontWeight.w500)),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'upload_plan.dart' show AppTheme;

class Costing extends StatefulWidget {
  const Costing({super.key});

  @override
  State<Costing> createState() => _CostingState();
}

class _CostingState extends State<Costing>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _calcData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCalculation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCalculation() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs     = await SharedPreferences.getInstance();
      final projectId = prefs.getString('current_project_id') ?? '';

      if (projectId.isEmpty) {
        setState(() {
          _error   = 'No project selected.\nPlease create or select a project first.';
          _loading = false;
        });
        return;
      }

      final token = await ApiService.getToken();
      if (token == null) {
        setState(() {
          _error   = 'Session expired. Please login again.';
          _loading = false;
        });
        return;
      }

      final result = await ApiService.calculateBricksWithTypes(
        projectId,
        brickTypeMap: {
          "9": "red_brick",
          "6": "white_cement",
          "4": "white_cement",
          "8": "white_cement",
        },
      );

      if (result['success'] == true) {
        setState(() { _calcData = result; _loading = false; });
      } else {
        setState(() {
          _error   = result['error'] ?? 'Calculation failed. Please upload a floor plan first.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  Future<void> _exportReport() async {
    final prefs     = await SharedPreferences.getInstance();
    final projectId = prefs.getString('current_project_id') ?? '';
    if (!mounted) return;

    if (projectId.isEmpty || _calcData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Calculate a project first, then export.'),
        backgroundColor: Color(0xFFDC2626),
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Export Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileSpreadsheet, color: Color(0xFF15803D)),
              title: const Text('Excel (.xlsx)'),
              subtitle: const Text('BOQ + Brick Work Calculation (matches your Excel)'),
              onTap: () {
                Navigator.pop(ctx);
                ApiService.exportExcel(projectId);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: Color(0xFFDC2626)),
              title: const Text('PDF Report'),
              subtitle: const Text('Printable summary'),
              onTap: () {
                Navigator.pop(ctx);
                ApiService.exportPDF(projectId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Costing & Analysis',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Material quantities and cost breakdown',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Row(children: [
              IconButton(
                onPressed: _loadCalculation,
                icon: const Icon(LucideIcons.refreshCw,
                    size: 18, color: AppTheme.slate500),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _exportReport,
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Export Report'),
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

        // ── Tab Bar ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E6FD9),
            unselectedLabelColor: AppTheme.slate500,
            indicatorColor: const Color(0xFF1E6FD9),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.layers, size: 16),
                  SizedBox(width: 6),
                  Text('Bricks'),
                ],
              )),
              Tab(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.package, size: 16),
                  SizedBox(width: 6),
                  Text('Cement'),
                ],
              )),
              Tab(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.box, size: 16),
                  SizedBox(width: 6),
                  Text('Sand'),
                ],
              )),
              Tab(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.wrench, size: 16),
                  SizedBox(width: 6),
                  Text('Iron'),
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Tab Content ──────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: Color(0xFF1E6FD9)),
                      SizedBox(height: 16),
                      Text('Loading calculation...',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.slate500)),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                LucideIcons.circle,
                                size: 40,
                                color: Color(0xFFEF4444)),
                          ),
                          const SizedBox(height: 16),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.slate600,
                                  height: 1.5)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadCalculation,
                            icon: const Icon(
                                LucideIcons.refreshCw,
                                size: 16),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF1E6FD9),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _calcData != null
                            ? _BricksTab(data: _calcData!)
                            : const _ComingSoon('Bricks'),
                        _calcData != null
                            ? _CementTab(data: _calcData!)
                            : const _ComingSoon('Cement'),
                        _calcData != null
                            ? _SandTab(data: _calcData!)
                            : const _ComingSoon('Sand'),
                        const _ComingSoon('Iron'),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BRICKS TAB
// ─────────────────────────────────────────────────────────────
class _BricksTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BricksTab({required this.data});

  static int _toInt(dynamic v) =>
      v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

  static double _toD(dynamic v) =>
      v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

  // BOQ — Brick Work Calculation rendered exactly like the client's Excel:
  // Table 1 (Gross) → Table 2 (Windows/Openings) → Table 3 (Doors) → Net → Bricks
  Widget _excelBoq(List walls, List winItems, List doorItems, Map vol,
      Map grand, String buffer) {
    const ft3tom3 = 0.028;
    String n(dynamic v, int d) => _toD(v).toStringAsFixed(d);

    Expanded cell(String s, int flex,
            {Color? col, TextAlign align = TextAlign.center, bool bold = false, double size = 11.5}) =>
        Expanded(
          flex: flex,
          child: Text(s,
              textAlign: align,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: col ?? AppTheme.slate700)),
        );

    Widget banner(String t, Color bg) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          color: bg,
          child: Text(t,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.4)),
        );

    Widget hdr(List<Widget> cells, Color bg) => Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: cells),
        );

    Widget row(List<Widget> cells, int i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: i.isEven ? Colors.white : AppTheme.slate50,
              border: const Border(
                  bottom: BorderSide(color: AppTheme.slate100))),
          child: Row(children: cells),
        );

    Widget foot(String label, double cuft, Color bg) => Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            cell(label, 13, bold: true, col: Colors.white, align: TextAlign.left),
            cell(cuft.toStringAsFixed(2), 3, bold: true, col: Colors.white),
            cell((cuft * ft3tom3).toStringAsFixed(4), 3, bold: true, col: Colors.white),
          ]),
        );

    final hStyle = AppTheme.slate500;
    final grossCuft = _toD(vol['gross_volume_cuft']);
    final netCuft   = _toD(vol['net_volume_cuft']);
    final netCum    = _toD(vol['net_volume_cum']);
    final winCuft   = winItems.fold<double>(0, (s, o) => s + _toD(o['volume_cuft']));
    final doorCuft  = doorItems.fold<double>(0, (s, o) => s + _toD(o['volume_cuft']));

    Widget dedRows(List items) => Column(
          children: List.generate(items.length, (i) {
            final o = items[i];
            return row([
              cell('${o['description'] ?? ''}', 11, align: TextAlign.left),
              cell('${o['nos'] ?? 1}', 2),
              cell(n(o['volume_cuft'], 2), 3),
              cell(n(_toD(o['volume_cuft']) * ft3tom3, 4), 3),
            ], i);
          }),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          banner('BRICK WORK CALCULATION', AppTheme.slate900),

          // TABLE 1 — GROSS WALL VOLUME
          banner('TABLE 1  —  GROSS WALL VOLUME', AppTheme.slate700),
          hdr([
            cell('Description', 5, col: hStyle, align: TextAlign.left, bold: true, size: 10.5),
            cell('Nos', 2, col: hStyle, bold: true, size: 10.5),
            cell('L (ft)', 2, col: hStyle, bold: true, size: 10.5),
            cell('B (ft)', 2, col: hStyle, bold: true, size: 10.5),
            cell('H (ft)', 2, col: hStyle, bold: true, size: 10.5),
            cell('Cu.Ft', 3, col: hStyle, bold: true, size: 10.5),
            cell('m³', 3, col: hStyle, bold: true, size: 10.5),
          ], AppTheme.slate100),
          ...List.generate(walls.length, (i) {
            final w = walls[i];
            return row([
              cell('${w['description'] ?? ''}', 5, align: TextAlign.left),
              cell('${w['nos'] ?? 1}', 2),
              cell(n(w['L'], 2), 2),
              cell(n(w['thickness_ft'], 3), 2),
              cell(n(w['H'], 2), 2),
              cell(n(w['wall_volume_cuft'], 2), 3),
              cell(n(w['wall_volume_cum'], 4), 3),
            ], i);
          }),
          foot('GROSS TOTAL', grossCuft, AppTheme.slate900),

          // TABLE 2 — WINDOWS / OPENINGS
          banner('TABLE 2  —  DEDUCTIONS (Windows / Vents / Openings)',
              const Color(0xFFB45309)),
          hdr([
            cell('Opening (L×H, thk)', 11, col: hStyle, align: TextAlign.left, bold: true, size: 10.5),
            cell('Nos', 2, col: hStyle, bold: true, size: 10.5),
            cell('Cu.Ft', 3, col: hStyle, bold: true, size: 10.5),
            cell('m³', 3, col: hStyle, bold: true, size: 10.5),
          ], AppTheme.slate100),
          if (winItems.isEmpty)
            row([cell('No windows detected', 19, align: TextAlign.left, col: AppTheme.slate400)], 0)
          else
            dedRows(winItems),
          foot('WINDOW / OPENING DEDUCTION', winCuft, const Color(0xFFB45309)),

          // TABLE 3 — DOORS
          banner('TABLE 3  —  DEDUCTIONS (Doors)', const Color(0xFF9A3412)),
          hdr([
            cell('Door (L×H, thk)', 11, col: hStyle, align: TextAlign.left, bold: true, size: 10.5),
            cell('Nos', 2, col: hStyle, bold: true, size: 10.5),
            cell('Cu.Ft', 3, col: hStyle, bold: true, size: 10.5),
            cell('m³', 3, col: hStyle, bold: true, size: 10.5),
          ], AppTheme.slate100),
          if (doorItems.isEmpty)
            row([cell('No doors detected', 19, align: TextAlign.left, col: AppTheme.slate400)], 0)
          else
            dedRows(doorItems),
          foot('DOOR DEDUCTION', doorCuft, const Color(0xFF9A3412)),

          // NET
          foot('NET VOLUME  =  Gross − Windows − Doors', netCuft,
              const Color(0xFF065F46)),

          // ── Conversion breakdown (mirrors client master) ──
          row([
            cell('Volume conversion  (Net CFT × 0.028)', 13, align: TextAlign.left, bold: true),
            cell('', 3),
            cell('${netCum.toStringAsFixed(2)} m³', 3, bold: true, col: AppTheme.slate800),
          ], 0),
          row([
            cell('Item conversion  (m³ × 500 bricks/m³)', 13, align: TextAlign.left),
            cell('', 3),
            cell('${(netCum * 500).toStringAsFixed(3)} nos', 3, col: AppTheme.slate700),
          ], 1),
          row([
            cell('Wastage allowance  ($buffer%)', 13, align: TextAlign.left),
            cell('', 3),
            cell('${(netCum * 500 * (double.tryParse(buffer) ?? 5) / 100).toStringAsFixed(2)} nos', 3, col: AppTheme.slate700),
          ], 0),
          row([
            cell('Total with wastage', 13, align: TextAlign.left, bold: true),
            cell('', 3),
            cell('${(netCum * 500 * (1 + (double.tryParse(buffer) ?? 5) / 100)).toStringAsFixed(2)} nos', 3, bold: true, col: AppTheme.slate800),
          ], 1),

          // Bricks
          Container(
            width: double.infinity,
            color: const Color(0xFFDC2626),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      'FINAL TAKE-OFF  (rounded up)',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5)),
                ),
                Text('${grand['final_bricks'] ?? 0} bricks',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grand    = data['grand_total']  ?? {};
    final red      = data['red_brick']    ?? {};
    final white    = data['white_cement'] ?? {};
    final deds     = data['deductions']   ?? {};
    final buffer   = (data['buffer_pct'] ??
        (data['formulas_used'] is Map ? data['formulas_used']['buffer_pct'] : null) ??
        5).toString();
    final mult     = (1 + (double.tryParse(buffer) ?? 5) / 100).toStringAsFixed(2);
    final walls     = (data['wall_breakdown'] as List?) ?? const [];
    final winMap    = (deds['windows'] is Map) ? deds['windows'] as Map : const {};
    final doorMap   = (deds['doors']   is Map) ? deds['doors']   as Map : const {};
    final winItems  = (winMap['items']  as List?) ?? const [];
    final doorItems = (doorMap['items'] as List?) ?? const [];
    final vol       = (data['volume_summary'] is Map) ? data['volume_summary'] as Map : const {};
    final rawZones = data['zone_summary'];
    // Handle both List and Map responses from different backend versions
    final zones = rawZones is Map
        ? rawZones.values.toList()
        : (rawZones as List?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Formula banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E6FD9)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FORMULA',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  'Bricks = Net brickwork volume (m³) × 500 bricks/m³ × $mult',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  const _Chip('Volume = L × B × H'),
                  const _Chip('500 bricks / m³'),
                  const _Chip('− openings (by volume)'),
                  const _Chip('9" → Red · 4/6/8" → White'),
                  _Chip('+$buffer% buffer'),
                ]),
                const SizedBox(height: 8),
                Text(grand['formula'] ?? '',
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── BOQ — Brick Work Calculation (client Excel format) ──
          _excelBoq(walls, winItems, doorItems, vol, grand, buffer),
          const SizedBox(height: 16),

          // Zone areas
          if (zones.isNotEmpty) ...[
            const Text('Zone Areas',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate800)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: zones.length,
              itemBuilder: (_, i) {
                final z = zones[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(z['label'] ?? z['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppTheme.slate700),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${z['area_sqft'] ?? 0} sqft',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E6FD9))),
                      Text(
                          '${z['length_ft'] ?? z['size']?['length_ft'] ?? '?'}'
                          '×${z['width_ft'] ?? z['size']?['width_ft'] ?? '?'} ft',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.slate400)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Stats
          Row(children: [
            _statCard('Total Bricks', '${grand['final_bricks'] ?? 0}',
                'incl. $buffer% buffer', AppTheme.slate900,
                const Color(0xFFF1F5F9)),
            const SizedBox(width: 12),
            _statCard('Red Bricks', '${red['final_with_10pct'] ?? 0}',
                '9" walls', const Color(0xFFDC2626),
                const Color(0xFFFEF2F2)),
            const SizedBox(width: 12),
            _statCard('Cement Blocks', '${white['final_with_10pct'] ?? 0}',
                '4" / 6" walls', const Color(0xFF1E6FD9),
                const Color(0xFFEFF6FF)),
            const SizedBox(width: 12),
            _statCard('Deducted', '${grand['total_deducted'] ?? 0}',
                'doors + windows', AppTheme.slate400,
                const Color(0xFFF8FAFC)),
          ]),
          const SizedBox(height: 20),

          // Red brick table
          _sectionLabel('RED BRICK WORK', const Color(0xFFDC2626),
              LucideIcons.layers),
          const SizedBox(height: 10),
          _wallTable(
            walls:       red['walls'] ?? [],
            color:       const Color(0xFFDC2626),
            grossBricks: _toInt(red['gross_bricks']),
            deducted:    _toInt(red['deducted']),
            netBricks:   _toInt(red['net_bricks']),
            finalBricks: _toInt(red['final_with_10pct']),
          ),
          const SizedBox(height: 20),

          // White cement table
          _sectionLabel('WHITE CEMENT BLOCK WORK',
              const Color(0xFF1E6FD9), LucideIcons.square),
          const SizedBox(height: 10),
          _wallTable(
            walls:       white['walls'] ?? [],
            color:       const Color(0xFF1E6FD9),
            grossBricks: _toInt(white['gross_bricks']),
            deducted:    _toInt(white['deducted']),
            netBricks:   _toInt(white['net_bricks']),
            finalBricks: _toInt(white['final_with_10pct']),
          ),
          const SizedBox(height: 20),

          // Deductions
          _sectionLabel('DEDUCTIONS — OPENINGS',
              AppTheme.slate600, LucideIcons.minus),
          const SizedBox(height: 10),
          _deductionCard(
            title: 'Windows & Ventilators',
            items: (deds['windows']?['items'] as List?) ?? [],
            total: _toInt(deds['windows']?['total_bricks']),
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 10),
          _deductionCard(
            title: 'Doors',
            items: (deds['doors']?['items'] as List?) ?? [],
            total: _toInt(deds['doors']?['total_bricks']),
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String sub,
      Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.slate500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.slate400)),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String title, Color color, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5)),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(child: Divider(color: color.withOpacity(0.3))),
    ]);
  }

  Widget _wallTable({
    required List walls,
    required Color color,
    required int grossBricks,
    required int deducted,
    required int netBricks,
    required int finalBricks,
  }) {
    if (walls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Center(
          child: Text('No walls of this type detected',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.slate400)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(12)),
            border: Border(
                bottom: BorderSide(color: AppTheme.slate200)),
          ),
          child: const Row(children: [
            Expanded(flex: 3,
                child: Text('Wall', style: _hStyle)),
            Expanded(child: Text('L×H sqft', style: _hStyle)),
            Expanded(child: Text('Vol m³', style: _hStyle)),
            Expanded(child: Text('Nos', style: _hStyle)),
            Expanded(child: Text('Gross', style: _hStyle)),
            Expanded(child: Text('Final', style: _hStyle)),
          ]),
        ),
        ...walls.map((w) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppTheme.slate100))),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: Row(children: [
                Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(w['description'] ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.slate700)),
              ]),
            ),
            Expanded(child: Text(
                '${w['wall_face_sqft'] ?? 0}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.slate600))),
            Expanded(child: Text(
                '${w['wall_volume_cum'] ?? 0}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color))),
            Expanded(child: Text(
                '${w['nos'] ?? 1}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.slate600))),
            Expanded(child: Text(
                '${w['bricks_raw'] ?? 0}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.slate600))),
            Expanded(child: Text(
                '${w['bricks_with_10pct'] ?? 0}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color))),
          ]),
        )),
        _sumRow('Gross Bricks', grossBricks, AppTheme.slate600),
        _sumRow('(−) Openings Deducted', deducted,
            const Color(0xFFEF4444)),
        _sumRow('Net Bricks', netBricks, AppTheme.slate700),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FINAL  (Net + buffer)',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Text('$finalBricks bricks',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _sumRow(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppTheme.slate100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
          Text('$value',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _deductionCard({
    required String title,
    required List items,
    required int total,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.slate800)),
              Text('$total bricks deducted',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.slate100),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('No items',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.slate400)),
          )
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['description'] ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate600)),
                Text(
                  '${item['nos'] ?? 1} nos  •  '
                  '${item['face_sqft'] ?? 0} sqft  •  '
                  '${item['bricks_deducted'] ?? 0} bricks',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.slate500)),
              ],
            ),
          )),
      ]),
    );
  }

  static const _hStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppTheme.slate500);
}

// ─────────────────────────────────────────────────────────────
//  CEMENT TAB
// ─────────────────────────────────────────────────────────────
class _CementTab extends StatefulWidget {
  final Map<String, dynamic> data;
  const _CementTab({required this.data});

  @override
  State<_CementTab> createState() => _CementTabState();
}

class _CementTabState extends State<_CementTab> {
  String _selectedMix       = '1:4';
  String _selectedThickness = '18mm';

  static const _mixes      = ['1:3', '1:4', '1:5', '1:6'];
  static const _thicknesses = ['12mm', '18mm'];

  @override
  Widget build(BuildContext context) {
    final cement   = widget.data['cement']         ?? {};
    final vol      = widget.data['volume_summary'] ?? {};
    final allMixes = cement['all_mixes']            ?? {};
    final perWall  = (cement['per_wall'] as List?)  ?? [];

    final currentMix = allMixes[_selectedMix] ?? {};
    final bags = _selectedThickness == '12mm'
        ? currentMix['cement_bags_12mm'] ?? 0
        : currentMix['cement_bags_18mm'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E6FD9)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CEMENT CALCULATION',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                const Text(
                  'Based on Master Data — Bags per m³ of brickwork',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _infoPill('Net Volume',
                      '${vol['net_volume_cuft'] ?? 0} Cu.Ft'),
                  const SizedBox(width: 8),
                  _infoPill('= ${vol['net_volume_cum'] ?? 0} m³', ''),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selectors
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8, runSpacing: 8,
            children: [
            const Text('Mortar Mix:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A2332))),
            ..._mixes.map((m) => _mixChip(m, _selectedMix == m, () {
                setState(() => _selectedMix = m);
              })),
            const SizedBox(width: 12),
            const Text('Plaster Thickness:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A2332))),
            ..._thicknesses.map((t) => _mixChip(t, _selectedThickness == t, () {
                setState(() => _selectedThickness = t);
              })),
          ]),
          const SizedBox(height: 16),

          // Summary cards
          Row(children: [
            _cementCard(
              'Total Cement Bags',
              '$bags',
              'bags',
              '$_selectedMix CM — $_selectedThickness',
              const Color(0xFF1E6FD9),
              const Color(0xFFEFF6FF),
              LucideIcons.package,
            ),
            const SizedBox(width: 12),
            _cementCard(
              'Net Brickwork Volume',
              '${vol['net_volume_cum'] ?? 0}',
              'm³',
              '${vol['net_volume_cuft'] ?? 0} Cu.Ft',
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
              LucideIcons.box,
            ),
            const SizedBox(width: 12),
            _cementCard(
              'Gross Volume',
              '${vol['gross_volume_cuft'] ?? 0}',
              'Cu.Ft',
              'Before deductions',
              const Color(0xFF0D9488),
              const Color(0xFFF0FDFA),
              LucideIcons.layers,
            ),
            const SizedBox(width: 12),
            _cementCard(
              'Deductions',
              '${vol['deduction_cuft'] ?? 0}',
              'Cu.Ft',
              'Openings volume',
              const Color(0xFFEF4444),
              const Color(0xFFFEF2F2),
              LucideIcons.minus,
            ),
          ]),
          const SizedBox(height: 20),

          // All mixes comparison table
          const Text('Cement Bags — All Mixes',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2332))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12)),
                  border: Border(
                      bottom: BorderSide(color: AppTheme.slate200)),
                ),
                child: const Row(children: [
                  Expanded(flex: 2,
                      child: Text('Mix', style: _CementTabState._hStyle)),
                  Expanded(child: Text('12mm Plaster\n(bags)',
                      style: _CementTabState._hStyle,
                      textAlign: TextAlign.center)),
                  Expanded(child: Text('18mm Plaster\n(bags)',
                      style: _CementTabState._hStyle,
                      textAlign: TextAlign.center)),
                ]),
              ),
              ..._mixes.map((mix) {
                final m = allMixes[mix] ?? {};
                final isSelected = mix == _selectedMix;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEFF6FF)
                        : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                          color: AppTheme.slate100),
                      left: isSelected
                          ? const BorderSide(
                              color: Color(0xFF1E6FD9), width: 3)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(
                      flex: 2,
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1E6FD9)
                                : AppTheme.slate300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('CM $mix',
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1E6FD9)
                                    : AppTheme.slate700)),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E6FD9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('SELECTED',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                    ),
                    Expanded(
                      child: Text(
                          '${m['cement_bags_12mm'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (_selectedThickness == '12mm' && isSelected)
                                  ? const Color(0xFF1E6FD9)
                                  : AppTheme.slate700)),
                    ),
                    Expanded(
                      child: Text(
                          '${m['cement_bags_18mm'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (_selectedThickness == '18mm' && isSelected)
                                  ? const Color(0xFF1E6FD9)
                                  : AppTheme.slate700)),
                    ),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),

          // Per-wall breakdown hidden — the BOQ (like the client Excel) shows
          // cement/sand per MIX from the net volume, not split per wall.
          if (false) ...[ // ignore: dead_code
            const Text('Cement per Wall',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2332))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12)),
                    border: Border(
                        bottom:
                            BorderSide(color: AppTheme.slate200)),
                  ),
                  child: const Row(children: [
                    Expanded(flex: 3,
                        child: Text('Wall', style: _hStyle)),
                    Expanded(child: Text('Nos',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                    Expanded(child: Text('Vol (m³)',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                    Expanded(child: Text('12mm bags',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                    Expanded(child: Text('18mm bags',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                  ]),
                ),
                ...perWall.map((w) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: AppTheme.slate100))),
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: Text(w['description'] ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.slate700)),
                    ),
                    Expanded(
                      child: Text('${w['nos'] ?? 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate600)),
                    ),
                    Expanded(
                      child: Text('${w['volume_cum'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate600)),
                    ),
                    Expanded(
                      child: Text('${w['cement_bags_12mm'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E6FD9))),
                    ),
                    Expanded(
                      child: Text('${w['cement_bags_18mm'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1557B0))),
                    ),
                  ]),
                )),
                // Total row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E6FD9),
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL CEMENT BAGS ($_selectedThickness)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text('$bags bags',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _cementCard(String label, String value, String unit,
      String sub, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 12, color: color.withOpacity(0.7))),
              ),
            ],
          ),
          Text(sub,
              style: TextStyle(
                  fontSize: 11, color: color.withOpacity(0.6))),
        ]),
      ),
    );
  }

  Widget _mixChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1E6FD9)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? const Color(0xFF1E6FD9)
                : AppTheme.slate200,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.slate600)),
      ),
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.isEmpty ? label : '$label: $value',
        style: const TextStyle(
            color: Colors.white, fontSize: 12),
      ),
    );
  }

  static const _hStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppTheme.slate500);
}

// ─────────────────────────────────────────────────────────────
//  SAND TAB
// ─────────────────────────────────────────────────────────────
class _SandTab extends StatefulWidget {
  final Map<String, dynamic> data;
  const _SandTab({required this.data});

  @override
  State<_SandTab> createState() => _SandTabState();
}

class _SandTabState extends State<_SandTab> {
  String _selectedMix  = '1:4';
  String _selectedUnit = 'tons';

  static const _mixes = ['1:3', '1:4', '1:5', '1:6'];

  @override
  Widget build(BuildContext context) {
    final sand     = widget.data['sand']           ?? {};
    final vol      = widget.data['volume_summary'] ?? {};
    final allMixes = sand['all_mixes']              ?? {};
    final perWall  = (sand['per_wall'] as List?)    ?? [];

    final currentMix = allMixes[_selectedMix] ?? {};
    final sandValue  = _selectedUnit == 'tons'
        ? currentMix['sand_tons'] ?? 0
        : currentMix['sand_cum']  ?? 0;
    final sandUnit   = _selectedUnit == 'tons' ? 'Tons' : 'm³';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF0D9488)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SAND CALCULATION',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                const Text(
                  'Based on Master Data — m³ / Tons per m³ of brickwork',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _infoPill('Net Volume',
                      '${vol['net_volume_cuft'] ?? 0} Cu.Ft'),
                  const SizedBox(width: 8),
                  _infoPill('= ${vol['net_volume_cum'] ?? 0} m³', ''),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selectors
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8, runSpacing: 8,
            children: [
            const Text('Mortar Mix:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A2332))),
            ..._mixes.map((m) => _mixChip(m, _selectedMix == m, () {
                setState(() => _selectedMix = m);
              }, const Color(0xFF0D9488))),
            const SizedBox(width: 12),
            const Text('Unit:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A2332))),
            _mixChip('Tons', _selectedUnit == 'tons',
                () => setState(() => _selectedUnit = 'tons'),
                const Color(0xFF0D9488)),
            _mixChip('m³', _selectedUnit == 'cum',
                () => setState(() => _selectedUnit = 'cum'),
                const Color(0xFF0D9488)),
          ]),
          const SizedBox(height: 16),

          // Summary cards
          Row(children: [
            _sandCard(
              'Total Sand Required',
              '$sandValue',
              sandUnit,
              'CM $_selectedMix mix',
              const Color(0xFF0D9488),
              const Color(0xFFF0FDFA),
              LucideIcons.box,
            ),
            const SizedBox(width: 12),
            _sandCard(
              'In m³',
              '${currentMix['sand_cum'] ?? 0}',
              'm³',
              'Volume measurement',
              const Color(0xFF1E6FD9),
              const Color(0xFFEFF6FF),
              LucideIcons.layers,
            ),
            const SizedBox(width: 12),
            _sandCard(
              'In Tons',
              '${currentMix['sand_tons'] ?? 0}',
              'Tons',
              'Weight measurement',
              const Color(0xFFF59E0B),
              const Color(0xFFFFFBEB),
              LucideIcons.weight,
            ),
            const SizedBox(width: 12),
            _sandCard(
              'Net Brickwork',
              '${vol['net_volume_cum'] ?? 0}',
              'm³',
              '${vol['net_volume_cuft'] ?? 0} Cu.Ft',
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
              LucideIcons.package,
            ),
          ]),
          const SizedBox(height: 20),

          // All mixes table
          const Text('Sand Quantities — All Mixes',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2332))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12)),
                  border: Border(
                      bottom: BorderSide(color: AppTheme.slate200)),
                ),
                child: const Row(children: [
                  Expanded(flex: 2,
                      child: Text('Mix', style: _hStyle)),
                  Expanded(child: Text('Sand (m³)',
                      style: _hStyle,
                      textAlign: TextAlign.center)),
                  Expanded(child: Text('Sand (Tons)',
                      style: _hStyle,
                      textAlign: TextAlign.center)),
                ]),
              ),
              ..._mixes.map((mix) {
                final m = allMixes[mix] ?? {};
                final isSelected = mix == _selectedMix;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0FDFA)
                        : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.slate100),
                      left: isSelected
                          ? const BorderSide(
                              color: Color(0xFF0D9488), width: 3)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(
                      flex: 2,
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0D9488)
                                : AppTheme.slate300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('CM $mix',
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF0D9488)
                                    : AppTheme.slate700)),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('SELECTED',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                    ),
                    Expanded(
                      child: Text('${m['sand_cum'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (_selectedUnit == 'cum' && isSelected)
                                  ? const Color(0xFF0D9488)
                                  : AppTheme.slate700)),
                    ),
                    Expanded(
                      child: Text('${m['sand_tons'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (_selectedUnit == 'tons' && isSelected)
                                  ? const Color(0xFF0D9488)
                                  : AppTheme.slate700)),
                    ),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),

          // Per wall
          if (perWall.isNotEmpty) ...[
            const Text('Sand per Wall',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2332))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12)),
                    border: Border(
                        bottom:
                            BorderSide(color: AppTheme.slate200)),
                  ),
                  child: const Row(children: [
                    Expanded(flex: 3,
                        child: Text('Wall', style: _hStyle)),
                    Expanded(child: Text('Nos',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                    Expanded(child: Text('Vol (m³)',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                    Expanded(child: Text('Sand (m³)',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                    Expanded(child: Text('Sand (Tons)',
                        style: _hStyle,
                        textAlign: TextAlign.center)),
                  ]),
                ),
                ...perWall.map((w) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppTheme.slate100))),
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: Text(w['description'] ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.slate700)),
                    ),
                    Expanded(
                      child: Text('${w['nos'] ?? 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate600)),
                    ),
                    Expanded(
                      child: Text('${w['volume_cum'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate600)),
                    ),
                    Expanded(
                      child: Text('${w['sand_cum'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D9488))),
                    ),
                    Expanded(
                      child: Text('${w['sand_tons'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B))),
                    ),
                  ]),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D9488),
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL SAND (CM $_selectedMix)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text('$sandValue $sandUnit',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sandCard(String label, String value, String unit,
      String sub, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(unit,
                  style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7))),
            ),
          ]),
          Text(sub,
              style: TextStyle(
                  fontSize: 11, color: color.withOpacity(0.6))),
        ]),
      ),
    );
  }

  Widget _mixChip(String label, bool selected, VoidCallback onTap,
      Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? color : AppTheme.slate200),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.slate600)),
      ),
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.isEmpty ? label : '$label: $value',
        style: const TextStyle(
            color: Colors.white, fontSize: 12),
      ),
    );
  }

  static const _hStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppTheme.slate500);
}

// ─────────────────────────────────────────────────────────────
//  COMING SOON
// ─────────────────────────────────────────────────────────────
class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.clock,
                size: 36, color: AppTheme.slate400),
          ),
          const SizedBox(height: 16),
          Text('$label calculation coming soon',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate500)),
          const SizedBox(height: 6),
          const Text(
            'Upload a floor plan to enable this section',
            style: TextStyle(
                fontSize: 13, color: AppTheme.slate400),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FORMULA CHIP
// ─────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}