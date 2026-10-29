import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!Env.isConfigured) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<void> signUp({required String email, required String password}) async {
    await client.auth.signUp(email: email, password: password);
  }

  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  // ---------------------------------------------------------------------
  // ACCOUNTS
  // ---------------------------------------------------------------------

  Future<void> pushAccount(Map<String, dynamic> data) =>
      client.from('accounts').upsert(data);

  Future<List<Map<String, dynamic>>> pullAccounts(DateTime? since) async {
    var query = client.from('accounts').select();
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final res = await query;
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------

  Future<void> pushCategory(Map<String, dynamic> data) =>
      client.from('categories').upsert(data);

  Future<List<Map<String, dynamic>>> pullCategories(DateTime? since) async {
    var query = client.from('categories').select();
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final res = await query;
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------

  Future<void> pushTransaction(Map<String, dynamic> data) =>
      client.from('transactions').upsert(data);

  Future<List<Map<String, dynamic>>> pullTransactions(DateTime? since) async {
    var query = client.from('transactions').select();
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final res = await query;
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------
  // BUDGETS
  // ---------------------------------------------------------------------

  Future<void> pushBudget(Map<String, dynamic> data) =>
      client.from('budgets').upsert(data);

  Future<List<Map<String, dynamic>>> pullBudgets(DateTime? since) async {
    var query = client.from('budgets').select();
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final res = await query;
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------
  // RECURRING TRANSACTIONS
  // ---------------------------------------------------------------------

  Future<void> pushRecurring(Map<String, dynamic> data) =>
      client.from('recurring_transactions').upsert(data);

  Future<List<Map<String, dynamic>>> pullRecurring(DateTime? since) async {
    var query = client.from('recurring_transactions').select();
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final res = await query;
    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------
  // SAVINGS GOALS
  // ---------------------------------------------------------------------

  Future<void> pushSavingsGoal(Map<String, dynamic> data) =>
      client.from('savings_goals').upsert(data);

  Future<List<Map<String, dynamic>>> pullSavingsGoals(DateTime? since) async {
    var query = client.from('savings_goals').select();
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final res = await query;
    return List<Map<String, dynamic>>.from(res);
  }
}
