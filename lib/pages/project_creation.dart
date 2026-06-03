import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';


class ProjectCreation extends StatefulWidget {
  const ProjectCreation({super.key});

  @override
  State<ProjectCreation> createState() => _ProjectCreationState();
}

class _ProjectCreationState extends State<ProjectCreation>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Create Project state ──────────────────────────────
  String selectedType  = 'residential';
  bool _isCreating     = false;
  String? _errorMessage;
  DateTime? _selectedDate;

  final _nameController    = TextEditingController();
  final _addressController = TextEditingController();
  final _clientController  = TextEditingController();

  // ── Select Project state ──────────────────────────────
  bool _loadingProjects    = true;
  List<dynamic> _projects  = [];
  String? _selectedProjectId;
  String? _currentProjectId;

  final types = [
    {'id': 'residential',   'label': 'Residential',   'icon': LucideIcons.house},
    {'id': 'commercial',    'label': 'Commercial',     'icon': LucideIcons.briefcase},
    {'id': 'industrial',    'label': 'Industrial',     'icon': LucideIcons.factory},
    {'id': 'infrastructure','label': 'Infrastructure', 'icon': LucideIcons.map},
    {'id': 'institutional', 'label': 'Institutional',  'icon': LucideIcons.building2},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final prefs     = await SharedPreferences.getInstance();
      final currentId = prefs.getString('current_project_id') ?? '';
      final data      = await ApiService.getProjects();
      if (mounted) {
        setState(() {
          _projects          = data;
          _currentProjectId  = currentId;
          _selectedProjectId = currentId.isNotEmpty ? currentId : null;
          _loadingProjects   = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Project name is required');
      return;
    }
    setState(() { _isCreating = true; _errorMessage = null; });
    try {
      final result = await ApiService.createProject(
        _nameController.text.trim(),
        _addressController.text.trim(),
      );
      if (result['id'] != null && mounted) {
        // Save as current project
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_project_id', result['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(LucideIcons.squareCheckBig,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Project "${result['name']}" created!'),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
        context.go('/');
      } else {
        setState(() =>
            _errorMessage = result['error'] ?? 'Failed to create project');
      }
    } catch (e) {
      setState(() =>
          _errorMessage = 'Connection error. Is your server running?');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _selectProject(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_project_id', projectId);
    setState(() {
      _currentProjectId  = projectId;
      _selectedProjectId = projectId;
    });
    if (mounted) {
      final project = _projects.firstWhere((p) => p['id'] == projectId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(LucideIcons.squareCheckBig,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('"${project['name']}" set as active project'),
          ]),
          backgroundColor: const Color(0xFF0891B2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Tabs ─────────────────────────────────
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF0891B2),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF0891B2),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.circle,
                              size: 16),
                          SizedBox(width: 6),
                          Text('Create New'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.folder, size: 16),
                          SizedBox(width: 6),
                          Text('Select Existing'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Tab 1: Create New ──────────────
                    _buildCreateForm(),
                    // ── Tab 2: Select Existing ─────────
                    _buildSelectExisting(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // ── Right: Summary ──────────────────────────────
        Expanded(
          child: Column(
            children: [
              // Current active project card
              if (_currentProjectId != null &&
                  _currentProjectId!.isNotEmpty &&
                  _projects.isNotEmpty)
                _buildCurrentProjectCard(),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Text('Project Details Summary',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    SizedBox(height: 16),
                    _SummaryRow(
                        'Project Value (Est.)', '₹2,450,000'),
                    _SummaryRow('Duration', '18 Months'),
                    _SummaryRow('Total Area', '12,500 sq ft'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Text('Cost Distribution by Role',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(PieChartData(
                        sections: [
                          PieChartSectionData(
                              value: 546200,
                              color: const Color(0xFF0891B2),
                              title: '',
                              radius: 60),
                          PieChartSectionData(
                              value: 311000,
                              color: const Color(0xFF3B82F6),
                              title: '',
                              radius: 60),
                          PieChartSectionData(
                              value: 225000,
                              color: const Color(0xFF8B5CF6),
                              title: '',
                              radius: 60),
                          PieChartSectionData(
                              value: 956000,
                              color: const Color(0xFF10B981),
                              title: '',
                              radius: 60),
                          PieChartSectionData(
                              value: 425000,
                              color: const Color(0xFFF59E0B),
                              title: '',
                              radius: 60),
                        ],
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Current Active Project Card ───────────────────────
  Widget _buildCurrentProjectCard() {
    final project = _projects.firstWhere(
      (p) => p['id'] == _currentProjectId,
      orElse: () => null,
    );
    if (project == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0891B2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.squareCheckBig,
                  size: 14, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Text('Active Project',
                  style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project['name'] ?? 'Unnamed',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          if ((project['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project['description'],
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  project['status'] ?? 'active',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    _tabController.animateTo(1),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Change →',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Create New Form ───────────────────────────────────
  Widget _buildCreateForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Information',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 24),

          // Project Name
          const Text('Project Name',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              prefixIcon: const Icon(LucideIcons.fileText,
                  size: 18, color: Color(0xFF94A3B8)),
              hintText: 'Enter project name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color(0xFF0891B2), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Address
          const Text('Project Address / Location',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter full address...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color(0xFF0891B2), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Client
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Client / Owner',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.user,
                            size: 18, color: Color(0xFF94A3B8)),
                        hintText: 'Client name...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF0891B2), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Start Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start Date',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ''
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.calendar,
                            size: 18, color: Color(0xFF94A3B8)),
                        hintText: 'dd/mm/yyyy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF0891B2), width: 2),
                        ),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate:   DateTime(2000),
                          lastDate:    DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Project Type
          const Text('Project Type',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: types.map((type) {
              final isSelected = selectedType == type['id'];
              return ChoiceChip(
                selected: isSelected,
                label: Column(
                  children: [
                    Icon(type['icon'] as IconData,
                        size: 24,
                        color: isSelected
                            ? const Color(0xFF0891B2)
                            : const Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(type['label'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF0891B2)
                                : const Color(0xFF64748B))),
                  ],
                ),
                selectedColor: const Color(0xFFECFEFF),
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0891B2)
                        : const Color(0xFFE2E8F0)),
                onSelected: (_) => setState(
                    () => selectedType = type['id'] as String),
              );
            }).toList(),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(children: [
                const Icon(LucideIcons.circle,
                    size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text(_errorMessage!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 13)),
              ]),
            ),
          ],

          const Spacer(),
          const Divider(),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(
                      color: Color(0xFFCBD5E1)),
                ),
                child: const Text('Advanced Settings'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isCreating ? null : _createProject,
                icon: _isCreating
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.check, size: 16),
                label: Text(
                    _isCreating ? 'Creating...' : 'Create Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891B2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF0891B2).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Select Existing Projects ──────────────────────────
  Widget _buildSelectExisting() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Projects',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
              IconButton(
                onPressed: _loadProjects,
                icon: const Icon(LucideIcons.refreshCw,
                    size: 16, color: Color(0xFF64748B)),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a project to make it active. All uploads and calculations will be linked to this project.',
            style: TextStyle(
                fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          if (_loadingProjects)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                    color: Color(0xFF0891B2)),
              ),
            )
          else if (_projects.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(LucideIcons.folderOpen,
                        size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text('No projects yet',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    const Text('Create your first project',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          _tabController.animateTo(0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF0891B2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create New Project'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _projects.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p         = _projects[index];
                  final id        = p['id'] as String;
                  final isActive  = id == _currentProjectId;
                  final isSelected = id == _selectedProjectId;
                  final status    = p['status'] ?? 'active';
                  final createdAt = DateTime.tryParse(
                      p['created_at'] ?? '');

                  final statusColor = status == 'active'
                      ? const Color(0xFF10B981)
                      : status == 'completed'
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF59E0B);
                  final statusBg = status == 'active'
                      ? const Color(0xFFD1FAE5)
                      : status == 'completed'
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFFEF3C7);

                  return InkWell(
                    onTap: () => setState(
                        () => _selectedProjectId = id),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFECFEFF)
                            : isSelected
                                ? const Color(0xFFF0F9FF)
                                : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF0891B2)
                              : isSelected
                                  ? const Color(0xFFBAE6FD)
                                  : const Color(0xFFE2E8F0),
                          width: isActive || isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF0891B2)
                                  : const Color(0xFFF1F5F9),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(
                              LucideIcons.building2,
                              size: 20,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(
                                      p['name'] ?? 'Unnamed',
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                          fontSize: 14,
                                          color: isActive
                                              ? const Color(
                                                  0xFF0891B2)
                                              : const Color(
                                                  0xFF1E293B)),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 8,
                                          vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                            0xFF0891B2),
                                        borderRadius:
                                            BorderRadius.circular(
                                                12),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold,
                                            letterSpacing: 0.5),
                                      ),
                                    ),
                                ]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 6,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius:
                                            BorderRadius.circular(
                                                999)),
                                    child: Text(
                                        status.isEmpty ? status : status[0].toUpperCase() + status.substring(1),

                                      style: TextStyle(
                                          fontSize: 11,
                                          color: statusColor,
                                          fontWeight:
                                              FontWeight.w500),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (createdAt != null)
                                    Text(
                                      'Created ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(
                                              0xFF94A3B8)),
                                    ),
                                ]),
                                if ((p['description'] ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    p['description'],
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                            Color(0xFF64748B)),
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Select button
                          if (!isActive)
                            ElevatedButton(
                              onPressed: () =>
                                  _selectProject(id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? const Color(0xFF0891B2)
                                    : const Color(0xFFF1F5F9),
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            8)),
                              ),
                              child: Text(
                                isSelected
                                    ? 'Set Active'
                                    : 'Select',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w500),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.check,
                                size: 18,
                                color: Color(0xFF10B981),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Color(0xFF64748B))),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

