import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SubscriptionPlaceholderPage extends StatelessWidget {
  const SubscriptionPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Subscription & Billing',
            subtitle: 'View plan usage and expiry (read-only)',
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.credit_card_rounded,
                    size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Subscription',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'View plan usage, expiry date, and trigger renewal.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
