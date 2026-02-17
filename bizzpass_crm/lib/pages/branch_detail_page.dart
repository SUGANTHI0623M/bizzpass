import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/branches_repository.dart';

/// Full-page branch details. Shown when user taps a branch row.
/// Sidebar remains (handled by parent shell).
class BranchDetailPage extends StatelessWidget {
  final Branch branch;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onStatusChanged;

  const BranchDetailPage({
    super.key,
    required this.branch,
    required this.onBack,
    this.onEdit,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title row
          Row(
            children: [
              IconButton.filled(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Back to branches',
                style: IconButton.styleFrom(
                  backgroundColor: context.cardHoverColor,
                  foregroundColor: context.textColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Branch details',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Main card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Head office chips at top
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _statusChip(context, 'Status', branch.isActive ? 'Active' : 'Inactive',
                        branch.isActive ? context.successColor : context.textMutedColor),
                    _statusChip(context, 'Head office', branch.isHeadOffice ? 'Yes' : 'No',
                        branch.isHeadOffice ? context.accentColor : context.textMutedColor),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                // Address section – show all parts
                Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: context.textMutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardHoverColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_addrLine(branch.addressAptBuilding) != null)
                        _addressLine(context, 'Apt / Building', _addrLine(branch.addressAptBuilding)!),
                      if (_addrLine(branch.addressStreet) != null)
                        _addressLine(context, 'Street', _addrLine(branch.addressStreet)!),
                      if (_addrLine(branch.addressCity) != null)
                        _addressLine(context, 'City', _addrLine(branch.addressCity)!),
                      if (_addrLine(branch.addressState) != null)
                        _addressLine(context, 'State', _addrLine(branch.addressState)!),
                      if (_addrLine(branch.addressZip) != null)
                        _addressLine(context, 'ZIP', _addrLine(branch.addressZip)!),
                      if (_addrLine(branch.addressCountry) != null)
                        _addressLine(context, 'Country', _addrLine(branch.addressCountry)!),
                      if (branch.fullAddress == '—')
                        Text(
                          '—',
                          style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Details grid
                _gridWrap(context, [
                  DetailTile(label: 'BRANCH NAME', value: branch.branchName),
                  DetailTile(label: 'CODE', value: branch.branchCode),
                  DetailTile(label: 'CONTACT', value: branch.contactNumber ?? '—'),
                  if (branch.createdAt != null && branch.createdAt!.isNotEmpty)
                    DetailTile(label: 'CREATED AT', value: _formatCreatedAt(branch.createdAt!)),
                  if (branch.latitude != null && branch.longitude != null)
                    DetailTile(
                      label: 'LOCATION (LAT, LONG)',
                      value: '${branch.latitude!.toStringAsFixed(6)}, ${branch.longitude!.toStringAsFixed(6)}',
                      mono: true,
                    ),
                  if (branch.attendanceRadiusM != null)
                    DetailTile(
                      label: 'ATTENDANCE CHECK-IN RADIUS',
                      value: '${branch.attendanceRadiusM!.toInt()} m',
                    ),
                ]),
                const SizedBox(height: 28),
                const Divider(height: 1),
                const SizedBox(height: 20),
                // Actions
                Row(
                  children: [
                    if (onEdit != null)
                      FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit branch'),
                      ),
                    if (onEdit != null && onStatusChanged != null)
                      const SizedBox(width: 12),
                    if (onStatusChanged != null)
                      IconButton.filled(
                        onPressed: onStatusChanged,
                        icon: Icon(
                          branch.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                          size: 28,
                          color: branch.isActive ? context.accentColor : context.textMutedColor,
                        ),
                        tooltip: branch.isActive ? 'Deactivate' : 'Activate',
                        style: IconButton.styleFrom(
                          backgroundColor: context.cardHoverColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: context.textMutedColor),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _gridWrap(BuildContext context, List<Widget> tiles) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: tiles,
    );
  }

  static String? _addrLine(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  static String _formatCreatedAt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _addressLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: context.textSecondaryColor, height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textMutedColor,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
