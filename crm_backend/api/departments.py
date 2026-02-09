"""Departments API - list, create, update, delete. Company Admin only."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission, _audit_log

router = APIRouter(prefix="/departments", tags=["departments"])


class CreateDepartmentBody(BaseModel):
    name: str


class UpdateDepartmentBody(BaseModel):
    name: str


def _dept_row(row) -> dict:
    return {
        "id": row["id"],
        "name": row.get("name") or "",
    }


@router.get("")
def list_departments(
    current_user: dict = Depends(require_permission("department.view")),
):
    """List departments for the company."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, name FROM departments WHERE company_id = %s ORDER BY name",
            (company_id,),
        )
        rows = cur.fetchall()
    return {"departments": [_dept_row(r) for r in rows]}


@router.post("")
def create_department(
    body: CreateDepartmentBody,
    current_user: dict = Depends(require_permission("department.create")),
):
    """Create a department."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    name = (body.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Department name is required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM departments WHERE company_id = %s AND LOWER(name) = LOWER(%s)",
            (company_id, name),
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="A department with this name already exists")
        cur.execute(
            "INSERT INTO departments (company_id, name, created_at, updated_at) VALUES (%s, %s, NOW(), NOW()) RETURNING id, name",
            (company_id, name),
        )
        row = cur.fetchone()
    _audit_log(current_user["id"], company_id, "department.create", "department", str(row["id"]))
    return _dept_row(row)


@router.patch("/{department_id}")
def update_department(
    department_id: int,
    body: UpdateDepartmentBody,
    current_user: dict = Depends(require_permission("department.edit")),
):
    """Update a department name."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    name = (body.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Department name is required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM departments WHERE id = %s AND company_id = %s",
            (department_id, company_id),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Department not found")
        cur.execute(
            "UPDATE departments SET name = %s, updated_at = NOW() WHERE id = %s AND company_id = %s",
            (name, department_id, company_id),
        )
    _audit_log(current_user["id"], company_id, "department.edit", "department", str(department_id))
    with get_cursor() as cur:
        cur.execute("SELECT id, name FROM departments WHERE id = %s", (department_id,))
        row = cur.fetchone()
    return _dept_row(row)


@router.delete("/{department_id}")
def delete_department(
    department_id: int,
    current_user: dict = Depends(require_permission("department.delete")),
):
    """Delete a department. Staff department field is not changed (free text)."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM departments WHERE id = %s AND company_id = %s",
            (department_id, company_id),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Department not found")
        cur.execute("DELETE FROM departments WHERE id = %s AND company_id = %s", (department_id, company_id))
    _audit_log(current_user["id"], company_id, "department.delete", "department", str(department_id))
    return {"ok": True}
