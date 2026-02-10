# How to run BizzPass Admin CRM

## Ports

| What        | URL                     | Port |
|------------|-------------------------|------|
| **App (UI)** | http://localhost:8080 | 8080 |
| **API**      | http://localhost:8000 | 8000 |

- Open the **app** in your browser: **http://localhost:8080**
- The **backend** must be running at **http://localhost:8000** for data (departments, staff, etc.).

---

## 1. Start the backend (required for data)

From the **project root** (bizzpass):

```powershell
docker compose up -d
```

This starts Postgres and the CRM API at http://localhost:8000.

---

## 2. Start the app (Flutter web)

From the **project root**:

```powershell
cd bizzpass_crm
flutter run -d web-server --web-port 8080
```

Then open: **http://localhost:8080**

---

## One-command start (backend only; app runs separately)

From the **project root**:

```powershell
.\scripts\run_app.ps1
```

This starts the backend (Docker) and prints both URLs. Run the Flutter command in step 2 in a **separate terminal** to start the app at 8080.

---

## Login 401 or "Cannot reach server"

- **401 Unauthorized**  
  The backend is reachable but the credentials are wrong. Use an existing user or create/reset one:
  - After `init_db.py`, a **superadmin** user is created. To set a known password:
    - From project root:  
      `docker exec -i local_postgres psql -U dev -d bizzpass -c "SELECT id, email FROM users LIMIT 5;"`
    - Reset password (run from repo root, with backend DB on localhost):  
      `cd crm_backend && python scripts/reset_superadmin_password.py`  
      Then log in with email `shadmin@gmail.com` and password `#sh123`.
  - For a **company admin**, use the email/password that was set when the company was created, or use `scripts/create_or_reset_company_admin.py` to create/reset one.

- **"Cannot reach server" / "Cannot reach backend"**  
  The app could not reach `http://localhost:8000`. Check:
  1. Backend is running: `docker ps` should show `crm_backend` (or run `docker compose up -d`).
  2. You are opening the app from the **same machine** that runs the backend. If you open the app at `http://<another-PC>:8080`, that browser will try to call `localhost:8000` on the other PC, not your server. Use the server’s IP in the app’s base URL for cross-device access.
  3. On the login page, tap **Retry** after starting the backend; the banner will re-check and clear if the backend is up.

---

## Payroll: "relation payroll_runs does not exist"

If creating a payroll run fails with **relation "payroll_runs" does not exist**, the payroll tables have not been created in the main database. Apply the schema once:

From project root (PowerShell):

```powershell
Get-Content "crm_backend\schema\payroll_schema.sql" -Raw | docker exec -i local_postgres psql -U dev -d bizzpass
```

Then try creating a payroll run again.
