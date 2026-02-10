import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/visitors_repository.dart';
import '../data/companies_repository.dart';

class VisitorsPage extends StatefulWidget {
  const VisitorsPage({super.key});

  @override
  State<VisitorsPage> createState() => _VisitorsPageState();
}

class _VisitorsPageState extends State<VisitorsPage> {
  final VisitorsRepository _repo = VisitorsRepository();
  final CompaniesRepository _companiesRepo = CompaniesRepository();
  List<Visitor> _visitors = [];
  List<Company> _companies = [];
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
      final v = await _repo.fetchVisitors();
      final c = await _companiesRepo.fetchCompanies();
      if (mounted) {
        setState(() {
          _visitors = v;
          _companies = c;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('VisitorsException: ', '').replaceAll('CompaniesException: ', '');
        });
      }
    }
  }

  void _showRegisterDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final visitorCompanyCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    int? selectedCompanyId;
    String? selectedIdProof;
    bool submitting = false;
    String? submitError;
    final companies = _companies.where((c) => c.isActive).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Register New Visitor', style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: context.textColor,
                      )),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, size: 20, color: context.textMutedColor),
                        style: IconButton.styleFrom(backgroundColor: context.cardHoverColor),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (submitError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: context.dangerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(submitError!, style: TextStyle(fontSize: 13, color: context.dangerColor)),
                        ),
                      ],
                      Row(children: [
                        Expanded(child: FormFieldWrapper(label: 'VISITOR NAME', child: TextFormField(
                          controller: nameCtrl,
                          style: TextStyle(fontSize: 13, color: context.textColor),
                          decoration: const InputDecoration(hintText: 'Full name'),
                        ))),
                        const SizedBox(width: 14),
                        Expanded(child: FormFieldWrapper(label: 'PHONE', child: TextFormField(
                          controller: phoneCtrl,
                          style: TextStyle(fontSize: 13, color: context.textColor),
                          decoration: const InputDecoration(hintText: '+91 XXXXX XXXXX'),
                        ))),
                      ]),
                      Row(children: [
                        Expanded(child: FormFieldWrapper(label: 'COMPANY', child: TextFormField(
                          controller: visitorCompanyCtrl,
                          style: TextStyle(fontSize: 13, color: context.textColor),
                          decoration: const InputDecoration(hintText: "Visitor's organization"),
                        ))),
                        const SizedBox(width: 14),
                        Expanded(child: FormFieldWrapper(
                          label: 'VISITING COMPANY',
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(),
                            dropdownColor: context.cardColor,
                            style: TextStyle(fontSize: 13, color: context.textColor),
                            hint: const Text('Select company...'),
                            value: selectedCompanyId,
                            items: companies.map((c) =>
                              DropdownMenuItem(value: c.id, child: Text(c.name)),
                            ).toList(),
                            onChanged: (v) => setDialogState(() => selectedCompanyId = v),
                          ),
                        )),
                      ]),
                      Row(children: [
                        Expanded(child: FormFieldWrapper(label: 'HOST EMPLOYEE', child: TextFormField(
                          controller: hostCtrl,
                          style: TextStyle(fontSize: 13, color: context.textColor),
                          decoration: const InputDecoration(hintText: 'Who are they meeting?'),
                        ))),
                        const SizedBox(width: 14),
                        Expanded(child: FormFieldWrapper(label: 'PURPOSE', child: TextFormField(
                          controller: purposeCtrl,
                          style: TextStyle(fontSize: 13, color: context.textColor),
                          decoration: const InputDecoration(hintText: 'Reason for visit'),
                        ))),
                      ]),
                      FormFieldWrapper(
                        label: 'ID PROOF TYPE',
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(),
                          dropdownColor: context.cardColor,
                          style: TextStyle(fontSize: 13, color: context.textColor),
                          hint: const Text('Select...'),
                          value: selectedIdProof,
                          items: const [
                            DropdownMenuItem(value: 'aadhaar', child: Text('Aadhaar')),
                            DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
                            DropdownMenuItem(value: 'dl', child: Text('Driving License')),
                            DropdownMenuItem(value: 'passport', child: Text('Passport')),
                          ],
                          onChanged: (v) => setDialogState(() => selectedIdProof = v),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: submitting ? null : () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: submitting ? null : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                setDialogState(() => submitError = 'Visitor name is required');
                                return;
                              }
                              if (selectedCompanyId == null) {
                                setDialogState(() => submitError = 'Please select a company');
                                return;
                              }
                              setDialogState(() {
                                submitting = true;
                                submitError = null;
                              });
                              try {
                                await _repo.registerVisitor(
                                  visitorName: name,
                                  visitorPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                  visitorCompany: visitorCompanyCtrl.text.trim().isEmpty ? null : visitorCompanyCtrl.text.trim(),
                                  companyId: selectedCompanyId!,
                                  hostName: hostCtrl.text.trim().isEmpty ? null : hostCtrl.text.trim(),
                                  purpose: purposeCtrl.text.trim().isEmpty ? null : purposeCtrl.text.trim(),
                                  idProofType: selectedIdProof,
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  _load();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Visitor registered'), backgroundColor: context.successColor),
                                  );
                                }
                              } catch (e) {
                                setDialogState(() {
                                  submitting = false;
                                  submitError = e.toString().replaceAll('VisitorsException: ', '');
                                });
                              }
                            },
                            child: submitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Register & Check In'),
                          ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _visitors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final checkedIn = _visitors.where((v) => v.status == 'checked_in').length;
    final expected = _visitors.where((v) => v.status == 'expected').length;
    final checkedOut = _visitors.where((v) => v.status == 'checked_out').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
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
                  Icon(Icons.info_outline_rounded, color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: context.textSecondaryColor))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          LayoutBuilder(builder: (ctx, c) {
            final crossCount = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 14, crossAxisSpacing: 14,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(icon: Icons.person_pin_circle_rounded, label: 'Checked In', value: '$checkedIn', accentColor: context.infoColor.withOpacity(0.12)),
                StatCard(icon: Icons.schedule_rounded, label: 'Expected', value: '$expected', accentColor: context.warningColor.withOpacity(0.12)),
                StatCard(icon: Icons.logout_rounded, label: 'Checked Out', value: '$checkedOut', accentColor: context.textMutedColor.withOpacity(0.12)),
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
            rows: _visitors.map((v) => DataRow(cells: [
              DataCell(Text(v.name, style: TextStyle(fontWeight: FontWeight.w600, color: context.textColor))),
              DataCell(Text(v.visitorCompany)),
              DataCell(Text(v.companyVisiting)),
              DataCell(Text(v.host)),
              DataCell(Text(v.purpose)),
              DataCell(StatusBadge(status: v.status)),
              DataCell(Text(v.badge, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: context.accentColor))),
              DataCell(Text(v.checkIn ?? '—', style: TextStyle(
                fontSize: 12, color: v.checkIn != null ? context.textMutedColor : context.textDimColor,
              ))),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}
