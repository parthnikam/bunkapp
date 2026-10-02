import 'package:flutter/cupertino.dart';
import '../theme/bunk_theme.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? value;
  final Color? valueColor;
  final IconData? prefixIcon;
  final VoidCallback? onTap;
  final bool showBorder;

  const SettingsTile({
    super.key,
    required this.title,
    this.value,
    this.valueColor,
    this.prefixIcon,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: BunkTheme.of(context).lightGrey,
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: BunkTheme.of(context).black, size: 24),
              const SizedBox(width: 16),
            ],
            Expanded(child: Text(title, style: BunkTheme.of(context).body)),
            if (value != null) ...[
              Text(
                value!,
                style: BunkTheme.of(context).body.copyWith(
                  color: valueColor ?? BunkTheme.of(context).black,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              CupertinoIcons.chevron_right,
              color: BunkTheme.of(context).grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
