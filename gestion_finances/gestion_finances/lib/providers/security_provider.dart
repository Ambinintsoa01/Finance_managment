import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/biometric_service.dart';

/// Service biométrique partagé
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// État de la sécurité de l'application
class SecurityState {
  final bool isSecurityEnabled;
  final bool lockOnBackground;
  final bool isUnlocked;
  final bool isDeviceSupported;
  final bool canCheckBiometrics;
  final List<BiometricType> availableBiometrics;
  final bool isAuthenticating;
  final String? errorMessage;
  final bool isInitialized;

  const SecurityState({
    this.isSecurityEnabled = true,
    this.lockOnBackground = true,
    this.isUnlocked = false,
    this.isDeviceSupported = false,
    this.canCheckBiometrics = false,
    this.availableBiometrics = const [],
    this.isAuthenticating = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  SecurityState copyWith({
    bool? isSecurityEnabled,
    bool? lockOnBackground,
    bool? isUnlocked,
    bool? isDeviceSupported,
    bool? canCheckBiometrics,
    List<BiometricType>? availableBiometrics,
    bool? isAuthenticating,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isInitialized,
  }) {
    return SecurityState(
      isSecurityEnabled: isSecurityEnabled ?? this.isSecurityEnabled,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isDeviceSupported: isDeviceSupported ?? this.isDeviceSupported,
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Indique si l'écran de verrouillage doit être affiché
  bool get shouldShowLockScreen =>
      isInitialized && isSecurityEnabled && isDeviceSupported && !isUnlocked;

  /// Vérifie si Face Unlock est détecté
  bool get hasFaceUnlock => availableBiometrics.contains(BiometricType.face);

  /// Vérifie si l'empreinte digitale est détectée
  bool get hasFingerprint =>
      availableBiometrics.contains(BiometricType.fingerprint);

  /// Vérifie si l'iris est détecté
  bool get hasIris => availableBiometrics.contains(BiometricType.iris);
}

/// Contrôleur gérant la sécurité et le verrouillage
class SecurityNotifier extends StateNotifier<SecurityState> {
  final BiometricService _biometricService;
  static const String _prefSecurityEnabled = 'app_security_enabled';
  static const String _prefLockOnBackground = 'app_lock_on_background';

  SecurityNotifier(this._biometricService) : super(const SecurityState()) {
    init();
  }

  /// Initialise la configuration et vérifie les fonctionnalités de l'appareil
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Par défaut, le verrouillage est activé comme demandé
      final isSecurityEnabled = prefs.getBool(_prefSecurityEnabled) ?? true;
      final lockOnBackground = prefs.getBool(_prefLockOnBackground) ?? true;

      final isDeviceSupported = await _biometricService.isDeviceSupported();
      final canCheckBiometrics = await _biometricService.canCheckBiometrics();
      final availableBiometrics =
          await _biometricService.getAvailableBiometrics();

      // Si l'appareil ne supporte aucune méthode de verrouillage (ni biométrie ni code),
      // on laisse déverrouillé pour ne pas bloquer l'utilisateur.
      final isUnlocked = !isSecurityEnabled || !isDeviceSupported;

      state = state.copyWith(
        isSecurityEnabled: isSecurityEnabled,
        lockOnBackground: lockOnBackground,
        isUnlocked: isUnlocked,
        isDeviceSupported: isDeviceSupported,
        canCheckBiometrics: canCheckBiometrics,
        availableBiometrics: availableBiometrics,
        isInitialized: true,
      );
    } catch (e) {
      debugPrint('SecurityNotifier.init error: $e');
      state = state.copyWith(
        isUnlocked: true,
        isInitialized: true,
        errorMessage: 'Impossible d\'initialiser la sécurité.',
      );
    }
  }

  /// Déclenche l'authentification biométrique / code de l'appareil
  Future<bool> authenticate({String? customReason}) async {
    if (state.isAuthenticating) return false;

    state = state.copyWith(
      isAuthenticating: true,
      clearErrorMessage: true,
    );

    final result = await _biometricService.authenticate(
      localizedReason: customReason,
    );

    switch (result) {
      case BiometricAuthResult.success:
        state = state.copyWith(
          isUnlocked: true,
          isAuthenticating: false,
          clearErrorMessage: true,
        );
        return true;

      case BiometricAuthResult.canceled:
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Authentification annulée. Appuyez sur déverrouiller pour réessayer.',
        );
        return false;

      case BiometricAuthResult.failed:
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Échec de la reconnaissance. Veuillez réessayer ou utiliser le code de l\'appareil.',
        );
        return false;

      case BiometricAuthResult.noBiometricsEnrolled:
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Aucune donnée biométrique enregistrée sur votre appareil. Vous pouvez utiliser votre code / schéma.',
        );
        return false;

      case BiometricAuthResult.passcodeNotSet:
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Aucun code de verrouillage n\'est configuré sur cet appareil.',
        );
        return false;

      case BiometricAuthResult.lockedOut:
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Trop de tentatives infructueuses. Veuillez réessayer dans quelques instants.',
        );
        return false;

      case BiometricAuthResult.error:
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Une erreur est survenue lors de l\'authentification. Veuillez réessayer.',
        );
        return false;
    }
  }

  /// Verrouille immédiatement l'application
  void lock() {
    if (state.isSecurityEnabled && state.isDeviceSupported) {
      state = state.copyWith(
        isUnlocked: false,
        clearErrorMessage: true,
      );
    }
  }

  /// Appelé lorsque l'application passe en arrière-plan
  void onAppBackgrounded() {
    // Si l'utilisateur est déjà en train de s'authentifier (boîte de dialogue système ouverte),
    // on ne reverrouille pas car cela perturberait le flux.
    if (state.isAuthenticating) return;

    if (state.isSecurityEnabled &&
        state.lockOnBackground &&
        state.isDeviceSupported) {
      state = state.copyWith(
        isUnlocked: false,
        clearErrorMessage: true,
      );
    }
  }

  /// Active ou désactive la sécurité avec confirmation par authentification
  Future<bool> toggleSecurity(bool enabled) async {
    // Si on change l'état, on demande confirmation par biométrie/code
    final verified = await authenticate(
      customReason: enabled
          ? 'Authentifiez-vous pour activer le verrouillage de l\'application'
          : 'Authentifiez-vous pour désactiver le verrouillage de l\'application',
    );

    if (!verified) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSecurityEnabled, enabled);

    state = state.copyWith(
      isSecurityEnabled: enabled,
      isUnlocked: true,
      clearErrorMessage: true,
    );
    return true;
  }

  /// Active ou désactive le reverrouillage automatique lors de la mise en arrière-plan
  Future<void> toggleLockOnBackground(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefLockOnBackground, enabled);
    state = state.copyWith(lockOnBackground: enabled);
  }

  /// Déverrouille de force si l'appareil n'a aucun moyen de verrouillage
  void bypassIfUnsupported() {
    if (!state.isDeviceSupported) {
      state = state.copyWith(isUnlocked: true);
    }
  }

  /// Efface le message d'erreur actuel
  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }
}

/// Provider d'état de sécurité
final securityProvider =
    StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final service = ref.watch(biometricServiceProvider);
  return SecurityNotifier(service);
});
