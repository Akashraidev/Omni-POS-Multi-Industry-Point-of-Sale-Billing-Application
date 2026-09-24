import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../modules/business_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/session_provider.dart';
import '../main_layout_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: 'admin123');
  final _openingCashCtrl = TextEditingController(text: '1000');

  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<AuthProvider>().init(biz.id);
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _openingCashCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _fillRole(String username, String password) {
    setState(() {
      _userCtrl.text = username;
      _passCtrl.text = password;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz == null) {
      setState(() => _errorMessage = 'No business profile selected.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final session = context.read<SessionProvider>();
    final openingCash = double.tryParse(_openingCashCtrl.text) ?? 0.0;

    final err = await auth.login(
      businessId: biz.id,
      username: _userCtrl.text,
      password: _passCtrl.text,
      openingCash: openingCash,
      sessionProv: session,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() => _errorMessage = err);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final biz = context.watch<BusinessProvider>().currentBusiness;
    final auth = context.watch<AuthProvider>();

    final primaryColor = theme.colorScheme.primary;
    final isMedical = biz?.type == BusinessType.medical;

    return Scaffold(
      body: Stack(
        children: [
          // Elegant decorative gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E1B4B),
                        const Color(0xFF0F172A),
                      ]
                    : [
                        primaryColor.withAlpha(25),
                        const Color(0xFFF8FAFC),
                        primaryColor.withAlpha(15),
                      ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    elevation: 16,
                    shadowColor: primaryColor.withAlpha(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Brand Icon Header
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryColor,
                                      primaryColor.withAlpha(190),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withAlpha(90),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isMedical ? Icons.local_pharmacy_rounded : Icons.point_of_sale_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Store & System Title
                            Text(
                              biz?.name ?? 'OminiPOS ERP',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMedical ? 'Pharmacy Management & POS Billing' : 'Multi-Business Point of Sale',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withAlpha(150),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Quick Demo Switcher Role Pills
                            Text(
                              'QUICK DEMO ROLES',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: theme.colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _rolePill('Admin', 'admin', 'admin123', Icons.shield_rounded, primaryColor),
                                _rolePill('Pharmacist', 'pharmacist', 'pharma123', Icons.medication_rounded, const Color(0xFF10B981)),
                                _rolePill('Cashier', 'cashier', 'cashier123', Icons.badge_rounded, const Color(0xFFF59E0B)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Error banner if any
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withAlpha(18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFEF4444).withAlpha(80)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Username input
                            TextFormField(
                              controller: _userCtrl,
                              decoration: InputDecoration(
                                labelText: 'Username or Operator Name',
                                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter operator username' : null,
                            ),
                            const SizedBox(height: 14),

                            // Password / PIN input
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password or PIN',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter password' : null,
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 14),

                            // Opening Cash balance input
                            TextFormField(
                              controller: _openingCashCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Opening Cash Float (₹)',
                                prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                                helperText: 'Recorded for daily shift reconciliation',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign In Button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: auth.isLoading ? null : _handleLogin,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Sign In & Open Shift',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolePill(String title, String username, String pass, IconData icon, Color color) {
    final isSelected = _userCtrl.text.toLowerCase() == username.toLowerCase();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _fillRole(username, pass),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withAlpha(80),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withAlpha(160)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
