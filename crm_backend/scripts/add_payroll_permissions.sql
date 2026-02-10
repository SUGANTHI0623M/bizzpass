-- ============================================================================
-- ADD PAYROLL PERMISSIONS TO RBAC SYSTEM
-- ============================================================================
-- Run this SQL script in your PostgreSQL database to add the missing
-- payroll permissions that fix the "Permission required: payroll.write" error
-- ============================================================================

-- Step 1: Add the 3 new payroll permissions
INSERT INTO rbac_permissions (code, module, description)
VALUES 
    ('payroll.view', 'payroll', 'View payroll data'),
    ('payroll.write', 'payroll', 'Create/Edit payroll'),
    ('payroll.approve', 'payroll', 'Approve payroll runs')
ON CONFLICT (code) DO NOTHING;

-- Step 2: Assign these permissions to COMPANY_ADMIN role
INSERT INTO rbac_role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM rbac_roles r, rbac_permissions p
WHERE r.code = 'COMPANY_ADMIN' 
AND p.code IN ('payroll.view', 'payroll.write', 'payroll.approve')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERY
-- Run this to verify the permissions were added:
-- ============================================================================

SELECT 
    r.name as role_name,
    p.code as permission_code,
    p.description
FROM rbac_roles r
JOIN rbac_role_permissions rp ON rp.role_id = r.id
JOIN rbac_permissions p ON p.id = rp.permission_id
WHERE r.code = 'COMPANY_ADMIN' 
AND p.module = 'payroll'
ORDER BY p.code;

-- Expected output:
-- role_name      | permission_code    | description
-- ---------------+--------------------+------------------------
-- Company Admin  | payroll.approve    | Approve payroll runs
-- Company Admin  | payroll.view       | View payroll data
-- Company Admin  | payroll.write      | Create/Edit payroll

-- ============================================================================
-- IMPORTANT: Run this on ALL your databases!
-- ============================================================================
-- 1. Run on master database (bizzpass)
-- 2. Run on each tenant database (bizzpass_c_1, bizzpass_c_2, etc.)
-- ============================================================================
