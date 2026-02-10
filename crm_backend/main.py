"""CRM Backend - FastAPI app. Serves bizzpass_crm (admin) and APIs for bizzpass DB."""
import logging
import time

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.auth import router as auth_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
from api.companies import router as companies_router
from api.licenses import router as licenses_router
from api.staff import router as staff_router
from api.visitors import router as visitors_router
from api.attendance import router as attendance_router
from api.attendance_modals import router as attendance_modals_router
from api.shift_modals import router as shift_modals_router
from api.office_holidays import router as office_holidays_router
from api.holiday_modals import router as holiday_modals_router
from api.leave_modals import router as leave_modals_router
from api.leave_categories import router as leave_categories_router
from api.payments import router as payments_router
from api.notifications import router as notifications_router
from api.plans import router as plans_router, create_plan
from api.dashboard import router as dashboard_router
from api.roles import router as roles_router
from api.audit_logs import router as audit_logs_router
from api.branches import router as branches_router
from api.departments import router as departments_router
from api.subscription import router as subscription_router
from api.payroll import router as payroll_router
from api.company_dashboard import router as company_dashboard_router

app = FastAPI(
    title="BizzPass CRM Backend",
    description="Backend for BizzPass Admin CRM (licenses, companies, staff, etc.)",
    version="1.0.0",
)

# Must list origins explicitly when allow_credentials=True (browser rejects "*" with credentials).
# Flutter web may use localhost or 127.0.0.1 depending on how it's launched.
_app_origins = [
    "http://localhost:3000",
    "http://localhost:808",
    "http://localhost:8080",
    "http://localhost:8081",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:808",
    "http://127.0.0.1:8080",
    "http://127.0.0.1:8081",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_app_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_requests(request, call_next):
    """Log each request for debugging loading/API issues."""
    start = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start) * 1000
    logger.info("%s %s -> %s (%.0f ms)", request.method, request.url.path, response.status_code, elapsed_ms)
    return response

app.include_router(auth_router)
app.include_router(companies_router)
app.include_router(licenses_router)
app.include_router(staff_router)
app.include_router(visitors_router)
app.include_router(attendance_router)
app.include_router(attendance_modals_router)
app.include_router(shift_modals_router)
app.include_router(office_holidays_router)
app.include_router(holiday_modals_router)
app.include_router(leave_modals_router)
app.include_router(leave_categories_router)
app.include_router(payments_router)
app.include_router(notifications_router)
app.include_router(plans_router)
app.include_router(dashboard_router)
app.include_router(roles_router)
app.include_router(audit_logs_router)
app.include_router(branches_router)
app.include_router(departments_router)
app.include_router(subscription_router)
app.include_router(payroll_router)
app.include_router(company_dashboard_router)

# Guarantee POST /plans/create is always registered (avoids 404 from router load order/cache)
app.add_api_route("/plans/create", create_plan, methods=["POST"])


@app.on_event("startup")
def startup():
    logger.info("BizzPass CRM Backend ready (health at GET /health)")


@app.get("/health")
def health():
    """No auth. Use this to check backend is up before/during frontend load."""
    return {"status": "ok"}


@app.get("/debug/routes")
def debug_routes():
    """List registered routes (for debugging 404s). No auth required."""
    routes = []
    for r in app.routes:
        if hasattr(r, "path") and hasattr(r, "methods"):
            routes.append({"path": r.path, "methods": list(r.methods)})
    return {"routes": routes}
