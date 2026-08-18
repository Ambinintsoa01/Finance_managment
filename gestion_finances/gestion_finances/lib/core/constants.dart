/// Types de mouvement financier.
class TxType {
  static const String income = 'income';
  static const String expense = 'expense';
  static const String transfer = 'transfer';
}

/// Types de comptes proposés par défaut.
class AccountType {
  static const String cash = 'cash';
  static const String bank = 'bank';
  static const String mobileMoney = 'mobile_money';
  static const String savings = 'savings';
  static const String other = 'other';

  static const List<Map<String, String>> all = [
    {'value': cash, 'label': 'Espèces', 'icon': 'cash'},
    {'value': bank, 'label': 'Compte bancaire', 'icon': 'bank'},
    {'value': mobileMoney, 'label': 'Mobile Money', 'icon': 'mobile'},
    {'value': savings, 'label': 'Épargne', 'icon': 'savings'},
    {'value': other, 'label': 'Autre', 'icon': 'wallet'},
  ];

  static String labelFor(String value) => all.firstWhere(
        (e) => e['value'] == value,
        orElse: () => all.last,
      )['label']!;
}

/// Devises disponibles (MGA en premier : contexte Madagascar).
class Currencies {
  static const List<String> all = ['MGA', 'EUR', 'USD', 'GBP'];
}

/// Palette de couleurs pour comptes / catégories.
class AppColors {
  static const List<String> palette = [
    '#2E7D5B', // vert
    '#3E7CB1', // bleu
    '#D1495B', // rouge
    '#F4A259', // orange
    '#8E7DBE', // violet
    '#5C946E', // vert foncé
    '#E07A5F', // corail
    '#3D5A80', // bleu marine
    '#B08968', // marron
    '#577590', // bleu gris
  ];
}

/// Icônes disponibles pour les comptes (clé -> nom logique, voir core/icons.dart).
class AccountIcons {
  static const List<String> all = [
    'cash',
    'bank',
    'mobile',
    'savings',
    'wallet',
    'card',
  ];
}

/// Icônes disponibles pour les catégories.
class CategoryIcons {
  static const List<String> all = [
    'food',
    'salary',
    'transport',
    'health',
    'education',
    'home',
    'shopping',
    'entertainment',
    'bills',
    'gift',
    'travel',
    'other',
  ];
}

/// Catégories par défaut créées à la première ouverture de l'application.
class DefaultCategories {
  static const List<Map<String, String>> all = [
    // Revenus
    {'name': 'Salaire', 'type': TxType.income, 'icon': 'salary'},
    {'name': 'Vente', 'type': TxType.income, 'icon': 'shopping'},
    {'name': 'Cadeau reçu', 'type': TxType.income, 'icon': 'gift'},
    {'name': 'Autre revenu', 'type': TxType.income, 'icon': 'other'},
    // Dépenses
    {'name': 'Alimentation', 'type': TxType.expense, 'icon': 'food'},
    {'name': 'Transport', 'type': TxType.expense, 'icon': 'transport'},
    {'name': 'Logement', 'type': TxType.expense, 'icon': 'home'},
    {'name': 'Santé', 'type': TxType.expense, 'icon': 'health'},
    {'name': 'Éducation', 'type': TxType.expense, 'icon': 'education'},
    {'name': 'Loisirs', 'type': TxType.expense, 'icon': 'entertainment'},
    {'name': 'Factures', 'type': TxType.expense, 'icon': 'bills'},
    {'name': 'Shopping', 'type': TxType.expense, 'icon': 'shopping'},
    {'name': 'Voyage', 'type': TxType.expense, 'icon': 'travel'},
    {'name': 'Autre dépense', 'type': TxType.expense, 'icon': 'other'},
  ];
}

/// Périodes disponibles sur le dashboard.
enum DashboardPeriod { week, month, year }
