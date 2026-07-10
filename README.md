# 📱 Digital List — Système de Gestion de Présence par QR Code

[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange?logo=firebase)](https://firebase.google.com)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-blue?logo=kubernetes)](https://kubernetes.io)
[![Jenkins](https://img.shields.io/badge/CI%2FCD-Jenkins-red?logo=jenkins)](https://jenkins.io)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> Application mobile Flutter de gestion de présence académique via QR Code avec architecture Cloud Native.

---

## 📋 Table des Matières

1. [Présentation](#présentation)
2. [Fonctionnalités](#fonctionnalités)
3. [Architecture](#architecture)
4. [Technologies](#technologies)
5. [Installation](#installation)
6. [Configuration Firebase](#configuration-firebase)
7. [Lancement](#lancement)
8. [Tests](#tests)
9. [Déploiement](#déploiement)
10. [DevOps](#devops)
11. [Contribution](#contribution)

---

## 🎯 Présentation

**Digital List** est une application mobile multiplateforme (Android / iOS) développée avec Flutter qui remplace les feuilles d'émargement papier par un système dématérialisé, sécurisé et traçable en temps réel.

### Problématique résolue
-  Fraude par émargement à la place d'un autre
-  Perte des feuilles de présence
-  Absence de statistiques en temps réel
-  Processus lent et manuel

### Solution apportée
-  QR Code unique par séance avec expiration (30 min)
-  Verrouillage par appareil (1 compte = 1 téléphone)
-  Détection de GPS simulé (anti-fraude)
-  Tableau de bord temps réel avec statistiques
-  Export PDF de feuilles d'émargement

---

## Fonctionnalités

### Étudiant
- Inscription et connexion sécurisée
- Scanner QR Code pour valider sa présence
- Historique des présences
- Statistiques personnelles

### Enseignant
- Création de séances de cours avec QR Code
- Suivi des présents en temps réel
- Export PDF de la feuille d'émargement
- Clôture de séance

### Administrateur
- Tableau de bord avec KPIs globaux
- Gestion des utilisateurs (blocage / déblocage)
- Approbation des demandes d'enseignants
- Supervision des séances actives

---

## Architecture

```
lib/
├── core/
│   ├── constants/          # Constantes globales
│   ├── errors/             # Hiérarchie des Failures
│   └── usecases/           # Interface UseCase abstraite
│
├── features/
│   ├── authentication/
│   │   └── domain/
│   │       ├── entities/   # UserEntity
│   │       ├── repositories/
│   │       └── usecases/   # SignIn, SignOut, ResetPassword
│   │
│   └── attendance/
│       └── domain/
│           ├── entities/   # AttendanceEntity, SessionEntity
│           ├── repositories/
│           └── usecases/   # ValidatePresence
│
├── screens/                # UI Screens (existant)
├── services/               # FirebaseService, PdfService
├── theme/                  # AppTheme Design System
└── widgets/                # PrimaryButton, CustomTextField
```

**Pattern architectural :** Layered Architecture + Service Pattern + Repository Pattern (domain layer)

**Gestion d'état :** `setState()` + `StreamBuilder` (natif Flutter)

---

## Technologies

| Catégorie | Technologie | Version |
|---|---|---|
| Framework mobile | Flutter | 3.22.x |
| Langage | Dart | 3.4.x |
| Authentification | Firebase Auth | 6.5.x |
| Base de données | Cloud Firestore | 6.4.x |
| Scanner QR | mobile_scanner | 7.2.x |
| Graphiques | fl_chart | 1.2.x |
| Animations | animate_do | 5.1.x |
| Typographie | google_fonts (Inter) | 8.1.x |
| PDF | pdf + printing | 3.12.x + 5.14.x |
| Géolocalisation | geolocator | 14.0.x |
| Device ID | device_info_plus | 13.1.x |
| CI/CD | Jenkins | Pipeline |
| Conteneurisation | Docker | 26.x |
| Orchestration | Kubernetes | 1.30 |
| Monitoring | Prometheus + Grafana | 2.50 + 10.3 |
| IaC | Ansible | 2.15+ |

---

## Installation

### Prérequis
```bash
# Flutter 3.22+
flutter --version

# Dart 3.4+
dart --version

# Java 17+ (pour Android build)
java --version
```

### Cloner le projet
```bash
git clone https://github.com/votre-org/digitallist.git
cd digitallist
flutter pub get
```

---

## Configuration Firebase

### 1. Créer un projet Firebase
1. Aller sur [console.firebase.google.com](https://console.firebase.google.com)
2. Créer un nouveau projet : `digitallist-prod`
3. Activer **Authentication** → Email/Password
4. Créer **Cloud Firestore** (mode production, region: `europe-west1`)

### 2. Ajouter l'application Android
1. Nom du package : `com.digitallist.app`
2. Télécharger `google-services.json`
3. Placer dans `android/app/`

### 3. Déployer les règles de sécurité
```bash
firebase deploy --only firestore:rules
```

### 4. Créer le compte Admin (manuel)
```
1. S'inscrire via l'application (rôle student par défaut)
2. Dans Firebase Console → Firestore → users/{uid}
3. Modifier : role = "admin"
```

---

## Lancement

```bash
# Mode développement
flutter run

# Sur un appareil spécifique
flutter devices
flutter run -d <device_id>

# Avec Firebase Emulator
docker compose up firebase-emulator
flutter run --dart-define=USE_EMULATOR=true
```

---

## Tests

```bash
# Tous les tests
flutter test

# Tests unitaires uniquement
flutter test test/unit/

# Tests widgets
flutter test test/widget/

# Avec couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Objectif de couverture : **80%**

---

## Déploiement

### Android APK
```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Ouvrir Xcode → Archive → Distribute
```

---

## DevOps

### Docker
```bash
# Build et tests
docker compose up flutter-test

# Stack monitoring
docker compose up prometheus grafana
```

### Kubernetes
```bash
# Déploiement complet
kubectl apply -f k8s/ -n digitallist

# Vérifier le déploiement
kubectl get pods -n digitallist
kubectl get hpa -n digitallist
```

### Ansible
```bash
# Installer Docker sur les serveurs
ansible-playbook -i ansible/inventory.ini ansible/install_docker.yml

# Déployer l'application
ansible-playbook -i ansible/inventory.ini ansible/deploy_app.yml \
  -e "build_number=42"
```

### Monitoring
- **Prometheus** : http://localhost:9090
- **Grafana** : http://localhost:3000 (admin / admin123)

---

## Contribution

```bash
# Créer une branche feature
git checkout -b feature/ma-fonctionnalite

# Commits conventionnels
git commit -m "feat(scanner): ajout validation GPS améliorée"

# Push et Pull Request
git push origin feature/ma-fonctionnalite
```

### Convention de commits
| Préfixe | Usage |
|---|---|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `refactor` | Refactorisation |
| `test` | Ajout de tests |
| `docs` | Documentation |
| `ci` | Pipeline CI/CD |

---

## Licence

MIT License — Copyright © 2026 Digital List

---


