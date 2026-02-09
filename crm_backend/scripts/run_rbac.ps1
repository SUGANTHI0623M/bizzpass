# Run RBAC migration (roles, permissions, company admin user)
# Use when DB exists but RBAC tables/company admin are missing.
Set-Location $PSScriptRoot\..
$env:PYTHONPATH = (Get-Location).Path
python -m scripts.rbac_migration
