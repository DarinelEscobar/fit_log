import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';

class ActiveSessionNotesCard extends StatelessWidget {
  const ActiveSessionNotesCard({
    required this.controller,
    required this.focusNode,
    required this.isVisible,
    required this.onToggleVisibility,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        if (!isVisible) {
          final hasNotes = controller.text.trim().isNotEmpty;
          return Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('active-session-notes-toggle'),
              onPressed: onToggleVisibility,
              style: OutlinedButton.styleFrom(
                foregroundColor: hasNotes
                    ? KineticNoirPalette.primary
                    : KineticNoirPalette.onSurfaceVariant,
                side: BorderSide(
                  color: (hasNotes
                          ? KineticNoirPalette.primary
                          : KineticNoirPalette.outlineVariant)
                      .withValues(alpha: 0.28),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                hasNotes
                    ? Icons.sticky_note_2_rounded
                    : Icons.edit_note_rounded,
                size: 18,
              ),
              label: Text(
                hasNotes ? 'SHOW NOTES' : 'NOTES',
                style: KineticNoirTypography.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: hasNotes
                      ? KineticNoirPalette.primary
                      : KineticNoirPalette.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          );
        }

        final isExpanded =
            focusNode.hasFocus || controller.text.trim().isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
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
              Row(
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
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('active-session-notes-hide'),
                    onPressed: () {
                      focusNode.unfocus();
                      onToggleVisibility();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: KineticNoirPalette.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.visibility_off_rounded, size: 16),
                    label: Text(
                      'HIDE',
                      style: KineticNoirTypography.body(
                        size: 10,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('active-session-notes'),
                controller: controller,
                focusNode: focusNode,
                minLines: isExpanded ? 4 : 2,
                maxLines: isExpanded ? 6 : 2,
                style: KineticNoirTypography.body(
                  size: 14,
                  weight: FontWeight.w600,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Write notes during the session...',
                  hintStyle: KineticNoirTypography.body(
                    size: 14,
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
