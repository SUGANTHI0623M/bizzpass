# Package Name Update: com.example.hrms → io.askeva.ehrms

## ✅ Changes Applied

1. **`android/app/build.gradle.kts`**
   - `namespace = "io.askeva.ehrms"`
   - `applicationId = "io.askeva.ehrms"`

2. **`android/app/src/main/kotlin/io/askeva/ehrms/MainActivity.kt`**
   - Created new package structure
   - Updated package declaration to `package io.askeva.ehrms`
   - Old file deleted

3. **`android/app/src/google-services.json`**
   - Updated `package_name` to `"io.askeva.ehrms"`

---

## ⚠️ IMPORTANT: Firebase Console Update Required

**You MUST update Firebase Console** to register the new package name:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `hrms-24dc5`
3. Go to **Project Settings** → **Your apps**
4. **Add a new Android app** (or edit existing):
   - Package name: `io.askeva.ehrms`
   - App nickname: "HRMS" (or your preferred name)
5. **Download the new `google-services.json`**
6. **Replace** `android/app/src/google-services.json` with the new file

**Why:** Firebase needs to know about your new package name for Google Sign-In and Firebase Auth to work correctly.

---

## Why Change Package Name?

- ❌ **`com.example.hrms`** is a placeholder that **Google Play Store REJECTS**
- ✅ **`io.askeva.ehrms`** follows reverse domain notation based on your domain (`ehrms.askeva.io`)
- ✅ Unique and professional package name required for Play Store

---

## Testing After Update

1. **Clean build:**
   ```bash
   cd hrms
   flutter clean
   flutter pub get
   ```

2. **Test build:**
   ```bash
   flutter build apk --debug
   # or
   flutter run
   ```

3. **Verify Firebase:**
   - Test Google Sign-In
   - Test Firebase Auth features
   - Check Firebase Console logs

---

## Note

The `google-services.json` file was manually updated, but you should download a fresh one from Firebase Console to ensure all Firebase services work correctly with the new package name.
