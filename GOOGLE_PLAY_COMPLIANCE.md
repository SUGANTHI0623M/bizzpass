# Google Play Store – End-to-End Compliance Guide

This document analyzes your **Attendance / HRMS** app (Flutter + Node backend) and lists **required changes** for Google Play policies: Privacy Policy, Data Safety, permissions, SDK usage, security, and compliance. Each change includes **before vs after** and a **final checklist** for fast approval.

---

## 1. Executive Summary

| Area | Status | Action |
|------|--------|--------|
| **Privacy Policy** | ❌ Missing | Publish a policy URL and add it in Play Console + in-app |
| **Data Safety form** | ⚠️ Must declare | Complete in Play Console to match actual data |
| **Permissions** | ✅ OK | Camera, Location declared; add rationale in-app |
| **Face / selfie** | ✅ Allowed | Disclose in policy & Data Safety; no extra permissions |
| **Third-party SDKs** | ⚠️ Must declare | Declare Firebase, Google Sign-In, ML Kit, etc. |
| **Security** | ⚠️ Fix for prod | Use HTTPS only; disable cleartext in release build |
| **Sensitive APIs** | ✅ Declare | Justify Camera & Location in Play Console if asked |

---

## 2. Required Changes (What & Why)

### 2.1 Privacy Policy (Required by Google Play)

**Why:** [Play policy](https://support.google.com/googleplay/android-developer/answer/9859455) requires a publicly accessible Privacy Policy URL before publishing.

**Before:** No privacy policy URL; no in-app link.

**After:**

1. **Host a Privacy Policy page** (e.g. `https://yourdomain.com/privacy` or GitHub Pages / Notion).
2. **Set the URL** in Play Console: **App content** → **Privacy policy**.
3. **Add an in-app link** (e.g. in Settings or drawer): “Privacy Policy” that opens the same URL (improves trust and helps review).

**What the policy must include (simple wording):**

- **Data collected:** Account (name, email, user ID), profile photo, attendance selfies, precise location at check-in/check-out, and (if used) address from reverse geocoding.
- **Why:** Account management, attendance verification, check-in/check-out location verification.
- **How:** Data sent over HTTPS; selfies/location stored on your servers (e.g. Cloudinary, DB); face verification (on-device with ML Kit + server-side comparison with profile photo).
- **Third parties:** Firebase (auth), Google Sign-In, ML Kit (on-device face detection), Cloudinary (image storage), and any analytics if you add them.
- **Retention:** How long you keep selfies/attendance data (e.g. as per company policy / 1 year).
- **User rights:** How users can request access, correction, or deletion (e.g. email or in-app request).
- **Contact:** Email or form for privacy questions.

---

### 2.2 Data Safety Form (Play Console)

**Why:** Google requires accurate declaration of data collection and handling in **App content** → **Data safety**.

**Before:** Form not filled or incomplete.

**After:** Declare the following so it **matches the app exactly**:

| Data type | Collected? | Purpose | Shared? | Optional? |
|-----------|------------|---------|---------|-----------|
| **Photos** (selfies, profile photo) | Yes | App functionality (attendance, verification) | Only with your backend / Cloudinary | No (required for attendance if enabled) |
| **Precise location** | Yes | App functionality (check-in/check-out place) | Only with your backend | No (required if geolocation required) |
| **Name, Email, User IDs** | Yes | Account management, app functionality | With your backend | No |
| **Address** (from reverse geocoding) | Yes, if stored | App functionality | With your backend | Depends on your use |

- **Encryption in transit:** Yes (HTTPS).
- **Data deletion:** “Users can request deletion” and describe how (e.g. contact email or in-app).

**Important:** Do **not** declare “Face recognition” as a separate feature unless you explicitly market it as such. You use **face detection** (is there one face?) and **face verification** (selfie vs profile photo); describe these under “App functionality” and in the privacy policy, not as “Face recognition” in the sensitive category unless required by local law.

---

### 2.3 Permissions (Android)

**Current state (AndroidManifest.xml):**

- `INTERNET`
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`
- `CAMERA`
- `uses-feature` camera (required=false)

**Why:** Play requires that sensitive permissions are justified and that users understand why they are used.

**Before:** No in-app explanation before requesting Camera or Location.

**After:**

1. **Keep permissions as-is** – no new broad permissions (e.g. do **not** add `READ_MEDIA_IMAGES` if you only capture selfies with the camera).
2. **Add a short in-app explanation** on the selfie/attendance screen (e.g. “Camera is used for your attendance selfie; location is used to record check-in/check-out place.”). This satisfies “clear permission strings and in-app explanation” and is implemented in the app.
3. **In Play Console**, if the “Permissions and APIs that access sensitive information” form appears, declare **Camera** and **Location** and state: “Camera for attendance selfie; location for check-in/check-out location.”

**Before (no rationale):** User sees system permission dialog without context.

**After (with rationale):** User sees your sentence on the screen and then the system dialog when you request permission.

---

### 2.4 Face Detection / Selfie / Attendance – Play Rules

**Why:** Google allows camera and face-related features when they are disclosed and used for a clear purpose.

**Your flow:**

1. **On-device:** ML Kit Face Detection – checks “one face” in the selfie (no biometric ID).
2. **Server:** Selfie is sent to backend; compared with profile photo (DeepFace) for verification.
3. **Storage:** Selfie may be stored (e.g. Cloudinary) for attendance records.

**Compliance:**

- **Disclosure:** Describe in Privacy Policy and Data Safety: “We use the camera for attendance selfies. We use on-device face detection to ensure one face is present, and we verify your selfie against your profile photo for attendance. Selfies and location are stored for attendance records.”
- **User-initiated:** Selfie is taken only when the user taps “take selfie” – no background or hidden camera. ✅
- **No Face ID / device biometrics:** You are not using device biometrics for login; you are using face detection + server-side comparison. ✅
- **Permissions:** Only CAMERA (and location) – no extra “biometric” permission needed for this use. ✅

**Before:** No written disclosure of face/selfie usage.

**After:** Privacy Policy + Data Safety clearly describe face detection, verification, and selfie storage.

---

### 2.5 Third-Party Services – Declaration

**Why:** Play expects that any SDK or service that collects or processes user data is declared and, if needed, reflected in your Privacy Policy and Data Safety.

**Your usage:**

| Service | Where | What to declare |
|---------|--------|------------------|
| **Firebase (Core, Auth)** | Flutter app | Auth, possibly device identifiers; declare in Data Safety if you collect identifiers; add to Privacy Policy. |
| **Google Sign-In** | Flutter app | Account info (email, name, ID); declare “Name, Email, User IDs” and mention Google Sign-In in policy. |
| **Google ML Kit Face Detection** | Flutter app | On-device only; no data sent to Google for face detection. Mention in Privacy Policy: “We use Google ML Kit for on-device face detection (one face check); no face data is sent to Google for this.” |
| **Cloudinary** | Backend | Storage of profile photos and attendance selfies; declare as “Photos” collected and “shared with service providers” (your backend → Cloudinary). |
| **DeepFace (backend)** | Backend | Server-side face verification; no data sent to third parties; mention in policy as “our servers compare your selfie with your profile photo.” |

**Before:** No central list; policy/SDK declarations incomplete.

**After:** Privacy Policy lists these; Data Safety reflects collection/sharing; in “SDK” or “Data safety” sections you accurately describe what each does.

---

### 2.6 Security – HTTPS & Cleartext

**Why:** Play and users expect all network data to be encrypted in transit. Using HTTP or allowing cleartext in production can cause rejections or security flags.

**Before:**

- **Flutter `constants.dart`:** `baseUrl = 'http://192.168.16.102:8001/api'` (HTTP, local).
- **Android:** `android:usesCleartextTraffic="true"` in main manifest (allows HTTP everywhere).

**After:**

1. **Flutter:** Production `baseUrl` must be **HTTPS** (e.g. `https://ehrms.askeva.io/api`). Use a build flavor or compile-time constant so dev can still use HTTP on local IP.
2. **Android:** Set `usesCleartextTraffic="false"` in the **main** (release) manifest. Allow cleartext only in **debug** manifest for local testing.

**Code/config changes applied in repo:**

- `constants.dart`: Production URL set to HTTPS; comment for local/dev.
- `AndroidManifest.xml`: `usesCleartextTraffic="false"` in main; debug manifest keeps `true` for development.

---

### 2.7 Backend (CORS, HTTPS, Cookies)

**Why:** Backend must accept requests from the app and, in production, run over HTTPS with secure cookies.

**Before:** CORS allows `https://ehrms.askeva.io` and localhost; mobile apps often send no `Origin` (already allowed). Cookie `secure: process.env.NODE_ENV === 'production'` is correct.

**After:**

- **CORS:** Keep allowing requests with no `origin` (mobile). For production, ensure only your app’s backend domain and any web admin URL are allowed.
- **HTTPS:** Serve backend over HTTPS in production (e.g. reverse proxy with SSL). Do not rely on HTTP for production API.
- **No code change required** if you already use HTTPS and `NODE_ENV=production` for cookies.

---

## 3. Before vs After – Summary Table

| Item | Before | After |
|------|--------|--------|
| **Privacy Policy** | No URL | URL in Play Console + in-app link |
| **Data Safety** | Empty/incomplete | Form filled: Photos, Location, Name/Email/IDs, encryption, deletion |
| **Permission rationale** | None | Short sentence on attendance/selfie screen |
| **Face/selfie disclosure** | Not written | In Privacy Policy + Data Safety |
| **Third-party list** | Not documented | Policy + Data Safety list Firebase, Google Sign-In, ML Kit, Cloudinary |
| **API base URL (prod)** | HTTP | HTTPS only for release |
| **Android cleartext** | `true` in main | `false` in main; `true` only in debug |
| **In-app Privacy link** | None | Settings or drawer link to policy URL |

---

## 4. Code & Config Changes Applied

### 4.1 Flutter – Production base URL (`lib/config/constants.dart`)

**Before:**

```dart
static const String baseUrl = 'http://192.168.16.102:8001/api';
```

**After:**

```dart
// Production (use this for Play Store build)
static const String baseUrl = 'https://ehrms.askeva.io/api';
// For local dev, temporarily switch to your machine IP, e.g.:
// static const String baseUrl = 'http://192.168.16.102:8001/api';
```

Use a build flavor or environment variable if you want to switch URLs per build without editing code.

### 4.2 Android – Cleartext traffic (`android/app/src/main/AndroidManifest.xml`)

**Before:**

```xml
<application
    ...
    android:usesCleartextTraffic="true"
```

**After:**

```xml
<application
    ...
    android:usesCleartextTraffic="false"
```

**Debug manifest** (`android/app/src/debug/AndroidManifest.xml`): Can override with `usesCleartextTraffic="true"` for local HTTP testing (already possible via debug manifest merge).

### 4.3 Android – Permission rationale (selfie screen)

**Before:** Screen had no text explaining why camera/location are used.

**After:** A short explanatory line/card on the selfie/attendance screen, e.g.: “Camera is used for your attendance selfie; location is used to record your check-in and check-out place.” This meets Play’s expectation for in-app explanation.

### 4.4 In-app Privacy Policy link

**After:** A “Privacy Policy” entry in Settings (or drawer) that opens your policy URL in the browser (e.g. `url_launcher`). You only need to set the URL constant to your real policy page.

---

## 5. Final Checklist – Fast Approval, Zero Policy Issues

Use this list before submitting to Play.

### 5.1 Before you build

- [ ] **Backend:** Production API is served over **HTTPS** (e.g. `https://ehrms.askeva.io`).
- [ ] **Flutter:** `constants.dart` (or your config) uses **HTTPS** base URL for release.
- [ ] **Android:** Main manifest has `usesCleartextTraffic="false"`; debug can keep `true` for local dev only.

### 5.2 Privacy & data

- [ ] **Privacy Policy** is published at a public URL (e.g. `https://yourdomain.com/privacy`).
- [ ] Policy clearly describes: account data, profile photo, selfies, location, address (if stored), face detection/verification, retention, user rights, contact.
- [ ] **Play Console** → App content → **Privacy policy** → URL set.
- [ ] **Data Safety** form completed: Photos, Precise location, Name/Email/IDs (and Address if stored); encryption in transit Yes; deletion option described.
- [ ] **In-app:** “Privacy Policy” link added (Settings or drawer) opening the same URL.

### 5.3 Permissions & sensitive APIs

- [ ] **Camera** and **Location** are the only sensitive permissions; no unnecessary ones (e.g. no READ_MEDIA_IMAGES if you only use camera).
- [ ] In-app explanation present on the screen where you request camera/location (attendance/selfie).
- [ ] If Play shows “Permissions and APIs that access sensitive information,” declare Camera and Location with justification: attendance selfie and check-in/check-out location.

### 5.4 Face / selfie / attendance

- [ ] Privacy Policy states: selfie for attendance, on-device face detection (ML Kit), server-side verification with profile photo, and where selfies are stored.
- [ ] Data Safety: “Photos” collected for app functionality; no misleading “Face recognition” claim unless you explicitly offer that.
- [ ] Selfie is **user-initiated** only (tap to take); no background or hidden camera.

### 5.5 Third-party

- [ ] Privacy Policy lists: Firebase, Google Sign-In, ML Kit (on-device), Cloudinary (and backend face verification).
- [ ] Data Safety reflects any data shared with these (e.g. photos with backend/Cloudinary; account data with Firebase/Google).

### 5.6 Backend & app behavior

- [ ] All API calls use **HTTPS** in production.
- [ ] Location is used **only in foreground** when the user is in the attendance/check-in flow (no background location unless justified and declared).
- [ ] No deceptive behavior; app description and screenshots match functionality.

### 5.7 Store listing

- [ ] App name and short description match the app (attendance/HRMS).
- [ ] Screenshots show real app flow (login, attendance, selfie, etc.).
- [ ] No placeholder or fake content.

---

## 6. One-Page “Copy-Paste” Summary for Play Console

When filling forms, you can use this wording (adjust to your exact setup):

- **Privacy policy:** “[Your full URL]”
- **Data collected:** Account information (name, email, user ID), profile photo, attendance selfies, precise location at check-in/check-out, and address from location when stored.
- **Purpose:** Account management, attendance verification, recording check-in/check-out location.
- **Encryption:** Data encrypted in transit (HTTPS).
- **Deletion:** Users can request deletion by [email / in-app request].
- **Camera use:** For taking attendance selfies only; user taps to capture; we verify selfie against profile photo for attendance.
- **Location use:** To record and verify check-in and check-out location; used only when the user is using the attendance screen (foreground).

---

## 7. Quick Reference – Your Stack vs Play

| Component | Your use | Play rule | Action |
|-----------|-----------|-----------|--------|
| Camera | Selfie for attendance | Disclose + justify | Policy + Data Safety + in-app rationale ✅ |
| Location | Check-in/out | Foreground, disclose | Policy + Data Safety + rationale ✅ |
| ML Kit | On-device face detection | No special declaration beyond “camera” | Mention in policy (on-device only) |
| Firebase / Google Sign-In | Auth | Declare in Data Safety if collecting IDs | List in policy + form |
| Cloudinary | Store selfies/photos | “Photos” shared with provider | Declare in Data Safety + policy |
| DeepFace (backend) | Face verification | Your server only | Describe in policy; no extra Play declaration |
| HTTPS | Production API | Required | Use HTTPS URL; no cleartext in release ✅ |

Following this guide and the checklist above will put your app in line with Google Play policies and reduce the risk of rejections. If you add new data or SDKs later, update the Privacy Policy and Data Safety form to match.
