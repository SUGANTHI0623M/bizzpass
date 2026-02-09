# Build with context from repo root: docker compose build (from repo root)
FROM python:3.12-slim

WORKDIR /app

COPY crm_backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Main schema so init_db can run inside container
COPY postgres_schema.sql .
COPY crm_backend/config/ config/
COPY crm_backend/api/ api/
COPY crm_backend/services/ services/
COPY crm_backend/schema/ schema/
COPY crm_backend/scripts/ scripts/
COPY crm_backend/main.py .

# When run in docker-compose, DB_HOST=postgres
ENV DB_HOST=postgres DB_PORT=5432 DB_NAME=bizzpass DB_USER=dev DB_PASSWORD=dev1234

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
