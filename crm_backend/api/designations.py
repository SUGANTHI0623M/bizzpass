"""Designations API - list, create, update, delete. Company Admin only. Same pattern as departments."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission, _audit_log

router = APIRouter(prefix="/designations", tags=["designations"])


class CreateDesignationBody(BaseModel):
    name: str
    active: bool = True


class UpdateDesignationBody(BaseModel):
    name: str | None = None
    active: bool | None = None


def _ts_str(ts):
    if ts is None:
        return None
    return ts.isoformat() if hasattr(ts, "isoformat") else str(ts)


def _row(r) -> dict:
    return {
        "id": r["id"],
        "name": r.get("name") or "",
        "active": bool(r.get("active") if r.get("active") is not None else True),
        "createdAt": _ts_str(r.get("created_at")),
    }


@router.get("")
def list_designations(
    active: bool | None = None,
    search: str | None = None,
    current_user: dict = Depends(require_permission("department.view")),
):
    """List designations for the company. Reuses department.view permission."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        sql = "SELECT id, name, active, created_at FROM designations WHERE company_id = %s"
        params: list = [company_id]
        if active is not None:
            sql += " AND active = %s"
            params.append(active)
        if search and search.strip():
            sql += " AND LOWER(name) LIKE LOWER(%s)"
            params.append(f"%{search.strip()}%")
        sql += " ORDER BY name"
        cur.execute(sql, tuple(params))
        rows = cur.fetchall()
    return {"designations": [_row(r) for r in rows]}


@router.post("")
def create_designation(
    body: CreateDesignationBody,
    current_user: dict = Depends(require_permission("department.create")),
):
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    name = (body.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Designation name is required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM designations WHERE company_id = %s AND LOWER(name) = LOWER(%s)",
            (company_id, name),
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="A designation with this name already exists")
        cur.execute(
            "INSERT INTO designations (company_id, name, active, created_at, updated_at) VALUES (%s, %s, %s, NOW(), NOW()) RETURNING id, name, active, created_at",
            (company_id, name, body.active),
        )
        row = cur.fetchone()
    _audit_log(current_user["id"], company_id, "designation.create", "designation", str(row["id"]))
    return _row(row)


@router.patch("/{designation_id}")
def update_designation(
    designation_id: int,
    body: UpdateDesignationBody,
    current_user: dict = Depends(require_permission("department.edit")),
):
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    name = (body.name or "").strip() if body.name is not None else None
    if name is not None and not name:
        raise HTTPException(status_code=400, detail="Designation name is required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM designations WHERE id = %s AND company_id = %s",
            (designation_id, company_id),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Designation not found")
        updates = []
        params: list = []
        if name is not None:
            updates.append("name = %s")
            params.append(name)
        if body.active is not None:
            updates.append("active = %s")
            params.append(body.active)
        if updates:
            params.extend([designation_id, company_id])
            cur.execute(
                f"UPDATE designations SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s AND company_id = %s",
                tuple(params),
            )
    _audit_log(current_user["id"], company_id, "designation.edit", "designation", str(designation_id))
    with get_cursor() as cur:
        cur.execute("SELECT id, name, active, created_at FROM designations WHERE id = %s", (designation_id,))
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Designation not found")
    return _row(row)


@router.delete("/{designation_id}")
def delete_designation(
    designation_id: int,
    current_user: dict = Depends(require_permission("department.delete")),
):
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM designations WHERE id = %s AND company_id = %s",
            (designation_id, company_id),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Designation not found")
        cur.execute("DELETE FROM designations WHERE id = %s AND company_id = %s", (designation_id, company_id))
    _audit_log(current_user["id"], company_id, "designation.delete", "designation", str(designation_id))
    return {"ok": True}
