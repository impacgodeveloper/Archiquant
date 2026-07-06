import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

// ─────────────────────────────────────────────────────────────
//  PLAN MODEL
// ─────────────────────────────────────────────────────────────
class _Plan {
  final String id;
  final String name;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final bool popular;
  final Color color;

  const _Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.popular,
    required this.color,
  });
}

const _plans = [
  _Plan(
    id: 'starter', name: 'Starter',
    price: '₹999', period: '/month',
    description: 'Perfect for small firms getting started',
    popular: false, color: Color(0xFF64748B),
    features: [
      'Up to 3 projects',
      'Up to 4 team members',
      'Blueprint OCR analysis',
      'Brick calculation BOQ',
      'Basic formula management',
      'Email support',
    ],
  ),
  _Plan(
    id: 'professional', name: 'Professional',
    price: '₹2,499', period: '/month',
    description: 'For growing architecture firms',
    popular: true, color: Color(0xFF0891B2),
    features: [
      'Unlimited projects',
      'Up to 6 team members',
      'Advanced OCR analysis',
      'Full material BOQ',
      'Custom formula editor',
      'Export PDF / Excel reports',
      'Priority email support',
    ],
  ),
  _Plan(
    id: 'enterprise', name: 'Enterprise',
    price: '₹4,999', period: '/month',
    description: 'For large firms and enterprises',
    popular: false, color: Color(0xFF7C3AED),
    features: [
      'Unlimited projects',
      'Unlimited team members',
      'Advanced OCR + AI analysis',
      'Full material BOQ suite',
      'Custom formula editor',
      'Export PDF / Excel reports',
      'Dedicated account manager',
      'Phone + priority support',
      'Custom integrations',
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
//  REGISTER PAGE
// ─────────────────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int    _step           = 0;
  String _selectedPlanId = 'professional';
  bool   _showPassword   = false;
  bool   _isLoading      = false;
  String? _error;

  final _companyNameCtrl = TextEditingController();
  final _slugCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();

  Map<String, dynamic>? _createdCompany;

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _slugCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onCompanyNameChanged(String value) {
    _slugCtrl.text = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _register() async {
    if (_companyNameCtrl.text.trim().isEmpty ||
        _slugCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all required fields');
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

    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await ApiService.register(
        _companyNameCtrl.text.trim(),
        _slugCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        plan:  _selectedPlanId,
        phone: _phoneCtrl.text.trim(),
      );

      if (result['token'] != null && mounted) {
        setState(() {
          _createdCompany = result['company'];
          _step           = 2;
          _isLoading      = false;
        });
      } else {
        setState(() {
          _error     = result['error'] ?? 'Registration failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error     = e is ApiException ? e.message : 'Connection error. Is your server running?';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(builder: (context, c) {
        final step = _step == 0
            ? _buildPlanStep()
            : _step == 1
                ? _buildDetailsStep()
                : _buildSuccessStep();
        // Narrow screens (phones): show the form full-width; the step rail would
        // squeeze the content to ~1 char wide (vertical text). Wide: two columns.
        if (c.maxWidth < 768) return SafeArea(child: step);
        return Row(
          children: [
            _buildLeftPanel(),
            Expanded(flex: 3, child: step),
          ],
        );
      }),
    );
  }

  // ── Left Panel ─────────────────────────────────────────
  Widget _buildLeftPanel() {
    return Container(
      width: 280,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0891B2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('A',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 10),
            const Text('ArchiQuant',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 40),
          _stepIndicator(0, 'Choose Plan',     _step >= 0),
          _stepConnector(),
          _stepIndicator(1, 'Company Details', _step >= 1),
          _stepConnector(),
          _stepIndicator(2, 'Start Building',  _step >= 2),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0891B2).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF0891B2).withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(LucideIcons.gift,
                      size: 14, color: Color(0xFF0891B2)),
                  SizedBox(width: 6),
                  Text('14-Day Free Trial',
                      style: TextStyle(
                          color: Color(0xFF0891B2),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
                SizedBox(height: 6),
                Text('No credit card required.\nCancel anytime.',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Have an account? ',
                style: TextStyle(
                    color: Colors.white54, fontSize: 12)),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: const Text('Sign in',
                  style: TextStyle(
                      color: Color(0xFF0891B2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _stepIndicator(int n, String label, bool active) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0891B2)
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? const Color(0xFF0891B2) : Colors.white24,
          ),
        ),
        alignment: Alignment.center,
        child: _step > n
            ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
            : Text('${n + 1}',
                style: TextStyle(
                    color: active ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    ]);
  }

  Widget _stepConnector() => Container(
        margin: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
        width: 2, height: 20,
        color: Colors.white12,
      );

  // ── Step 0 — Plan Selection ─────────────────────────────
  Widget _buildPlanStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose your plan',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text(
            'Start with a 14-day free trial. No credit card required.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _plans.map((plan) => Expanded(
              child: _PlanCard(
                plan:       plan,
                isSelected: _selectedPlanId == plan.id,
                onTap:      () => setState(() => _selectedPlanId = plan.id),
              ),
            )).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0891B2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue with ${_plans.firstWhere((p) => p.id == _selectedPlanId).name}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'All plans include 14-day free trial • Cancel anytime',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Company Details ────────────────────────────
  Widget _buildDetailsStep() {
    final plan = _plans.firstWhere((p) => p.id == _selectedPlanId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(LucideIcons.arrowLeft,
                size: 16, color: Color(0xFF64748B)),
            label: const Text('Back to plans',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          const SizedBox(height: 16),

          // Plan badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: plan.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: plan.color.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(LucideIcons.check, size: 16, color: plan.color),
              const SizedBox(width: 8),
              Text(
                '${plan.name} Plan — ${plan.price}${plan.period}',
                style: TextStyle(
                    color: plan.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _step = 0),
                child: Text('Change',
                    style: TextStyle(
                        color: plan.color,
                        fontSize: 12,
                        decoration: TextDecoration.underline)),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          const Text('Set up your workspace',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          const Text('Create your company account',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 28),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Company Name
                _formLabel('Company Name *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _companyNameCtrl,
                  onChanged: _onCompanyNameChanged,
                  decoration: _inputDec(
                    icon: LucideIcons.building2,
                    hint: 'e.g. IMPACGO Architects',
                  ),
                ),
                const SizedBox(height: 18),

                // Company Slug
                _formLabel('Company ID'),
                const SizedBox(height: 4),
                const Text(
                  'Auto-generated from company name — used for login',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _slugCtrl,
                  decoration: _inputDec(
                    icon: LucideIcons.hash,
                    hint: 'e.g. impacgo',
                    suffix: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFEFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Login slug',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0891B2))),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Admin Email
                _formLabel('Admin Email *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDec(
                    icon: LucideIcons.mail,
                    hint: 'admin@yourcompany.com',
                  ),
                ),
                const SizedBox(height: 18),

                // Phone Number
                _formLabel('Phone Number'),
                const SizedBox(height: 4),
                const Text(
                  'Optional — for account recovery and notifications',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDec(
                    icon: LucideIcons.phone,
                    hint: '+91 98765 43210',
                  ),
                ),
                const SizedBox(height: 18),

                // Password
                _formLabel('Password *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  decoration: _inputDec(
                    icon: LucideIcons.lock,
                    hint: 'Min 6 characters',
                    suffix: IconButton(
                      icon: Icon(
                        _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Error
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFECACA)),
                    ),
                    child: Row(children: [
                      const Icon(LucideIcons.circle,
                          size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13)),
                      ),
                    ]),
                  ),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF0891B2).withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Create Account',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'By creating an account you agree to our Terms of Service',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2 — Success ────────────────────────────────────
  Widget _buildSuccessStep() {
    final plan = _plans.firstWhere((p) => p.id == _selectedPlanId);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF6EE7B7), width: 2),
                ),
                child: const Icon(LucideIcons.circle,
                    size: 40, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 24),
              const Text('Account Created!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 10),
              Text(
                'Welcome to ArchiQuant. Your ${plan.name} workspace is ready.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 15),
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Account Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 14),
                    _successRow(LucideIcons.building2, 'Company',
                        _companyNameCtrl.text),
                    _successRow(LucideIcons.hash, 'Login Slug',
                        _slugCtrl.text),
                    _successRow(LucideIcons.mail, 'Email',
                        _emailCtrl.text),
                    if (_phoneCtrl.text.isNotEmpty)
                      _successRow(LucideIcons.phone, 'Phone',
                          _phoneCtrl.text),
                    _successRow(LucideIcons.sparkles, 'Plan',
                        '${plan.name} — 14 day free trial'),
                    _successRow(LucideIcons.users, 'Team limit',
                        '${_createdCompany?['max_users'] ?? 4} members'),
                    _successRow(LucideIcons.folder, 'Project limit',
                        '${_createdCompany?['max_projects'] ?? 3} projects'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(children: [
                  Icon(LucideIcons.info,
                      size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '14-day free trial started. No payment needed right now.',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF92400E)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(LucideIcons.layoutDashboard, size: 18),
                  label: const Text('Go to Dashboard',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text('$label:',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  Widget _formLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF334155),
          fontSize: 14));

  InputDecoration _inputDec({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) =>
      InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        suffixIcon: suffix,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF0891B2), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      );
}

// ─────────────────────────────────────────────────────────────
//  PLAN CARD WIDGET
// ─────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? plan.color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? plan.color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: plan.color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.popular)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: plan.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('MOST POPULAR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              )
            else
              const SizedBox(height: 30),

            Text(plan.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? plan.color
                        : const Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? plan.color
                            : const Color(0xFF1E293B))),
                Text(plan.period,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF94A3B8))),
              ],
            ),
            const SizedBox(height: 6),
            Text(plan.description,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4)),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Icon(LucideIcons.check,
                    size: 14,
                    color: isSelected
                        ? plan.color
                        : const Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(f,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155))),
                ),
              ]),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isSelected
                  ? ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: plan.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: plan.color,
                        side: BorderSide(color: plan.color),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Select Plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}