# Final Publish Checklist – Ready for Google Play Store

**Last Updated:** Pre-submission review  
**Status:** ✅ Code fixes applied | ⚠️ Action items remaining

---

## ✅ CODE FIXES APPLIED

1. ✅ **Package name:** Changed to `io.askeva.ehrms` (Play Store compliant)
2. ✅ **App label:** Updated to "HRMS - Employee Attendance"
3. ✅ **App description:** Updated to "Employee Attendance & HR Management System"
4. ✅ **HTTPS base URL:** Set to `https://ehrms.askeva.io/api`
5. ✅ **Cleartext disabled:** Release builds use HTTPS only
6. ✅ **Privacy Policy link:** Added in Settings screen
7. ✅ **Permission rationale:** Added on attendance/selfie screen
8. ✅ **Debug prints:** Wrapped in `kDebugMode` in `auth_service.dart` (others can be done similarly)

## ⚠️ CRITICAL: App Icon (MUST FIX)

**Current:** Using default Flutter icon (`ic_launcher.png`)

**Issue:** Play Store will reject for "icon doesn't match content" or "generic/placeholder icon"

**Required:** Custom icon representing HRMS/Attendance app

**Quick Fix:** See `QUICK_ICON_SETUP.md` for step-by-step guide

**Icon Requirements:**
- Must represent HRMS/Attendance (clock, calendar, office, person)
- Must match app name ("HRMS" or "Employee Attendance")
- Must be professional/high-quality
- Size: 1024x1024px source, auto-generated for all densities

**Action:** Create custom icon and update using `flutter_launcher_icons` package (see `QUICK_ICON_SETUP.md`)

---

## ⚠️ REMAINING DEBUG PRINTS (Optional but Recommended)

These files still have debug prints. They won't cause rejection but should be wrapped in `kDebugMode`:

- `lib/services/attendance_service.dart` - 6 debugPrint statements
- `lib/services/salary_service.dart` - 5 print statements  
- `lib/screens/dashboard/home_dashboard_screen.dart` - 10+ debugPrint statements
- `lib/screens/salary/salary_overview_screen.dart` - 20+ debugPrint statements
- `lib/screens/assets/assets_listing_screen.dart` - 1 print statement

**Note:** `debugPrint` is automatically disabled in release builds, but wrapping in `kDebugMode` is cleaner.

---

## 🔴 CRITICAL: App Signing (MUST FIX BEFORE PUBLISHING)

**Current:** Using debug signing (`signingConfig = signingConfigs.getByName("debug")`)

**Required:** Release signing key or Play App Signing

### Option 1: Play App Signing (Recommended - Easiest)
1. Upload your app bundle to Play Console
2. Google will manage signing automatically
3. No additional setup needed

### Option 2: Manual Release Signing
1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore ~/hrms-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias hrms
   ```
2. Create `android/key.properties`:
   ```properties
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=hrms
   storeFile=<path-to-keystore>
   ```
3. Update `build.gradle.kts` to use release signing

**Action:** Choose Option 1 (Play App Signing) - it's automatic when you upload.

---

## ✅ PRE-PUBLISH CHECKLIST

### 1. Backend (Required)
- [ ] Backend API is live at `https://ehrms.askeva.io/api` (HTTPS)
- [ ] SSL certificate valid (no browser warnings)
- [ ] CORS configured for mobile app
- [ ] Environment variables set (`NODE_ENV=production`)

### 2. Privacy Policy (Required)
- [ ] Published at `https://ehrms.askeva.io/privacy`
- [ ] Publicly accessible (no login)
- [ ] Contains all required sections (see `GOOGLE_PLAY_COMPLIANCE.md`)
- [ ] URL matches `constants.dart` → `privacyPolicyUrl`

### 3. Play Console Setup (Required)
- [ ] **Privacy Policy URL** set in App content → Privacy policy
- [ ] **Data Safety form** completed:
  - Photos (selfies, profile photos)
  - Precise location
  - Name, Email, User IDs
  - Encryption in transit: Yes
  - Data deletion: Users can request
- [ ] **Permissions declared** (if prompted):
  - Camera: "Attendance selfie"
  - Location: "Check-in/out location"

### 4. App Build
- [ ] **Release build created:**
  ```bash
  flutter build appbundle --release
  ```
- [ ] **Tested on device:**
  - ✅ Connects to production API
  - ✅ Login works
  - ✅ Attendance/selfie works
  - ✅ Location permission requested
  - ✅ Camera permission requested
  - ✅ Privacy Policy link opens
  - ✅ No crashes

### 5. Store Listing
- [ ] **App name:** "HRMS" or "Employee Attendance" (matches icon theme)
- [ ] **Short description** (80 chars): "Employee attendance tracking with selfie check-in..."
- [ ] **Full description** (4000 chars max): Describe attendance, payroll, leave, etc.
- [ ] **Screenshots** (at least 2): Show attendance, dashboard, selfie check-in screens
- [ ] **App icon:** ⚠️ **CUSTOM ICON REQUIRED** (not default Flutter icon)
  - Must represent HRMS/Attendance (clock, calendar, office)
  - Must match app name and description
  - See `QUICK_ICON_SETUP.md` for setup guide
- [ ] **Feature graphic** (optional): 1024x500px banner

### 6. Content Rating
- [ ] Questionnaire completed
- [ ] Age rating selected (likely "Everyone" or "Teen")
- [ ] Category: "Business" or "Productivity"

---

## 🚨 COMMON REJECTION REASONS (Avoid)

1. ❌ **Icon doesn't match content** → ⚠️ **CRITICAL:** Use custom HRMS/Attendance icon (not default Flutter icon)
2. ❌ **Generic/placeholder icon** → Use professional custom icon representing your app
3. ❌ **Privacy Policy missing/inaccessible** → Must be public URL
4. ❌ **Data Safety incomplete** → Match exactly what app does
5. ❌ **Debug signing** → Use Play App Signing (automatic)
6. ❌ **Misleading description** → Describe actual features only
7. ❌ **App crashes** → Test release build thoroughly
8. ❌ **Placeholder content** → Remove all test data
9. ❌ **Permissions not justified** → Explain Camera & Location

---

## 📋 FINAL STEPS

1. **Build release bundle:**
   ```bash
   cd hrms
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

2. **Upload to Play Console:**
   - Go to Play Console → Your app → Release → Production
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Complete all forms (Privacy Policy, Data Safety, etc.)

3. **Submit for review**

---

## ✅ READY TO PUBLISH?

**Code:** ✅ Ready  
**Backend:** ⚠️ Verify HTTPS is live  
**Privacy Policy:** ⚠️ Must publish  
**Play Console:** ⚠️ Complete forms  
**Signing:** ⚠️ Use Play App Signing (automatic)

**Once all ⚠️ items are done → You can submit!**

---

## 📚 Reference Documents

- **Full compliance guide:** `GOOGLE_PLAY_COMPLIANCE.md`
- **Pre-publish verification:** `PRE_PUBLISH_VERIFICATION.md`
- **Package name update:** `PACKAGE_NAME_UPDATE.md`
