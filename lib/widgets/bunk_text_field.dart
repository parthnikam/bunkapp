import 'package:flutter/cupertino.dart';
import '../theme/bunk_theme.dart';

class BunkTextField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final IconData prefixIcon;
  final bool isDropdown;
  final String? value;
  final VoidCallback? onTap;

  const BunkTextField({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.placeholder,
    this.controller,
    this.isDropdown = false,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: BunkTheme.of(context).bodyBold,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isDropdown ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: BunkTheme.of(context).white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BunkTheme.of(context).lightGrey),
            ),
            child: Row(
              children: [
                Icon(prefixIcon, color: BunkTheme.of(context).grey, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: isDropdown
                      ? Text(
                          value ?? placeholder ?? '',
                          style: value != null ? BunkTheme.of(context).body : BunkTheme.of(context).body.copyWith(color: BunkTheme.of(context).grey),
                        )
                      : CupertinoTextField(
                          controller: controller,
                          placeholder: placeholder,
                          placeholderStyle: BunkTheme.of(context).body.copyWith(color: BunkTheme.of(context).grey),
                          style: BunkTheme.of(context).body,
                          decoration: null, // removes default border
                          padding: EdgeInsets.zero,
                        ),
                ),
                if (isDropdown)
                  Icon(CupertinoIcons.chevron_down, color: BunkTheme.of(context).black, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
