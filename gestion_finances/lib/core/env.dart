/// Configuration de connexion à Supabase.
///
/// ⚠️ À REMPLIR avant de lancer l'application :
/// 1. Crée un projet gratuit sur https://supabase.com
/// 2. Va dans Project Settings > API
/// 3. Copie "Project URL" et "anon public key" ci-dessous
///
/// Pour un usage en production, préfère des variables d'environnement
/// (--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...)
/// plutôt que des valeurs codées en dur.
class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://VOTRE-PROJET.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'VOTRE_CLE_ANON_PUBLIC',
  );

  static bool get isConfigured =>
      !supabaseUrl.contains('VOTRE-PROJET') &&
      !supabaseAnonKey.contains('VOTRE_CLE');
}
