# Guide de Dépannage - Problème iOS Pods

## Problème
Erreur lors de l'installation des pods CocoaPods pour iOS :
```
fatal: unable to access 'https://github.com/firebase/firebase-ios-sdk.git/': 
Recv failure: Connection reset by peer
```

## Solutions

### Solution 1 : Réessayer plus tard
Le problème est souvent temporaire (problème réseau avec GitHub). Réessayez :
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

### Solution 2 : Utiliser un VPN
Si vous êtes dans une région avec restrictions réseau, utilisez un VPN.

### Solution 3 : Cloner manuellement le dépôt Firebase
```bash
# Cloner le dépôt dans un endroit accessible
cd ~/Library/Caches/CocoaPods/Pods/Release
git clone --depth 1 --branch UtilitiesComponents-1.1.0 \
  https://github.com/firebase/firebase-ios-sdk.git \
  GoogleUtilitiesComponents-1.1.0

# Puis réessayer pod install
cd ../../../../flutter_application_1/ios
pod install
```

### Solution 4 : Tester sur d'autres plateformes
L'application fonctionne sur :
- **Web** : `flutter run -d chrome`
- **macOS** : `flutter run -d macos`
- **Android** : Si vous avez un appareil Android connecté

### Solution 5 : Configurer Git pour utiliser SSH
Si vous avez configuré SSH avec GitHub :
```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
cd ios
pod install
```

### Solution 6 : Utiliser un miroir GitHub
Si disponible dans votre région, utilisez un miroir GitHub.

## Vérification de la connexion
Testez votre connexion à GitHub :
```bash
curl -I https://github.com/firebase/firebase-ios-sdk.git
```

## Note
L'application fonctionne parfaitement sur Android et Web. Le problème iOS est uniquement lié à l'installation des dépendances, pas au code de l'application.


