import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class LockScreen extends StatefulWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtl = <String>['', '', '', ''];
  final _focusNodes = List.generate(4, (_) => FocusNode());
  int _currentIndex = 0;
  bool _showError = false;

  @override
  void dispose() {
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_currentIndex >= 4) return;
    _pinCtl[_currentIndex] = digit;
    _showError = false;
    if (_currentIndex < 3) {
      setState(() => _currentIndex++);
      _focusNodes[_currentIndex].requestFocus();
    } else {
      _verify();
    }
  }

  void _onDelete() {
    if (_currentIndex <= 0) return;
    _pinCtl[_currentIndex] = '';
    setState(() => _currentIndex--);
    _focusNodes[_currentIndex].requestFocus();
  }

  void _verify() async {
    final pin = _pinCtl.join();
    final valid = await context.read<AuthCubit>().verifyPin(pin);
    if (!mounted) return;
    if (valid) {
      for (int i = 0; i < 4; i++) {
        _pinCtl[i] = '';
      }
      _currentIndex = 0;
    } else {
      setState(() {
        _showError = true;
        for (int i = 0; i < 4; i++) {
          _pinCtl[i] = '';
        }
        _currentIndex = 0;
      });
      _focusNodes[0].requestFocus();
    }
  }

  void _biometricAuth() async {
    final ok = await context.read<AuthCubit>().authenticateWithBiometrics();
    if (ok && mounted) {
      for (int i = 0; i < 4; i++) {
        _pinCtl[i] = '';
      }
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (!state.isLocked) return widget.child;

        return Scaffold(
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Enter PIN', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (_showError)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(AppMessages.incorrectPin, style: TextStyle(color: Colors.red)),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = _pinCtl[i].isNotEmpty;
                    return Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                if (state.biometricEnabled)
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.fingerprint),
                    onPressed: _biometricAuth,
                    tooltip: 'Use biometrics',
                  ),
                const SizedBox(height: 24),
                _DigitPad(onDigit: _onDigit, onDelete: _onDelete),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DigitPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _DigitPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _Row(digits: ['1', '2', '3'], onDigit: onDigit),
          _Row(digits: ['4', '5', '6'], onDigit: onDigit),
          _Row(digits: ['7', '8', '9'], onDigit: onDigit),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 64),
                _DigitButton(digit: '0', onDigit: onDigit),
                IconButton(
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<String> digits;
  final void Function(String) onDigit;

  const _Row({required this.digits, required this.onDigit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map((d) => _DigitButton(digit: d, onDigit: onDigit)).toList(),
      ),
    );
  }
}

class _DigitButton extends StatelessWidget {
  final String digit;
  final void Function(String) onDigit;

  const _DigitButton({required this.digit, required this.onDigit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: TextButton(
        onPressed: () => onDigit(digit),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          textStyle: const TextStyle(fontSize: 24),
        ),
        child: Text(digit),
      ),
    );
  }
}
