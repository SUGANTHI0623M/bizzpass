"""Leave Categories API. Company-scoped CRUD for leave categories (Sick, Casual, etc.)."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/leave-categories", tags=["leave-categories"])


class CreateLeaveCategoryBody(BaseModel):
    name: str


class UpdateLeaveCategoryBody(BaseModel):
    name: str | None = None
    isActive: bool | None = None


def _row_to_dict(row) -> dict:
    return {
        "id": row["id"],
        "name": row.get("name") or "",
        "isActive": bool(row.get("is_active", True)),
    }


def _company_filter(company_id) -> tuple[str, list]:
    if company_id:
        return " WHERE company_id = %s", [company_id]
    return "", []


@router.get("")
def list_leave_categories(
    current_user: dict = Depends(require_permission("settings.view")),
):
    """List leave categories. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"categories": []}
    where, params = _company_filter(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            SELECT id, name, is_active
            FROM leave_categories
            {where}
            ORDER BY name
            """,
            params,
        )
        rows = cur.fetchall()
    return {"categories": [_row_to_dict(r) for r in rows]}


@router.post("")
def create_leave_category(
    body: CreateLeaveCategoryBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Create leave category. Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company Admin must have company_id")

    name = body.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    now = datetime.utcnow()
    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO leave_categories (company_id, name, is_active, created_at, updated_at)
            VALUES (%s, %s, TRUE, %s, %s)
            RETURNING id, name, is_active
            """,
            (company_id, name, now, now),
        )
        row = cur.fetchone()
    return _row_to_dict(row)


@router.patch("/{category_id}")
def update_leave_category(
    category_id: int,
    body: UpdateLeaveCategoryBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Update leave category. Company Admin: must own the category."""
    company_id = current_user.get("company_id")
    updates = []
    params = []
    if body.name is not None:
        updates.append("name = %s")
        params.append(body.name.strip())
    if body.isActive is not None:
        updates.append("is_active = %s")
        params.append(body.isActive)
    if not updates:
        with get_cursor() as cur:
            cur.execute(
                "SELECT id, name, is_active FROM leave_categories WHERE id = %s" + (" AND company_id = %s" if company_id else ""),
                (category_id,) + ((company_id,) if company_id else ()),
            )
            row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Leave category not found")
        return _row_to_dict(row)
    params.append(datetime.utcnow())
    updates.append("updated_at = %s")
    params.append(category_id)
    if company_id:
        params.append(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            UPDATE leave_categories SET {", ".join(updates)}
            WHERE id = %s """ + ("AND company_id = %s" if company_id else "") + """
            RETURNING id, name, is_active
            """,
            tuple(params),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Leave category not found")
    return _row_to_dict(row)


@router.delete("/{category_id}")
def delete_leave_category(
    category_id: int,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Delete leave category. Company Admin: must own the category."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "DELETE FROM leave_categories WHERE id = %s AND company_id = %s RETURNING id",
                (category_id, company_id),
            )
        else:
            cur.execute(
                "DELETE FROM leave_categories WHERE id = %s RETURNING id",
                (category_id,),
            )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Leave category not found")
    return {"ok": True}
