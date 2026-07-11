import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class AuthState {
  final bool isLocked;
  final bool pinEnabled;
  final bool biometricEnabled;

  const AuthState({
    this.isLocked = false,
    this.pinEnabled = false,
    this.biometricEnabled = false,
  });

  AuthState copyWith({
    bool? isLocked,
    bool? pinEnabled,
    bool? biometricEnabled,
  }) {
    return AuthState(
      isLocked: isLocked ?? this.isLocked,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _pinKey = 'app_pin';
  static const _biometricKey = 'biometric_enabled';

  AuthCubit({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuth = localAuth ?? LocalAuthentication(),
       super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      final biometric = await _storage.read(key: _biometricKey);
      final pinEnabled = pin != null && pin.isNotEmpty;
      final biometricEnabled = biometric == 'true';
      debugPrint('[AuthCubit] init - pinEnabled: $pinEnabled, biometricEnabled: $biometricEnabled');
      emit(AuthState(
        isLocked: pinEnabled,
        pinEnabled: pinEnabled,
        biometricEnabled: biometricEnabled,
      ));
    } catch (e) {
      debugPrint('[AuthCubit] init error (platform unavailable): $e');
      emit(const AuthState(isLocked: false));
    }
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    final valid = stored == pin;
    debugPrint('[AuthCubit] verifyPin - valid: $valid');
    if (valid) emit(state.copyWith(isLocked: false));
    return valid;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    debugPrint('[AuthCubit] PIN set');
    emit(state.copyWith(pinEnabled: true, isLocked: false));
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricKey);
    debugPrint('[AuthCubit] PIN removed');
    emit(const AuthState(isLocked: false));
  }

  Future<void> changePin(String oldPin, String newPin) async {
    final valid = await verifyPin(oldPin);
    if (!valid) throw Exception('Current PIN is incorrect');
    await setPin(newPin);
    debugPrint('[AuthCubit] PIN changed');
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!available) {
        debugPrint('[AuthCubit] biometrics not available');
        return false;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: AppMessages.biometricReason,
      );
      debugPrint('[AuthCubit] biometric auth result: $authenticated');
      if (authenticated) emit(state.copyWith(isLocked: false));
      return authenticated;
    } catch (e) {
      debugPrint('[AuthCubit] biometric auth error: $e');
      return false;
    }
  }

  Future<void> toggleBiometric(bool enabled) async {
    if (enabled) {
      final available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!available) {
        debugPrint('[AuthCubit] biometrics not available, cannot enable');
        return;
      }
    }
    await _storage.write(key: _biometricKey, value: enabled.toString());
    debugPrint('[AuthCubit] biometric toggled: $enabled');
    emit(state.copyWith(biometricEnabled: enabled));
  }

  void unlock() {
    debugPrint('[AuthCubit] unlock');
    emit(state.copyWith(isLocked: false));
  }

  void lock() {
    debugPrint('[AuthCubit] lock');
    emit(state.copyWith(isLocked: true));
  }
}
