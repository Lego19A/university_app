// ============================================================
// DRAGGABLE SESSION WIDGET - A draggable block representing
// a single lecture or lab session. The user drags this from
// the "pool" area onto the timetable grid.
//
// While dragging:
//   - The original position shows a ghosted placeholder.
//   - The drag feedback shows a semi-transparent card.
//   - The global draggedSessionProvider is set so the grid
//     can render guided DragTarget overlays at valid slots.
//
// On drag end/cancel:
//   - The draggedSessionProvider is cleared back to null.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';

class DraggableSessionWidget extends ConsumerWidget {
  final Session session;

  const DraggableSessionWidget({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<Session>(
      data: session,

      // -- Notify grid: drag started, render guided targets --
      onDragStarted: () {
        ref.read(draggedSessionProvider.notifier).state = session;
      },

      // -- Notify grid: drag completed (accepted by a target) --
      onDragCompleted: () {
        ref.read(draggedSessionProvider.notifier).state = null;
      },

      // -- Notify grid: drag canceled (not accepted) --
      onDraggableCanceled: (_, __) {
        ref.read(draggedSessionProvider.notifier).state = null;
      },

      // -- Feedback: What you see while dragging --
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.85,
          child: _SessionCardContent(session: session, width: 140),
        ),
      ),

      // -- ChildWhenDragging: Ghost left behind in the pool --
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _SessionCardContent(session: session),
      ),

      // -- Child: Normal resting state in the pool --
      child: _SessionCardContent(session: session),
    );
  }
}

// ============================================================
// _SessionCardContent - Shared card UI for all Draggable states.
// Shows subject code, session type badge, and duration.
// ============================================================
class _SessionCardContent extends StatelessWidget {
  final Session session;
  final double? width;

  const _SessionCardContent({required this.session, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: session.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: session.color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Subject code + type badge row --
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.subjectCode,
                style: AppTypography.header3.copyWith(
                  color: session.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: session.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  session.typeLabel,
                  style: AppTypography.caption.copyWith(
                    color: session.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // -- Duration label --
          Text(
            '${session.durationHours}hr',
            style: AppTypography.caption.copyWith(
              color: session.color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
