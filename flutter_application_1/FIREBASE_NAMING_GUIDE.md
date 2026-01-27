# Firebase Project & App Naming Guide

## Recommended Names

### 1. Firebase Project Name

**Recommended Options:**

1. **`ar-book-scanner-algeria`** ⭐ (Recommended)

   - Short, descriptive
   - Uses hyphens (Firebase-friendly)
   - Clear purpose

2. **`book-scanner-ar-dz`**

   - Includes country code (DZ = Algeria)
   - Professional

3. **`bibliotheque-ar-scanner`**

   - French name (matches app language)
   - Descriptive

4. **`ghiz-book-scanner`**
   - Uses your project folder name
   - Short and unique

**Firebase Project Name Rules:**

- ✅ Use lowercase letters
- ✅ Use hyphens (-) instead of spaces
- ✅ Keep it under 30 characters
- ✅ No special characters except hyphens
- ✅ Must be globally unique

**When creating in Firebase Console:**

- Go to: https://console.firebase.google.com/
- Click "Add project"
- Enter: `ar-book-scanner-algeria`
- Project ID will auto-generate: `ar-book-scanner-algeria` (or similar)

---

### 2. App Display Name (What users see)

**Recommended:**

**English:**

- `AR Book Scanner`
- `Book Scanner AR`
- `Library AR Scanner`

**French (Recommended - matches your app):**

- `Scanner AR Livres` ⭐
- `Scanner de Livres AR`
- `Bibliothèque AR`

**Current app title:** `Scanner de Livres AR - Algérie`

**Recommendation:** Use **`Scanner AR Livres`** (shorter, cleaner for app icon)

---

### 3. Package Name / Application ID (Android)

**Current:** `com.example.flutter_application_1`

**Recommended Options:**

1. **`com.ghiz.bookscanner`** ⭐ (Recommended)

   - Uses your project folder name
   - Professional
   - Clear purpose

2. **`com.ghiz.arscanner`**

   - Shorter
   - AR-focused

3. **`dz.ghiz.bookscanner`**

   - Includes country code
   - More specific

4. **`com.bibliotheque.arscanner`**
   - French domain style
   - Descriptive

**Package Name Rules:**

- ✅ Reverse domain notation: `com.yourcompany.appname`
- ✅ Lowercase only
- ✅ Use dots (.) as separators
- ✅ No spaces or special characters
- ✅ Must be unique (globally)

**To change in your project:**

Update `android/app/build.gradle.kts`:

```kotlin
namespace = "com.ghiz.bookscanner"
applicationId = "com.ghiz.bookscanner"
```

---

### 4. Bundle Identifier (iOS)

**Current:** Likely `com.example.flutterApplication1`

**Recommended:** `com.ghiz.bookscanner`

**To change in your project:**

Update `ios/Runner.xcodeproj/project.pbxproj`:

- Find `PRODUCT_BUNDLE_IDENTIFIER`
- Change to: `com.ghiz.bookscanner`

Or in Xcode:

1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. General tab → Bundle Identifier
4. Change to: `com.ghiz.bookscanner`

---

## Complete Setup Checklist

### Step 1: Choose Your Names

✅ **Firebase Project Name:** `ar-book-scanner-algeria`
✅ **App Display Name:** `Scanner AR Livres`
✅ **Android Package:** `com.ghiz.bookscanner`
✅ **iOS Bundle ID:** `com.ghiz.bookscanner`

### Step 2: Update Your Flutter Project

#### Update Android Package Name

**File:** `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.ghiz.bookscanner"  // Change this

    defaultConfig {
        applicationId = "com.ghiz.bookscanner"  // Change this
        // ... rest of config
    }
}
```

#### Update iOS Bundle Identifier

**File:** `ios/Runner/Info.plist`

```xml
<key>CFBundleDisplayName</key>
<string>Scanner AR Livres</string>  <!-- Change this -->

<key>CFBundleName</key>
<string>bookscanner</string>  <!-- Change this -->
```

**In Xcode:**

- Open `ios/Runner.xcworkspace`
- Select Runner → General
- Bundle Identifier: `com.ghiz.bookscanner`
- Display Name: `Scanner AR Livres`

#### Update App Title

**File:** `lib/main.dart`

```dart
MaterialApp(
  title: 'Scanner AR Livres',  // Already good, or shorten
  // ...
)
```

### Step 3: Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click **"Add project"**
3. **Project name:** `ar-book-scanner-algeria`
4. **Project ID:** (auto-generated, keep it or customize)
5. Click **Continue**
6. **Google Analytics:** Enable (recommended)
7. Click **Create project**

### Step 4: Add Android App to Firebase

1. In Firebase Console, click **"Add app"** → Android icon
2. **Android package name:** `com.ghiz.bookscanner`
3. **App nickname (optional):** `AR Book Scanner Android`
4. **Debug signing certificate SHA-1:** (optional for now)
5. Click **Register app**
6. Download `google-services.json`
7. Place in: `android/app/google-services.json`

**Add to `android/app/build.gradle.kts`:**

```kotlin
plugins {
    // ... existing plugins
    id("com.google.gms.google-services")  // Add this
}
```

**Add to `android/build.gradle.kts`:**

```kotlin
buildscript {
    dependencies {
        // ... existing dependencies
        classpath("com.google.gms:google-services:4.4.0")  // Add this
    }
}
```

### Step 5: Add iOS App to Firebase

1. In Firebase Console, click **"Add app"** → iOS icon
2. **iOS bundle ID:** `com.ghiz.bookscanner`
3. **App nickname (optional):** `AR Book Scanner iOS`
4. **App Store ID:** (leave blank for now)
5. Click **Register app**
6. Download `GoogleService-Info.plist`
7. Place in: `ios/Runner/GoogleService-Info.plist`

**Add to Xcode:**

1. Open `ios/Runner.xcworkspace`
2. Drag `GoogleService-Info.plist` into `Runner` folder
3. Make sure "Copy items if needed" is checked

### Step 6: Verify Setup

Run these commands:

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run on Android
flutter run

# Run on iOS
flutter run -d ios
```

---

## Naming Summary Table

| Item                 | Current                             | Recommended               | Location                  |
| -------------------- | ----------------------------------- | ------------------------- | ------------------------- |
| **Firebase Project** | -                                   | `ar-book-scanner-algeria` | Firebase Console          |
| **App Display Name** | `Scanner de Livres AR - Algérie`    | `Scanner AR Livres`       | `Info.plist`, `main.dart` |
| **Android Package**  | `com.example.flutter_application_1` | `com.ghiz.bookscanner`    | `build.gradle.kts`        |
| **iOS Bundle ID**    | `com.example.flutterApplication1`   | `com.ghiz.bookscanner`    | Xcode project             |
| **App Title**        | `Scanner de Livres AR - Algérie`    | `Scanner AR Livres`       | `main.dart`               |

---

## Important Notes

### ⚠️ Package Name Changes

**If you change the package name:**

1. You'll need to create a NEW Firebase app (can't change existing)
2. Old Firebase app will stop working
3. Users will need to reinstall the app
4. Consider this carefully if app is already published

**For new projects:** Change it now before Firebase setup!

### ✅ Best Practices

1. **Use consistent naming** across all platforms
2. **Keep it short** but descriptive
3. **Avoid special characters** except dots and hyphens
4. **Use reverse domain notation** for packages
5. **Make it unique** to avoid conflicts

### 🔒 Security

- Package names are permanent (hard to change later)
- Choose a domain you control or plan to use
- Don't use `com.example.*` in production

---

## Quick Reference

**Firebase Project Name:**

```
ar-book-scanner-algeria
```

**App Names:**

- Display: `Scanner AR Livres`
- Package: `com.ghiz.bookscanner`
- Bundle: `com.ghiz.bookscanner`

**Firebase Console:**

- Project ID: `ar-book-scanner-algeria` (or auto-generated)
- Android App: `com.ghiz.bookscanner`
- iOS App: `com.ghiz.bookscanner`

---

## Next Steps

1. ✅ Choose your names (use recommendations above)
2. ✅ Update package names in project files
3. ✅ Create Firebase project with chosen name
4. ✅ Add Android app with package name
5. ✅ Add iOS app with bundle ID
6. ✅ Download config files
7. ✅ Integrate Firebase (see `FIREBASE_INTEGRATION_GUIDE.md`)

---

## Questions?

**Q: Can I change the Firebase project name later?**
A: No, project names are permanent. You can change the display name, but not the project ID.

**Q: Can I change package name after publishing?**
A: Technically yes, but it creates a new app. Users would need to reinstall. Change it before first release.

**Q: What if my domain is different?**
A: Use `com.yourdomain.appname` format. If you don't have a domain, use `com.ghiz.*` or your name.

**Q: Should I use French or English names?**
A: Your app is in French, so French names make sense. But package names should be English (standard practice).

