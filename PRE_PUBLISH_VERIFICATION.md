# Pre-Publish Verification Checklist – Google Play Store

**Date:** Before submitting your app to Play Store  
**Status:** ✅ Code changes complete | ⚠️ Action items below

---

## ✅ Code Changes (COMPLETED)

| Item | Status | File |
|------|--------|------|
| **HTTPS base URL** | ✅ Done | `hrms/lib/config/constants.dart` → `https://ehrms.askeva.io/api` |
| **Privacy Policy URL constant** | ✅ Done | `hrms/lib/config/constants.dart` → `privacyPolicyUrl` |
| **Android cleartext disabled (release)** | ✅ Done | `android/app/src/main/AndroidManifest.xml` → `usesCleartextTraffic="false"` |
| **Debug cleartext override** | ✅ Done | `android/app/src/debug/AndroidManifest.xml` → `tools:replace` added |
| **Permission rationale (in-app)** | ✅ Done | `selfie_checkin_screen.dart` → Info box added |
| **Privacy Policy link (Settings)** | ✅ Done | `settings_screen.dart` → Link added |

---

## ⚠️ ACTION REQUIRED – Before Publishing

### 1. Backend Production Setup

- [ ] **Backend API is served over HTTPS** at `https://ehrms.askeva.io/api`
  - Verify: Open `https://ehrms.askeva.io/api` in browser (should not show SSL error)
  - If using reverse proxy (nginx/Apache), ensure SSL certificate is valid
  - Test: App should connect to production API without errors

- [ ] **Backend CORS allows your app**
  - Check `app_backend/index.js` → CORS config includes your production domain
  - Mobile apps may send no `Origin` header (already handled in your code ✅)

- [ ] **Backend environment variables set**
  - `NODE_ENV=production` (for secure cookies)
  - All API keys/secrets configured (Cloudinary, JWT secret, etc.)

---

### 2. Privacy Policy (REQUIRED)

- [ ] **Privacy Policy page is published** at `https://ehrms.askeva.io/privacy`
  - Must be publicly accessible (no login required)
  - Content must include:
    - ✅ Data collected: Account (name, email, user ID), profile photo, attendance selfies, precise location, address (if stored)
    - ✅ Purpose: Account management, attendance verification, check-in/out location
    - ✅ How: HTTPS encryption, storage (Cloudinary/DB), face detection (ML Kit on-device), face verification (server-side)
    - ✅ Third parties: Firebase, Google Sign-In, ML Kit, Cloudinary
    - ✅ Retention: How long you keep data (e.g., "as per company policy" or "1 year")
    - ✅ User rights: How to request access, correction, or deletion (email or in-app)
    - ✅ Contact: Email or form for privacy questions

- [ ] **Privacy Policy URL matches code**
  - Verify `constants.dart` → `privacyPolicyUrl = 'https://ehrms.askeva.io/privacy'`
  - Test: Open Settings → Privacy Policy → Should open your policy page

---

### 3. Google Play Console Setup

#### 3.1 Store Listing

- [ ] **App name** matches your app (e.g., "HRMS" or "Employee Attendance")
- [ ] **Short description** (80 chars): Clear, accurate description
- [ ] **Full description**: Explains attendance, selfie check-in, location tracking
- [ ] **Screenshots**: Real app screens (login, attendance, selfie, dashboard)
- [ ] **App icon**: Professional icon (not placeholder)
- [ ] **Feature graphic** (if using): Attractive banner

#### 3.2 Privacy Policy (REQUIRED)

- [ ] **App content** → **Privacy policy** → URL set to `https://ehrms.askeva.io/privacy`
  - Must match the URL in your code
  - Must be accessible without login

#### 3.3 Data Safety Form (REQUIRED)

Go to **App content** → **Data safety** and declare:

- [ ] **Data collected:**
  - ✅ **Photos** (selfies, profile photo)
    - Purpose: App functionality
    - Shared: Only with your backend/Cloudinary (not with third parties for ads)
    - Optional: No (required for attendance)
  - ✅ **Precise location**
    - Purpose: App functionality (check-in/out place)
    - Shared: Only with your backend
    - Optional: No (required if geolocation enabled)
  - ✅ **Name, Email, User IDs**
    - Purpose: Account management, app functionality
    - Shared: Only with your backend
    - Optional: No
  - ✅ **Address** (if you store reverse geocoded address)
    - Purpose: App functionality
    - Shared: Only with your backend
    - Optional: Depends on your use

- [ ] **Data security:**
  - ✅ **Encryption in transit:** Yes (HTTPS)

- [ ] **Data deletion:**
  - ✅ **Users can request deletion:** Yes
  - Describe how: "Users can request deletion by emailing [your-email] or through the app support form"

- [ ] **Do NOT declare:**
  - ❌ "Face recognition" as a sensitive category (unless you explicitly offer that)
  - ✅ Instead: Describe face detection/verification under "App functionality" in Photos section

#### 3.4 Sensitive Permissions (if prompted)

If Play Console shows **"Permissions and APIs that access sensitive information":**

- [ ] **Camera**
  - Justification: "Camera is used for taking attendance selfies. Users tap to capture their photo for check-in/check-out verification."
  
- [ ] **Location**
  - Justification: "Location is used to record and verify check-in and check-out place for attendance. Used only when the user is actively using the attendance screen (foreground)."

---

### 4. App Build & Testing

- [ ] **Release build created**
  ```bash
  flutter build appbundle --release
  # or
  flutter build apk --release
  ```

- [ ] **Test release build on device**
  - ✅ App connects to production API (`https://ehrms.askeva.io/api`)
  - ✅ Login works
  - ✅ Attendance/selfie flow works
  - ✅ Location permission requested correctly
  - ✅ Camera permission requested correctly
  - ✅ Privacy Policy link opens in browser
  - ✅ No crashes or errors

- [ ] **Verify HTTPS only in release**
  - ✅ Release build cannot connect to HTTP URLs (expected)
  - ✅ Debug build can still use HTTP for local dev (expected)

- [ ] **App signing**
  - ✅ Release build signed with your Play Store signing key
  - ✅ Or: Use Play App Signing (recommended)

---

### 5. Content Rating & Compliance

- [ ] **Content rating questionnaire** completed
  - Select appropriate age rating (likely "Everyone" or "Teen" for HRMS)

- [ ] **Target audience** set
  - Age group: Appropriate for your users
  - Content: No inappropriate content

- [ ] **App category** selected
  - Likely: "Business" or "Productivity"

---

### 6. Final Checks

- [ ] **No placeholder content**
  - ✅ All screens show real functionality
  - ✅ No "Lorem ipsum" or test data visible to users

- [ ] **App description accuracy**
  - ✅ Description matches actual features
  - ✅ Mentions camera, location, selfie if applicable

- [ ] **Support contact**
  - ✅ Support email or website provided in Play Console

- [ ] **Version code & name**
  - ✅ Version code increments with each release
  - ✅ Version name follows semantic versioning (e.g., 1.0.1)

---

## 🚨 Common Rejection Reasons (Avoid These)

1. **Privacy Policy missing or inaccessible** → Ensure URL is public and works
2. **Data Safety form incomplete or inaccurate** → Match exactly what your app does
3. **Misleading description** → Describe actual features only
4. **Placeholder content** → Remove all test/placeholder data
5. **Permissions not justified** → Explain Camera & Location clearly
6. **HTTPS not used** → Ensure production API is HTTPS
7. **App crashes** → Test release build thoroughly

---

## ✅ Ready to Submit Checklist

Before clicking "Submit for review":

- [ ] All items in Section 2 (Backend) completed
- [ ] All items in Section 3 (Play Console) completed
- [ ] Release build tested and working
- [ ] Privacy Policy URL accessible
- [ ] Data Safety form matches app behavior
- [ ] No placeholder content
- [ ] App description accurate

---

## 📝 Quick Reference

- **Privacy Policy URL:** `https://ehrms.askeva.io/privacy` (must be published)
- **Production API:** `https://ehrms.askeva.io/api` (must be HTTPS)
- **Code Privacy URL:** `hrms/lib/config/constants.dart` → `privacyPolicyUrl`
- **Compliance Guide:** See `GOOGLE_PLAY_COMPLIANCE.md` in repo root

---

## 🎯 Summary

**Code changes:** ✅ Complete  
**Backend:** ⚠️ Verify HTTPS is live  
**Privacy Policy:** ⚠️ Must publish before submitting  
**Play Console:** ⚠️ Complete Privacy Policy URL + Data Safety form  

**Once all ⚠️ items are done, you're ready to submit!**
