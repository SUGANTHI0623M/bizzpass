# BizzPass CRM - Comprehensive Payroll System

## Overview

The BizzPass Payroll System is a complete, production-ready payroll management solution with extensive customization options to support companies of all types and sizes.

## Features

### ✅ Implemented

1. **Flexible Salary Components**
   - Create custom earning and deduction components
   - Support for fixed amount, percentage-based, and formula-based calculations
   - Statutory and non-statutory components
   - Taxable/non-taxable configuration

2. **Comprehensive Payroll Settings**
   - Pay cycle configuration (monthly, bi-monthly, weekly)
   - Working days basis (26 days, 30 days, actual calendar days)
   - Leave policies (paid/unpaid leave types, encashment rules)
   - Attendance-based calculations (LOP, grace days, late penalties)
   - Overtime configuration (multipliers for weekday/weekend/holiday)
   - Statutory deductions (PF, ESI, PT, TDS) with customizable rates
   - Gratuity settings
   - Pro-rata calculations for joiners/exits
   - Arrears management
   - Location-based allowances

3. **Employee Salary Structures**
   - Individual salary breakdowns
   - Effective date management
   - Salary revision history
   - Component-level overrides

4. **Payroll Processing**
   - Monthly payroll run creation
   - Automatic salary calculation based on attendance and leaves
   - LOP (Loss of Pay) calculation
   - Overtime calculation
   - Statutory deduction calculation
   - Multi-step workflow (Draft → Calculate → Approve → Pay)

5. **Payroll Transactions (Payslips)**
   - Detailed earnings and deductions breakdown
   - Attendance summary
   - Leave summary
   - Payment tracking
   - Hold/freeze functionality

6. **Tax Management**
   - Employee tax declarations (80C, 80D, etc.)
   - Old vs New tax regime support
   - HRA exemption calculations
   - TDS calculation

7. **Reports & Analytics**
   - Payroll summary reports
   - Period-wise analysis
   - Department/branch-wise reports

## Database Schema

The payroll system uses the following main tables:

1. `salary_components` - Master list of earnings and deductions
2. `payroll_settings` - Company-wide payroll configuration
3. `employee_salary_structures` - Individual employee salary assignments
4. `payroll_runs` - Monthly payroll processing batches
5. `payroll_transactions` - Individual employee payslips
6. `payroll_arrears` - Salary revision arrears tracking
7. `payroll_holds` - Salary hold/freeze scenarios
8. `loan_installments` - Loan recovery tracking
9. `tax_declarations` - Employee tax saving declarations
10. `payroll_audit_log` - Complete audit trail

## Installation & Setup

### Step 1: Initialize Database Schema

Run the payroll schema initialization script for all tenant databases:

```bash
cd crm_backend
python scripts/init_payroll_schema.py
```

This will:
- Create all payroll tables
- Add necessary indexes for performance
- Seed default salary components (Basic, HRA, PF, ESI, etc.)

### Step 2: Verify Backend API

Ensure the backend is running:

```bash
cd crm_backend
python main.py
```

Check the API documentation at `http://localhost:8000/docs`

Payroll endpoints should be visible under the `payroll` tag.

### Step 3: Configure Payroll Settings

1. Log in to the CRM as Company Admin
2. Navigate to **Payroll → Settings**
3. Click **Configure Settings**
4. Fill in all required fields:
   - Pay cycle and working days
   - Leave policies
   - Attendance rules
   - Overtime settings
   - Statutory deduction rates
   - Other company-specific policies
5. Save the settings

### Step 4: Create Salary Components

1. Navigate to **Payroll → Components**
2. Review the default components
3. Add company-specific components as needed:
   - Click **Add Component**
   - Fill in details (name, type, calculation method)
   - Set taxability and statutory flags
   - Save

### Step 5: Assign Salary Structures to Employees

For each employee:
1. Go to **Staff** page
2. Select an employee
3. Navigate to **Salary** tab
4. Assign salary components
5. Save the structure

## Usage Guide

### Creating a Payroll Run

1. Navigate to **Payroll → Payroll Runs**
2. Click **New Payroll Run**
3. Select month and year
4. Add optional filters (department, branch)
5. Click **Create**

### Processing Payroll

1. Open the payroll run (status: Draft)
2. Click **Calculate** button
   - System will:
     - Fetch attendance data
     - Fetch leave data
     - Calculate LOP
     - Calculate overtime (if enabled)
     - Apply salary components
     - Calculate statutory deductions
     - Generate payslips for all employees
3. Review calculated payslips
4. Click **Approve** button
5. Mark as **Paid** after bank transfers are complete

### Viewing Payslips

1. Navigate to **Payroll → Payroll Runs**
2. Click **View** on any run
3. See all employee payslips
4. Download individual payslips (PDF generation to be implemented)

## Customization Guide

### Scenario 1: IT Company with Variable Pay

**Requirements:**
- Basic salary: 50% of CTC
- Variable pay: Based on performance
- No overtime

**Configuration:**
1. Add components:
   - Basic Salary (50% of gross)
   - HRA (40% of basic)
   - Performance Bonus (variable, manual input)
   - PF (12% of basic, capped at ₹1800)
   - TDS (calculated based on tax declarations)

2. Settings:
   - Working days: 26 days
   - Overtime: Disabled
   - Leave encashment: Enabled

### Scenario 2: Manufacturing Company with Overtime

**Requirements:**
- Shift-based work
- Overtime payment
- Holiday work compensation

**Configuration:**
1. Components:
   - Basic Salary (40% of gross)
   - DA (Dearness Allowance, 20% of basic)
   - Shift Allowance (₹2000 fixed)
   - OT Pay (calculated)
   - PF, ESI, PT

2. Settings:
   - Working days: 30 days
   - Overtime: Enabled
   - Weekday OT: 1.5x
   - Weekend OT: 2.0x
   - Holiday OT: 2.5x
   - Holiday work compensation: Double pay

### Scenario 3: Retail with Sales Commission

**Requirements:**
- Fixed salary + commission
- Tiered commission structure

**Configuration:**
1. Components:
   - Basic Salary (fixed)
   - Sales Commission (manual input based on performance)
   - PF, PT

2. Settings:
   - Working days: 26 days
   - Commission calculation: Manual (based on sales report)

### Scenario 4: Location-Based Allowances

**Requirements:**
- Different HRA for metro/non-metro cities

**Configuration:**
1. Enable location-based allowances in settings
2. Configure HRA rules:
   ```json
   {
     "mumbai": {"hra_percentage": 50},
     "delhi": {"hra_percentage": 50},
     "bangalore": {"hra_percentage": 40},
     "tier2": {"hra_percentage": 30}
   }
   ```
3. Assign employees to branches with location tags

## API Endpoints

### Salary Components
- `GET /payroll/components` - List all components
- `POST /payroll/components` - Create component
- `PATCH /payroll/components/{id}` - Update component
- `DELETE /payroll/components/{id}` - Delete component

### Payroll Settings
- `GET /payroll/settings` - Get company settings
- `POST /payroll/settings` - Save/update settings

### Salary Structures
- `GET /payroll/salary-structures` - List structures
- `POST /payroll/salary-structures` - Create structure

### Payroll Runs
- `GET /payroll/runs` - List all runs
- `GET /payroll/runs/{id}` - Get run details with transactions
- `POST /payroll/runs` - Create run
- `POST /payroll/runs/{id}/calculate` - Calculate payroll
- `POST /payroll/runs/{id}/approve` - Approve payroll

### Payroll Transactions
- `GET /payroll/transactions/{id}` - Get payslip details
- `PATCH /payroll/transactions/{id}` - Update transaction

### Tax Declarations
- `GET /payroll/tax-declarations` - List declarations
- `POST /payroll/tax-declarations` - Submit declaration

### Reports
- `GET /payroll/reports/summary` - Get summary report

## Performance Optimizations

The system is optimized for speed:

1. **Indexed Queries**: All frequently queried fields have indexes
2. **Batch Processing**: Payroll calculation processes multiple employees efficiently
3. **Caching**: Settings and components are cached per company
4. **Async Processing**: Long-running calculations can be moved to background tasks
5. **Connection Pooling**: Database connection pooling enabled

## Security

- All endpoints require authentication
- Permission-based access control (`payroll:read`, `payroll:write`, `payroll:approve`)
- Audit logging for all payroll operations
- Sensitive salary data encrypted at rest (to be implemented)

## Testing Checklist

### Backend Tests
- [x] Salary component CRUD operations
- [x] Payroll settings configuration
- [x] Salary structure creation
- [x] Payroll run calculation logic
- [x] LOP calculation
- [x] Statutory deduction calculation
- [x] API error handling

### Frontend Tests
- [x] Navigation to payroll pages
- [x] Component management UI
- [x] Settings configuration UI
- [x] Payroll run creation and processing
- [x] Payslip viewing
- [x] Error handling and user feedback

### Integration Tests
- [ ] End-to-end payroll flow (create → calculate → approve → pay)
- [ ] Attendance data integration
- [ ] Leave data integration
- [ ] Multi-company isolation
- [ ] Performance testing with large datasets

## Future Enhancements

1. **Payslip Generation**: PDF generation with company branding
2. **Bank File Generation**: NEFT/RTGS file formats
3. **Email Notifications**: Auto-send payslips to employees
4. **Employee Self-Service**: View payslips, download Form 16
5. **Advanced Reports**: Excel export, graphical dashboards
6. **Loan Management**: Complete loan lifecycle
7. **Bonus Calculation**: Automated bonus calculations
8. **Leave Encashment**: Automated encashment processing
9. **Form 16 Generation**: Annual tax statements
10. **Provident Fund Returns**: EPF monthly returns
11. **ESI Returns**: ESI monthly returns
12. **Professional Tax Returns**: State-wise PT filing
13. **Payroll Reversal**: Undo/modify processed payroll
14. **Multi-currency**: Support for international payroll

## Troubleshooting

### Issue: Payroll calculation fails
**Solution**: Check that:
- Payroll settings are configured
- Employee has a salary structure assigned
- Attendance data is available for the period

### Issue: Wrong LOP calculation
**Solution**: Verify:
- Working days basis in settings
- Leave types marked as paid/unpaid
- Attendance records are correct

### Issue: Statutory deduction incorrect
**Solution**: Check:
- PF/ESI rates in settings
- Wage ceilings configured correctly
- Employee salary exceeds threshold limits

## Support & Contribution

For issues or enhancements:
1. Check this documentation
2. Review the code comments
3. Contact the development team

## Version History

- **v1.0.0** (2026-02-10): Initial comprehensive payroll system release
  - Complete database schema
  - Backend APIs
  - Frontend UI with tabs
  - Salary component management
  - Payroll run processing
  - Basic reporting

---

**Developed by**: BizzPass Development Team  
**Last Updated**: February 10, 2026
