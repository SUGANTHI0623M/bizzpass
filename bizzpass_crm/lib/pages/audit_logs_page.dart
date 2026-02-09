import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/audit_logs_repository.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final AuditLogsRepository _repo = AuditLogsRepository();
  List<AuditLogEntry> _logs = [];
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
      final list = await _repo.fetchAuditLogs(limit: 100);
      if (mounted) {
        setState(() {
          _logs = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('AuditLogsException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Audit Logs',
            subtitle: 'Track staff, role, and system actions',
          ),
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
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          if (_loading && _logs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else
            AppDataTable(
              columns: const [
                DataCol('Action'),
                DataCol('Actor'),
                DataCol('Entity'),
                DataCol('Time'),
              ],
              rows: _logs
                  .map((l) => DataRow(
                        cells: [
                          DataCell(Text(l.action,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text))),
                          DataCell(Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.actorName ?? '—',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.text)),
                              if (l.actorEmail != null)
                                Text(l.actorEmail!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textDim)),
                            ],
                          )),
                          DataCell(Text(
                            [l.entityType, l.entityId]
                                .where((x) => x != null && x.isNotEmpty)
                                .join(' #'),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          )),
                          DataCell(Text(
                            l.createdAt ?? '—',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          )),
                        ],
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
