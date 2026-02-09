"""Audit logs API - list company audit logs. Admin only."""
from fastapi import APIRouter, Depends, Query

from config.database import get_cursor
from api.auth import require_any_permission

router = APIRouter(prefix="/audit-logs", tags=["audit-logs"])


@router.get("")
def list_audit_logs(
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    action: str | None = None,
    entity_type: str | None = None,
    current_user: dict = Depends(require_any_permission("settings.view", "audit.view")),
):
    """List audit logs for the company. Company Admin sees only their company's logs."""
    company_id = current_user.get("company_id")
    # Super Admin can see all; Company Admin only their company
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                """
                SELECT a.id, a.user_id, a.company_id, a.action, a.entity_type, a.entity_id,
                       a.details, a.ip_address, a.created_at,
                       u.name AS actor_name, u.email AS actor_email
                FROM audit_logs a
                LEFT JOIN users u ON u.id = a.user_id
                WHERE a.company_id = %s
                ORDER BY a.created_at DESC
                LIMIT %s OFFSET %s
                """,
                (company_id, limit, offset),
            )
        else:
            cur.execute(
                """
                SELECT a.id, a.user_id, a.company_id, a.action, a.entity_type, a.entity_id,
                       a.details, a.ip_address, a.created_at,
                       u.name AS actor_name, u.email AS actor_email
                FROM audit_logs a
                LEFT JOIN users u ON u.id = a.user_id
                ORDER BY a.created_at DESC
                LIMIT %s OFFSET %s
                """,
                (limit, offset),
            )
        rows = cur.fetchall()

    logs = []
    for r in rows:
        logs.append({
            "id": r["id"],
            "userId": r.get("user_id"),
            "companyId": r.get("company_id"),
            "action": r.get("action") or "",
            "entityType": r.get("entity_type"),
            "entityId": r.get("entity_id"),
            "details": r.get("details"),
            "ipAddress": r.get("ip_address"),
            "createdAt": (r.get("created_at") or "").__str__()[:19] if r.get("created_at") else None,
            "actorName": r.get("actor_name"),
            "actorEmail": r.get("actor_email"),
        })

    if action:
        logs = [l for l in logs if l["action"] == action]
    if entity_type:
        logs = [l for l in logs if l["entityType"] == entity_type]

    return {"auditLogs": logs}
