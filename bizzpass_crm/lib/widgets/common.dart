import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// ─── Formatters ──────────────────────────────────────────────────────────────

String fmtINR(int paise) {
  final formatter =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return formatter.format(paise);
}

String fmtNumber(int n) => NumberFormat('#,##,###', 'en_IN').format(n);

// ─── Status Badge ────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  final bool large;
  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: large ? 12 : 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static _StatusConfig _statusConfig(BuildContext context, String status) {
    switch (status) {
      case 'active':
        return _StatusConfig(context.successColor, 'Active');
      case 'expired':
        return _StatusConfig(context.dangerColor, 'Expired');
      case 'expiring_soon':
        return _StatusConfig(context.warningColor, 'Expiring Soon');
      case 'suspended':
        return _StatusConfig(context.dangerColor, 'Suspended');
      case 'unassigned':
        return _StatusConfig(context.textMutedColor, 'Unassigned');
      case 'captured':
        return _StatusConfig(context.successColor, 'Captured');
      case 'refunded':
        return _StatusConfig(context.warningColor, 'Refunded');
      case 'failed':
        return _StatusConfig(context.dangerColor, 'Failed');
      case 'present':
        return _StatusConfig(context.successColor, 'Present');
      case 'absent':
        return _StatusConfig(context.dangerColor, 'Absent');
      case 'late':
        return _StatusConfig(context.warningColor, 'Late');
      case 'checked_in':
        return _StatusConfig(context.infoColor, 'Checked In');
      case 'checked_out':
        return _StatusConfig(context.textMutedColor, 'Checked Out');
      case 'expected':
        return _StatusConfig(context.warningColor, 'Expected');
      case 'inactive':
        return _StatusConfig(context.textMutedColor, 'Inactive');
      case 'sent':
        return _StatusConfig(context.infoColor, 'Sent');
      case 'delivered':
        return _StatusConfig(context.successColor, 'Delivered');
      case 'read':
        return _StatusConfig(context.textMutedColor, 'Read');
      case 'pending':
        return _StatusConfig(context.warningColor, 'Pending');
      case 'revoked':
        return _StatusConfig(context.dangerColor, 'Revoked');
      default:
        return _StatusConfig(context.textMutedColor, status);
    }
  }
}

class _StatusConfig {
  final Color color;
  final String label;
  const _StatusConfig(this.color, this.label);
}

// ─── Priority Dot ────────────────────────────────────────────────────────────

class PriorityDot extends StatelessWidget {
  final String priority;
  const PriorityDot({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case 'urgent':
        color = context.dangerColor;
        break;
      case 'high':
        color = context.warningColor;
        break;
      case 'normal':
        color = context.infoColor;
        break;
      default:
        color = context.textMutedColor;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? sub, trend;
  final bool trendUp;
  final Color accentColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.trend,
    this.trendUp = true,
    this.accentColor = const Color(0x1AA78BFA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: context.accentColor),
                ),
                if (trend != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: trendUp ? context.successColor : context.dangerColor,
                      ),
                      const SizedBox(width: 3),
                      Text(trend!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                trendUp ? context.successColor : context.dangerColor,
                          )),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                  letterSpacing: -0.5,
                  height: 1.1,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w500,
                )),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!,
                  style:
                      TextStyle(fontSize: 11, color: context.textDimColor)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final double? bottomPadding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding ?? 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                      letterSpacing: -0.3,
                    )),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textMutedColor,
                          fontWeight: FontWeight.w400,
                        )),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add_rounded, size: 16),
              label: Text(actionLabel!),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AppSearchBar({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 44,
        width: 380,
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(fontSize: 13, color: context.textColor),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(Icons.search_rounded,
                size: 18, color: context.textDimColor),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
        ),
      ),
    );
  }
}

// ─── Tab Bar ─────────────────────────────────────────────────────────────────

class AppTabBar extends StatelessWidget {
  final List<TabItem> tabs;
  final String active;
  final ValueChanged<String> onChanged;
  final double? marginBottom;

  const AppTabBar({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChanged,
    this.marginBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom ?? 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = active == t.id;
            return GestureDetector(
              onTap: () => onChanged(t.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? context.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : context.textMutedColor,
                        )),
                    if (t.count != null) ...[
                      const SizedBox(width: 6),
                      Text('(${t.count})',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isActive ? Colors.white70 : context.textDimColor,
                          )),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TabItem {
  final String id, label;
  final int? count;
  const TabItem({required this.id, required this.label, this.count});
}

// ─── Data Table ──────────────────────────────────────────────────────────────

class AppDataTable extends StatelessWidget {
  final List<DataCol> columns;
  final List<DataRow> rows;
  /// When false, checkbox column is hidden (e.g. when using row tap for navigation).
  final bool showCheckboxColumn;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.showCheckboxColumn = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 320),
            child: DataTable(
              showCheckboxColumn: showCheckboxColumn,
              headingRowColor: WidgetStateProperty.all(context.cardHoverColor),
              headingTextStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: context.textMutedColor,
              ),
              dataTextStyle:
                  TextStyle(fontSize: 13, color: context.textSecondaryColor),
              columnSpacing: 24,
              horizontalMargin: 16,
              dividerThickness: 0.5,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 60,
              columns: columns
                  .map((c) => DataColumn(
                        label: Text(c.label.toUpperCase()),
                      ))
                  .toList(),
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}

class DataCol {
  final String label;
  const DataCol(this.label);
}

// ─── Avatar Circle ───────────────────────────────────────────────────────────

class AvatarCircle extends StatelessWidget {
  final String name;
  final int seed;
  final double size;
  final bool round;

  const AvatarCircle({
    super.key,
    required this.name,
    this.seed = 0,
    this.size = 34,
    this.round = false,
  });

  @override
  Widget build(BuildContext context) {
    final hue = ((seed > 0 ? seed : name.hashCode) * 47 % 360).toDouble();
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: HSLColor.fromAHSL(1, hue, 0.5, 0.85).toColor(),
        borderRadius: BorderRadius.circular(round ? size / 2 : 10),
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
            color: HSLColor.fromAHSL(1, hue, 0.45, 0.35).toColor(),
          )),
    );
  }
}

// ─── Detail Row (for modals) ─────────────────────────────────────────────────

class DetailTile extends StatelessWidget {
  final String label, value;
  final bool mono;
  final Color? valueColor;

  const DetailTile({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardHoverColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: context.textDimColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? context.textSecondaryColor,
                fontFamily: mono ? 'monospace' : null,
                fontWeight: mono ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

// ─── Form Field Wrapper ──────────────────────────────────────────────────────

class FormFieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;

  const FormFieldWrapper({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textMutedColor,
                  letterSpacing: 0.3,
                )),
          ),
          child,
        ],
      ),
    );
  }
}

// ─── Info Metric (for modal stats) ───────────────────────────────────────────

class InfoMetric extends StatelessWidget {
  final String label, value;
  final Color? valueColor;

  const InfoMetric(
      {super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: valueColor ?? context.accentColor,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: context.textDimColor)),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, description;

  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: context.textDimColor),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textMutedColor,
                )),
            const SizedBox(height: 6),
            Text(description,
                style: TextStyle(fontSize: 13, color: context.textDimColor)),
          ],
        ),
      ),
    );
  }
}
