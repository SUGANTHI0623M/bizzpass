import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/notifications_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsRepository _repo = NotificationsRepository();
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('NotificationsException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: 'Notifications',
              subtitle: 'Delivery tracking for all notifications'),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          AppDataTable(
            columns: const [
              DataCol(''),
              DataCol('Title'),
              DataCol('Company'),
              DataCol('Type'),
              DataCol('Channel'),
              DataCol('Status'),
              DataCol('Date'),
            ],
            rows: _notifications
                .map((n) => DataRow(cells: [
                      DataCell(PriorityDot(priority: n.priority)),
                      DataCell(Text(n.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text))),
                      DataCell(Text(n.company)),
                      DataCell(Text(
                        n.type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5),
                      )),
                      DataCell(
                          Text(_capitalize(n.channel.replaceAll('_', ' ')))),
                      DataCell(StatusBadge(status: n.status)),
                      DataCell(Text(n.createdAt)),
                    ]))
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
