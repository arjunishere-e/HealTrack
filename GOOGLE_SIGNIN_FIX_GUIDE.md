# Google Sign-In Fix Guide for HealTrack

## 🔴 Problem Identified

Your `google-services.json` file has an **empty OAuth client array** (`"oauth_client": []`), which means Google Sign-In is not properly configured in Firebase Console.

## ✅ Your SHA Fingerprints (Already Generated)

**Debug Keystore:**

- **SHA-1:** `4D:F2:3C:3C:5D:BC:7C:7E:DA:CC:70:3C:51:0C:19:7C:04:B6:95:32`
- **SHA-256:** `34:7B:DC:85:DA:5C:CE:08:F0:E2:C8:1E:A0:8E:9C:15:B5:89:C2:2B:D8:0B:D2:A6:BB:90:5C:F6:F2:5F:C6:8A`

---

## 📋 Step-by-Step Fix

### **Step 1: Add SHA Fingerprints to Firebase**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **healtrack-2a168**
3. Click on **⚙️ Project Settings** (gear icon at top left)
4. Scroll down to **"Your apps"** section
5. Find your Android app: **com.example.nova**
6. Click **"Add fingerprint"**
7. Paste the **SHA-1** fingerprint:
   ```
   4D:F2:3C:3C:5D:BC:7C:7E:DA:CC:70:3C:51:0C:19:7C:04:B6:95:32
   ```
8. Click **"Add fingerprint"** again
9. Paste the **SHA-256** fingerprint:
   ```
   34:7B:DC:85:DA:5C:CE:08:F0:E2:C8:1E:A0:8E:9C:15:B5:89:C2:2B:D8:0B:D2:A6:BB:90:5C:F6:F2:5F:C6:8A
   ```

### **Step 2: Enable Google Sign-In Authentication**

1. In Firebase Console, click **Authentication** in the left sidebar
2. Click on the **Sign-in method** tab
3. Find **Google** in the provider list
4. Click on **Google**
5. Toggle **Enable** to ON
6. Enter your support email (your Gmail address)
7. Click **Save**

### **Step 3: Download New google-services.json**

1. Go back to **⚙️ Project Settings**
2. Scroll down to your Android app
3. Click **"google-services.json"** download button
4. **Replace** the existing file at:

   ```
   HealTrack/android/app/google-services.json
   ```

   ⚠️ **IMPORTANT:** The new file will have populated `oauth_client` array with Web Client ID

### **Step 4: Rebuild the App**

Run these commands in PowerShell:

```powershell
cd "c:\Users\ARJUN\OneDrive\Desktop\miniproject\HealTrack"

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build APK for testing on real phone
flutter build apk --release

# OR run on emulator
flutter run
```

### **Step 5: Test Google Sign-In**

1. **On Emulator:**

   - Make sure emulator has Google Play Services
   - Sign in with your Google account in the emulator first (Settings > Accounts)
   - Then test the app

2. **On Real Phone:**
   - Install the new APK: `build/app/outputs/flutter-apk/app-release.apk`
   - Tap "Login with Google"
   - Select your Google account
   - Should successfully log in and navigate to home screen

---

## 🔍 What Was Wrong?

### Before:

```json
{
  "oauth_client": [] // ❌ Empty!
}
```

### After (Expected):

```json
{
  "oauth_client": [
    {
      "client_id": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
      "client_type": 3
    }
  ]
}
```

---

## 🛠️ Additional Issues Fixed

### Auth State Persistence

The auth state persistence should work automatically after fixing Google Sign-In because:

1. **Splash Screen** (`lib/features/splash/splash_screen.dart`) correctly checks:

   ```dart
   final user = FirebaseAuth.instance.currentUser;
   if (user != null) {
     Navigator.pushReplacementNamed(context, AppRoutes.home);
   } else {
     Navigator.pushReplacementNamed(context, AppRoutes.login);
   }
   ```

2. **Auth Service** (`lib/data/services/auth_service.dart`) stores user data in Firestore:

   ```dart
   await _firestore.collection('users').doc(userCredential.user?.uid).set({
     'lastLogin': DateTime.now(),
     'uid': userCredential.user?.uid,
     'provider': 'google',
   }, SetOptions(merge: true));
   ```

3. **Firebase Auth** automatically persists authentication tokens locally

---

## 🚨 Troubleshooting

### Issue: "Google sign in was cancelled"

- User tapped outside the Google Sign-In dialog
- Try again

### Issue: "Network request failed"

- Check internet connection
- Verify Firebase project is not in billing/quota issues

### Issue: "com.google.android.gms.common.api.ApiException: 10"

- SHA-1/SHA-256 not added to Firebase Console
- Wrong google-services.json file
- Google Play Services not installed on emulator

### Issue: Still redirecting to login after app restart

- Make sure you downloaded the **new** google-services.json after adding SHA fingerprints
- Rebuild app completely with `flutter clean`
- Check Firebase Console > Authentication > Users to see if user is actually being created

---

## ✅ Checklist

- [ ] Added SHA-1 fingerprint to Firebase Console
- [ ] Added SHA-256 fingerprint to Firebase Console
- [ ] Enabled Google Sign-In in Authentication settings
- [ ] Added support email in Google Sign-In settings
- [ ] Downloaded new google-services.json
- [ ] Replaced old google-services.json with new one
- [ ] Verified `oauth_client` array is NOT empty in new file
- [ ] Ran `flutter clean`
- [ ] Ran `flutter pub get`
- [ ] Built new APK or ran on emulator
- [ ] Tested Google Sign-In functionality
- [ ] Tested auth persistence (close and reopen app)

---

## 📚 Reference

- [Firebase Console](https://console.firebase.google.com/)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Auth for Flutter](https://firebase.google.com/docs/auth/flutter/start)

---

## 📧 Support

If you encounter any issues after following these steps:

1. Check Firebase Console > Authentication > Users to see if sign-ins are recorded
2. Check logcat for specific error messages: `flutter logs` or `adb logcat`
3. Verify the package name in google-services.json matches: `com.example.nova`
