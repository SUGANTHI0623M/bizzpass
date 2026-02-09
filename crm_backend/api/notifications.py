"""Notifications API - list delivery tracking."""
from fastapi import APIRouter, Depends
from config.database import get_cursor
from api.auth import get_current_super_admin

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _notification_row(row) -> dict:
    created = row.get("created_at") or row.get("sent_at")
    return {
        "id": row["id"],
        "type": row.get("type") or "",
        "title": row.get("title") or "",
        "company": row.get("company_name") or "",
        "channel": (row.get("channel") or "email").lower(),
        "status": (row.get("status") or "pending").lower(),
        "priority": (row.get("priority") or "normal").lower(),
        "createdAt": created.strftime("%Y-%m-%d") if created and hasattr(created, "strftime") else (str(created)[:10] if created else ""),
    }


@router.get("")
def list_notifications(
    current_user: dict = Depends(get_current_super_admin),
):
    """List all notifications."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT n.id, n.type, n.title, n.channel, n.status, n.priority, n.created_at, n.sent_at,
                   c.name AS company_name
            FROM notifications n
            LEFT JOIN companies c ON c.id = n.company_id
            ORDER BY n.created_at DESC
            LIMIT 500
            """
        )
        rows = cur.fetchall()

    return {"notifications": [_notification_row(r) for r in rows]}
