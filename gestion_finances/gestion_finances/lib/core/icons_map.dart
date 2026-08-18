import 'package:flutter/material.dart';

/// Convertit les clés d'icônes stockées en base (String) en IconData Flutter.
/// On stocke des Strings plutôt que des codePoints pour rester stable
/// entre les versions de Flutter et lisible dans Supabase.
IconData iconFromKey(String key) {
  switch (key) {
    // Comptes
    case 'cash':
      return Icons.payments_outlined;
    case 'bank':
      return Icons.account_balance_outlined;
    case 'mobile':
      return Icons.phone_iphone_outlined;
    case 'savings':
      return Icons.savings_outlined;
    case 'wallet':
      return Icons.account_balance_wallet_outlined;
    case 'card':
      return Icons.credit_card_outlined;

    // Catégories
    case 'food':
      return Icons.restaurant_outlined;
    case 'salary':
      return Icons.work_outline;
    case 'transport':
      return Icons.directions_bus_outlined;
    case 'health':
      return Icons.local_hospital_outlined;
    case 'education':
      return Icons.school_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'entertainment':
      return Icons.movie_outlined;
    case 'bills':
      return Icons.receipt_long_outlined;
    case 'gift':
      return Icons.card_giftcard_outlined;
    case 'travel':
      return Icons.flight_takeoff_outlined;
    case 'category':
    case 'other':
    default:
      return Icons.category_outlined;
  }
}

Color colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}
