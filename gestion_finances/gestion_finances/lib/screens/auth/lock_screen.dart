import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../providers/security_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _hasAutoTriggered = false;

  @override
  void initState() {
    super.initState();
    // Déclenche automatiquement l'authentification à l'affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAutoAuth();
    });
  }

  void _triggerAutoAuth() {
    if (!mounted || _hasAutoTriggered) return;
    _hasAutoTriggered = true;
    final securityState = ref.read(securityProvider);
    if (securityState.isDeviceSupported && !securityState.isUnlocked) {
      ref.read(securityProvider.notifier).authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Icône sécurisée
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 52,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                const Text(
                  'Mes Finances',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Application sécurisée',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Cartouche des méthodes supportées
                _buildMethodsChipGroup(securityState),

                const SizedBox(height: 32),

                // Message d'erreur éventuel
                if (securityState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            securityState.errorMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Bouton principal Déverrouiller
                if (securityState.isDeviceSupported) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: securityState.isAuthenticating
                          ? null
                          : () {
                              ref.read(securityProvider.notifier).authenticate();
                            },
                      icon: securityState.isAuthenticating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.fingerprint, size: 24),
                      label: Text(
                        securityState.isAuthenticating
                            ? 'Vérification en cours...'
                            : 'Déverrouiller l\'application',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Utilisez Face Unlock, votre empreinte digitale\nou le mot de passe de votre appareil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ] else ...[
                  // Cas où l'appareil n'a aucune méthode de verrouillage configurée
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          'Aucune méthode de sécurité configurée',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Votre appareil ne possède ni empreinte, ni Face Unlock, ni code de déverrouillage configuré.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(securityProvider.notifier)
                                  .bypassIfUnsupported();
                            },
                            child: const Text('Continuer vers l\'accueil'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodsChipGroup(SecurityState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MÉTHODES DE DÉVERROUILLAGE DISPONIBLES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildMethodBadge(
                icon: Icons.face,
                label: 'Face Unlock',
                isAvailable: state.hasFaceUnlock,
              ),
              _buildMethodBadge(
                icon: Icons.fingerprint,
                label: 'Empreinte',
                isAvailable: state.hasFingerprint,
              ),
              _buildMethodBadge(
                icon: Icons.pin_outlined,
                label: 'Code / MDP appareil',
                isAvailable: state.isDeviceSupported,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge({
    required IconData icon,
    required String label,
    required bool isAvailable,
  }) {
    final color = isAvailable ? AppTheme.primary : Colors.grey.shade400;
    final bg = isAvailable
        ? AppTheme.primary.withValues(alpha: 0.1)
        : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
