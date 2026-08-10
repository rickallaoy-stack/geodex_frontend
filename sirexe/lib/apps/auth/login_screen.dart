import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../ministere/ministere_app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum Role { ministere, terrain }

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  Role _role       = Role.ministere;
  bool _loading    = false;
  bool _obscure    = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double>    _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _fillDemo(Role role) {
    setState(() {
      _role = role;
      _emailCtrl.text = role == Role.ministere
        ? 'demo.ministere@mines.ci'
        : 'demo.operateur@geodex.ci';
      _passCtrl.text = 'demo1234';
      _error = null;
    });
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _loading = false);

    if (_role == Role.ministere) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MinistereApp()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MinistereApp()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(
            painter: _GridPainter())),
          Positioned(
            top: -100, left: 0, right: 0,
            child: Center(child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  SirexeTheme.accentBlue.withOpacity(0.06),
                  Colors.transparent,
                ])),
            ))),
          Center(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: SirexeTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SirexeTheme.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: SirexeTheme.accentBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SirexeTheme.accentBlue.withOpacity(0.25))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 9, height: 9,
                          decoration: const BoxDecoration(
                            color: SirexeTheme.accentBlue,
                            shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        const Text('GEODEX', style: TextStyle(
                          color: SirexeTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20, letterSpacing: 3)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Système de gestion des permis miniers · CI',
                      style: TextStyle(
                        color: SirexeTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    Row(children: [
                      _RoleCard(
                        emoji: '🏛️',
                        label: 'Ministère',
                        desc: 'Dashboard · Audit',
                        active: _role == Role.ministere,
                        color: SirexeTheme.accentBlue,
                        onTap: () => setState(() => _role = Role.ministere)),
                      const SizedBox(width: 8),
                      _RoleCard(
                        emoji: '⛏️',
                        label: 'Opérateur terrain',
                        desc: 'Pesée · GPS · Offline',
                        active: _role == Role.terrain,
                        color: SirexeTheme.accent,
                        onTap: () => setState(() => _role = Role.terrain)),
                    ]),
                    const SizedBox(height: 20),
                    _Field(
                      label: 'Identifiant',
                      controller: _emailCtrl,
                      hint: _role == Role.ministere
                        ? 'agent.ministere@mines.ci'
                        : 'operateur.site@geodex.ci',
                      icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Mot de passe',
                      controller: _passCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                          size: 16,
                          color: SirexeTheme.textSecondary),
                        onPressed: () =>
                          setState(() => _obscure = !_obscure),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints())),
                    const SizedBox(height: 6),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                            color: SirexeTheme.danger, size: 13),
                          const SizedBox(width: 6),
                          Text(_error!, style: const TextStyle(
                            color: SirexeTheme.danger, fontSize: 12)),
                        ]),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _role == Role.ministere
                            ? SirexeTheme.accentBlue
                            : SirexeTheme.accent),
                        child: TextButton(
                          onPressed: _loading ? null : _login,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                          child: _loading
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_role == Role.ministere
                                    ? '🏛️  Accéder au Dashboard'
                                    : '⛏️  Accéder à l\'App Terrain',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                                ],
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Container(
                        height: 0.5, color: SirexeTheme.border)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Accès démo',
                          style: TextStyle(
                            color: SirexeTheme.textSecondary, fontSize: 11))),
                      Expanded(child: Container(
                        height: 0.5, color: SirexeTheme.border)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _DemoBtn(
                        label: '👤 Demo Ministère',
                        onTap: () => _fillDemo(Role.ministere)),
                      const SizedBox(width: 8),
                      _DemoBtn(
                        label: '👤 Demo Opérateur',
                        onTap: () => _fillDemo(Role.terrain)),
                    ]),
                    const SizedBox(height: 16),
                    const Text(
                      'Ministère des Mines, du Pétrole et de l\'Énergie · CI',
                      style: TextStyle(
                        color: SirexeTheme.textSecondary, fontSize: 10),
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          )),
        ]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F6FEB).withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override bool shouldRepaint(_) => false;
}

class _RoleCard extends StatelessWidget {
  final String emoji, label, desc;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({required this.emoji, required this.label,
    required this.desc, required this.active,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.08) : SirexeTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : SirexeTheme.border,
            width: active ? 1.5 : 0.5)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            color: active ? color : SirexeTheme.textPrimary,
            fontSize: 12, fontWeight: FontWeight.w600)),
          Text(desc, style: const TextStyle(
            color: SirexeTheme.textSecondary, fontSize: 10),
            textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  const _Field({required this.label, required this.hint,
    required this.controller, required this.icon,
    this.obscure = false, this.suffix});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 11,
        fontWeight: FontWeight.w500, letterSpacing: 0.5)),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: SirexeTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: SirexeTheme.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon,
            color: SirexeTheme.textSecondary, size: 16),
          suffixIcon: suffix,
          filled: true,
          fillColor: SirexeTheme.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SirexeTheme.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SirexeTheme.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SirexeTheme.accentBlue, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12)),
      ),
    ],
  );
}

class _DemoBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DemoBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: SirexeTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: SirexeTheme.border)),
        child: Text(label, style: const TextStyle(
          color: SirexeTheme.textSecondary, fontSize: 11),
          textAlign: TextAlign.center),
      ),
    ),
  );
}
