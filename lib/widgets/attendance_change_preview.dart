import 'package:flutter/cupertino.dart';
import '../theme/bunk_theme.dart';

/// Before/after attendance on a subject card.
///
/// Not bunked: `current% → next%` (next in red). Bunked: only the live
/// percentage, in black. Wide screens lay this out in a row; narrow ones
/// stack it.
class AttendanceChangePreview extends StatelessWidget {
  final bool checked;
  final int currentPct;
  final int nextPct;

  const AttendanceChangePreview({
    super.key,
    required this.checked,
    required this.currentPct,
    required this.nextPct,
  });

  @override
  Widget build(BuildContext context) {
    final nextPctColor = checked
        ? BunkTheme.of(context).green
        : BunkTheme.of(context).red;

    final wide = MediaQuery.sizeOf(context).width >= 400;
    return wide
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    alignment: const Alignment(1.0, 0.0),
                    child: FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                  );
                },
                child: checked
                    ? const SizedBox(key: ValueKey('empty'))
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '$currentPct%',
                                style: BunkTheme.of(context).bodyBold,
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 4.0,
                              left: 12.0,
                              right: 12.0,
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_right,
                              size: 14,
                              color: BunkTheme.of(context).grey,
                            ),
                          ),
                        ],
                      ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    style: BunkTheme.of(context).bodyBold.copyWith(
                      color: checked
                          ? BunkTheme.of(context).black
                          : nextPctColor,
                    ),
                    child: Text('$nextPct%'),
                  ),
                ],
              ),
            ],
          )
        : SizedBox(
            height: 65,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.horizontal,
                          alignment: const Alignment(1.0, 0.0),
                          child: FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                        );
                      },
                  child: checked
                      ? const SizedBox(key: ValueKey('empty'))
                      : Column(
                          key: const ValueKey('content'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '$currentPct%',
                                  style: BunkTheme.of(context).bodyBold,
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                left: 12.0,
                                right: 12.0,
                              ),
                              child: Icon(
                                CupertinoIcons.arrow_down,
                                size: 14,
                                color: BunkTheme.of(context).grey,
                              ),
                            ),
                          ],
                        ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      style: BunkTheme.of(context).bodyBold.copyWith(
                        color: checked
                            ? BunkTheme.of(context).black
                            : nextPctColor,
                      ),
                      child: Text('$nextPct%'),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}
