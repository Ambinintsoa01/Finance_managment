# Mes Finances — Gestion financière multi-comptes (Flutter + Supabase)

Application mobile Android **offline-first** de gestion de finances personnelles :
plusieurs comptes (Espèces, Banque, Mobile Money, Épargne...), transferts entre
comptes, catégories personnalisées, tableau de bord avec graphiques
(`fl_chart`), et synchronisation cloud optionnelle via **Supabase** (gratuit)
pour le multi-appareil.

---

## ⚠️ Important — à lire avant de commencer

Ce dossier contient le **code source complet** de l'application (`lib/`,
`pubspec.yaml`, schéma SQL Supabase). Il ne contient **pas** les dossiers
`android/` et `ios/` : ceux-ci sont générés automatiquement par la commande
`flutter create` et doivent l'être **sur ta machine**, avec le SDK Flutter
installé (ce que l'environnement qui a généré ce code n'a pas).

La procédure ci-dessous t'explique comment assembler un projet Flutter
exécutable en quelques commandes.

---

## 1. Prérequis

- **Flutter SDK** installé (`flutter --version` doit fonctionner) — [guide d'installation](https://docs.flutter.dev/get-started/install)
- **Android Studio** ou VS Code avec les extensions Flutter/Dart
- Un émulateur Android configuré, ou un téléphone Android en mode développeur (débogage USB)
- Un compte gratuit sur [supabase.com](https://supabase.com) (optionnel mais recommandé pour la synchronisation)

Vérifie ton installation :
```bash
flutter doctor
```

---

## 2. Créer le projet Flutter et y copier le code

```bash
# 1. Crée un nouveau projet Flutter (génère android/, ios/, etc.)
flutter create --org com.tonentreprise gestion_finances
cd gestion_finances

# 2. Supprime le lib/ et le pubspec.yaml générés par défaut
rm -rf lib pubspec.yaml

# 3. Copie le contenu de CE dossier livré (lib/, pubspec.yaml, supabase/,
#    analysis_options.yaml, README.md) à la racine du projet fraîchement créé,
#    en écrasant les fichiers existants si besoin.
```

Structure finale attendue :
```
gestion_finances/
├── android/            <- généré par flutter create
├── ios/                <- généré par flutter create
├── lib/                <- fourni (ce livrable)
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   ├── data/
│   │   ├── local/          (Drift : tables.dart, database.dart)
│   │   ├── remote/          (supabase_service.dart)
│   │   ├── repositories/
│   │   └── sync/            (sync_service.dart)
│   ├── providers/            (Riverpod)
│   ├── screens/
│   └── widgets/
├── supabase/
│   └── schema.sql       <- à exécuter dans Supabase
├── pubspec.yaml         <- fourni (ce livrable)
└── analysis_options.yaml
```

---

## 3. Installer les dépendances

```bash
flutter pub get
```

---

## 4. Générer le code Drift (base de données locale)

L'application utilise **Drift** pour SQLite, qui génère du code à partir des
définitions de tables (`lib/data/local/tables.dart`). Cette étape est
**obligatoire** avant de pouvoir compiler :

```bash
dart run build_runner build --delete-conflicting-outputs
dart run flutter_launcher_icons
```

Cela crée le fichier `lib/data/local/database.g.dart` (ne pas éditer
manuellement — il est régénéré à chaque modification de `tables.dart`).

> Pendant le développement, tu peux laisser tourner
> `dart run build_runner watch --delete-conflicting-outputs`
> pour régénérer automatiquement à chaque sauvegarde.

---

## 5. Configurer Supabase (synchronisation cloud — optionnel)

L'application fonctionne **100% hors-ligne sans aucune configuration**.
Si tu veux activer la sauvegarde cloud et la synchronisation multi-appareil :

### 5.1. Créer le projet Supabase
1. Va sur [supabase.com](https://supabase.com) → "New Project" (gratuit)
2. Choisis un nom, un mot de passe de base de données, une région proche de toi
3. Attends la fin du provisioning (~2 min)

### 5.2. Créer les tables et la sécurité (RLS)
1. Dans le dashboard Supabase, va dans **SQL Editor** → **New query**
2. Colle l'intégralité du contenu du fichier `supabase/schema.sql` fourni
3. Exécute (**Run**)

Cela crée les tables `accounts`, `categories`, `transactions`, avec :
- Les contraintes de cohérence (types, montants positifs, transferts valides)
- Les index nécessaires à la synchronisation incrémentale
- Les **Row Level Security (RLS) policies** : chaque utilisateur ne peut lire/
  écrire que ses propres données (`auth.uid() = user_id`), indispensable
  car la clé publique de l'app est exposée côté client
- Un trigger qui met à jour automatiquement `updated_at` à chaque modification

### 5.3. Récupérer les clés API
1. Dans Supabase : **Project Settings** → **API**
2. Copie **Project URL** et la clé **anon public**

### 5.4. Configurer l'application

Ouvre `lib/core/env.dart` et remplace les valeurs par défaut :

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://xxxxxxxxxxxx.supabase.co', // <- ta valeur
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // <- ta valeur
);
```

**Alternative recommandée (plus sûre, ne commite pas les clés) :** lance
l'application avec les clés en argument, sans toucher au fichier :

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 5.5. (Recommandé) Désactiver la confirmation email pour les tests
Dans Supabase : **Authentication** → **Providers** → **Email** → décoche
*"Confirm email"* pendant le développement, pour pouvoir te connecter
immédiatement après inscription. Réactive-la en production.

---

## 6. Lancer l'application

```bash
# Sur un émulateur ou téléphone Android connecté
flutter run

# Ou en précisant explicitement l'appareil
flutter devices
flutter run -d <device_id>
```

Pour générer un APK installable :
```bash
flutter build apk --release
# APK généré dans build/app/outputs/flutter-apk/app-release.apk
```

---

## 7. Comment fonctionne l'application

### Multi-comptes
- Onglet **Comptes** : créer/modifier/supprimer des comptes (Espèces, Banque,
  Mobile Money, Épargne, Autre), chacun avec sa devise, son icône, sa couleur
- Le **solde de chaque compte** est recalculé dynamiquement à partir du solde
  initial + l'historique de ses transactions (jamais stocké en dur, donc
  toujours cohérent)
- Bouton **transfert** (icône ↔ en haut de l'écran Comptes) pour déplacer de
  l'argent entre deux comptes

### Mouvements (Entrées / Sorties / Transferts)
- Bouton **+** flottant : formulaire unique avec sélecteur Dépense / Revenu /
  Transfert, sélection du compte (et compte destination si transfert),
  catégorie, date, note
- Onglet **Mouvements** : historique complet, groupé par jour, modifiable

### Tableau de bord
- Carrousel des comptes en haut (tape sur un compte pour filtrer tout le
  dashboard dessus, ou "Tous" pour la vue consolidée)
- Solde total + entrées/sorties de la période
- Sélecteur de période (Semaine / Mois / Année) avec navigation ← →
- Graphique en barres : évolution entrées vs sorties
- Camembert : répartition des dépenses par catégorie

### Fonctionnement hors-ligne et synchronisation
- **Toutes les écritures sont locales et immédiates** (SQLite via Drift) —
  l'app est 100% utilisable sans connexion, y compris sans jamais se
  connecter à un compte
- Quand tu te connectes (onglet Réglages) et qu'une connexion internet est
  disponible, la synchronisation se déclenche automatiquement (et peut être
  relancée manuellement) :
  1. **Push** : les lignes créées/modifiées hors-ligne (marquées `dirty`)
     sont envoyées vers Supabase
  2. **Pull** : les changements distants plus récents que la dernière
     synchronisation sont récupérés et fusionnés localement
  3. **Résolution de conflit** : en cas de modification simultanée sur deux
     appareils, la version la plus récente (`updated_at`) l'emporte
     (last-write-wins)
- Connecte-toi avec le même compte sur un second téléphone pour retrouver
  toutes tes données

---

## 8. Dépendances utilisées

| Rôle | Package |
|---|---|
| State management | `flutter_riverpod` |
| Base de données locale | `drift` + `sqlite3_flutter_libs` |
| Backend cloud | `supabase_flutter` |
| Graphiques | `fl_chart` |
| Détection réseau | `connectivity_plus` |
| Identifiants uniques | `uuid` |
| Dates / montants | `intl` |
| Préférences locales | `shared_preferences` |

---

## 9. Problèmes fréquents

**`Target of URI doesn't exist: 'database.g.dart'`**
→ Tu n'as pas encore lancé `dart run build_runner build --delete-conflicting-outputs`.

**L'app ne compile pas / erreurs Gradle Android**
→ Vérifie que `android/app/build.gradle` a `minSdkVersion 21` ou plus
(requis par `sqlite3_flutter_libs` et `supabase_flutter`). `flutter create`
récent le configure déjà correctement par défaut.

**La synchronisation reste sur "Connecte-toi pour activer la synchronisation"**
→ Va dans Réglages et connecte-toi (ou inscris-toi). Sans compte Supabase
configuré (étape 5), l'app reste volontairement 100% locale.

**Erreur RLS "new row violates row-level security policy"**
→ Vérifie que tu as bien exécuté l'intégralité de `supabase/schema.sql`
(notamment la section RLS), et que l'utilisateur est bien connecté avant
la synchronisation.

---

Bon développement ! 🚀
