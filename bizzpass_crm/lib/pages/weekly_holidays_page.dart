import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Weekly Holidays configuration: weekly off pattern and attendance on weekly off.
/// Copy and layout aligned with web screenshots.
class WeeklyHolidaysPage extends StatefulWidget {
  final VoidCallback onBack;

  const WeeklyHolidaysPage({super.key, required this.onBack});

  @override
  State<WeeklyHolidaysPage> createState() => _WeeklyHolidaysPageState();
}

class _WeeklyHolidaysPageState extends State<WeeklyHolidaysPage> {
  int _selectedTab = 0; // 0 = Weekly Off, 1 = Attendance On Weekly Off
  String _pattern = 'odd_even'; // 'standard' | 'odd_even'

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                style: IconButton.styleFrom(
                  backgroundColor: context.successColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: SectionHeader(
                  title: 'Weekly Holidays',
                  subtitle: 'Configure weekly off and attendance on weekly off',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tabs: Weekly Off | Attendance On Weekly Off
          Row(
            children: [
              _TabChip(
                label: 'Weekly Off',
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Attendance On Weekly Off',
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_selectedTab == 0) _buildWeeklyOffContent(),
          if (_selectedTab == 1) _buildAttendanceOnWeeklyOffContent(),
        ],
      ),
    );
  }

  Widget _buildWeeklyOffContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Off Pattern',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose how weekly offs are calculated for your business.',
          style: TextStyle(
            fontSize: 13,
            color: context.textMutedColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _PatternOption(
          value: 'standard',
          groupValue: _pattern,
          title: 'Standard Pattern',
          subtitle: 'Select specific days of the week as weekly offs.',
          onTap: () => setState(() => _pattern = 'standard'),
        ),
        const SizedBox(height: 12),
        _PatternOption(
          value: 'odd_even',
          groupValue: _pattern,
          title: 'Odd/Even Saturday Pattern',
          subtitle:
              'Odd Saturdays are working days, Even Saturdays are off. All Sundays are off.',
          onTap: () => setState(() => _pattern = 'odd_even'),
        ),
        if (_pattern == 'odd_even') ...[
          const SizedBox(height: 20),
          _PatternDetailsBox(),
        ],
      ],
    );
  }

  Widget _buildAttendanceOnWeeklyOffContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance On Weekly Off',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure whether employees can mark attendance on weekly off days. This can be managed per attendance modal.',
            style: TextStyle(
              fontSize: 13,
              color: context.textMutedColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.borderColor : context.borderColor.withOpacity(0.6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? context.textColor : context.textMutedColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PatternOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? context.successColor : context.borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Radio<String>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: (_) => onTap(),
                  activeColor: context.successColor,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return context.successColor;
                    }
                    return context.successColor.withOpacity(0.6);
                  }),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textMutedColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternDetailsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.successColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Details:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 12),
          _Bullet(text: 'Odd Saturdays (1st, 3rd, 5th, etc.) are ', bold: 'working days'),
          SizedBox(height: 6),
          _Bullet(text: 'Even Saturdays (2nd, 4th, 6th, etc.) are ', bold: 'weekly off'),
          SizedBox(height: 6),
          _Bullet(text: 'All Sundays are ', bold: 'weekly off'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final String bold;

  const _Bullet({required this.text, required this.bold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: context.textMutedColor,
              height: 1.5,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: context.textMutedColor,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: text),
                  TextSpan(
                    text: bold,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
