import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/env.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/sync_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await SupabaseService.instance.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compte créé ! Vérifie ta boîte mail si la confirmation est activée.')),
          );
        }
      } else {
        await SupabaseService.instance.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
      // Déclenche une synchronisation immédiate après connexion.
      ref.read(syncStatusProvider.notifier).sync();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Synchronisation Cloud')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              "La synchronisation Supabase n'est pas encore configurée.\n\n"
              "Renseigne SUPABASE_URL et SUPABASE_ANON_KEY dans lib/core/env.dart "
              "(voir le README) pour activer la sauvegarde cloud multi-appareil.\n\n"
              "L'application reste pleinement utilisable hors-ligne en attendant.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Créer un compte' : 'Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 56, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                'Connecte-toi pour synchroniser tes données\nsur tous tes appareils',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isSignUp ? "S'inscrire" : 'Se connecter'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? 'Déjà un compte ? Se connecter' : "Pas encore de compte ? S'inscrire"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
