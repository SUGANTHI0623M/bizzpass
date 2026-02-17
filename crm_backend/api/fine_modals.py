"""Fine Modals API. Company-scoped CRUD for fine modal templates (grace rules + fine calculation)."""
from datetime import datetime
import json

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/fine-modals", tags=["fine-modals"])


# --- Grace config structures ---
class GraceRuleBody(BaseModel):
    enabled: bool = True
    graceMinutesPerDay: int = 10
    graceCountPerMonth: int = 3
    resetCycle: str = "MONTHLY"  # MONTHLY | WEEKLY | NEVER
    graceType: str = "PER_OCCURRENCE"  # PER_OCCURRENCE | COUNT_BASED | COMBINED
    weekStartDay: int = 1  # 0=Sunday, 1=Monday


class GraceConfigBody(BaseModel):
    lateLogin: GraceRuleBody | None = None
    earlyLogout: GraceRuleBody | None = None


def _default_grace_config() -> dict:
    return {
        "lateLogin": {
            "enabled": True,
            "graceMinutesPerDay": 10,
            "graceCountPerMonth": 3,
            "resetCycle": "MONTHLY",
            "graceType": "PER_OCCURRENCE",
            "weekStartDay": 1,
        },
        "earlyLogout": {
            "enabled": False,
            "graceMinutesPerDay": 0,
            "graceCountPerMonth": 0,
            "resetCycle": "MONTHLY",
            "graceType": "PER_OCCURRENCE",
            "weekStartDay": 1,
        },
    }


class CreateFineModalBody(BaseModel):
    name: str
    description: str | None = None
    isActive: bool = True
    graceConfig: dict | None = None
    fineCalculationMethod: str = "per_minute"  # per_minute | fixed_per_occurrence
    fineFixedAmount: float | None = None


class UpdateFineModalBody(BaseModel):
    name: str | None = None
    description: str | None = None
    isActive: bool | None = None
    graceConfig: dict | None = None
    fineCalculationMethod: str | None = None
    fineFixedAmount: float | None = None


def _modal_row(row) -> dict:
    gc = row.get("grace_config")
    if isinstance(gc, str):
        try:
            gc = json.loads(gc) if gc else None
        except (json.JSONDecodeError, TypeError):
            gc = None
    if not gc:
        gc = _default_grace_config()
    return {
        "id": row["id"],
        "name": row.get("name") or "",
        "description": row.get("description") or "",
        "isActive": bool(row.get("is_active")),
        "graceConfig": gc,
        "fineCalculationMethod": row.get("fine_calculation_method") or "per_minute",
        "fineFixedAmount": float(row["fine_fixed_amount"]) if row.get("fine_fixed_amount") is not None else None,
    }


def _company_filter(company_id) -> tuple[str, list]:
    if company_id:
        return " WHERE company_id = %s", [company_id]
    return "", []


@router.get("")
def list_fine_modals(
    current_user: dict = Depends(require_permission("settings.view")),
):
    """List fine modals. Super Admin: all. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    where, params = _company_filter(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            SELECT id, name, description, is_active, grace_config,
                   fine_calculation_method, fine_fixed_amount
            FROM fine_modal_templates
            {where}
            ORDER BY name
            """,
            params,
        )
        rows = cur.fetchall()
    return {"modals": [_modal_row(r) for r in rows]}


@router.post("")
def create_fine_modal(
    body: CreateFineModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Create fine modal. Company Admin: requires company_id."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company Admin must have company_id")

    now = datetime.utcnow()
    gc = body.graceConfig or _default_grace_config()
    # Normalize grace config
    if "lateLogin" not in gc:
        gc = {**gc, "lateLogin": _default_grace_config()["lateLogin"]}
    if "earlyLogout" not in gc:
        gc = {**gc, "earlyLogout": _default_grace_config()["earlyLogout"]}

    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO fine_modal_templates (
                company_id, name, description, is_active, grace_config,
                fine_calculation_method, fine_fixed_amount, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id, name, description, is_active, grace_config,
                      fine_calculation_method, fine_fixed_amount
            """,
            (
                company_id,
                body.name.strip(),
                body.description or None,
                body.isActive,
                json.dumps(gc),
                body.fineCalculationMethod or "per_minute",
                body.fineFixedAmount,
                now,
                now,
            ),
        )
        row = cur.fetchone()
    return _modal_row(row)


@router.patch("/{modal_id}")
def update_fine_modal(
    modal_id: int,
    body: UpdateFineModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Update fine modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    updates = []
    params = []

    if body.name is not None:
        updates.append("name = %s")
        params.append(body.name.strip())
    if body.description is not None:
        updates.append("description = %s")
        params.append(body.description or None)
    if body.isActive is not None:
        updates.append("is_active = %s")
        params.append(body.isActive)
    if body.graceConfig is not None:
        updates.append("grace_config = %s")
        params.append(json.dumps(body.graceConfig))
    if body.fineCalculationMethod is not None:
        updates.append("fine_calculation_method = %s")
        params.append(body.fineCalculationMethod)
    if body.fineFixedAmount is not None:
        updates.append("fine_fixed_amount = %s")
        params.append(body.fineFixedAmount)

    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    updates.append("updated_at = %s")
    params.append(datetime.utcnow())
    params.append(modal_id)
    if company_id:
        params.append(company_id)

    where = " AND company_id = %s" if company_id else ""
    with get_cursor() as cur:
        cur.execute(
            f"""
            UPDATE fine_modal_templates
            SET {", ".join(updates)}
            WHERE id = %s{where}
            RETURNING id, name, description, is_active, grace_config,
                      fine_calculation_method, fine_fixed_amount
            """,
            params,
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Fine modal not found")
    return _modal_row(row)


@router.delete("/{modal_id}")
def delete_fine_modal(
    modal_id: int,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Delete fine modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "DELETE FROM fine_modal_templates WHERE id = %s AND company_id = %s RETURNING id",
                (modal_id, company_id),
            )
        else:
            cur.execute(
                "DELETE FROM fine_modal_templates WHERE id = %s RETURNING id",
                (modal_id,),
            )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Fine modal not found")
    return {"ok": True}
