# Face Detection – What’s Used & Deployment Guide

This document describes **what is used for face detection** in the HRMS app and **what you must do on the server** when you deploy from Git (without pushing `.env`).

---

## 1. What Is Used for Face Detection

### 1.1 Flutter app (mobile)

| Component | Purpose |
|----------|--------|
| **`google_mlkit_face_detection`** | On-device face detection: checks that the selfie has **exactly one face** before upload. |
| **`image_picker`** | Captures selfie from **front camera** (profile photo and attendance). |
| **Face detection helper** | `hrms/lib/utils/face_detection_helper.dart` – calls ML Kit and returns valid/invalid + message. |

- **No backend call** for “one face” check; it runs on the device.
- **No env vars** in the app for face detection; only the API base URL (e.g. in `constants.dart` or build config).

### 1.2 Backend (Node.js + Python)

| Component | Purpose |
|----------|--------|
| **Node.js** | Receives selfie (base64), fetches profile photo, writes temp files, calls Python script, returns match/no match. |
| **Python 3** | Runs the face verification script. |
| **`face_verify/face_verify.py`** | Compares selfie image with profile photo using DeepFace. |
| **DeepFace** | Python library (with OpenFace/Facenet) – compares two face images and returns match/no match. |
| **Model weights** | Stored under `face_verify/.deepface/weights/`. OpenFace weights (~15 MB) can be **downloaded at first run** from GitHub, or pre-downloaded (see below). |

- **No env vars** are required specifically for face verification; the backend only needs the same `.env` as the rest of the app (DB, JWT, Cloudinary, etc.).

---

## 2. What Is NOT in Git (You Create on the Server)

When you push to Git and deploy, the following are **not** in the repo and must be created or configured on the server:

| Item | Where / How |
|------|-------------|
| **`.env`** | Create manually on the server with production values (see Section 5). |
| **`app_backend/face_verify/venv/`** | Python virtual environment – create on the server and install dependencies (see Section 4). |
| **`app_backend/face_verify/.deepface/`** | Created by DeepFace at runtime; contains downloaded model weights. Optional: pre-download to avoid first-run download (see Section 4.4). |

`.gitignore` already excludes:

- `app_backend/.env` and `*.env`
- `app_backend/face_verify/venv/`
- `app_backend/face_verify/.deepface/`

So you **do not** push env file or Python venv; you **do** push `face_verify.py` and `requirements.txt`.

---

## 3. Server Requirements

- **Node.js** (e.g. v18 or v20 LTS) – for the backend API.
- **Python 3.8+** (3.10 or 3.12 recommended) – for face verification.
- **Outbound HTTPS** – so the backend can:
  - Fetch profile photos (e.g. Cloudinary URLs).
  - Download OpenFace weights from GitHub on first run (if not pre-downloaded).
- **Enough RAM** – recommend at least 1–2 GB for Node + Python; TensorFlow/DeepFace can use ~500 MB–1 GB when running.

---

## 4. What to Do on the Deployment Server

### 4.1 Clone and install Node backend

```bash
git clone <your-repo-url> hrms
cd hrms/app_backend
npm install
```

### 4.2 Create `.env`

Create `app_backend/.env` with your **production** values (see Section 5 for variable names). Do not commit this file.

### 4.3 Create Python venv and install DeepFace

**Where to add venv**

| What | Where |
|------|--------|
| Create the venv **inside** | `app_backend/face_verify/venv` |
| Full path (example) | `hrms/app_backend/face_verify/venv/` |

So the venv folder lives **inside** `face_verify` (same folder as `face_verify.py` and `requirements.txt`). The backend expects this path and will use `venv/Scripts/python.exe` (Windows) or `venv/bin/python` (Linux/macOS).

**What to add (ignore in Git)**

In `.gitignore` (already present in this repo):

```
app_backend/face_verify/venv/
```

Do **not** commit the `venv` folder; create it on each machine or server where you run the backend.

**Commands to create venv and install**

From the **project root** (or from `app_backend`):

```bash
cd app_backend/face_verify
python3 -m venv venv
# Linux/macOS:
source venv/bin/activate
# Windows:
# venv\Scripts\activate

pip install --upgrade pip
pip install -r requirements.txt
```

- **First run** of `pip install -r requirements.txt` may take several minutes (TensorFlow and dependencies).
- The backend runs the script using the venv’s Python (see `authController.js`: it uses `face_verify/venv/Scripts/python.exe` on Windows; on Linux/macOS you’d use `face_verify/venv/bin/python` – ensure your backend is configured for the OS you deploy to).

**Backend compatibility:**  
The backend auto-detects the venv Python path:

- **Windows:** `face_verify/venv/Scripts/python.exe`
- **Linux / macOS:** `face_verify/venv/bin/python`

No code change is needed when deploying to Linux; ensure the venv is created in `app_backend/face_verify/venv` as above.

### 4.4 (Optional) Pre-download OpenFace weights

To avoid downloading weights on the first user request (and to avoid dependency on GitHub at runtime):

1. Create the directory:  
   `app_backend/face_verify/.deepface/weights/`
2. Download the file (one-time):  
   `https://github.com/serengil/deepface_models/releases/download/v1.0/openface_weights.h5`  
   and place it as:  
   `app_backend/face_verify/.deepface/weights/openface_weights.h5`

Then the script will use this file and will not try to download it.

### 4.5 Start the backend

From `app_backend`:

```bash
npm run start
# or
node index.js
```

Use your usual process manager (e.g. PM2, systemd) in production.

### 4.6 Flutter app (build and API URL)

- Build the Flutter app (e.g. `flutter build apk` / `flutter build ios`) with the **production API base URL** (e.g. `https://your-api-domain.com/api` in `constants.dart` or via build-time config).
- No extra “face detection” config is required in the app; it only needs to talk to your backend and use the same auth as today.

---

## 5. Environment Variables (for `.env` on the server)

These are the variables the backend expects. **Do not commit real values**; set them only in `.env` on the server.

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | Yes | Backend port (e.g. 8001). |
| `MONGODB_URI` | Yes | MongoDB connection string. |
| `JWT_SECRET` | Yes | Secret for signing JWT. |
| `JWT_EXPIRES_IN` | Optional | e.g. `2d`. |
| `JWT_REFRESH_EXPIRES_IN` | Optional | e.g. `7d`. |
| `NODE_ENV` | Optional | e.g. `production`. |
| `FRONTEND_URL` | Optional | Frontend origin for CORS (e.g. `https://hrms.askeva.io`). |
| `CLOUDINARY_CLOUD_NAME` | Yes* | Cloudinary cloud name (profile/upload). |
| `CLOUDINARY_API_KEY` | Yes* | Cloudinary API key. |
| `CLOUDINARY_API_SECRET` | Yes* | Cloudinary API secret. |
| `EMAIL_*` / `SENDPULSE_*` | As needed | For emails (password reset, etc.). |

\* Required if you use profile photo upload (and thus face verification with profile photo).

**Face verification** does **not** use any extra env vars; it only needs the backend to run and the Python script to be callable with the venv Python.

---

## 6. Quick deployment checklist

- [ ] Clone repo; do **not** commit `.env` or `face_verify/venv` or `face_verify/.deepface`.
- [ ] Create `app_backend/.env` with production values.
- [ ] Run `npm install` in `app_backend`.
- [ ] Create `app_backend/face_verify/venv`, activate it, run `pip install -r requirements.txt`.
- [ ] (Optional) Pre-download `openface_weights.h5` into `app_backend/face_verify/.deepface/weights/`.
- [ ] Ensure backend uses the correct Python path for your OS (venv on Windows vs Linux).
- [ ] Start backend (e.g. `node index.js` or PM2).
- [ ] Build Flutter app with production API URL; deploy app as usual.

---

## 7. Summary

- **Face detection (one face)** = Flutter only, via **Google ML Kit**; nothing to install on the server for this.
- **Face matching (selfie vs profile)** = **Node + Python (DeepFace)** in `app_backend/face_verify`. On deploy: create `.env`, create Python venv, install `requirements.txt`, optionally pre-download OpenFace weights, and start the backend. No extra env vars are needed for face verification beyond the ones used by the rest of the backend.
