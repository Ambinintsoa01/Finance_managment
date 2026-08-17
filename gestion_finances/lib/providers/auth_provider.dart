import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import '../data/remote/supabase_service.dart';

/// Expose l'état d'authentification Supabase. Si Supabase n'est pas
/// configuré (clés absentes), l'app reste utilisable en local uniquement.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  if (!Env.isConfigured) return const Stream.empty();
  return SupabaseService.instance.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  if (!Env.isConfigured) return null;
  return SupabaseService.instance.currentUser;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
