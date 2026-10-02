import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../state.dart';
import '../theme/bunk_theme.dart';

class BunkTodayButton extends ConsumerStatefulWidget {
  final int dayIndex;

  const BunkTodayButton({super.key, required this.dayIndex});

  @override
  ConsumerState<BunkTodayButton> createState() => _BunkTodayButtonState();
}

class _BunkTodayButtonState extends ConsumerState<BunkTodayButton> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleData = ref.watch(scheduleDataProvider);
    final classes = scheduleData.schedule[widget.dayIndex] ?? [];
    final classNames = classes.map((c) => c.name).toList();
    final classesCount = classNames.length;
    
    final dayBunks = ref.watch(bunkedProvider.select((b) => b[widget.dayIndex]));
    final bunkedCount = dayBunks == null ? 0 : classNames.where((s) => dayBunks.contains(s)).length;
    final isBunked = classesCount > 0 && classesCount == bunkedCount;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        
        final willBeBunked = !isBunked;
        if (willBeBunked) {
          _audioPlayer.play(AssetSource('bunk.mp3'));
        }
        
        ref
            .read(bunkedProvider.notifier)
            .toggleBunkWholeDay(widget.dayIndex, classNames);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isBunked ? BunkTheme.of(context).background : BunkTheme.of(context).black,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            isBunked ? 'BUNKED!' : 'BUNK!',
            key: ValueKey<bool>(isBunked),
            style: BunkTheme.of(context).button.copyWith(
              fontSize: 56,
              color: isBunked ? BunkTheme.of(context).black : BunkTheme.of(context).white,
            ),
          ),
        ),
      ),
    );
  }
}
