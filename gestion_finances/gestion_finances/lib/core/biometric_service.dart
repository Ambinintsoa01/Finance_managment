import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// Service gérant l'authentification biométrique (empreinte, Face Unlock, iris)
/// et le code / mot de passe de l'appareil.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Vérifie si l'appareil supporte la biométrie ou un code de verrouillage d'appareil.
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('BiometricService.isDeviceSupported PlatformException: $e');
      return false;
    } catch (e) {
      debugPrint('BiometricService.isDeviceSupported error: $e');
      return false;
    }
  }

  /// Vérifie si des capteurs biométriques sont présents et utilisables.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint('BiometricService.canCheckBiometrics PlatformException: $e');
      return false;
    } catch (e) {
      debugPrint('BiometricService.canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Retourne la liste des types biométriques enregistrés sur l'appareil.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricService.getAvailableBiometrics PlatformException: $e');
      return [];
    } catch (e) {
      debugPrint('BiometricService.getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Déclenche l'authentification avec biométrie ou mot de passe / code de l'appareil.
  /// 
  /// [biometricOnly] est fixé à false pour permettre l'utilisation du mot de passe /
  /// code / schéma de l'appareil si l'utilisateur le souhaite ou si la biométrie échoue.
  Future<BiometricAuthResult> authenticate({
    String? localizedReason,
  }) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: localizedReason ??
            'Authentifiez-vous avec votre empreinte, votre visage ou le code de votre appareil pour continuer.',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Authentification requise',
            signInHint: 'Empreinte, Face Unlock ou code de l\'appareil',
            cancelButton: 'Annuler',
          ),
          IOSAuthMessages(
            cancelButton: 'Annuler',
            localizedFallbackTitle: 'Utiliser le mot de passe',
          ),
        ],
        biometricOnly: false,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );

      if (success) {
        return BiometricAuthResult.success;
      } else {
        return BiometricAuthResult.failed;
      }
    } on LocalAuthException catch (e) {
      debugPrint('BiometricService.authenticate LocalAuthException: ${e.code} - ${e.description}');
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
          return BiometricAuthResult.canceled;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          return BiometricAuthResult.noBiometricsEnrolled;
        case LocalAuthExceptionCode.noCredentialsSet:
          return BiometricAuthResult.passcodeNotSet;
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricAuthResult.lockedOut;
        default:
          return BiometricAuthResult.error;
      }
    } on PlatformException catch (e) {
      debugPrint('BiometricService.authenticate PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'NotEnrolled') {
        return BiometricAuthResult.noBiometricsEnrolled;
      } else if (e.code == 'PasscodeNotSet') {
        return BiometricAuthResult.passcodeNotSet;
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricAuthResult.lockedOut;
      }
      return BiometricAuthResult.error;
    } catch (e) {
      debugPrint('BiometricService.authenticate unexpected error: $e');
      return BiometricAuthResult.error;
    }
  }

  /// Arrête toute authentification en cours.
  Future<bool> cancelAuthentication() async {
    try {
      return await _auth.stopAuthentication();
    } catch (_) {
      return false;
    }
  }
}

/// Résultat détaillé d'une tentative d'authentification biométrique.
enum BiometricAuthResult {
  success,
  failed,
  canceled,
  noBiometricsEnrolled,
  passcodeNotSet,
  lockedOut,
  error,
}
