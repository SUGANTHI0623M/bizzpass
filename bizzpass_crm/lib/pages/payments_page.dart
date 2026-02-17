import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/payments_repository.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final PaymentsRepository _repo = PaymentsRepository();
  List<Payment> _payments = [];
  bool _loading = true;
  String? _error;
  String _search = '';

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
      final list = await _repo.fetchPayments(
        search: _search.trim().isEmpty ? null : _search.trim(),
      );
      if (mounted) {
        setState(() {
          _payments = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('PaymentsException: ', '');
        });
      }
    }
  }

  List<Payment> get _filtered => _payments
      .where((p) =>
          p.company.toLowerCase().contains(_search.toLowerCase()) ||
          p.companyEmail.toLowerCase().contains(_search.toLowerCase()) ||
          p.razorpayId.toLowerCase().contains(_search.toLowerCase()) ||
          p.plan.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final totalCaptured = _payments
        .where((p) => p.status == 'captured')
        .fold(0, (s, p) => s + p.amount);
    final totalRefunded = _payments
        .where((p) => p.status == 'refunded')
        .fold(0, (s, p) => s + p.amount);
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: 'Payments', subtitle: 'Track all payment transactions'),
          LayoutBuilder(builder: (ctx, c) {
            final crossCount = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                    icon: Icons.credit_card_rounded,
                    label: 'Total Captured',
                    value: fmtINR(totalCaptured),
                    accentColor: context.successColor.withOpacity(0.12)),
                StatCard(
                    icon: Icons.refresh_rounded,
                    label: 'Refunded',
                    value: fmtINR(totalRefunded),
                    accentColor: context.warningColor.withOpacity(0.12)),
                StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Transactions',
                    value: '${_payments.length}',
                    accentColor: context.infoColor.withOpacity(0.12)),
              ],
            );
          }),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              fontSize: 13, color: context.textSecondaryColor))),
                  TextButton(onPressed: _load, child: Text('Retry')),
                ],
              ),
            ),
          ],
          AppSearchBar(
              hint: 'Search by company, email, plan or payment ID...',
              onChanged: (v) => setState(() => _search = v)),
          if (_loading && _payments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else
            AppDataTable(
              columns: const [
                DataCol('Company'),
                DataCol('Email'),
                DataCol('Amount'),
                DataCol('Plan'),
                DataCol('Gateway'),
                DataCol('Method'),
                DataCol('Status'),
                DataCol('Razorpay ID'),
                DataCol('Date'),
              ],
              rows: filtered
                  .map((p) => DataRow(cells: [
                        DataCell(Text(p.company,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.textColor))),
                        DataCell(Text(p.companyEmail,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.textMutedColor))),
                        DataCell(Text(fmtINR(p.amount),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: context.textColor,
                                fontSize: 14))),
                        DataCell(Text(p.plan)),
                        DataCell(Text(
                            p.gateway[0].toUpperCase() + p.gateway.substring(1),
                            style:
                                TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(p.method.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.textMutedColor))),
                        DataCell(StatusBadge(status: p.status)),
                        DataCell(Text(p.razorpayId,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: context.textDimColor))),
                        DataCell(Text(p.paidAt)),
                      ]))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
