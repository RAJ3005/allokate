import 'package:local_auth/local_auth.dart';

class LocalAuthHelper {
  /// Determined to return a true/false value based on the user's biometric outcome.
  /// Throws exceptions otherwise.
  static Future<bool> offerBiometrics() async {
    var localAuth = LocalAuthentication();
    bool canCheck = await localAuth.canCheckBiometrics;
    if (!canCheck) {
      throw Exception('No biometrics available on this device');
    }

    var availableBiometrics = await localAuth.getAvailableBiometrics();
    if (availableBiometrics.isEmpty) {
      throw Exception('No biometrics available on this device');
    }

    return await localAuth.authenticate(localizedReason: 'Please verify your identity', stickyAuth: true);
  }
}
