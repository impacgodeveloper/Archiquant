import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class TeamManagementCard extends StatefulWidget {
  final String currentUserRole;
  final String currentUserId;

  const TeamManagementCard({
    super.key,
    required this.currentUserRole,
    required this.currentUserId,
  });

  @override
  State<TeamManagementCard> createState() => _TeamManagementCardState();
}

class _TeamManagementCardState extends State<TeamManagementCard> {
  List<dynamic> _team      = [];
  bool          _loading   = true;
  bool          _showForm  = false;
  bool          _inviting  = false;
  String?       _error;
  String?       _success;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  String _role        = 'sub_user';
  bool   _showPass    = false;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getTeam();
      if (mounted) {
        setState(() { _team = data; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _inviteUser() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Email and password are required');
      return;
    }
    if (!isValidEmail(_emailCtrl.text)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    final pwErr = passwordError(_passwordCtrl.text);
    if (pwErr != null) {
      setState(() => _error = pwErr);
      return;
    }

    setState(() { _inviting = true; _error = null; _success = null; });

    try {
      final result = await ApiService.inviteUser(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _role,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _success  = 'Team member added successfully!';
          _showForm = false;
          _inviting = false;
        });
        _emailCtrl.clear();
        _passwordCtrl.clear();
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _role = 'sub_user';
        _loadTeam();
      } else {
        setState(() {
          _error    = result['error'] ?? 'Failed to add user';
          _inviting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error    = e is ApiException ? e.message : 'Could not add user. Please try again.';
        _inviting = false;
      });
    }
  }

  Future<void> _toggleUser(String userId, bool currentActive, String email) async {
    final confirm = await _showConfirmDialog(
      title:        currentActive ? 'Deactivate User' : 'Activate User',
      message:      currentActive
          ? 'Are you sure you want to deactivate $email?\nThey will not be able to login.'
          : 'Activate $email? They will be able to login again.',
      confirmText:  currentActive ? 'Deactivate' : 'Activate',
      confirmColor: currentActive
          ? const Color(0xFFEF4444)
          : const Color(0xFF10B981),
    );

    if (confirm != true) return;

    try {
      await ApiService.toggleUser(userId);
      _loadTeam();
      if (mounted) {
        _showSnack(
          currentActive ? '$email deactivated' : '$email activated',
          currentActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', const Color(0xFFEF4444));
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    final confirm = await _showConfirmDialog(
      title:        'Delete User',
      message:      'Are you sure you want to permanently delete $email?\nThis action cannot be undone.',
      confirmText:  'Delete',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirm != true) return;

    try {
      final result = await ApiService.deleteUser(userId);
      if (result['success'] == true) {
        _loadTeam();
        if (mounted) {
          _showSnack('$email deleted successfully', const Color(0xFF10B981));
        }
      } else {
        if (mounted) {
          _showSnack(
            result['error'] ?? 'Failed to delete user',
            const Color(0xFFEF4444),
          );
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', const Color(0xFFEF4444));
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color  confirmColor,
  }) {
    return showDialog<bool>(
      context:             context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2332))),
        content: Text(message,
            style: const TextStyle(
                color: Color(0xFF6B7A8D), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7A8D))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUserRole == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.users,
                    size: 18, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Members',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    Text('Manage architects and team members',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (isAdmin) ...[
                IconButton(
                  onPressed: _loadTeam,
                  icon: const Icon(LucideIcons.refreshCw,
                      size: 16, color: Color(0xFF64748B)),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showForm = !_showForm),
                  icon: Icon(
                    _showForm ? LucideIcons.x : LucideIcons.userPlus,
                    size: 16,
                  ),
                  label: Text(_showForm ? 'Cancel' : 'Add Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showForm
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E6FD9),
                    foregroundColor: _showForm
                        ? const Color(0xFF475569)
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ]),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // ── Success message ──────────────────────────────
          if (_success != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: Row(children: [
                const Icon(LucideIcons.circleCheck,
                    size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_success!,
                      style: const TextStyle(
                          color: Color(0xFF10B981), fontSize: 13)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _success = null),
                  child: const Icon(LucideIcons.x,
                      size: 14, color: Color(0xFF10B981)),
                ),
              ]),
            ),

          // ── Invite form ──────────────────────────────────
          if (_showForm && isAdmin)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF1E6FD9).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E6FD9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.userPlus,
                          size: 16, color: Color(0xFF1E6FD9)),
                    ),
                    const SizedBox(width: 10),
                    const Text('Add New Team Member',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1E293B))),
                  ]),
                  const SizedBox(height: 16),

                  // Name + Email
                  Row(children: [
                    Expanded(child: _formField(
                        'Full Name', _nameCtrl,
                        LucideIcons.user, 'e.g. Rajesh Kumar')),
                    const SizedBox(width: 16),
                    Expanded(child: _formField(
                        'Email Address *', _emailCtrl,
                        LucideIcons.mail, 'architect@company.com',
                        type: TextInputType.emailAddress)),
                  ]),
                  const SizedBox(height: 14),

                  // Phone + Password
                  Row(children: [
                    Expanded(child: _formField(
                        'Phone Number', _phoneCtrl,
                        LucideIcons.phone, '+91 98765 43210',
                        type: TextInputType.phone)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Password *',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: !_showPass,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(LucideIcons.lock,
                                  size: 16, color: Color(0xFF94A3B8)),
                              hintText: 'Min 6 characters',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPass
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 16,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setState(
                                    () => _showPass = !_showPass),
                              ),
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
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // Role
                  const Text('Role',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Row(children: [
                    _roleChip('sub_user', 'Architect', LucideIcons.hardHat),
                    const SizedBox(width: 10),
                    _roleChip('admin', 'Admin', LucideIcons.shield),
                  ]),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFFECACA)),
                      ),
                      child: Row(children: [
                        const Icon(LucideIcons.circleAlert,
                            size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _inviting ? null : _inviteUser,
                      icon: _inviting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(LucideIcons.userPlus, size: 16),
                      label: Text(_inviting ? 'Adding...' : 'Add Team Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FD9),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Team list ────────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1E6FD9))),
            )
          else if (_team.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(children: [
                  const Icon(LucideIcons.users,
                      size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text('No team members yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  const Text('Add architects to your team',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF94A3B8))),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _showForm = true),
                      icon: const Icon(LucideIcons.userPlus, size: 16),
                      label: const Text('Add First Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FD9),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ]),
              ),
            )
          else
            Column(
              children: _team.map((member) {
                final memberId      = member['id'] as String;
                final email         = member['email']     ?? '';
                final fullName      = member['full_name'] ?? '';
                final phone         = member['phone']     ?? '';
                final role          = member['role']      ?? 'sub_user';
                final isActive      = member['active']    ?? true;
                final isCurrentUser = memberId == widget.currentUserId;
                final createdAt     = DateTime.tryParse(
                    member['created_at'] ?? '');

                final displayName =
                    fullName.isNotEmpty ? fullName : email;
                final initials = displayName.isNotEmpty
                    ? displayName[0].toUpperCase() : '?';

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? const Color(0xFFF8FAFF)
                        : Colors.white,
                    border: const Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(children: [

                    // Avatar
                    Stack(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: role == 'admin'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF0FDF4),
                        child: Text(initials,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: role == 'admin'
                                    ? const Color(0xFF1E6FD9)
                                    : const Color(0xFF10B981))),
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B))),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E6FD9)
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                child: const Text('You',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF1E6FD9),
                                        fontWeight:
                                            FontWeight.w600)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B))),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(phone,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8))),
                          ],
                          const SizedBox(height: 6),
                          Row(children: [
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: role == 'admin'
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF0FDF4),
                                borderRadius:
                                    BorderRadius.circular(4),
                                border: Border.all(
                                  color: role == 'admin'
                                      ? const Color(0xFFBFDBFE)
                                      : const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    role == 'admin'
                                        ? LucideIcons.shield
                                        : LucideIcons.hardHat,
                                    size: 10,
                                    color: role == 'admin'
                                        ? const Color(0xFF1E6FD9)
                                        : const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    role == 'admin'
                                        ? 'Admin' : 'Architect',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: role == 'admin'
                                            ? const Color(0xFF1E6FD9)
                                            : const Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isActive
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444)),
                              ),
                            ),

                            if (createdAt != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Joined ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),

                    // Actions
                    if (isAdmin && !isCurrentUser)
                      Row(children: [
                        // Toggle active/inactive
                        Tooltip(
                          message: isActive ? 'Deactivate' : 'Activate',
                          child: InkWell(
                            onTap: () => _toggleUser(
                                memberId, isActive, email),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFFFF7ED)
                                    : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isActive
                                    ? LucideIcons.userX
                                    : LucideIcons.userCheck,
                                size: 16,
                                color: isActive
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete
                        Tooltip(
                          message: 'Delete user',
                          child: InkWell(
                            onTap: () => _deleteUser(memberId, email),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  LucideIcons.trash2,
                                  size: 16,
                                  color: Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                      ]),
                  ]),
                );
              }).toList(),
            ),

          // Plan limit info
          if (_team.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12)),
                border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(children: [
                const Icon(LucideIcons.info,
                    size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text(
                  '${_team.length} member${_team.length != 1 ? 's' : ''} in your team',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────

  Widget _formField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType type = TextInputType.text,
  }) {
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
          controller:   controller,
          keyboardType: type,
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                size: 16, color: const Color(0xFF94A3B8)),
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
          ),
        ),
      ],
    );
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final isSelected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E6FD9)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E6FD9)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: isSelected
                  ? Colors.white : const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white : const Color(0xFF64748B))),
        ]),
      ),
    );
  }
}