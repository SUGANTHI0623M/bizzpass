import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/staff_repository.dart';
import '../data/mock_data.dart' show Staff;

/// User Management: list of company admins (staff with portal login). Table, search, active/inactive.
/// Add Admin uses same details as staff; admins have all permissions (Company Admin role).
class UserManagementPage extends StatefulWidget {
  final VoidCallback onBack;
  /// Navigate to Add Admin screen (create admin with same form as staff, Company Admin role).
  final VoidCallback onAddAdmin;
  /// When set, tapping a row opens the staff details screen for that admin.
  final void Function(Staff)? onSelectAdmin;

  const UserManagementPage({
    super.key,
    required this.onBack,
    required this.onAddAdmin,
    this.onSelectAdmin,
  });

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final StaffRepository _repo = StaffRepository();
  List<Staff> _admins = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _tab = 'all';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchAdmins(
        search: _search.trim().isEmpty ? null : _search.trim(),
        tab: 'all',
      );
      if (!mounted) return;
      setState(() {
        _admins = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('StaffException: ', '');
        _loading = false;
      });
    }
  }

  List<Staff> get _filtered {
    if (_tab == 'all') return _admins;
    if (_tab == 'active') return _admins.where((s) => s.status == 'active').toList();
    return _admins.where((s) => s.status != 'active').toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Settings',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Company admins with portal access',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: widget.onAddAdmin,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Admin'),
                style: TextButton.styleFrom(
                  foregroundColor: context.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: context.warningColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!, style: TextStyle(color: context.textColor, fontSize: 13))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          AppTabBar(
            tabs: [
              TabItem(id: 'all', label: 'All', count: _admins.length),
              TabItem(
                  id: 'active',
                  label: 'Active',
                  count: _admins.where((s) => s.status == 'active').length),
              TabItem(
                  id: 'inactive',
                  label: 'Inactive',
                  count: _admins.where((s) => s.status != 'active').length),
            ],
            active: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          const SizedBox(height: 12),
          AppSearchBar(
            hint: 'Search by name, email, phone, department...',
            onChanged: (v) {
              setState(() => _search = v);
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                if (mounted) _load();
              });
            },
          ),
          const SizedBox(height: 16),
          if (_loading && _admins.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined,
                        size: 48, color: context.textMutedColor),
                    const SizedBox(height: 16),
                    Text(
                      _admins.isEmpty ? 'No admin users yet' : 'No admins match the current filters',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _admins.isEmpty
                          ? 'Add an admin to give them portal access with full permissions.'
                          : 'Try another tab or search.',
                      style: TextStyle(
                          fontSize: 14, color: context.textSecondaryColor),
                      textAlign: TextAlign.center,
                    ),
                    if (_admins.isEmpty) ...[
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: widget.onAddAdmin,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Admin'),
                        style: TextButton.styleFrom(
                          foregroundColor: context.accentColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: AppDataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataCol('Name'),
                  DataCol('Email'),
                  DataCol('Phone'),
                  DataCol('Role'),
                  DataCol('Status'),
                  DataCol('Joined'),
                ],
                rows: _filtered
                        .map((s) => DataRow(
                          cells: [
                            DataCell(
                              InkWell(
                                onTap: widget.onSelectAdmin != null
                                    ? () => widget.onSelectAdmin!(s)
                                    : null,
                                child: Row(
                                  children: [
                                    AvatarCircle(
                                        name: s.name, seed: s.id, round: true),
                                    const SizedBox(width: 10),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: context.textColor),
                                        ),
                                        if (s.designation.isNotEmpty)
                                          Text(
                                            s.designation,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: context.textDimColor),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: widget.onSelectAdmin != null
                                    ? () => widget.onSelectAdmin!(s)
                                    : null,
                                child: Text(s.email),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: widget.onSelectAdmin != null
                                    ? () => widget.onSelectAdmin!(s)
                                    : null,
                                child: Text(s.phone.isNotEmpty ? s.phone : '—'),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: widget.onSelectAdmin != null
                                    ? () => widget.onSelectAdmin!(s)
                                    : null,
                                child: Text(s.roleName ?? 'Company Admin'),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: widget.onSelectAdmin != null
                                    ? () => widget.onSelectAdmin!(s)
                                    : null,
                                child: StatusBadge(status: s.status),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: widget.onSelectAdmin != null
                                    ? () => widget.onSelectAdmin!(s)
                                    : null,
                                child: Text(s.joiningDate),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
