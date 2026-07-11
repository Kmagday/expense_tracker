import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class PinSetScreen extends StatefulWidget {
  final bool isChange;

  const PinSetScreen({super.key, this.isChange = false});

  @override
  State<PinSetScreen> createState() => _PinSetScreenState();
}

class _PinSetScreenState extends State<PinSetScreen> {
  final _pinCtl = <String>['', '', '', ''];
  final _confirmCtl = <String>['', '', '', ''];
  int _step = 0; // 0 = enter, 1 = confirm
  int _currentIndex = 0;
  bool _showError = false;
  String _errorMsg = '';

  void _onDigit(String digit) {
    if (_currentIndex >= 4) return;
    if (_step == 0) {
      _pinCtl[_currentIndex] = digit;
    } else {
      _confirmCtl[_currentIndex] = digit;
    }
    _showError = false;
    if (_currentIndex < 3) {
      setState(() => _currentIndex++);
    } else if (_step == 0) {
      setState(() {
        _step = 1;
        _currentIndex = 0;
      });
    } else {
      _submit();
    }
  }

  void _onDelete() {
    if (_currentIndex <= 0 && _step == 0) return;
    if (_currentIndex <= 0 && _step == 1) {
      setState(() {
        _step = 0;
        _currentIndex = 3;
        _pinCtl[3] = '';
      });
      return;
    }
    if (_step == 0) {
      _pinCtl[_currentIndex] = '';
      setState(() => _currentIndex--);
    } else {
      _confirmCtl[_currentIndex] = '';
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submit() async {
    final pin = _pinCtl.join();
    final confirm = _confirmCtl.join();
    if (pin != confirm) {
      setState(() {
        _showError = true;
        _errorMsg = 'PINs do not match';
        _step = 0;
        _currentIndex = 0;
        for (int i = 0; i < 4; i++) {
          _pinCtl[i] = '';
          _confirmCtl[i] = '';
        }
      });
      return;
    }
    await context.read<AuthCubit>().setPin(pin);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.pinSetSuccess)),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isChange ? PageTitles.changePin : PageTitles.setPin)),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _step == 0 ? 'Enter new 4-digit PIN' : 'Confirm PIN',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (_showError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_errorMsg, style: const TextStyle(color: Colors.red)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = (_step == 0 ? _pinCtl[i] : _confirmCtl[i]).isNotEmpty;
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
            _DigitPad(onDigit: _onDigit, onDelete: _onDelete),
          ],
        ),
      ),
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
