# iOS Setup Instructions

## ✅ Bundle Identifier Updated

The bundle identifier has been changed from `com.example.flutterApplication1` to `com.ghiz.bookscanner` in:
- ✅ `ios/Runner.xcodeproj/project.pbxproj` (all configurations)
- ✅ Test bundle identifiers updated

## 🔧 Next Steps in Xcode

Xcode should now be open. Follow these steps:

### 1. Configure Signing & Capabilities

1. In Xcode, select **"Runner"** project (blue icon) in the left sidebar
2. Select **"Runner"** target under TARGETS
3. Click the **"Signing & Capabilities"** tab
4. Check ✅ **"Automatically manage signing"**
5. Select your **Team**: `Apple Development: fetho0@hotmail.com (7Z6F9UUUJ6)`
6. Xcode will automatically:
   - Register the bundle ID `com.ghiz.bookscanner`
   - Create a provisioning profile
   - Configure code signing

### 2. Verify Bundle Identifier

Make sure the **Bundle Identifier** shows: `com.ghiz.bookscanner`

### 3. Select Your Device

1. At the top toolbar, click the device selector
2. Select **"Fetho (wireless)"** or your connected iPhone

### 4. Build & Run

Click the **Play** button (▶️) or press `Cmd + R` to build and run.

---

## 🚀 Alternative: Run from Terminal

After configuring signing in Xcode, you can also run from terminal:

```bash
cd /Users/fathallah/projects/ghiz/flutter_application_1
flutter run -d 00008020-000A25613650003A
```

---

## ⚠️ Troubleshooting

### Issue: "No profiles for 'com.ghiz.bookscanner' were found"

**Solution:**
1. Make sure you're logged into Xcode with your Apple ID
2. Go to Xcode → Settings → Accounts
3. Add your Apple ID if not already added
4. Select your team in Signing & Capabilities

### Issue: "Bundle identifier is not available"

**Solution:**
- The bundle ID `com.ghiz.bookscanner` should be available
- If not, try a more unique one like `com.ghiz.bookscanner.app` or add your name

### Issue: Device not trusted

**Solution:**
1. On your iPhone, go to: **Settings → General → VPN & Device Management**
2. Tap on your developer certificate
3. Tap **"Trust"**

### Issue: Camera permission denied

**Solution:**
- The app will request camera permission on first use
- Go to iPhone **Settings → Scanner AR Livres → Camera** and enable it

---

## ✅ Current Configuration

| Item | Value |
|------|-------|
| **Bundle Identifier** | `com.ghiz.bookscanner` |
| **Display Name** | `Scanner AR Livres` |
| **Development Team** | `Apple Development: fetho0@hotmail.com (7Z6F9UUUJ6)` |
| **Target Device** | `Fetho (wireless)` |

---

## 📱 After Successful Build

Once the app launches on your iPhone:
1. ✅ Test library selection
2. ✅ Test book search
3. ✅ Test AR scanning (grant camera permission)
4. ✅ Test correction workflow

The app should now build and run successfully! 🎉


