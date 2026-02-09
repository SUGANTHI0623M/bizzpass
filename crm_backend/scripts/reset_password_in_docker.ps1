# Reset superadmin password. Run from project root.
$BizzpassRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
docker run --rm `
  --network bizzpass_default `
  -v "${BizzpassRoot}:/app" `
  -e DB_HOST=postgres `
  -e DB_PORT=5432 `
  -e DB_NAME=bizzpass `
  -e DB_USER=dev `
  -e DB_PASSWORD=dev1234 `
  python:3.12-slim `
  bash -c "pip install -q psycopg2-binary bcrypt && cd /app/crm_backend && python scripts/reset_superadmin_password.py"
