"""Departments API - list, create, update, delete. Company Admin only."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission, _audit_log

try:
    import psycopg2
except ImportError:
    psycopg2 = None  # type: ignore

router = APIRouter(prefix="/departments", tags=["departments"])


class CreateDepartmentBody(BaseModel):
    name: str
    active: bool = True
    attendanceModalId: int | None = None
    overtimeTemplateId: int | None = None
    leaveModalId: int | None = None
    shiftModalId: int | None = None
    holidayModalId: int | None = None
    salaryModalId: int | None = None
    fineModalId: int | None = None


class UpdateDepartmentBody(BaseModel):
    name: str | None = None
    active: bool | None = None
    attendanceModalId: int | None = None
    overtimeTemplateId: int | None = None
    leaveModalId: int | None = None
    shiftModalId: int | None = None
    holidayModalId: int | None = None
    salaryModalId: int | None = None
    fineModalId: int | None = None


def _ts_str(ts):
    """Format timestamp for API (ISO string or None)."""
    if ts is None:
        return None
    return ts.isoformat() if hasattr(ts, "isoformat") else str(ts)


def _dept_row(row) -> dict:
    """Build API response row; safe when 'active' is missing (e.g. before migration)."""
    active = row.get("active")
    if active is None and "active" not in row:
        active = True  # column missing (pre-migration)
    elif active is None:
        active = True   # NULL in db
    out = {
        "id": row["id"],
        "name": row.get("name") or "",
        "active": bool(active),
        "createdAt": _ts_str(row.get("created_at")),
    }
    for key, col in (
        ("attendanceModalId", "attendance_modal_id"),
        ("overtimeTemplateId", "overtime_template_id"),
        ("leaveModalId", "leave_modal_id"),
        ("shiftModalId", "shift_modal_id"),
        ("holidayModalId", "holiday_modal_id"),
        ("salaryModalId", "salary_modal_id"),
        ("fineModalId", "fine_modal_id"),
    ):
        if col in row and row[col] is not None:
            out[key] = int(row[col])
        else:
            out[key] = None
    return out


@router.get("")
def list_departments(
    active: bool | None = None,
    search: str | None = None,
    current_user: dict = Depends(require_permission("department.view")),
):
    """List departments for the company. Filter by active (true/false) and search by name."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        # Support both 'active' (init_db) and 'is_active' column names
        try:
            cur.execute("SELECT id, name, active FROM departments WHERE company_id = %s LIMIT 1", (company_id,))
            cur.fetchone()
            col_active = "active"
        except Exception:
            col_active = "is_active AS active"
        sql = f"SELECT id, name, {col_active}, created_at FROM departments WHERE company_id = %s"
        params: list = [company_id]
        if active is not None:
            if col_active == "active":
                sql += " AND active = %s"
            else:
                sql += " AND is_active = %s"
            params.append(active)
        if search and search.strip():
            sql += " AND LOWER(name) LIKE LOWER(%s)"
            params.append(f"%{search.strip()}%")
        sql += " ORDER BY name"
        # Include template IDs when columns exist (after migration)
        sql_ext = sql.replace(
            f"SELECT id, name, {col_active}, created_at FROM",
            f"SELECT id, name, {col_active}, created_at, attendance_modal_id, overtime_template_id, leave_modal_id, shift_modal_id, holiday_modal_id, salary_modal_id, fine_modal_id FROM",
        )
        try:
            cur.execute(sql_ext, tuple(params))
            rows = cur.fetchall()
        except Exception:
            cur.connection.rollback()
            cur.execute(sql, tuple(params))
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
        # Try full INSERT with template columns; if DB has no such columns (migration not run), fall back to minimal INSERT
        try:
            cur.execute(
                """INSERT INTO departments (company_id, name, active, attendance_modal_id, overtime_template_id, leave_modal_id, shift_modal_id, holiday_modal_id, salary_modal_id, fine_modal_id, created_at, updated_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                   RETURNING id, name, active, created_at, attendance_modal_id, overtime_template_id, leave_modal_id, shift_modal_id, holiday_modal_id, salary_modal_id, fine_modal_id""",
                (
                    company_id,
                    name,
                    body.active,
                    body.attendanceModalId,
                    body.overtimeTemplateId,
                    body.leaveModalId,
                    body.shiftModalId,
                    body.holidayModalId,
                    body.salaryModalId,
                    body.fineModalId,
                ),
            )
        except Exception as e:
            if psycopg2 and isinstance(e, psycopg2.ProgrammingError) and ("column" in str(e).lower() or "does not exist" in str(e).lower()):
                cur.connection.rollback()
                cur.execute(
                    "INSERT INTO departments (company_id, name, active, created_at, updated_at) VALUES (%s, %s, %s, NOW(), NOW()) RETURNING id, name, active, created_at",
                    (company_id, name, body.active),
                )
            else:
                raise
        row = cur.fetchone()
    _audit_log(current_user["id"], company_id, "department.create", "department", str(row["id"]))
    return _dept_row(row)


@router.patch("/{department_id}")
def update_department(
    department_id: int,
    body: UpdateDepartmentBody,
    current_user: dict = Depends(require_permission("department.edit")),
):
    """Update a department name and/or active status."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    name = (body.name or "").strip() if body.name is not None else None
    if name is not None and not name:
        raise HTTPException(status_code=400, detail="Department name is required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM departments WHERE id = %s AND company_id = %s",
            (department_id, company_id),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Department not found")
        updates = []
        params: list = []
        if name is not None:
            updates.append("name = %s")
            params.append(name)
        if body.active is not None:
            updates.append("active = %s")
            params.append(body.active)
        # Template IDs: only when sent (so client can clear with null; old clients don't clear)
        payload = body.model_dump(exclude_unset=True)
        template_updates = []
        template_params: list = []
        for key, col in (
            ("attendanceModalId", "attendance_modal_id"),
            ("overtimeTemplateId", "overtime_template_id"),
            ("leaveModalId", "leave_modal_id"),
            ("shiftModalId", "shift_modal_id"),
            ("holidayModalId", "holiday_modal_id"),
            ("salaryModalId", "salary_modal_id"),
            ("fineModalId", "fine_modal_id"),
        ):
            if key in payload:
                template_updates.append(f"{col} = %s")
                template_params.append(payload[key])
        all_updates = updates + template_updates
        if all_updates:
            params_ext = params + template_params + [department_id, company_id]
            try:
                cur.execute(
                    f"UPDATE departments SET {', '.join(all_updates)}, updated_at = NOW() WHERE id = %s AND company_id = %s",
                    tuple(params_ext),
                )
            except Exception as e:
                if psycopg2 and isinstance(e, psycopg2.ProgrammingError) and ("column" in str(e).lower() or "does not exist" in str(e).lower()) and template_updates:
                    if updates:
                        cur.connection.rollback()
                        cur.execute(
                            f"UPDATE departments SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s AND company_id = %s",
                            tuple(params + [department_id, company_id]),
                        )
                else:
                    raise
    _audit_log(current_user["id"], company_id, "department.edit", "department", str(department_id))
    with get_cursor() as cur:
        try:
            cur.execute(
                "SELECT id, name, active, created_at, attendance_modal_id, overtime_template_id, leave_modal_id, shift_modal_id, holiday_modal_id, salary_modal_id, fine_modal_id FROM departments WHERE id = %s",
                (department_id,),
            )
            row = cur.fetchone()
        except Exception:
            cur.connection.rollback()
            cur.execute(
                "SELECT id, name, active, created_at FROM departments WHERE id = %s",
                (department_id,),
            )
            row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Department not found")
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
