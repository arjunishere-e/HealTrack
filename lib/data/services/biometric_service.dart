import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.canCheckBiometrics;
      return isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate user using biometric (fingerprint/face/iris)
  Future<bool> authenticateWithBiometric({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  /// Check if fingerprint is specifically available
  Future<bool> isFingerprintAvailable() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      return false;
    }
  }

  /// Authenticate specifically for password reset with custom message
  Future<bool> authenticateForPasswordReset() async {
    return authenticateWithBiometric(
      reason: 'Verify your identity to reset password',
      useErrorDialogs: true,
    );
  }
}
