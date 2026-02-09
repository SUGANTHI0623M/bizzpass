# Run DB init from inside Docker so we connect to the postgres container (avoids host Postgres on 5432).
# Uses full init_db.py (schema, migrations, seeds, RBAC). Ensure docker compose is up first.
$BizzpassRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
docker run --rm `
  --network bizzpass_default `
  -v "${BizzpassRoot}:/workspace" `
  -e DB_HOST=postgres `
  -e DB_PORT=5432 `
  -e DB_NAME=bizzpass `
  -e DB_USER=dev `
  -e DB_PASSWORD=dev1234 `
  -w /workspace/crm_backend `
  python:3.12-slim `
  bash -c "pip install -q -r requirements.txt && python scripts/init_db.py"
