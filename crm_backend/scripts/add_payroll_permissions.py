"""
Add Payroll Permissions to RBAC System

This script adds the missing payroll permissions to the rbac_permissions table
and assigns them to the COMPANY_ADMIN role.

Run this script ONCE to fix the payroll permission bug.

Usage:
    python crm_backend/scripts/add_payroll_permissions.py
"""

import sys
import os

# Add crm_backend directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from config.database import get_connection


def add_payroll_permissions():
    """Add payroll permissions to master database and all tenant databases."""
    
    print("=" * 80)
    print("ADDING PAYROLL PERMISSIONS TO RBAC SYSTEM")
    print("=" * 80)
    
    # Connect to master database
    print("\n[1/3] Connecting to master database...")
    master_conn = get_connection(db_name="postgres")
    master_cur = master_conn.cursor()
    
    try:
        # Check if payroll permissions already exist
        master_cur.execute("""
            SELECT code FROM rbac_permissions 
            WHERE code IN ('payroll.view', 'payroll.write', 'payroll.approve')
        """)
        existing = [row[0] for row in master_cur.fetchall()]
        
        if len(existing) == 3:
            print("✅ Payroll permissions already exist in master database!")
            print(f"   Found: {', '.join(existing)}")
        else:
            print(f"⚠️  Found {len(existing)} of 3 permissions. Adding missing ones...")
            
            # Add missing permissions
            permissions = [
                ('payroll.view', 'payroll', 'View payroll data'),
                ('payroll.write', 'payroll', 'Create/Edit payroll'),
                ('payroll.approve', 'payroll', 'Approve payroll runs'),
            ]
            
            for code, module, description in permissions:
                if code not in existing:
                    master_cur.execute("""
                        INSERT INTO rbac_permissions (code, module, description)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (code) DO NOTHING
                    """, (code, module, description))
                    print(f"   ✅ Added: {code}")
            
            master_conn.commit()
            print("✅ Payroll permissions added to master database!")
        
        # Assign to COMPANY_ADMIN role
        print("\n[2/3] Assigning permissions to COMPANY_ADMIN role...")
        
        master_cur.execute("""
            SELECT id FROM rbac_roles WHERE code = 'COMPANY_ADMIN'
        """)
        admin_role = master_cur.fetchone()
        
        if not admin_role:
            print("⚠️  COMPANY_ADMIN role not found in master database!")
        else:
            admin_role_id = admin_role[0]
            print(f"   Found COMPANY_ADMIN role (ID: {admin_role_id})")
            
            # Get payroll permission IDs
            master_cur.execute("""
                SELECT id, code FROM rbac_permissions 
                WHERE code IN ('payroll.view', 'payroll.write', 'payroll.approve')
            """)
            permissions = master_cur.fetchall()
            
            for perm_id, code in permissions:
                master_cur.execute("""
                    INSERT INTO rbac_role_permissions (role_id, permission_id)
                    VALUES (%s, %s)
                    ON CONFLICT (role_id, permission_id) DO NOTHING
                """, (admin_role_id, perm_id))
                print(f"   ✅ Assigned: {code}")
            
            master_conn.commit()
            print("✅ Permissions assigned to COMPANY_ADMIN role!")
        
    except Exception as e:
        print(f"❌ Error in master database: {e}")
        master_conn.rollback()
        return False
    finally:
        master_cur.close()
        master_conn.close()
    
    # Now process tenant databases
    print("\n[3/3] Processing tenant databases...")
    
    try:
        # Get list of tenant databases
        postgres_conn = get_connection(db_name="postgres")
        postgres_cur = postgres_conn.cursor()
        
        postgres_cur.execute("""
            SELECT datname FROM pg_database 
            WHERE datname LIKE 'bizzpass_c_%'
            ORDER BY datname
        """)
        tenant_dbs = [row[0] for row in postgres_cur.fetchall()]
        
        postgres_cur.close()
        postgres_conn.close()
        
        if not tenant_dbs:
            print("   ℹ️  No tenant databases found (bizzpass_c_*)")
            return True
        
        print(f"   Found {len(tenant_dbs)} tenant database(s): {', '.join(tenant_dbs)}")
        
        success_count = 0
        for db_name in tenant_dbs:
            try:
                print(f"\n   Processing {db_name}...")
                tenant_conn = get_connection(db_name=db_name)
                tenant_cur = tenant_conn.cursor()
                
                # Add permissions
                permissions = [
                    ('payroll.view', 'payroll', 'View payroll data'),
                    ('payroll.write', 'payroll', 'Create/Edit payroll'),
                    ('payroll.approve', 'payroll', 'Approve payroll runs'),
                ]
                
                for code, module, description in permissions:
                    tenant_cur.execute("""
                        INSERT INTO rbac_permissions (code, module, description)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (code) DO NOTHING
                    """, (code, module, description))
                
                # Assign to COMPANY_ADMIN role
                tenant_cur.execute("""
                    SELECT id FROM rbac_roles WHERE code = 'COMPANY_ADMIN'
                """)
                admin_role = tenant_cur.fetchone()
                
                if admin_role:
                    admin_role_id = admin_role[0]
                    
                    tenant_cur.execute("""
                        SELECT id FROM rbac_permissions 
                        WHERE code IN ('payroll.view', 'payroll.write', 'payroll.approve')
                    """)
                    perm_ids = [row[0] for row in tenant_cur.fetchall()]
                    
                    for perm_id in perm_ids:
                        tenant_cur.execute("""
                            INSERT INTO rbac_role_permissions (role_id, permission_id)
                            VALUES (%s, %s)
                            ON CONFLICT (role_id, permission_id) DO NOTHING
                        """, (admin_role_id, perm_id))
                
                tenant_conn.commit()
                tenant_cur.close()
                tenant_conn.close()
                
                print(f"      ✅ {db_name} - Success!")
                success_count += 1
                
            except Exception as e:
                print(f"      ❌ {db_name} - Error: {e}")
                continue
        
        print(f"\n   📊 Results: {success_count}/{len(tenant_dbs)} databases updated successfully")
        
    except Exception as e:
        print(f"❌ Error processing tenant databases: {e}")
        return False
    
    print("\n" + "=" * 80)
    print("✅ PAYROLL PERMISSIONS SETUP COMPLETE!")
    print("=" * 80)
    print("\nNext steps:")
    print("1. Refresh your browser")
    print("2. Go to Roles & Permissions page")
    print("3. Verify payroll permissions are visible")
    print("4. Test accessing the Payroll page")
    print()
    
    return True


def verify_permissions():
    """Verify that payroll permissions were added successfully."""
    
    print("\n" + "=" * 80)
    print("VERIFICATION")
    print("=" * 80)
    
    try:
        conn = get_connection(db_name="postgres")
        cur = conn.cursor()
        
        # Check permissions exist
        cur.execute("""
            SELECT code, module, description 
            FROM rbac_permissions 
            WHERE module = 'payroll'
            ORDER BY code
        """)
        perms = cur.fetchall()
        
        if perms:
            print("\n✅ Payroll permissions in database:")
            for code, module, desc in perms:
                print(f"   - {code}: {desc}")
        else:
            print("\n⚠️  No payroll permissions found!")
            return False
        
        # Check COMPANY_ADMIN has permissions
        cur.execute("""
            SELECT r.code, p.code
            FROM rbac_roles r
            JOIN rbac_role_permissions rp ON rp.role_id = r.id
            JOIN rbac_permissions p ON p.id = rp.permission_id
            WHERE r.code = 'COMPANY_ADMIN' AND p.module = 'payroll'
            ORDER BY p.code
        """)
        assignments = cur.fetchall()
        
        if assignments:
            print("\n✅ COMPANY_ADMIN role has payroll permissions:")
            for role_code, perm_code in assignments:
                print(f"   - {perm_code}")
        else:
            print("\n⚠️  COMPANY_ADMIN role does NOT have payroll permissions!")
            return False
        
        cur.close()
        conn.close()
        
        print("\n✅ VERIFICATION PASSED!")
        return True
        
    except Exception as e:
        print(f"\n❌ Verification failed: {e}")
        return False


if __name__ == "__main__":
    print("\n")
    print("=" * 80)
    print(" " * 20 + "PAYROLL PERMISSIONS SETUP SCRIPT")
    print("=" * 80)
    print()
    
    # Run the script
    success = add_payroll_permissions()
    
    if success:
        # Verify
        verify_permissions()
        print("\n🎉 ALL DONE! Payroll module should now be accessible.")
    else:
        print("\n❌ Setup failed. Please check the errors above.")
        sys.exit(1)
