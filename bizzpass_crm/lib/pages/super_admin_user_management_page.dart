import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Super Admin: manage platform administrators. Admin-side settings.
class SuperAdminUserManagementPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onAddAdmin;

  const SuperAdminUserManagementPage({
    super.key,
    required this.onBack,
    this.onAddAdmin,
  });

  @override
  State<SuperAdminUserManagementPage> createState() =>
      _SuperAdminUserManagementPageState();
}

class _SuperAdminUserManagementPageState
    extends State<SuperAdminUserManagementPage> {
  bool _loading = false;

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
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SectionHeader(
                  title: 'User Management',
                  subtitle: 'Add and manage platform admin users',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Platform Administrators',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    if (widget.onAddAdmin != null)
                      TextButton.icon(
                        onPressed: _loading ? null : widget.onAddAdmin,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Admin'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  _buildPlaceholderContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 48,
              color: context.textMutedColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Platform administrator management',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add and manage super admin users who can access the admin CRM.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textMutedColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'API integration coming soon',
              style: TextStyle(
                fontSize: 12,
                color: context.textDimColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
