# Pre-Publish Audit – Complete App Review

**Date:** Pre-submission review  
**Status:** ⚠️ **Issues Found** – Fix before publishing

---

## 🔴 CRITICAL ISSUES (Must Fix)

### 1. Debug Print Statements in Production Code
**Risk:** Performance impact, potential security leak (logs may expose sensitive data)

**Found in:**
- `lib/services/auth_service.dart` - 8+ `print()` statements
- `lib/services/attendance_service.dart` - 6+ `debugPrint()` statements  
- `lib/services/salary_service.dart` - 5+ `print()` statements
- `lib/screens/dashboard/home_dashboard_screen.dart` - 10+ `debugPrint()` statements
- `lib/screens/salary/salary_overview_screen.dart` - 20+ `debugPrint()` statements
- `lib/screens/assets/assets_listing_screen.dart` - 1 `print()` statement

**Fix:** Wrap all debug prints in `kDebugMode` check or remove for production.

---

### 2. App Label Too Generic
**Risk:** Low user trust, unprofessional appearance

**Current:** `android:label="hrms"`  
**Should be:** More descriptive (e.g., "HRMS - Employee Attendance" or "Askeva HRMS")

**File:** `android/app/src/main/AndroidManifest.xml`

---

### 3. Release Signing Configuration Missing
**Risk:** Cannot publish to Play Store (debug signing not allowed)

**Current:** `signingConfig = signingConfigs.getByName("debug")`  
**Required:** Proper release signing key

**File:** `android/app/build.gradle.kts`

**Action:** Set up release signing key or use Play App Signing (recommended).

---

## ⚠️ MEDIUM PRIORITY (Should Fix)

### 4. App Description Too Short
**Current:** `description: "HRMS"`  
**Should be:** More descriptive (e.g., "Employee Attendance & HR Management System")

**File:** `pubspec.yaml`

---

### 5. Version Management
**Current:** `version: 1.0.1+1`  
**Status:** ✅ OK for first release

**Note:** Increment version code (+1) for each Play Store update.

---

## ✅ GOOD (No Changes Needed)

- ✅ Package name: `io.askeva.ehrms` (unique, compliant)
- ✅ HTTPS base URL configured
- ✅ Cleartext traffic disabled for release
- ✅ Permissions properly declared
- ✅ Privacy Policy link added
- ✅ Permission rationale added
- ✅ No placeholder content in UI
- ✅ No hardcoded test credentials in app code
- ✅ Firebase properly configured

---

## 📋 FIXES TO APPLY

See next section for code changes.
