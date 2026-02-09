# Run RBAC migration from inside Docker (after init_db and sample data exist).
$BizzpassRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$NetworkName = "bizzpass_default"
# Try default compose project network
docker run --rm `
  --network $NetworkName `
  -v "${BizzpassRoot}:/app" `
  -e DB_HOST=postgres `
  -e DB_PORT=5432 `
  -e DB_NAME=bizzpass `
  -e DB_USER=dev `
  -e DB_PASSWORD=dev1234 `
  -w /app/crm_backend `
  python:3.12-slim `
  bash -c "pip install -q psycopg2-binary bcrypt pydantic-settings && PYTHONPATH=/app/crm_backend python /app/crm_backend/scripts/rbac_migration.py"
