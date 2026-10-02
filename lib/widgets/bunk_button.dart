import 'package:flutter/cupertino.dart';
import '../theme/bunk_theme.dart';

class BunkButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showArrow;

  const BunkButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: BunkTheme.of(context).black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: BunkTheme.of(context).button),
            if (showArrow) ...[
              const SizedBox(width: 8),
              Icon(CupertinoIcons.arrow_right, color: BunkTheme.of(context).white, size: 24),
            ],
          ],
        ),
      ),
    );
  }
}
