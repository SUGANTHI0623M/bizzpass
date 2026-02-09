"""Visitors API - list, register visitor. Super Admin sees all; Company Admin sees own company only."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_user, require_permission

router = APIRouter(prefix="/visitors", tags=["visitors"])


class VisitorRegister(BaseModel):
    visitor_name: str
    visitor_phone: str | None = None
    visitor_company: str | None = None
    company_id: int
    host_employee_id: int | None = None
    host_name: str | None = None
    purpose: str | None = None
    id_proof_type: str | None = None


def _visitor_row(row) -> dict:
    check_in = row.get("check_in")
    return {
        "id": row["id"],
        "name": row.get("visitor_name") or "",
        "visitorCompany": row.get("visitor_company") or "",
        "companyVisiting": row.get("company_name") or "",
        "purpose": row.get("purpose") or "",
        "host": row.get("host_name") or "",
        "status": (row.get("status") or "expected").replace(" ", "_").lower(),
        "badge": row.get("badge_number") or "",
        "checkIn": check_in.strftime("%Y-%m-%d %H:%M") if hasattr(check_in, "strftime") else (str(check_in)[:16] if check_in else None),
    }


@router.get("")
def list_visitors(
    current_user: dict = Depends(require_permission("visitor.view")),
):
    """List visitors. Super Admin: all companies. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                """
                SELECT v.id, v.visitor_name, v.visitor_company, v.purpose, v.host_name,
                       v.check_in, v.check_out, v.status, v.badge_number,
                       c.name AS company_name
                FROM visitors v
                JOIN companies c ON c.id = v.company_id
                WHERE v.company_id = %s
                ORDER BY v.created_at DESC
                """,
                (company_id,),
            )
        else:
            cur.execute(
                """
                SELECT v.id, v.visitor_name, v.visitor_company, v.purpose, v.host_name,
                       v.check_in, v.check_out, v.status, v.badge_number,
                       c.name AS company_name
                FROM visitors v
                JOIN companies c ON c.id = v.company_id
                ORDER BY v.created_at DESC
                """
            )
        rows = cur.fetchall()

    return {"visitors": [_visitor_row(r) for r in rows]}


@router.post("")
def register_visitor(
    body: VisitorRegister,
    current_user: dict = Depends(require_permission("visitor.create")),
):
    """Register a new visitor. Company Admin can only register for own company."""
    company_id = current_user.get("company_id")
    if company_id and body.company_id != company_id:
        raise HTTPException(status_code=403, detail="Cannot register visitor for another company")
    with get_cursor() as cur:
        cur.execute("SELECT id FROM companies WHERE id = %s", (body.company_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Company not found")

        cur.execute("SELECT MAX(id) + 1 AS next_id FROM visitors")
        next_num = (cur.fetchone() or {}).get("next_id", 1) or 1
        badge = f"V-{next_num:04d}"

        cur.execute(
            """
            INSERT INTO visitors (company_id, visitor_name, visitor_phone, visitor_company,
                                 host_name, host_employee_id, purpose, id_proof_type,
                                 status, badge_number, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'expected', %s, NOW(), NOW())
            RETURNING id, visitor_name, visitor_company, purpose, host_name, check_in, status, badge_number
            """,
            (
                body.company_id,
                body.visitor_name,
                body.visitor_phone or "",
                body.visitor_company or "",
                body.host_name or "",
                body.host_employee_id,
                body.purpose or "",
                body.id_proof_type or "",
                badge,
            ),
        )
        row = cur.fetchone()

    with get_cursor() as cur2:
        cur2.execute("SELECT name FROM companies WHERE id = %s", (body.company_id,))
        company_name = (cur2.fetchone() or {}).get("name", "")

    return _visitor_row({**dict(row), "company_name": company_name})


@router.post("/{visitor_id}/check-in")
def check_in_visitor(
    visitor_id: int,
    current_user: dict = Depends(require_permission("visitor.checkin")),
):
    """Check in a visitor."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "UPDATE visitors SET status = 'checked_in', check_in = NOW(), updated_at = NOW() WHERE id = %s AND status = 'expected' AND company_id = %s RETURNING id",
                (visitor_id, company_id),
            )
        else:
            cur.execute(
                "UPDATE visitors SET status = 'checked_in', check_in = NOW(), updated_at = NOW() WHERE id = %s AND status = 'expected' RETURNING id",
                (visitor_id,),
            )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Visitor not found or already checked in")
    return {"ok": True}


@router.post("/{visitor_id}/check-out")
def check_out_visitor(
    visitor_id: int,
    current_user: dict = Depends(require_permission("visitor.checkout")),
):
    """Check out a visitor."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "UPDATE visitors SET status = 'checked_out', check_out = NOW(), updated_at = NOW() WHERE id = %s AND status = 'checked_in' AND company_id = %s RETURNING id",
                (visitor_id, company_id),
            )
        else:
            cur.execute(
                "UPDATE visitors SET status = 'checked_out', check_out = NOW(), updated_at = NOW() WHERE id = %s AND status = 'checked_in' RETURNING id",
                (visitor_id,),
            )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Visitor not found or not checked in")
    return {"ok": True}
