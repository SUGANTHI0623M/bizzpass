import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ReportsPlaceholderPage extends StatelessWidget {
  const ReportsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Reports',
            subtitle: 'View and export reports',
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.analytics_rounded,
                    size: 64, color: context.textMutedColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Reports module',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'View reports and export data.',
                  style: TextStyle(
                      fontSize: 14, color: context.textSecondaryColor),
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
