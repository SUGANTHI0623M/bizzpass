"""Roles & Permissions API - list roles, create custom role, edit permissions. Company Admin only."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_user, require_permission

router = APIRouter(prefix="/roles", tags=["roles"])


class CreateRoleBody(BaseModel):
    name: str
    description: str | None = None
    permission_codes: list[str] = []


class UpdateRoleBody(BaseModel):
    name: str | None = None
    description: str | None = None
    permission_codes: list[str] | None = None


def _role_row(row) -> dict:
    return {
        "id": row["id"],
        "code": row.get("code") or "",
        "name": row.get("name") or "",
        "description": (row.get("description") or "").strip() or None,
        "companyId": row.get("company_id"),
        "isSystemRole": bool(row.get("is_system_role")),
        "permissionCodes": row.get("permission_codes") or [],
    }


@router.get("")
def list_roles(
    current_user: dict = Depends(require_permission("role.view")),
):
    """List roles: system default roles + company custom roles. Company Admin sees only their scope."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT r.id, r.code, r.name, r.description, r.company_id,
                   (r.company_id IS NULL) AS is_system_role
            FROM rbac_roles r
            WHERE r.company_id IS NULL OR r.company_id = %s
            ORDER BY r.company_id NULLS FIRST, r.name
            """,
            (company_id,) if company_id else (None,),
        )
        rows = cur.fetchall()
        role_ids = [r["id"] for r in rows]
        perm_by_role = {}
        if role_ids:
            cur.execute(
                """
                SELECT rp.role_id, p.code
                FROM rbac_role_permissions rp
                JOIN rbac_permissions p ON p.id = rp.permission_id
                WHERE rp.role_id = ANY(%s)
                ORDER BY rp.role_id, p.code
                """,
                (role_ids,),
            )
            for row in cur.fetchall():
                rid = row["role_id"]
                if rid not in perm_by_role:
                    perm_by_role[rid] = []
                perm_by_role[rid].append(row["code"])

        # Staff count per role (users in this company with this role)
        staff_count_by_role = {}
        if role_ids and company_id:
            cur.execute(
                """
                SELECT rbac_role_id, COUNT(*) AS cnt
                FROM users
                WHERE rbac_role_id = ANY(%s) AND company_id_bigint = %s AND is_active IS NOT DISTINCT FROM TRUE
                GROUP BY rbac_role_id
                """,
                (role_ids, company_id),
            )
            for row in cur.fetchall():
                staff_count_by_role[row["rbac_role_id"]] = row["cnt"] or 0

    roles = []
    for r in rows:
        codes = perm_by_role.get(r["id"], [])
        roles.append({
            **_role_row({**r, "permission_codes": codes}),
            "permissionCodes": codes,
            "staffCount": staff_count_by_role.get(r["id"], 0),
        })
    return {"roles": roles}


@router.get("/permissions")
def list_permissions(
    current_user: dict = Depends(get_current_user),
):
    """List all permissions grouped by category. No special permission required (needed for role edit UI)."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT id, code, module, description
            FROM rbac_permissions
            ORDER BY module, code
            """
        )
        rows = cur.fetchall()

    # Group by module for UI
    by_module = {}
    for r in rows:
        mod = (r.get("module") or "other").lower()
        if mod not in by_module:
            by_module[mod] = []
        by_module[mod].append({
            "id": r["id"],
            "code": r.get("code") or "",
            "description": (r.get("description") or "").strip() or r.get("code"),
        })

    return {"permissions": by_module, "allCodes": [r["code"] for r in rows]}


@router.post("")
def create_role(
    body: CreateRoleBody,
    current_user: dict = Depends(require_permission("role.create")),
):
    """Create a custom role for the company. Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    name = (body.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Role name is required")

    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM rbac_roles WHERE company_id = %s AND LOWER(name) = LOWER(%s)",
            (company_id, name),
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="A role with this name already exists")

        # Generate a code for custom role (e.g. CUSTOM_1)
        cur.execute(
            "SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM rbac_roles WHERE company_id = %s",
            (company_id,),
        )
        row = cur.fetchone()
        next_id = (row.get("next_id") if row else None) or 1
        code = f"CUSTOM_{next_id}"

        cur.execute(
            """
            INSERT INTO rbac_roles (code, name, company_id, description)
            VALUES (%s, %s, %s, %s)
            RETURNING id, code, name, description, company_id
            """,
            (code, name, company_id, (body.description or "").strip() or None),
        )
        role_row = cur.fetchone()
        role_id = role_row["id"]

        # Resolve permission ids from codes
        perm_codes = [c for c in (body.permission_codes or []) if c]
        if perm_codes:
            cur.execute(
                "SELECT id, code FROM rbac_permissions WHERE code = ANY(%s)",
                (perm_codes,),
            )
            perm_ids = [r["id"] for r in cur.fetchall()]
            for pid in perm_ids:
                cur.execute(
                    "INSERT INTO rbac_role_permissions (role_id, permission_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                    (role_id, pid),
                )

    # Audit
    try:
        with get_cursor() as cur:
            cur.execute(
                """
                INSERT INTO audit_logs (user_id, company_id, action, entity_type, entity_id, details, created_at)
                VALUES (%s, %s, 'role.create', 'role', %s, %s, NOW())
                """,
                (current_user["id"], company_id, str(role_id), '{"name": "' + name.replace('"', '\\"') + '"}'),
            )
    except Exception:
        pass

    return _role_row({**dict(role_row), "is_system_role": False, "permission_codes": perm_codes})


@router.patch("/{role_id}")
def update_role(
    role_id: int,
    body: UpdateRoleBody,
    current_user: dict = Depends(require_permission("role.edit")),
):
    """Update a custom role (name, description, permissions). Cannot edit system roles or Company Admin."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, code, name, company_id FROM rbac_roles WHERE id = %s",
            (role_id,),
        )
        role = cur.fetchone()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    if role.get("company_id") != company_id:
        raise HTTPException(status_code=403, detail="Cannot edit this role")
    if (role.get("code") or "").upper() == "COMPANY_ADMIN":
        raise HTTPException(status_code=403, detail="Cannot edit Company Admin role")

    with get_cursor() as cur:
        if body.name is not None:
            name = (body.name or "").strip()
            if name:
                cur.execute(
                    "UPDATE rbac_roles SET name = %s WHERE id = %s",
                    (name, role_id),
                )
        if body.description is not None:
            cur.execute(
                "UPDATE rbac_roles SET description = %s WHERE id = %s",
                ((body.description or "").strip() or None, role_id),
            )
        if body.permission_codes is not None:
            cur.execute("DELETE FROM rbac_role_permissions WHERE role_id = %s", (role_id,))
            perm_codes = [c for c in body.permission_codes if c]
            if perm_codes:
                cur.execute(
                    "SELECT id FROM rbac_permissions WHERE code = ANY(%s)",
                    (perm_codes,),
                )
                for r in cur.fetchall():
                    cur.execute(
                        "INSERT INTO rbac_role_permissions (role_id, permission_id) VALUES (%s, %s)",
                        (role_id, r["id"]),
                    )

    # Audit
    try:
        with get_cursor() as cur:
            cur.execute(
                "INSERT INTO audit_logs (user_id, company_id, action, entity_type, entity_id, created_at) VALUES (%s, %s, 'role.edit', 'role', %s, NOW())",
                (current_user["id"], company_id, str(role_id)),
            )
    except Exception:
        pass

    with get_cursor() as cur:
        cur.execute(
            "SELECT r.id, r.code, r.name, r.description, r.company_id FROM rbac_roles r WHERE r.id = %s",
            (role_id,),
        )
        r = cur.fetchone()
        cur.execute(
            "SELECT p.code FROM rbac_permissions p JOIN rbac_role_permissions rp ON rp.permission_id = p.id WHERE rp.role_id = %s",
            (role_id,),
        )
        codes = [row["code"] for row in cur.fetchall()]
    return _role_row({**dict(r), "is_system_role": False, "permission_codes": codes})


@router.get("/{role_id}/staff-count")
def get_role_staff_count(
    role_id: int,
    current_user: dict = Depends(require_permission("role.view")),
):
    """Get number of staff assigned to this role (in current company)."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, company_id FROM rbac_roles WHERE id = %s",
            (role_id,),
        )
        role = cur.fetchone()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    if company_id and role.get("company_id") is not None and role.get("company_id") != company_id:
        raise HTTPException(status_code=403, detail="Access denied")
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT COUNT(*) AS cnt FROM users
            WHERE rbac_role_id = %s AND company_id_bigint = %s AND is_active IS NOT DISTINCT FROM TRUE
            """,
            (role_id, company_id),
        )
        row = cur.fetchone()
    count = (row.get("cnt") or 0) if row else 0
    return {"staffCount": count}


@router.delete("/{role_id}")
def delete_role(
    role_id: int,
    current_user: dict = Depends(require_permission("role.edit")),
):
    """Delete a custom role. Fails if any staff is assigned to this role. Cannot delete system roles."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, code, company_id FROM rbac_roles WHERE id = %s",
            (role_id,),
        )
        role = cur.fetchone()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    if role.get("company_id") != company_id:
        raise HTTPException(status_code=403, detail="Cannot delete this role")
    if (role.get("code") or "").upper() == "COMPANY_ADMIN":
        raise HTTPException(status_code=403, detail="Cannot delete Company Admin role")
    if role.get("company_id") is None:
        raise HTTPException(status_code=403, detail="Cannot delete system role")
    with get_cursor() as cur:
        cur.execute(
            "SELECT COUNT(*) AS cnt FROM users WHERE rbac_role_id = %s AND company_id_bigint = %s",
            (role_id, company_id),
        )
        row = cur.fetchone()
    count = (row.get("cnt") or 0) if row else 0
    if count > 0:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot delete: this role is assigned to {count} staff. Reassign or remove them first.",
        )
    with get_cursor() as cur:
        cur.execute("DELETE FROM rbac_role_permissions WHERE role_id = %s", (role_id,))
        cur.execute("DELETE FROM rbac_roles WHERE id = %s", (role_id,))
    try:
        with get_cursor() as cur:
            cur.execute(
                "INSERT INTO audit_logs (user_id, company_id, action, entity_type, entity_id, created_at) VALUES (%s, %s, 'role.delete', 'role', %s, NOW())",
                (current_user["id"], company_id, str(role_id)),
            )
    except Exception:
        pass
    return {"ok": True}


@router.get("/{role_id}")
def get_role(
    role_id: int,
    current_user: dict = Depends(require_permission("role.view")),
):
    """Get a single role with permissions."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, code, name, description, company_id FROM rbac_roles WHERE id = %s",
            (role_id,),
        )
        r = cur.fetchone()
    if not r:
        raise HTTPException(status_code=404, detail="Role not found")
    if company_id and r.get("company_id") is not None and r.get("company_id") != company_id:
        raise HTTPException(status_code=403, detail="Access denied")
    with get_cursor() as cur:
        cur.execute(
            "SELECT p.code FROM rbac_permissions p JOIN rbac_role_permissions rp ON rp.permission_id = p.id WHERE rp.role_id = %s",
            (role_id,),
        )
        codes = [row["code"] for row in cur.fetchall()]
        staff_count = 0
        if company_id:
            cur.execute(
                "SELECT COUNT(*) AS cnt FROM users WHERE rbac_role_id = %s AND company_id_bigint = %s AND is_active IS NOT DISTINCT FROM TRUE",
                (role_id, company_id),
            )
            sc_row = cur.fetchone()
            staff_count = (sc_row.get("cnt") or 0) if sc_row else 0
    return {**_role_row({**dict(r), "is_system_role": r.get("company_id") is None, "permission_codes": codes}), "staffCount": staff_count}
