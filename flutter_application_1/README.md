# Scanner de Livres AR

Une application Flutter qui permet de scanner des livres par code-barres et de détecter leur ordre d'arrangement.

## Fonctionnalités

- 📱 **Scan de codes-barres** : Scanner les codes-barres des livres avec la caméra
- 📚 **Détection d'ordre** : L'ordre des livres est automatiquement déterminé par l'ordre de scan
- 🎯 **Vue AR** : Visualiser l'ordre des livres scannés avec une vue augmentée utilisant la caméra
- 📋 **Liste des livres** : Consulter tous les livres scannés avec leurs détails

## Structure de l'application

- **Liste** : Affiche tous les livres scannés avec leur ordre, code-barres et date de scan
- **Scanner** : Interface de scan avec la caméra pour scanner les codes-barres
- **AR** : Vue augmentée montrant l'ordre des livres avec la caméra en arrière-plan

## Installation

1. Installer les dépendances :
```bash
flutter pub get
```

2. Pour Android, assurez-vous que les permissions de caméra sont configurées dans `AndroidManifest.xml`

3. Pour iOS, les permissions sont configurées dans `Info.plist`

## Utilisation

1. Ouvrir l'onglet **Scanner**
2. Pointer la caméra vers le code-barres d'un livre
3. Le livre est automatiquement ajouté avec un numéro d'ordre
4. Répéter pour chaque livre dans l'ordre souhaité
5. Consulter l'onglet **Liste** pour voir tous les livres
6. Utiliser l'onglet **AR** pour visualiser l'ordre avec la caméra

## Technologies utilisées

- Flutter
- `mobile_scanner` : Pour le scan de codes-barres
- `provider` : Pour la gestion d'état (optionnel, préparé pour extension future)

## Notes

- L'ordre des livres est déterminé par l'ordre chronologique de scan
- Un livre déjà scanné ne peut pas être ajouté deux fois
- Les livres peuvent être supprimés individuellement ou tous en même temps
