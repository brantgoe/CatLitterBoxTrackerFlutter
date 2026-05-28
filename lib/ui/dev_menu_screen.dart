import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../data/database.dart';
import '../state/providers.dart';

const int _hourMs = 60 * 60 * 1000;

class _DevTaskState {
  _DevTaskState(this.task, this.cleaningsSinceAnchor);
  final MaintenanceTask task;
  final int cleaningsSinceAnchor;
}

final _devTasksProvider = StreamProvider<List<_DevTaskState>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final boxes = ref.watch(boxesInActiveRoomProvider).value ?? const [];
  if (boxes.isEmpty) return Stream.value(const []);
  final flows = boxes.map<Stream<List<_DevTaskState>>>((b) {
    return repo.observeMaintenanceTasks(b.id).switchMap((tasks) {
      if (tasks.isEmpty) return Stream.value(const <_DevTaskState>[]);
      final stateStreams = tasks.map((t) => repo
          .observeCleaningsSince(b.id, t.anchorTimestamp)
          .map((c) => _DevTaskState(t, c)));
      return Rx.combineLatestList<_DevTaskState>(stateStreams);
    });
  }).toList();
  return Rx.combineLatestList<List<_DevTaskState>>(flows)
      .map((lists) => lists.expand((x) => x).toList());
});

class DevMenuScreen extends ConsumerWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(_devTasksProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Dev menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Cleaning status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
              'Rewrites the most recent cleaning timestamp to land in the desired band.'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _force(ref, context, _Band.overdue),
                  child: const Text('Force OVERDUE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _force(ref, context, _Band.warn),
                  child: const Text('Force WARN'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _force(ref, context, _Band.fresh),
                  child: const Text('Force FRESH'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('Maintenance items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
              'Each button lowers the task\'s interval to match the current cleaning count, so the item shows as "Due now".'),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            const Text('No tasks configured. Add one in box settings.'),
          for (final s in tasks)
            Card(
              child: ListTile(
                title: Text(s.task.name),
                subtitle: Text(
                    '${s.cleaningsSinceAnchor} / ${s.task.intervalCleanings} cleanings since anchor'),
                trailing: OutlinedButton(
                  child: const Text('DUE NOW'),
                  onPressed: () async {
                    await ref
                        .read(repositoryProvider)
                        .forceMaintenanceDueNow(s.task.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Applied')),
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _force(WidgetRef ref, BuildContext context, _Band band) async {
    final repo = ref.read(repositoryProvider);
    final boxes = ref.read(boxesInActiveRoomProvider).value ?? const [];
    if (boxes.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final b in boxes) {
      final int offsetMs = switch (band) {
        _Band.overdue => (b.overdueThresholdHours + 1) * _hourMs,
        _Band.warn => (b.warnThresholdHours + 1) * _hourMs,
        _Band.fresh => 0,
      };
      await repo.setLastCleaningTimestamp(b.id, now - offsetMs);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applied')),
      );
    }
  }
}

enum _Band { overdue, warn, fresh }
