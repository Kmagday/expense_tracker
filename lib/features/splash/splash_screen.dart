import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _ctrl.reverse();
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.child,
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Expense Tracker',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Track smart, spend wise',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
