import 'package:flutter/material.dart';
import '../theme/bunk_theme.dart';

class ExpressiveProgressBar extends StatelessWidget {
  final String label;
  final double percentage; // E.g., 0.87 for 87%
  final Color baseColor;
  final Color textColor;

  const ExpressiveProgressBar({
    super.key,
    required this.label,
    required this.percentage,
    required this.baseColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // ponytail: minimum that works, no unrequested abstractions
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BunkTheme.of(context).bodyBold.copyWith(fontSize: 15.0),
            ),
          const SizedBox(height: 2.0),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percentage.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: val,
                        child: Container(
                          height: 6.0,
                          decoration: BoxDecoration(
                            color: BunkTheme.of(context).black,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  SizedBox(
                    width: 60.0,
                    child: Text(
                      '${(val * 100).toInt()}%',
                      style: BunkTheme.of(context).bodyBold.copyWith(
                        color: baseColor,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16.0),
          Divider(height: 1.0, thickness: 1.0, color: BunkTheme.of(context).lightGrey),
        ],
      ),
    );
  }
}
