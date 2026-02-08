import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingsItem(Icons.shield_rounded, 'Security', 'OTP settings, password policies, session management'),
      _SettingsItem(Icons.credit_card_rounded, 'Payment Gateway', 'Razorpay / Stripe API keys and webhook configuration'),
      _SettingsItem(Icons.notifications_rounded, 'Notification Rules', 'Configure expiry reminders, email templates, channels'),
      _SettingsItem(Icons.receipt_long_rounded, 'Invoice Settings', 'Company details, GST info, invoice numbering format'),
      _SettingsItem(Icons.my_location_rounded, 'Geofence Defaults', 'Default radius, location accuracy requirements'),
      _SettingsItem(Icons.layers_rounded, 'Modules', 'Enable/disable modules per plan (Attendance, VMS, Payroll)'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Settings', subtitle: 'Platform configuration'),
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 700 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 100,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _buildSettingsCard(items[i]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(_SettingsItem item) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.title, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text,
                )),
                const SizedBox(height: 4),
                Text(item.desc, style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.4,
                ), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textDim),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title, desc;
  const _SettingsItem(this.icon, this.title, this.desc);
}
