import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class VisitorsPage extends StatelessWidget {
  const VisitorsPage({super.key});

  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Register New Visitor', style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text,
                      )),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                        style: IconButton.styleFrom(backgroundColor: AppColors.cardHover),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: FormFieldWrapper(label: 'VISITOR NAME', child: TextFormField(
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: const InputDecoration(hintText: 'Full name'),
                        ))),
                        const SizedBox(width: 14),
                        Expanded(child: FormFieldWrapper(label: 'PHONE', child: TextFormField(
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: const InputDecoration(hintText: '+91 XXXXX XXXXX'),
                        ))),
                      ]),
                      Row(children: [
                        Expanded(child: FormFieldWrapper(label: 'COMPANY', child: TextFormField(
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: const InputDecoration(hintText: "Visitor's organization"),
                        ))),
                        const SizedBox(width: 14),
                        Expanded(child: FormFieldWrapper(
                          label: 'VISITING COMPANY',
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(),
                            dropdownColor: AppColors.card,
                            style: const TextStyle(fontSize: 13, color: AppColors.text),
                            hint: const Text('Select company...'),
                            items: companies.where((c) => c.isActive).map((c) =>
                              DropdownMenuItem(value: c.name, child: Text(c.name)),
                            ).toList(),
                            onChanged: (_) {},
                          ),
                        )),
                      ]),
                      Row(children: [
                        Expanded(child: FormFieldWrapper(label: 'HOST EMPLOYEE', child: TextFormField(
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: const InputDecoration(hintText: 'Who are they meeting?'),
                        ))),
                        const SizedBox(width: 14),
                        Expanded(child: FormFieldWrapper(label: 'PURPOSE', child: TextFormField(
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: const InputDecoration(hintText: 'Reason for visit'),
                        ))),
                      ]),
                      FormFieldWrapper(
                        label: 'ID PROOF TYPE',
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(),
                          dropdownColor: AppColors.card,
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          hint: const Text('Select...'),
                          items: const [
                            DropdownMenuItem(value: 'aadhaar', child: Text('Aadhaar')),
                            DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
                            DropdownMenuItem(value: 'dl', child: Text('Driving License')),
                            DropdownMenuItem(value: 'passport', child: Text('Passport')),
                          ],
                          onChanged: (_) {},
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          const SizedBox(width: 10),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Register & Check In')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkedIn = visitors.where((v) => v.status == 'checked_in').length;
    final expected = visitors.where((v) => v.status == 'expected').length;
    final checkedOut = visitors.where((v) => v.status == 'checked_out').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Visitor Management',
            subtitle: 'Track visitors across all branches',
            actionLabel: 'Register Visitor',
            actionIcon: Icons.person_add_rounded,
            onAction: () => _showRegisterDialog(context),
          ),

          LayoutBuilder(builder: (ctx, c) {
            final crossCount = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 14, crossAxisSpacing: 14,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(icon: Icons.person_pin_circle_rounded, label: 'Checked In', value: '$checkedIn', accentColor: AppColors.info.withOpacity(0.12)),
                StatCard(icon: Icons.schedule_rounded, label: 'Expected', value: '$expected', accentColor: AppColors.warning.withOpacity(0.12)),
                StatCard(icon: Icons.logout_rounded, label: 'Checked Out', value: '$checkedOut', accentColor: AppColors.textMuted.withOpacity(0.12)),
              ],
            );
          }),

          const SizedBox(height: 24),
          AppDataTable(
            columns: const [
              DataCol('Visitor'), DataCol('From'), DataCol('Visiting'),
              DataCol('Host'), DataCol('Purpose'), DataCol('Status'),
              DataCol('Badge'), DataCol('Check In'),
            ],
            rows: visitors.map((v) => DataRow(cells: [
              DataCell(Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text))),
              DataCell(Text(v.visitorCompany)),
              DataCell(Text(v.companyVisiting)),
              DataCell(Text(v.host)),
              DataCell(Text(v.purpose)),
              DataCell(StatusBadge(status: v.status)),
              DataCell(Text(v.badge, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.accent))),
              DataCell(Text(v.checkIn ?? '—', style: TextStyle(
                fontSize: 12, color: v.checkIn != null ? AppColors.textMuted : AppColors.textDim,
              ))),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}
