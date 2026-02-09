# BizzPass CRM Backend

Python FastAPI backend for **BizzPass Admin CRM** (bizzpass_crm). Uses the **bizzpass** PostgreSQL database.

## Structure

```
crm_backend/
├── config/          # Settings, database connection
├── api/             # Routes (auth, etc.)
├── scripts/         # DB init, seed superadmin
├── main.py          # FastAPI app
└── requirements.txt
```

## Setup

### Option A: Run with Docker (recommended — avoids DB connection issues)

From the **repo root** (bizzpass/):

```bash
docker compose up -d
```

This starts Postgres and the CRM backend. The backend connects to the DB using hostname `postgres` inside Docker, so login works. The API is at http://localhost:8000.

**After backend code changes (e.g. new routes like POST /plans/create):** Rebuild and restart the backend container so the new code is used:
```powershell
docker compose build crm_backend
docker compose up -d crm_backend
```
Or from repo root: `docker compose up -d --build` to rebuild and restart all services.

If the DB is empty, run the init script once. From **repo root** either:

- **Using the running backend container:**  
  `docker compose exec crm_backend python /app/scripts/init_db.py`
- **Or use the PowerShell helper:**  
  `.\crm_backend\scripts\run_init_in_docker.ps1`

### Option B: Run backend on your machine

If you run `uvicorn` on the host, the backend uses `localhost:5432` for the DB. If another PostgreSQL is installed and using port 5432, you'll get "password authentication failed for user dev" because that's a different server. Either:

- Stop the other PostgreSQL so only Docker Postgres is on 5432, or  
- Run the backend in Docker (Option A).

1. Start Postgres: `docker compose up -d` (only the postgres service if you prefer).
2. Init DB/superadmin: run `.\crm_backend\scripts\run_init_in_docker.ps1` once.
3. Run API (from `crm_backend`):
   - First time, install into the **venv** (use the venv’s Python so you don’t touch system Python):
     ```powershell
     .\.venv\Scripts\python.exe -m pip install -r requirements.txt
     ```
   - Start the backend:
     ```powershell
     .\.venv\Scripts\python.exe -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
     ```
   Or run `.\scripts\run_backend.ps1` (uses the venv’s Python automatically).

## Superadmin login

- **Email:** `shadmin@gmail.com`
- **Password:** `#sh123`

## Endpoints

All endpoints except `/health` and `/auth/login` require `Authorization: Bearer <token>`.

### Auth
- `GET /health` — health check (no auth)
- `POST /auth/login` — body: `{ "email": "...", "password": "..." }` → returns `{ "token": "...", "user": { ... } }`

### Companies
- `GET /companies` — list companies (?search=, ?tab=all|active|inactive|expiring)
- `GET /companies/{id}` — get company
- `POST /companies` — create company
- `PATCH /companies/{id}` — update company
- `POST /companies/{id}/logo` — upload logo (multipart form, Cloudinary)
- `DELETE /companies/{id}` — soft-deactivate

### Licenses
- `GET /licenses` — list licenses (?search=, ?tab=all|active|expired|unassigned|suspended)
- `POST /licenses` — create license

### Staff
- `GET /staff` — list staff (?search=, ?tab=all|active|inactive)

### Visitors
- `GET /visitors` — list visitors
- `POST /visitors` — register visitor
- `POST /visitors/{id}/check-in` — check in
- `POST /visitors/{id}/check-out` — check out

### Attendance
- `GET /attendance/today` — today's attendance
- `GET /attendance` — attendance (?target_date=YYYY-MM-DD)

### Payments, Plans, Notifications, Dashboard
- `GET /payments` — list payments
- `GET /plans` — list subscription plans
- `GET /notifications` — list notifications
- `GET /dashboard` — dashboard stats
- `GET /dashboard/companies` — companies for dashboard
- `GET /dashboard/licenses` — licenses for dashboard
- `GET /dashboard/payments` — payments for dashboard

## Per-company databases

When you **create a company** (POST /companies), the backend automatically:

1. Inserts the company into the **main** database (`bizzpass`).
2. Creates a **separate PostgreSQL database** for that company (e.g. `bizzpass_c_123`).
3. Applies the **tenant schema** to that database (staff, branches, attendance, leaves, payroll, visitors, etc.).

All existing CRM features (companies list, licenses, staff list, etc.) continue to use the main database only; nothing changes for current behaviour. The per-company DB is ready for future use (e.g. company-specific app or APIs that connect to `companies.db_name`).

**Requirement:** The DB user (`DB_USER`, e.g. `dev`) must be allowed to create databases. In PostgreSQL run once:

```sql
ALTER USER dev CREATEDB;
```

(With Docker Postgres you can run this inside the container or from any client connected to the main DB.)

**Existing deployments:** If your `companies` table was created before this feature, add the column once:

```sql
ALTER TABLE companies ADD COLUMN IF NOT EXISTS db_name VARCHAR(64) NULL;
```

## Environment (optional)

Create `.env` in `crm_backend/` (see `.env.example`):

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `JWT_SECRET` (use a strong secret in production)
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` — for logo uploads
