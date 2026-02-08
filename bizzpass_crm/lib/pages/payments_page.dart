import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  String _search = '';

  List<Payment> get _filtered => payments.where((p) =>
    p.company.toLowerCase().contains(_search.toLowerCase()) ||
    p.razorpayId.toLowerCase().contains(_search.toLowerCase())
  ).toList();

  @override
  Widget build(BuildContext context) {
    final totalCaptured = payments.where((p) => p.status == 'captured').fold(0, (s, p) => s + p.amount);
    final totalRefunded = payments.where((p) => p.status == 'refunded').fold(0, (s, p) => s + p.amount);
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Payments', subtitle: 'Track all payment transactions'),

          LayoutBuilder(builder: (ctx, c) {
            final crossCount = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 14, crossAxisSpacing: 14,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(icon: Icons.credit_card_rounded, label: 'Total Captured', value: fmtINR(totalCaptured), accentColor: AppColors.success.withOpacity(0.12)),
                StatCard(icon: Icons.refresh_rounded, label: 'Refunded', value: fmtINR(totalRefunded), accentColor: AppColors.warning.withOpacity(0.12)),
                StatCard(icon: Icons.receipt_long_rounded, label: 'Transactions', value: '${payments.length}', accentColor: AppColors.info.withOpacity(0.12)),
              ],
            );
          }),

          const SizedBox(height: 24),
          AppSearchBar(hint: 'Search by company or Razorpay ID...', onChanged: (v) => setState(() => _search = v)),
          AppDataTable(
            columns: const [
              DataCol('Company'), DataCol('Amount'), DataCol('Plan'),
              DataCol('Gateway'), DataCol('Method'), DataCol('Status'),
              DataCol('Razorpay ID'), DataCol('Date'),
            ],
            rows: filtered.map((p) => DataRow(cells: [
              DataCell(Text(p.company, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text))),
              DataCell(Text(fmtINR(p.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 14))),
              DataCell(Text(p.plan)),
              DataCell(Text(p.gateway[0].toUpperCase() + p.gateway.substring(1), style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(p.method.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
              DataCell(StatusBadge(status: p.status)),
              DataCell(Text(p.razorpayId, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textDim))),
              DataCell(Text(p.paidAt)),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}
