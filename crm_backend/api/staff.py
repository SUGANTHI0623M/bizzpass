"""Staff API - list, create, update employees. Super Admin sees all; Company Admin sees own company only."""
import bcrypt
from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_user, require_permission, _audit_log

router = APIRouter(prefix="/staff", tags=["staff"])


class CreateStaffBody(BaseModel):
    fullName: str
    email: str
    phone: str | None = None
    employeeId: str | None = None
    department: str | None = None
    designation: str | None = None
    joiningDate: str | None = None
    branchId: int | None = None
    loginMethod: str = "password"  # otp | password
    temporaryPassword: str | None = None
    roleId: int
    status: str = "active"  # active | inactive
    attendanceModalId: int | None = None
    shiftModalId: int | None = None
    leaveModalId: int | None = None
    holidayModalId: int | None = None
    staffType: str | None = None
    reportingManager: str | None = None
    salaryCycle: str | None = None
    grossSalary: float | None = None
    netSalary: float | None = None
    gender: str | None = None
    dob: str | None = None
    maritalStatus: str | None = None
    bloodGroup: str | None = None
    addressLine1: str | None = None
    addressCity: str | None = None
    addressState: str | None = None
    addressPostalCode: str | None = None
    addressCountry: str | None = None
    uan: str | None = None
    panNumber: str | None = None
    aadhaarNumber: str | None = None
    pfNumber: str | None = None
    esiNumber: str | None = None
    bankName: str | None = None
    ifscCode: str | None = None
    accountNumber: str | None = None
    accountHolderName: str | None = None
    upiId: str | None = None
    bankVerificationStatus: str | None = None


class UpdateStaffBody(BaseModel):
    fullName: str | None = None
    phone: str | None = None
    department: str | None = None
    designation: str | None = None
    status: str | None = None
    roleId: int | None = None
    branchId: int | None = None
    attendanceModalId: int | None = None
    shiftModalId: int | None = None
    leaveModalId: int | None = None
    holidayModalId: int | None = None
    staffType: str | None = None
    reportingManager: str | None = None
    salaryCycle: str | None = None
    grossSalary: float | None = None
    netSalary: float | None = None
    gender: str | None = None
    dob: str | None = None
    maritalStatus: str | None = None
    bloodGroup: str | None = None
    addressLine1: str | None = None
    addressCity: str | None = None
    addressState: str | None = None
    addressPostalCode: str | None = None
    addressCountry: str | None = None
    uan: str | None = None
    panNumber: str | None = None
    aadhaarNumber: str | None = None
    pfNumber: str | None = None
    esiNumber: str | None = None
    bankName: str | None = None
    ifscCode: str | None = None
    accountNumber: str | None = None
    accountHolderName: str | None = None
    upiId: str | None = None
    bankVerificationStatus: str | None = None


def _date_str(d) -> str:
    if d is None:
        return ""
    return str(d)[:10] if hasattr(d, "__str__") else ""


def _staff_row(row) -> dict:
    return {
        "id": row["id"],
        "employeeId": row.get("employee_id") or "",
        "name": row.get("name") or "",
        "email": row.get("email") or "",
        "phone": row.get("phone") or "",
        "company": row.get("company_name") or "",
        "designation": row.get("designation") or "",
        "department": row.get("department") or "",
        "status": (row.get("status") or "active").lower(),
        "joiningDate": _date_str(row.get("joining_date")),
        "roleId": row.get("rbac_role_id"),
        "roleName": row.get("role_name"),
        "userId": row.get("user_id"),
        "branchId": row.get("branch_id"),
        "branchName": row.get("branch_name"),
        "attendanceModalId": row.get("attendance_modal_id"),
        "shiftModalId": row.get("shift_modal_id"),
        "leaveModalId": row.get("leave_modal_id"),
        "holidayModalId": row.get("holiday_modal_id"),
        "staffType": row.get("staff_type") or "",
        "reportingManager": row.get("reporting_manager") or "",
        "salaryCycle": row.get("salary_cycle") or "",
        "grossSalary": row.get("gross_salary"),
        "netSalary": row.get("net_salary"),
        "gender": row.get("gender") or "",
        "dob": _date_str(row.get("dob")),
        "maritalStatus": row.get("marital_status") or "",
        "bloodGroup": row.get("blood_group") or "",
        "addressLine1": row.get("address_line1") or "",
        "addressCity": row.get("address_city") or "",
        "addressState": row.get("address_state") or "",
        "addressPostalCode": row.get("address_postal_code") or "",
        "addressCountry": row.get("address_country") or "",
        "uan": row.get("uan") or "",
        "panNumber": row.get("pan") or "",
        "aadhaarNumber": row.get("aadhaar") or "",
        "pfNumber": row.get("pf_number") or "",
        "esiNumber": row.get("esi_number") or "",
        "bankName": row.get("bank_name") or "",
        "ifscCode": row.get("ifsc_code") or "",
        "accountNumber": row.get("account_number") or "",
        "accountHolderName": row.get("account_holder_name") or "",
        "upiId": row.get("upi_id") or "",
        "bankVerificationStatus": row.get("bank_verification_status") or "",
    }


def _staff_select_cols():
    return """s.id, s.employee_id, s.name, s.email, s.phone, s.designation, s.department,
                       s.status, s.joining_date, s.branch_id,
                       s.attendance_modal_id, s.shift_modal_id, s.leave_modal_id, s.holiday_modal_id,
                       s.staff_type, s.reporting_manager, s.salary_cycle, s.gross_salary, s.net_salary,
                       s.gender, s.dob, s.marital_status, s.blood_group,
                       s.address_line1, s.address_city, s.address_state, s.address_postal_code, s.address_country,
                       s.uan, s.pan, s.aadhaar, s.pf_number, s.esi_number,
                       s.bank_name, s.ifsc_code, s.account_number, s.account_holder_name, s.upi_id, s.bank_verification_status,
                       u.id AS user_id, u.rbac_role_id, rr.name AS role_name,
                       COALESCE(c.name, '') AS company_name,
                       b.id AS branch_id_big, b.branch_name"""


def _list_staff_sql(company_id, branch_id=None, department=None, joining_date_from=None, joining_date_to=None):
    """Build SQL and params for staff list with optional filters."""
    join_branch = " LEFT JOIN branches b ON (b.id::text = s.branch_id OR (s.branch_id IS NOT NULL AND b.id = NULLIF(TRIM(s.branch_id), '')::int)) AND b.company_id = s.company_id"
    select = """
                SELECT """ + _staff_select_cols() + """
                FROM staff s
                LEFT JOIN companies c ON (c.id = s.company_id) OR (c.mongo_id = s.business_id) OR (c.id::text = s.business_id)
                LEFT JOIN users u ON u.company_id_bigint = s.company_id AND LOWER(u.email) = LOWER(s.email)
                LEFT JOIN rbac_roles rr ON rr.id = u.rbac_role_id
    """ + join_branch
    where = " WHERE s.company_id = %s OR (c.id = %s AND (c.mongo_id = s.business_id OR c.id::text = s.business_id))"
    params = [company_id, company_id]
    if branch_id is not None:
        where += " AND (b.id = %s OR s.branch_id = %s)"
        params.extend([branch_id, str(branch_id)])
    if department:
        where += " AND LOWER(TRIM(s.department)) = LOWER(TRIM(%s))"
        params.append(department)
    if joining_date_from:
        where += " AND s.joining_date >= %s::date"
        params.append(joining_date_from)
    if joining_date_to:
        where += " AND s.joining_date <= %s::date"
        params.append(joining_date_to)
    return select + where + " ORDER BY s.name", params


@router.get("")
def list_staff(
    search: str | None = None,
    tab: str = "all",
    department: str | None = None,
    joiningDateFrom: str | None = None,
    joiningDateTo: str | None = None,
    branchId: int | None = None,
    current_user: dict = Depends(require_permission("user.view")),
):
    """List staff. Super Admin: all companies. Company Admin: own company only. Filter by department, joining date, branch."""
    company_id = current_user.get("company_id")
    if company_id:
        sql, params = _list_staff_sql(company_id, branch_id=branchId, department=department, joining_date_from=joiningDateFrom, joining_date_to=joiningDateTo)
        with get_cursor() as cur:
            cur.execute(sql, params)
            rows = cur.fetchall()
    else:
        with get_cursor() as cur:
            cur.execute(
                """
                SELECT """ + _staff_select_cols() + """
                FROM staff s
                LEFT JOIN companies c ON (c.mongo_id = s.business_id) OR (c.id::text = s.business_id) OR (c.id = s.company_id)
                LEFT JOIN users u ON u.company_id_bigint = s.company_id AND LOWER(u.email) = LOWER(s.email)
                LEFT JOIN rbac_roles rr ON rr.id = u.rbac_role_id
                LEFT JOIN branches b ON (b.id::text = s.branch_id OR (s.branch_id IS NOT NULL AND b.id = NULLIF(TRIM(s.branch_id), '')::int)) AND b.company_id = s.company_id
                ORDER BY s.name
                """
            )
            rows = cur.fetchall()
        if branchId is not None or department or joiningDateFrom or joiningDateTo:
            # Post-filter for Super Admin (no company scope)
            if branchId is not None:
                rows = [r for r in rows if (r.get("branch_id") == str(branchId) or r.get("branch_id_big") == branchId)]
            if department:
                rows = [r for r in rows if (r.get("department") or "").strip().lower() == department.strip().lower()]
            if joiningDateFrom:
                try:
                    from datetime import datetime
                    d = datetime.strptime(joiningDateFrom[:10], "%Y-%m-%d").date()
                    rows = [r for r in rows if r.get("joining_date") and r.get("joining_date") >= d]
                except Exception:
                    pass
            if joiningDateTo:
                try:
                    from datetime import datetime
                    d = datetime.strptime(joiningDateTo[:10], "%Y-%m-%d").date()
                    rows = [r for r in rows if r.get("joining_date") and r.get("joining_date") <= d]
                except Exception:
                    pass

    staff = []
    for r in rows:
        r["branch_id"] = r.get("branch_id_big") or (int(r["branch_id"]) if r.get("branch_id") and str(r.get("branch_id")).isdigit() else None)
        r["branch_name"] = r.get("branch_name")
        staff.append(_staff_row(r))

    if search:
        s = search.lower()
        staff = [
            st
            for st in staff
            if (st["name"] or "").lower().find(s) >= 0
            or (st["company"] or "").lower().find(s) >= 0
            or (st["department"] or "").lower().find(s) >= 0
            or (st.get("branchName") or "").lower().find(s) >= 0
        ]
    if tab == "active":
        staff = [st for st in staff if st["status"] == "active"]
    elif tab == "inactive":
        staff = [st for st in staff if st["status"] != "active"]

    return {"staff": staff}


@router.get("/limits")
def get_staff_limits(
    current_user: dict = Depends(get_current_user),
):
    """Return license usage for company (staff count, branches, license active). Company Admin only. max_users = max staff allowed."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"currentUsers": 0, "maxUsers": None, "currentBranches": 0, "maxBranches": None, "licenseActive": True}
    with get_cursor() as cur:
        cur.execute(
            "SELECT COUNT(*) AS cnt FROM staff WHERE company_id = %s",
            (company_id,),
        )
        current_users = (cur.fetchone() or {}).get("cnt") or 0
        cur.execute(
            "SELECT COUNT(*) AS cnt FROM branches WHERE company_id = %s",
            (company_id,),
        )
        current_branches = (cur.fetchone() or {}).get("cnt") or 0
        cur.execute(
            "SELECT l.max_users, l.max_branches, l.status FROM licenses l WHERE l.company_id = %s LIMIT 1",
            (company_id,),
        )
        row = cur.fetchone()
    if not row:
        return {
            "currentUsers": current_users,
            "maxUsers": 0,
            "currentBranches": current_branches,
            "maxBranches": 0,
            "licenseActive": False,
        }
    status = (row.get("status") or "").lower()
    return {
        "currentUsers": current_users,
        "maxUsers": row.get("max_users"),
        "currentBranches": current_branches,
        "maxBranches": row.get("max_branches"),
        "licenseActive": status == "active",
    }


@router.get("/{staff_id}")
def get_staff(
    staff_id: int,
    current_user: dict = Depends(require_permission("user.view")),
):
    """Get a single staff by id."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT """ + _staff_select_cols() + """, s.company_id
            FROM staff s
            LEFT JOIN companies c ON c.id = s.company_id
            LEFT JOIN users u ON u.company_id_bigint = s.company_id AND LOWER(u.email) = LOWER(s.email)
            LEFT JOIN rbac_roles rr ON rr.id = u.rbac_role_id
            LEFT JOIN branches b ON (b.id::text = s.branch_id OR (s.branch_id IS NOT NULL AND b.id = NULLIF(TRIM(s.branch_id), '')::int)) AND b.company_id = s.company_id
            WHERE s.id = %s
            """,
            (staff_id,),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Staff not found")
    if company_id and row.get("company_id") != company_id:
        raise HTTPException(status_code=403, detail="Access denied")
    row["branch_id"] = row.get("branch_id_big") or (int(row["branch_id"]) if row.get("branch_id") and str(row.get("branch_id")).isdigit() else None)
    row["branch_name"] = row.get("branch_name")
    return _staff_row(row)


def _validate_staff_creation(current_user: dict, company_id: int, role_id: int) -> None:
    """Raise HTTPException if license inactive, staff limit reached, or role invalid. Limit is from plan (max_users = max staff)."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT l.id, l.status, l.max_users
            FROM licenses l
            WHERE l.company_id = %s
            LIMIT 1
            """,
            (company_id,),
        )
        lic = cur.fetchone()
    if not lic:
        raise HTTPException(status_code=400, detail="Company license not found.")
    if (lic.get("status") or "").lower() not in ("active",):
        raise HTTPException(status_code=400, detail="License is not active. Cannot add staff.")
    max_users = lic.get("max_users")
    if max_users is not None:  # NULL = unlimited
        with get_cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) AS cnt FROM staff WHERE company_id = %s",
                (company_id,),
            )
            current = (cur.fetchone() or {}).get("cnt") or 0
        if current >= max_users:
            raise HTTPException(
                status_code=400,
                detail=f"Staff limit reached ({current}/{max_users}). Delete a staff to add another, or upgrade your plan.",
            )
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, company_id FROM rbac_roles WHERE id = %s",
            (role_id,),
        )
        role = cur.fetchone()
    if not role:
        raise HTTPException(status_code=400, detail="Role not found.")
    if role.get("company_id") is not None and role.get("company_id") != company_id:
        raise HTTPException(status_code=400, detail="Role does not belong to your company.")


@router.post("")
def create_staff(
    body: CreateStaffBody,
    current_user: dict = Depends(require_permission("user.create")),
):
    """Create staff (and optional login user). Validates license, user limit, role."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required.")
    email = (body.email or "").strip().lower()
    if not email:
        raise HTTPException(status_code=400, detail="Email is required.")
    _validate_staff_creation(current_user, company_id, body.roleId)

    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM users WHERE LOWER(email) = LOWER(%s) AND company_id_bigint = %s",
            (email, company_id),
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="A user with this email already exists in your company.")

    name = (body.fullName or "").strip() or email
    employee_id = (body.employeeId or "").strip()
    if not employee_id:
        with get_cursor() as cur:
            cur.execute("SELECT COUNT(*) AS c FROM staff WHERE company_id = %s", (company_id,))
            next_num = (cur.fetchone() or {}).get("c", 0) + 1
            employee_id = str(next_num)

    joining_date = None
    if body.joiningDate:
        try:
            joining_date = date.fromisoformat(body.joiningDate[:10])
        except Exception:
            pass
    dob_date = None
    if body.dob:
        try:
            dob_date = date.fromisoformat(body.dob[:10])
        except Exception:
            pass

    user_id_created = None
    if body.loginMethod == "password" and body.temporaryPassword:
        hashed = bcrypt.hashpw(
            body.temporaryPassword.encode("utf-8"),
            bcrypt.gensalt(rounds=12),
        ).decode("utf-8")
        with get_cursor() as cur:
            cur.execute(
                """
                INSERT INTO users (name, email, password, role, company_id_bigint, rbac_role_id, is_active, created_at, updated_at)
                VALUES (%s, %s, %s, 'staff', %s, %s, %s, NOW(), NOW())
                RETURNING id
                """,
                (name, email, hashed, company_id, body.roleId, body.status.lower() == "active"),
            )
            user_id_created = cur.fetchone()["id"]

    with get_cursor() as cur:
        branch_id_val = str(body.branchId) if body.branchId is not None else None
        cur.execute(
            """
            INSERT INTO staff (employee_id, name, email, phone, designation, department, status, joining_date, company_id, user_id, branch_id,
                attendance_modal_id, shift_modal_id, leave_modal_id, holiday_modal_id, staff_type, reporting_manager, salary_cycle, gross_salary, net_salary,
                gender, dob, marital_status, blood_group, address_line1, address_city, address_state, address_postal_code, address_country,
                uan, pan, aadhaar, pf_number, esi_number, bank_name, ifsc_code, account_number, account_holder_name, upi_id, bank_verification_status,
                created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            RETURNING id
            """,
            (
                employee_id,
                name,
                email,
                (body.phone or "").strip() or None,
                (body.designation or "").strip() or None,
                (body.department or "").strip() or None,
                (body.status or "active").lower(),
                joining_date,
                company_id,
                str(user_id_created) if user_id_created else None,
                branch_id_val,
                body.attendanceModalId,
                body.shiftModalId,
                body.leaveModalId,
                body.holidayModalId,
                (body.staffType or "").strip() or None,
                (body.reportingManager or "").strip() or None,
                (body.salaryCycle or "").strip() or None,
                body.grossSalary,
                body.netSalary,
                (body.gender or "").strip() or None,
                dob_date,
                (body.maritalStatus or "").strip() or None,
                (body.bloodGroup or "").strip() or None,
                (body.addressLine1 or "").strip() or None,
                (body.addressCity or "").strip() or None,
                (body.addressState or "").strip() or None,
                (body.addressPostalCode or "").strip() or None,
                (body.addressCountry or "").strip() or None,
                (body.uan or "").strip() or None,
                (body.panNumber or "").strip() or None,
                (body.aadhaarNumber or "").strip() or None,
                (body.pfNumber or "").strip() or None,
                (body.esiNumber or "").strip() or None,
                (body.bankName or "").strip() or None,
                (body.ifscCode or "").strip() or None,
                (body.accountNumber or "").strip() or None,
                (body.accountHolderName or "").strip() or None,
                (body.upiId or "").strip() or None,
                (body.bankVerificationStatus or "").strip() or None,
            ),
        )
        staff_row = cur.fetchone()
    staff_id = staff_row["id"]

    if not user_id_created and body.loginMethod == "password":
        # Create user without password (can use OTP later)
        hashed = bcrypt.hashpw(
            ("ChangeMe123!").encode("utf-8"),
            bcrypt.gensalt(rounds=12),
        ).decode("utf-8")
        with get_cursor() as cur:
            cur.execute(
                """
                INSERT INTO users (name, email, password, role, company_id_bigint, rbac_role_id, is_active, created_at, updated_at)
                VALUES (%s, %s, %s, 'staff', %s, %s, %s, NOW(), NOW())
                RETURNING id
                """,
                (name, email, hashed, company_id, body.roleId, body.status.lower() == "active"),
            )
            user_id_created = cur.fetchone()["id"]
            cur.execute(
                "UPDATE staff SET user_id = %s WHERE id = %s",
                (str(user_id_created), staff_id),
            )

    _audit_log(current_user["id"], company_id, "staff.create", "staff", str(staff_id))
    # Return full staff row (same shape as get_staff)
    with get_cursor() as cur:
        cur.execute(
            "SELECT " + _staff_select_cols() + " FROM staff s "
            "LEFT JOIN companies c ON c.id = s.company_id "
            "LEFT JOIN users u ON u.company_id_bigint = s.company_id AND LOWER(u.email) = LOWER(s.email) "
            "LEFT JOIN rbac_roles rr ON rr.id = u.rbac_role_id "
            "LEFT JOIN branches b ON (b.id::text = s.branch_id OR (s.branch_id IS NOT NULL AND b.id = NULLIF(TRIM(s.branch_id), '')::int)) AND b.company_id = s.company_id "
            "WHERE s.id = %s",
            (staff_id,),
        )
        row = cur.fetchone()
    if row:
        row["branch_id"] = row.get("branch_id_big") or (int(row["branch_id"]) if row.get("branch_id") and str(row.get("branch_id")).isdigit() else None)
        row["branch_name"] = row.get("branch_name")
    return _staff_row(row or {})


@router.patch("/{staff_id}")
def update_staff(
    staff_id: int,
    body: UpdateStaffBody,
    current_user: dict = Depends(require_permission("user.edit")),
):
    """Update staff and optionally linked user (role, status)."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, name, email, company_id, user_id FROM staff WHERE id = %s",
            (staff_id,),
        )
        staff = cur.fetchone()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found.")
    if company_id and staff.get("company_id") != company_id:
        raise HTTPException(status_code=403, detail="Access denied.")

    with get_cursor() as cur:
        if body.fullName is not None:
            cur.execute("UPDATE staff SET name = %s WHERE id = %s", (body.fullName.strip(), staff_id))
        if body.phone is not None:
            cur.execute("UPDATE staff SET phone = %s WHERE id = %s", (body.phone.strip() or None, staff_id))
        if body.department is not None:
            cur.execute("UPDATE staff SET department = %s WHERE id = %s", (body.department.strip() or None, staff_id))
        if body.designation is not None:
            cur.execute("UPDATE staff SET designation = %s WHERE id = %s", (body.designation.strip() or None, staff_id))
        if body.status is not None:
            status = body.status.lower()
            cur.execute("UPDATE staff SET status = %s WHERE id = %s", (status, staff_id))
            uid = staff.get("user_id")
            if uid is not None and str(uid).strip().isdigit():
                try:
                    cur.execute(
                        "UPDATE users SET is_active = %s WHERE id = %s",
                        (status == "active", int(uid)),
                    )
                except Exception:
                    pass
        if body.roleId is not None:
            cur.execute(
                "SELECT company_id FROM rbac_roles WHERE id = %s",
                (body.roleId,),
            )
            role = cur.fetchone()
            if not role:
                raise HTTPException(status_code=400, detail="Role not found.")
            if company_id and role.get("company_id") is not None and role.get("company_id") != company_id:
                raise HTTPException(status_code=403, detail="Role does not belong to your company.")
            uid = staff.get("user_id")
            if uid and str(uid).isdigit():
                cur.execute(
                    "UPDATE users SET rbac_role_id = %s WHERE id = %s",
                    (body.roleId, int(uid)),
                )
        if body.branchId is not None:
            cur.execute(
                "UPDATE staff SET branch_id = %s WHERE id = %s",
                (str(body.branchId) if body.branchId else None, staff_id),
            )
        if body.attendanceModalId is not None:
            cur.execute("UPDATE staff SET attendance_modal_id = %s WHERE id = %s", (body.attendanceModalId, staff_id))
        if body.shiftModalId is not None:
            cur.execute("UPDATE staff SET shift_modal_id = %s WHERE id = %s", (body.shiftModalId, staff_id))
        if body.leaveModalId is not None:
            cur.execute("UPDATE staff SET leave_modal_id = %s WHERE id = %s", (body.leaveModalId, staff_id))
        if body.holidayModalId is not None:
            cur.execute("UPDATE staff SET holiday_modal_id = %s WHERE id = %s", (body.holidayModalId, staff_id))
        if body.staffType is not None:
            cur.execute("UPDATE staff SET staff_type = %s WHERE id = %s", (body.staffType.strip() or None, staff_id))
        if body.reportingManager is not None:
            cur.execute("UPDATE staff SET reporting_manager = %s WHERE id = %s", (body.reportingManager.strip() or None, staff_id))
        if body.salaryCycle is not None:
            cur.execute("UPDATE staff SET salary_cycle = %s WHERE id = %s", (body.salaryCycle.strip() or None, staff_id))
        if body.grossSalary is not None:
            cur.execute("UPDATE staff SET gross_salary = %s WHERE id = %s", (body.grossSalary, staff_id))
        if body.netSalary is not None:
            cur.execute("UPDATE staff SET net_salary = %s WHERE id = %s", (body.netSalary, staff_id))
        if body.gender is not None:
            cur.execute("UPDATE staff SET gender = %s WHERE id = %s", (body.gender.strip() or None, staff_id))
        if body.dob is not None:
            dob_val = None
            try:
                dob_val = date.fromisoformat(body.dob[:10])
            except Exception:
                pass
            cur.execute("UPDATE staff SET dob = %s WHERE id = %s", (dob_val, staff_id))
        if body.maritalStatus is not None:
            cur.execute("UPDATE staff SET marital_status = %s WHERE id = %s", (body.maritalStatus.strip() or None, staff_id))
        if body.bloodGroup is not None:
            cur.execute("UPDATE staff SET blood_group = %s WHERE id = %s", (body.bloodGroup.strip() or None, staff_id))
        if body.addressLine1 is not None:
            cur.execute("UPDATE staff SET address_line1 = %s WHERE id = %s", (body.addressLine1.strip() or None, staff_id))
        if body.addressCity is not None:
            cur.execute("UPDATE staff SET address_city = %s WHERE id = %s", (body.addressCity.strip() or None, staff_id))
        if body.addressState is not None:
            cur.execute("UPDATE staff SET address_state = %s WHERE id = %s", (body.addressState.strip() or None, staff_id))
        if body.addressPostalCode is not None:
            cur.execute("UPDATE staff SET address_postal_code = %s WHERE id = %s", (body.addressPostalCode.strip() or None, staff_id))
        if body.addressCountry is not None:
            cur.execute("UPDATE staff SET address_country = %s WHERE id = %s", (body.addressCountry.strip() or None, staff_id))
        if body.uan is not None:
            cur.execute("UPDATE staff SET uan = %s WHERE id = %s", (body.uan.strip() or None, staff_id))
        if body.panNumber is not None:
            cur.execute("UPDATE staff SET pan = %s WHERE id = %s", (body.panNumber.strip() or None, staff_id))
        if body.aadhaarNumber is not None:
            cur.execute("UPDATE staff SET aadhaar = %s WHERE id = %s", (body.aadhaarNumber.strip() or None, staff_id))
        if body.pfNumber is not None:
            cur.execute("UPDATE staff SET pf_number = %s WHERE id = %s", (body.pfNumber.strip() or None, staff_id))
        if body.esiNumber is not None:
            cur.execute("UPDATE staff SET esi_number = %s WHERE id = %s", (body.esiNumber.strip() or None, staff_id))
        if body.bankName is not None:
            cur.execute("UPDATE staff SET bank_name = %s WHERE id = %s", (body.bankName.strip() or None, staff_id))
        if body.ifscCode is not None:
            cur.execute("UPDATE staff SET ifsc_code = %s WHERE id = %s", (body.ifscCode.strip() or None, staff_id))
        if body.accountNumber is not None:
            cur.execute("UPDATE staff SET account_number = %s WHERE id = %s", (body.accountNumber.strip() or None, staff_id))
        if body.accountHolderName is not None:
            cur.execute("UPDATE staff SET account_holder_name = %s WHERE id = %s", (body.accountHolderName.strip() or None, staff_id))
        if body.upiId is not None:
            cur.execute("UPDATE staff SET upi_id = %s WHERE id = %s", (body.upiId.strip() or None, staff_id))
        if body.bankVerificationStatus is not None:
            cur.execute("UPDATE staff SET bank_verification_status = %s WHERE id = %s", (body.bankVerificationStatus.strip() or None, staff_id))

    _audit_log(current_user["id"], company_id, "staff.edit", "staff", str(staff_id))
    with get_cursor() as cur:
        cur.execute(
            "SELECT " + _staff_select_cols() + " FROM staff s "
            "LEFT JOIN companies c ON c.id = s.company_id "
            "LEFT JOIN users u ON u.company_id_bigint = s.company_id AND LOWER(u.email) = LOWER(s.email) "
            "LEFT JOIN rbac_roles rr ON rr.id = u.rbac_role_id "
            "LEFT JOIN branches b ON (b.id::text = s.branch_id OR (s.branch_id IS NOT NULL AND b.id = NULLIF(TRIM(s.branch_id), '')::int)) AND b.company_id = s.company_id "
            "WHERE s.id = %s",
            (staff_id,),
        )
        row = cur.fetchone()
    if row:
        row["branch_id"] = row.get("branch_id_big") or (int(row["branch_id"]) if row.get("branch_id") and str(row.get("branch_id")).isdigit() else None)
        row["branch_name"] = row.get("branch_name")
    return _staff_row(row or staff)
