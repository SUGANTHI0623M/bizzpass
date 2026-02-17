"""Company Admin Dashboard API - Employee-focused dashboard data."""
from fastapi import APIRouter, Depends, Query
from datetime import datetime, date, timedelta
from config.database import get_cursor
from api.auth import get_current_company_admin

router = APIRouter(prefix="/company-dashboard", tags=["company-dashboard"])


@router.get("/overview")
def get_company_dashboard_overview(
    current_user: dict = Depends(get_current_company_admin),
):
    """Get comprehensive dashboard overview for company admin."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"error": "Company ID not found"}

    # Tenant schema uses business_id (VARCHAR); main DB may use company_id (BIGINT). Support both.
    company_ref = str(company_id) if company_id is not None else None
    with get_cursor() as cur:
        # Employee Analytics (staff: business_id or company_id)
        try:
            cur.execute(
                """
                SELECT 
                    COUNT(*) FILTER (WHERE status = 'active') as active_employees,
                    COUNT(*) FILTER (WHERE status = 'inactive') as inactive_employees,
                    COUNT(*) FILTER (WHERE joining_date >= CURRENT_DATE - INTERVAL '30 days') as hired_last_30_days,
                    COUNT(*) as total_employees
                FROM staff 
                WHERE (business_id = %s OR company_id = %s)
                """,
                (company_ref, company_id),
            )
            employee_stats = cur.fetchone() or {}
        except Exception:
            employee_stats = {}

        # Today's Attendance (join staff to filter by company; attendances has date, punch_in, punch_out, status)
        try:
            cur.execute(
                """
                SELECT 
                    COUNT(*) FILTER (WHERE a.status IN ('present', 'late', 'marked')) as present,
                    COUNT(*) FILTER (WHERE a.status = 'absent') as absent,
                    COUNT(*) FILTER (WHERE a.status = 'on_leave') as on_leave
                FROM attendances a
                LEFT JOIN staff s ON (s.id::text = a.employee_id OR s.mongo_id = a.employee_id OR a.employee_id::text = s.employee_id)
                WHERE a.date = CURRENT_DATE AND (s.business_id = %s OR s.company_id = %s)
                """,
                (company_ref, company_id),
            )
            today_attendance = cur.fetchone() or {}
        except Exception:
            today_attendance = {}

        # Total Exits
        try:
            cur.execute(
                """
                SELECT COUNT(*) as exits
                FROM staff 
                WHERE (business_id = %s OR company_id = %s) AND status = 'inactive'
                """,
                (company_ref, company_id),
            )
            exits = (cur.fetchone() or {}).get("exits", 0) or 0
        except Exception:
            exits = 0

        # Pending Approval Requests Count
        try:
            cur.execute(
                """
                SELECT COUNT(*) as pending_requests
                FROM attendances a
                LEFT JOIN staff s ON (s.id::text = a.employee_id OR s.mongo_id = a.employee_id OR a.employee_id::text = s.employee_id)
                WHERE a.date >= CURRENT_DATE - INTERVAL '7 days'
                AND a.status = 'pending'
                AND (s.business_id = %s OR s.company_id = %s)
                """,
                (company_ref, company_id),
            )
            pending_requests = (cur.fetchone() or {}).get("pending_requests", 0) or 0
        except Exception:
            pending_requests = 0

    return {
        "employeeAnalytics": {
            "active": int(employee_stats.get("active_employees", 0) or 0),
            "hired": int(employee_stats.get("hired_last_30_days", 0) or 0),
            "exits": int(exits),
            "total": int(employee_stats.get("total_employees", 0) or 0),
        },
        "todayAttendance": {
            "present": int(today_attendance.get("present", 0) or 0),
            "absent": int(today_attendance.get("absent", 0) or 0),
            "onLeave": int(today_attendance.get("on_leave", 0) or 0),
        },
        "pendingRequests": int(pending_requests),
    }


@router.get("/birthdays")
def get_upcoming_birthdays(
    current_user: dict = Depends(get_current_company_admin),
    days_ahead: int = Query(7, description="Number of days to look ahead"),
):
    """Get upcoming birthdays in the company."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"birthdays": []}

    company_ref = str(company_id) if company_id is not None else None
    with get_cursor() as cur:
        try:
            cur.execute(
                """
                SELECT id, name, dob, designation, avatar
                FROM staff
                WHERE (business_id = %s OR company_id = %s)
                AND status = 'active'
                AND dob IS NOT NULL
                ORDER BY EXTRACT(MONTH FROM dob), EXTRACT(DAY FROM dob)
                LIMIT 10
                """,
                (company_ref, company_id),
            )
            rows = cur.fetchall()
        except Exception:
            rows = []

    birthdays = []
    for r in rows:
        dob = r.get("dob")
        if dob:
            # Calculate days until birthday
            today = date.today()
            bday_this_year = date(today.year, dob.month, dob.day)
            if bday_this_year < today:
                bday_this_year = date(today.year + 1, dob.month, dob.day)
            days_until = (bday_this_year - today).days

            birthdays.append({
                "id": r["id"],
                "name": r.get("name", ""),
                "designation": r.get("designation", ""),
                "date": str(dob)[:10],
                "daysUntil": days_until,
                "avatar": r.get("avatar"),
            })

    return {"birthdays": birthdays}


@router.get("/upcoming-holidays")
def get_upcoming_holidays(
    current_user: dict = Depends(get_current_company_admin),
    limit: int = Query(5, description="Number of holidays to return"),
):
    """Get upcoming holidays for the company (office_holidays table; column is name, not holiday_name)."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"holidays": []}

    with get_cursor() as cur:
        try:
            cur.execute(
                """
                SELECT oh.id, oh.name as holiday_name, oh.date as holiday_date, 'office' as holiday_type
                FROM office_holidays oh
                WHERE oh.company_id = %s
                AND oh.date >= CURRENT_DATE
                ORDER BY oh.date
                LIMIT %s
                """,
                (company_id, limit),
            )
            rows = cur.fetchall()
        except Exception:
            rows = []

    holidays = []
    for r in rows:
        holiday_date = r.get("holiday_date")
        if holiday_date:
            days_until = (holiday_date - date.today()).days
            holidays.append({
                "id": r["id"],
                "name": r.get("holiday_name", ""),
                "date": str(holiday_date)[:10],
                "type": r.get("holiday_type", ""),
                "daysUntil": days_until,
            })

    return {"holidays": holidays}


@router.get("/shift-schedule")
def get_shift_schedule(
    current_user: dict = Depends(get_current_company_admin),
):
    """Get shift schedule information (shift_modals table; column is name)."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"shifts": []}

    company_ref = str(company_id)
    with get_cursor() as cur:
        try:
            cur.execute(
                """
                SELECT 
                    sm.id, 
                    sm.name as shift_name,
                    sm.start_time,
                    sm.end_time,
                    'regular' as shift_type,
                    COUNT(s.id) as staff_count
                FROM shift_modals sm
                LEFT JOIN staff s ON (s.shift_modal_id = sm.id OR s.attendance_template_id::text = sm.id::text) AND (s.business_id = %s OR s.company_id = %s)
                WHERE sm.company_id = %s
                GROUP BY sm.id, sm.name, sm.start_time, sm.end_time
                ORDER BY sm.start_time
                LIMIT 5
                """,
                (company_ref, company_id, company_id),
            )
            rows = cur.fetchall()
        except Exception:
            rows = []

    shifts = []
    for r in rows:
        start_time = r.get("start_time")
        end_time = r.get("end_time")
        
        # Format times
        start_str = str(start_time) if start_time else "00:00"
        end_str = str(end_time) if end_time else "00:00"
        
        shifts.append({
            "id": r["id"],
            "name": r.get("shift_name", ""),
            "startTime": start_str,
            "endTime": end_str,
            "type": r.get("shift_type", ""),
            "staffCount": int(r.get("staff_count", 0) or 0),
        })

    return {"shifts": shifts}


@router.get("/my-leaves")
def get_my_leaves(
    current_user: dict = Depends(get_current_company_admin),
):
    """Get leave balance and history for current user."""
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")

    if not company_id or not user_id:
        return {"leaves": []}

    company_ref = str(company_id)
    with get_cursor() as cur:
        staff_row = None
        try:
            cur.execute(
                """
                SELECT COALESCE(leave_modal_id, leave_template_id::bigint) as leave_modal_id
                FROM staff
                WHERE id = %s AND (business_id = %s OR company_id = %s)
                """,
                (user_id, company_ref, company_id),
            )
            staff_row = cur.fetchone()
        except Exception:
            pass

        leave_modal_id = (staff_row or {}).get("leave_modal_id") if staff_row else None
        leave_types = []

        if leave_modal_id:
            try:
                cur.execute(
                    """
                    SELECT lc.id, COALESCE(lc.category_name, lc.name) as category_name, lc.total_days, COALESCE(lc.carry_forward, FALSE) as carry_forward
                    FROM leave_categories lc
                    WHERE lc.leave_modal_id = %s OR lc.company_id = %s
                    """,
                    (leave_modal_id, company_id),
                )
                leave_types = cur.fetchall()
            except Exception:
                pass

        if not leave_types:
            try:
                cur.execute(
                    """
                    SELECT id, COALESCE(name, '') as category_name, NULL::int as total_days, FALSE as carry_forward
                    FROM leave_categories WHERE company_id = %s LIMIT 10
                    """,
                    (company_id,),
                )
                leave_types = cur.fetchall()
            except Exception:
                pass

        if not leave_types:
            leave_types = [
                {"id": 1, "category_name": "Casual Leave", "total_days": 12, "carry_forward": False},
                {"id": 2, "category_name": "Unpaid Leave", "total_days": 0, "carry_forward": False},
                {"id": 3, "category_name": "Leave without Pay", "total_days": 0, "carry_forward": False},
                {"id": 4, "category_name": "Medical Leave", "total_days": 10, "carry_forward": True},
            ]

    leaves = []
    for lt in leave_types:
        # For now, return available days (you can track used days in a separate table)
        leaves.append({
            "id": lt.get("id", 0),
            "type": lt.get("category_name", ""),
            "available": int(lt.get("total_days", 0) or 0),
            "used": 0,  # TODO: Calculate from leave applications
            "total": int(lt.get("total_days", 0) or 0),
        })

    return {"leaves": leaves}


@router.get("/approval-requests")
def get_approval_requests(
    current_user: dict = Depends(get_current_company_admin),
    request_type: str = Query("attendance", description="Type: attendance, overtime, expenses"),
):
    """Get approval requests for the manager/admin."""
    company_id = current_user.get("company_id")
    
    if not company_id:
        return {"requests": []}

    company_ref = str(company_id)
    requests = []
    
    with get_cursor() as cur:
        if request_type == "attendance":
            try:
                cur.execute(
                    """
                    SELECT 
                        a.id,
                        a.employee_id,
                        COALESCE(s.name, 'Unknown') as staff_name,
                        a.date as attendance_date,
                        a.punch_in as check_in_time,
                        a.punch_out as check_out_time,
                        a.status
                    FROM attendances a
                    LEFT JOIN staff s ON (s.id::text = a.employee_id OR s.mongo_id = a.employee_id OR a.employee_id::text = s.employee_id)
                    WHERE (s.business_id = %s OR s.company_id = %s)
                    AND a.date >= CURRENT_DATE - INTERVAL '7 days'
                    AND a.status = 'pending'
                    ORDER BY a.date DESC, a.punch_in DESC NULLS LAST
                    LIMIT 50
                    """,
                    (company_ref, company_id),
                )
                rows = cur.fetchall()
            except Exception:
                rows = []
            
            for r in rows:
                requests.append({
                    "id": r["id"],
                    "staffName": r.get("staff_name", ""),
                    "type": "attendance",
                    "date": str(r.get("attendance_date") or "")[:10],
                    "checkIn": str(r.get("check_in_time") or "")[:5] if r.get("check_in_time") else "",
                    "checkOut": str(r.get("check_out_time") or "")[:5] if r.get("check_out_time") else "",
                    "status": r.get("status", ""),
                })

    return {"requests": requests, "count": len(requests)}


@router.get("/announcements")
def get_announcements(
    current_user: dict = Depends(get_current_company_admin),
    limit: int = Query(10, description="Number of announcements"),
):
    """Get company announcements."""
    company_id = current_user.get("company_id")
    
    if not company_id:
        return {"announcements": []}

    with get_cursor() as cur:
        # Using notifications table for announcements
        cur.execute(
            """
            SELECT id, title, message, created_at, priority
            FROM notifications
            WHERE company_id = %s
            AND type IN ('announcement', 'info')
            ORDER BY created_at DESC
            LIMIT %s
            """,
            (company_id, limit),
        )
        rows = cur.fetchall()

    announcements = []
    for r in rows:
        created_at = r.get("created_at")
        date_str = str(created_at)[:10] if created_at else ""
        
        announcements.append({
            "id": r["id"],
            "title": r.get("title", ""),
            "message": r.get("message", ""),
            "date": date_str,
            "priority": r.get("priority", "normal"),
        })

    return {"announcements": announcements}


@router.get("/total-expenses")
def get_total_expenses(
    current_user: dict = Depends(get_current_company_admin),
    period: str = Query("month", description="Period: today, week, month, year"),
):
    """Get total expenses for the company."""
    company_id = current_user.get("company_id")
    
    if not company_id:
        return {"totalExpenses": 0, "currency": "INR"}

    # Map period to SQL interval
    interval_map = {
        "today": "0 days",
        "week": "7 days",
        "month": "30 days",
        "year": "365 days",
    }
    interval = interval_map.get(period, "30 days")

    with get_cursor() as cur:
        # Calculate from payments or a dedicated expenses table
        # For now, using payments as proxy
        if period == "today":
            sql = """
                SELECT COALESCE(SUM(total_amount), 0) as total
                FROM payments
                WHERE company_id = %s
                AND DATE(created_at) = CURRENT_DATE
                AND status = 'captured'
            """
        elif period == "week":
            sql = """
                SELECT COALESCE(SUM(total_amount), 0) as total
                FROM payments
                WHERE company_id = %s
                AND created_at >= CURRENT_DATE - INTERVAL '7 days'
                AND status = 'captured'
            """
        elif period == "year":
            sql = """
                SELECT COALESCE(SUM(total_amount), 0) as total
                FROM payments
                WHERE company_id = %s
                AND created_at >= CURRENT_DATE - INTERVAL '365 days'
                AND status = 'captured'
            """
        else:  # month
            sql = """
                SELECT COALESCE(SUM(total_amount), 0) as total
                FROM payments
                WHERE company_id = %s
                AND created_at >= CURRENT_DATE - INTERVAL '30 days'
                AND status = 'captured'
            """
        
        cur.execute(sql, (company_id,))
        result = cur.fetchone() or {}
        total = float(result.get("total", 0) or 0)

    return {
        "totalExpenses": round(total, 2),
        "currency": "INR",
        "period": period,
    }
