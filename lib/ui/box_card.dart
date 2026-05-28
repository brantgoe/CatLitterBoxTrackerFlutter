import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'flash.dart';
import 'theme.dart';
import 'time_formatting.dart';

class BoxCard extends ConsumerStatefulWidget {
  const BoxCard({
    super.key,
    required this.state,
    required this.onDeleteEvent,
    required this.onMaintenanceTap,
  });

  final BoxScreenState state;
  final void Function(CleaningEvent event) onDeleteEvent;
  final void Function(MaintenanceItem item) onMaintenanceTap;

  @override
  ConsumerState<BoxCard> createState() => _BoxCardState();
}

class _BoxCardState extends ConsumerState<BoxCard> {
  late int _now;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now().millisecondsSinceEpoch;
    _ticker = Ticker(_tick)..start();
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _now = DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final box = state.box;
    final last = state.lastCleaning;
    final elapsed = last == null ? null : _now - last.timestamp;
    final freshness = elapsed == null
        ? null
        : freshnessFor(
            elapsedMs: elapsed,
            warnHours: box.warnThresholdHours,
            overdueHours: box.overdueThresholdHours,
          );
    final borderColor = last == null
        ? AppColors.statusOverdue
        : freshness!.level == FreshnessLevel.ok
            ? Colors.transparent
            : freshness.color;
    final flash = last == null ||
        (freshness != null && freshness.level != FreshnessLevel.ok);

    return FlashPulse(
      enabled: flash,
      builder: (context, phase) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: flash
                  ? borderColor.withValues(alpha: phase)
                  : Colors.transparent,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                box.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(box),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _statusRow(box, last, elapsed, freshness, phase),
              const SizedBox(height: 16),
              _maintenanceSection(state),
              const SizedBox(height: 16),
              _historySection(state.history),
            ],
          ),
        );
      },
    );
  }

  String _subtitle(LitterBox box) {
    switch (box.typeKind) {
      case BoxTypeKind.manualScoop:
        return 'Manual scooping';
      case BoxTypeKind.automatic:
        final model = '${box.brand} ${box.model}'.trim();
        return model.isEmpty ? 'Automatic' : 'Automatic · $model';
    }
  }

  Widget _statusRow(
    LitterBox box,
    CleaningEvent? last,
    int? elapsed,
    Freshness? freshness,
    double phase,
  ) {
    final isOk = freshness?.level == FreshnessLevel.ok;
    final dotColor = last == null
        ? AppColors.statusOverdue
        : freshness!.color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: isOk ? 1.0 : (0.25 + 0.75 * phase),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Last cleaned',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          last == null ? 'Never cleaned' : formatElapsed(elapsed!),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: last == null
                ? AppColors.statusOverdue
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _maintenanceSection(BoxScreenState state) {
    if (state.maintenance.isEmpty) return const SizedBox.shrink();
    final sortMode = ref.watch(maintenanceSortModeProvider);
    final sorted = [...state.maintenance];
    if (sortMode == MaintenanceSortMode.upNext) {
      sorted.sort((a, b) {
        final c = a.remaining.compareTo(b.remaining);
        if (c != 0) return c;
        return a.task.intervalCleanings.compareTo(b.task.intervalCleanings);
      });
    } else {
      sorted.sort((a, b) {
        final c = a.task.intervalCleanings.compareTo(b.task.intervalCleanings);
        if (c != 0) return c;
        return a.remaining.compareTo(b.remaining);
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              ref.read(maintenanceSortModeProvider.notifier).toggle(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              sortMode == MaintenanceSortMode.upNext
                  ? 'UP NEXT ⇅'
                  : 'BY TASK ⇅',
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final item in sorted) _maintenanceRow(item),
      ],
    );
  }

  Widget _maintenanceRow(MaintenanceItem item) {
    final dueText = item.remaining < 0
        ? 'Overdue by ${-item.remaining} cleanings'
        : item.remaining == 0
            ? 'Due now'
            : item.remaining == 1
                ? 'Due next cleaning'
                : 'Due in ${item.remaining} cleanings';
    final color = item.remaining < 0
        ? AppColors.statusOverdue
        : item.remaining == 0
            ? AppColors.statusWarn
            : AppColors.textSecondary;
    final flash = item.remaining <= 0;
    final flashColor = item.remaining < 0
        ? AppColors.statusOverdue
        : AppColors.statusWarn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FlashPulse(
        enabled: flash,
        builder: (context, phase) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: flash
                  ? Color.lerp(AppColors.surface, flashColor, phase * 0.4)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.task.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueText,
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => widget.onMaintenanceTap(item),
                  child: const Text('DONE'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _historySection(List<CleaningEvent> history) {
    if (history.isEmpty) {
      return const Text(
        'No cleanings logged yet',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT CLEANINGS',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        for (final event in history.take(15))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatHistoryRow(event.timestamp, _now),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary),
                  onPressed: () => widget.onDeleteEvent(event),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class Ticker {
  Ticker(this._onTick);

  final void Function() _onTick;
  bool _cancelled = false;

  Future<void> start() async {
    while (!_cancelled) {
      await Future<void>.delayed(const Duration(seconds: 30));
      if (_cancelled) return;
      _onTick();
    }
  }

  void cancel() => _cancelled = true;
}
