"""Grace Resolution Service - Resolve grace config with priority: Staff > Department > Company > Shift."""

import json
from datetime import date
from typing import Optional


def _default_late_login() -> dict:
    return {
        "enabled": True,
        "graceMinutesPerDay": 10,
        "graceCountPerMonth": 3,
        "resetCycle": "MONTHLY",
        "graceType": "PER_OCCURRENCE",
        "weekStartDay": 1,
    }


def _default_early_logout() -> dict:
    return {
        "enabled": False,
        "graceMinutesPerDay": 0,
        "graceCountPerMonth": 0,
        "resetCycle": "MONTHLY",
        "graceType": "PER_OCCURRENCE",
        "weekStartDay": 1,
    }


def _parse_grace_config(gc) -> dict | None:
    """Parse grace_config from DB (dict or JSON string)."""
    if gc is None:
        return None
    if isinstance(gc, dict):
        return gc
    if isinstance(gc, str):
        try:
            return json.loads(gc) if gc.strip() else None
        except (json.JSONDecodeError, TypeError):
            return None
    return None


def resolve_grace_config(
    staff_fine_modal: dict | None,
    department_fine_modal: dict | None,
    company_grace_config: dict | None,
    shift_grace_minutes: int = 10,
) -> dict:
    """
    Resolve effective grace config with priority:
    Staff (fine_modal) > Department (fine_modal) > Company (payroll_settings.grace_config) > Shift default.

    Args:
        staff_fine_modal: Fine modal row for staff (or None)
        department_fine_modal: Fine modal row for department (or None)
        company_grace_config: grace_config from payroll_settings (or None)
        shift_grace_minutes: Fallback grace minutes from shift modal

    Returns:
        Effective grace_config dict with lateLogin and earlyLogout.
    """
    # Staff level - completely replaces lower levels
    if staff_fine_modal and staff_fine_modal.get("grace_config"):
        gc = _parse_grace_config(staff_fine_modal["grace_config"])
        if gc:
            return _merge_grace_config(gc, shift_grace_minutes)

    # Department level
    if department_fine_modal and department_fine_modal.get("grace_config"):
        gc = _parse_grace_config(department_fine_modal["grace_config"])
        if gc:
            return _merge_grace_config(gc, shift_grace_minutes)

    # Company level
    if company_grace_config:
        gc = _parse_grace_config(company_grace_config)
        if gc:
            return _merge_grace_config(gc, shift_grace_minutes)

    # Shift default
    return {
        "lateLogin": {**_default_late_login(), "graceMinutesPerDay": shift_grace_minutes},
        "earlyLogout": _default_early_logout(),
    }


def _merge_grace_config(gc: dict, shift_grace: int) -> dict:
    """Merge partial grace config with defaults."""
    late = gc.get("lateLogin")
    early = gc.get("earlyLogout")
    return {
        "lateLogin": {
            **_default_late_login(),
            **(late or {}),
            "graceMinutesPerDay": (late or {}).get("graceMinutesPerDay", shift_grace),
        },
        "earlyLogout": {
            **_default_early_logout(),
            **(early or {}),
        },
    }


def _cycle_start(reset_cycle: str, d: date, week_start_day: int = 1) -> date:
    """Return start of reset cycle for date d."""
    if reset_cycle == "MONTHLY":
        return date(d.year, d.month, 1)
    if reset_cycle == "WEEKLY":
        # week_start_day: 0=Sunday, 1=Monday
        wd = d.weekday()  # 0=Monday, 6=Sunday
        if week_start_day == 0:
            wd = (wd + 1) % 7  # Sunday = 0
        delta = wd
        from datetime import timedelta

        return d - timedelta(days=delta)
    # NEVER: treat as single unbounded period (use epoch or distant past)
    return date(1970, 1, 1)


def should_apply_grace(
    violation_type: str,  # LATE_LOGIN | EARLY_LOGOUT
    late_or_early_minutes: int,
    grace_config: dict,
    late_count_in_cycle: int,  # Count of late logins in current cycle BEFORE this violation
    attendance_status: str | None,
    is_leave_approved: bool = False,
) -> tuple[bool, str]:
    """
    Determine if grace applies for this violation.

    Rules:
    - Grace must NOT apply if attendance is HALF_DAY, ABSENT, or leave approved.
    - Check grace minutes and grace count per violation type.
    - late_count_in_cycle: number of late logins in current reset cycle BEFORE this one.

    Returns:
        (applies_grace, reason)
    """
    if attendance_status and attendance_status.upper() in ("HALF_DAY", "HALFDAY"):
        return False, "HALF_DAY"
    if attendance_status and attendance_status.upper() == "ABSENT":
        return False, "ABSENT"
    if is_leave_approved:
        return False, "LEAVE_APPROVED"

    rule_key = "lateLogin" if violation_type == "LATE_LOGIN" else "earlyLogout"
    rule = grace_config.get(rule_key) or _default_late_login() if rule_key == "lateLogin" else _default_early_logout()

    if not rule.get("enabled", True):
        return False, "DISABLED"

    grace_min = rule.get("graceMinutesPerDay", 0)
    grace_count = rule.get("graceCountPerMonth", 0)
    grace_type = rule.get("graceType", "PER_OCCURRENCE")

    # Per Occurrence: only grace minutes matter (each late within grace mins is ignored)
    if grace_type == "PER_OCCURRENCE":
        if late_or_early_minutes <= grace_min and late_count_in_cycle < grace_count:
            return True, "GRACE_APPLIED"
        return False, "EXCEEDED_GRACE"

    # Count-Based: first N late logins ignored regardless of minutes
    if grace_type == "COUNT_BASED":
        if late_count_in_cycle < grace_count:
            return True, "GRACE_APPLIED"
        return False, "EXCEEDED_COUNT"

    # Combined: must be within grace minutes AND within grace count
    if grace_type == "COMBINED":
        if late_or_early_minutes <= grace_min and late_count_in_cycle < grace_count:
            return True, "GRACE_APPLIED"
        return False, "EXCEEDED_COMBINED"

    return False, "UNKNOWN_TYPE"


def get_effective_grace_minutes(grace_config: dict, violation_type: str) -> int:
    """Return effective grace minutes for violation type."""
    rule_key = "lateLogin" if violation_type == "LATE_LOGIN" else "earlyLogout"
    rule = grace_config.get(rule_key) or {}
    return int(rule.get("graceMinutesPerDay", 0) or 0)


def get_reset_cycle(grace_config: dict, violation_type: str) -> str:
    """Return reset cycle for violation type: MONTHLY | WEEKLY | NEVER."""
    rule_key = "lateLogin" if violation_type == "LATE_LOGIN" else "earlyLogout"
    rule = grace_config.get(rule_key) or {}
    return (rule.get("resetCycle") or "MONTHLY").upper()
