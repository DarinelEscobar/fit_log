import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';

class ActiveSessionNotesCard extends StatelessWidget {
  const ActiveSessionNotesCard({
    required this.controller,
    required this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final isExpanded =
            focusNode.hasFocus || controller.text.trim().isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: KineticNoirPalette.surfaceLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: focusNode.hasFocus
                  ? KineticNoirPalette.primary.withValues(alpha: 0.35)
                  : KineticNoirPalette.outlineVariant.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SESSION NOTES',
                style: KineticNoirTypography.body(
                  size: 10,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('active-session-notes'),
                controller: controller,
                focusNode: focusNode,
                minLines: isExpanded ? 4 : 1,
                maxLines: isExpanded ? 6 : 1,
                style: KineticNoirTypography.body(
                  size: 15,
                  weight: FontWeight.w600,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Write notes during the session...',
                  hintStyle: KineticNoirTypography.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: KineticNoirPalette.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
