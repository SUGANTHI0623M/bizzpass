import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class TasksPlaceholderPage extends StatelessWidget {
  const TasksPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Tasks',
            subtitle: 'Create, assign, and track tasks',
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.task_alt_rounded,
                    size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Tasks module',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create tasks, assign to staff, and update status.',
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
