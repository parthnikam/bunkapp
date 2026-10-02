import 'package:flutter/cupertino.dart';
import '../../../theme/bunk_theme.dart';
import '../../../widgets/bunk_button.dart';

class IntroPage extends StatelessWidget {
  final VoidCallback onNext;

  const IntroPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/bunk.png',
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'STAY ON TRACK.\nFREE AND OFFLINE',
                  style: BunkTheme.of(context).bodyBold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Smart attendance tracking\nmade simple.',
                  style: BunkTheme.of(context).caption.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(context, true),
              _buildDot(context, false),
            ],
          ),
          const SizedBox(height: 32),
          BunkButton(text: 'GET STARTED', onPressed: onNext),
        ],
      ),
    );
  }

  Widget _buildDot(BuildContext context, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: 24,
      decoration: BoxDecoration(
        color: active
            ? BunkTheme.of(context).black
            : BunkTheme.of(context).lightGrey,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
