# Final "Silly" Rejection Checklist – Quick Reference

**Use this checklist before submitting to Play Store**

---

## ✅ CODE FIXES APPLIED

- ✅ Login explanation text added
- ✅ All other code checks passed

---

## ⚠️ PLAY CONSOLE SETUP (Must Complete)

### Before Uploading:

- [ ] **Category:** Select "Business" or "Productivity" (NOT Social/Communication/Dating)
- [ ] **App Name:** Use "HRMS" or "Employee Attendance" (matches icon theme)
- [ ] **Short Description:** "Employee attendance tracking with selfie check-in and location verification"
- [ ] **Full Description:** Describe actual features (attendance, payroll, leave, loans, expenses)
- [ ] **Screenshots:** Capture from **release build** showing:
  - Login screen
  - Dashboard
  - Attendance/selfie check-in
  - Salary overview
  - Leave requests
- [ ] **Privacy Policy URL:** Set to `https://ehrms.askeva.io/privacy`
- [ ] **Test Privacy Policy URL:** Open in incognito browser (must be accessible, no 404)

### Developer Account:

- [ ] **Contact Email:** Fill in Play Console
- [ ] **Address:** Fill in Play Console
- [ ] **Developer Profile:** Complete all required fields

---

## ⚠️ CONTENT VERIFICATION

- [ ] **Privacy Policy Content:** Verify it mentions:
  - ✅ Camera (selfie)
  - ✅ Location (attendance)
  - ✅ Face detection/verification
  - ✅ Data storage (Cloudinary)
  - ✅ Third parties (Firebase, Google Sign-In, ML Kit)
  - ❌ Does NOT mention phone/contacts/SMS (if app doesn't use them)

- [ ] **Store Description:** 
  - ✅ Simple, honest wording
  - ✅ No "AI-powered", "100% secure", "Government approved"
  - ✅ Describes actual features only
  - ✅ Clean English, no grammar errors

- [ ] **App Icon:** 
  - ⚠️ **CRITICAL:** Must be custom icon (not default Flutter icon)
  - ✅ Represents HRMS/Attendance (clock, calendar, office)
  - ✅ Matches app name theme

---

## ✅ CODE CHECKS (Already Done)

- ✅ Content matches title/description
- ✅ No dummy/test data
- ✅ Empty states handled properly
- ✅ Field validation correct
- ✅ Permissions match features
- ✅ No grammar errors
- ✅ Error handling prevents crashes
- ✅ Version management correct
- ✅ No over-promising claims
- ✅ Login explanation added

---

## 🎯 FINAL STEPS

1. **Create custom icon** (see `QUICK_ICON_SETUP.md`)
2. **Build release:**
   ```bash
   flutter build appbundle --release
   ```
3. **Capture screenshots** from release build
4. **Test Privacy Policy URL** in incognito
5. **Complete Play Console forms:**
   - Category: Business/Productivity
   - Privacy Policy URL
   - Data Safety form
   - Screenshots
   - Description
6. **Upload app bundle**
7. **Submit for review**

---

## ✅ READY TO SUBMIT?

**Code:** ✅ Ready  
**Icon:** ⚠️ Create custom icon  
**Play Console:** ⚠️ Complete forms  
**Privacy Policy:** ⚠️ Verify content & URL  

**Once icon is created and Play Console forms are complete → Submit!**
