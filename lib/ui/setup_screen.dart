import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../services/litter_recommender.dart';
import '../state/providers.dart';
import 'box_config_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider).value ?? const [];
    final activeRoom = ref.watch(activeRoomProvider).value;
    final targetId = _selectedRoomId ?? activeRoom?.id;
    final currentRoom = rooms.firstWhere(
      (r) => r.id == targetId,
      orElse: () => rooms.isEmpty
          ? BoxRoom(id: 0, syncId: '', name: '', catCount: 0, updatedAt: 0)
          : rooms.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        actions: [
          TextButton(
            onPressed: () {
              if (currentRoom.id != 0) {
                ref.read(repositoryProvider).setActiveRoomId(currentRoom.id);
              }
              Navigator.of(context).pop();
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Room'),
          const SizedBox(height: 8),
          DropdownButton<int>(
            value: currentRoom.id == 0 ? null : currentRoom.id,
            isExpanded: true,
            hint: const Text('Pick a room'),
            items: rooms
                .map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(r.name),
                    ))
                .toList(),
            onChanged: (id) => setState(() => _selectedRoomId = id),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New room'),
                onPressed: _promptCreateRoom,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Rename'),
                onPressed: currentRoom.id == 0
                    ? null
                    : () => _promptRenameRoom(currentRoom),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                onPressed: rooms.length <= 1 || currentRoom.id == 0
                    ? null
                    : () => _confirmDeleteRoom(currentRoom),
              ),
            ],
          ),
          if (currentRoom.id != 0) ...[
            const Divider(height: 32),
            _CatCountStepper(room: currentRoom),
            const SizedBox(height: 12),
            _RecommendationCard(room: currentRoom),
          ],
          const Divider(height: 32),
          Row(
            children: [
              const Expanded(child: Text('Boxes in this room')),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Box'),
                onPressed: currentRoom.id == 0
                    ? null
                    : () => _addBoxAndOpen(currentRoom.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentRoom.id != 0)
            _BoxList(roomId: currentRoom.id),
        ],
      ),
    );
  }

  Future<void> _promptCreateRoom() async {
    final controller = TextEditingController(text: 'Unnamed Room');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create new room'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final repo = ref.read(repositoryProvider);
    final id = await repo.insertRoom(name);
    repo.setActiveRoomId(id);
    if (mounted) setState(() => _selectedRoomId = id);
  }

  Future<void> _promptRenameRoom(BoxRoom room) async {
    final controller = TextEditingController(text: room.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename room'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == room.name) return;
    await ref
        .read(repositoryProvider)
        .updateRoom(room.copyWith(name: name));
  }

  Future<void> _confirmDeleteRoom(BoxRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this room?'),
        content: Text(
            '${room.name} and all its boxes/history will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(repositoryProvider).deleteRoom(room);
    if (mounted) setState(() => _selectedRoomId = null);
  }

  Future<void> _addBoxAndOpen(int roomId) async {
    final repo = ref.read(repositoryProvider);
    final id = await repo.insertBox(
      LitterBoxesCompanion.insert(name: 'New box', roomId: Value(roomId)),
    );
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BoxConfigScreen(boxId: id),
      ));
    }
  }
}

class _CatCountStepper extends ConsumerWidget {
  const _CatCountStepper({required this.room});
  final BoxRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = room.catCount;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Cats living in this room',
            style: TextStyle(fontSize: 16),
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.remove),
          onPressed: cats <= 0
              ? null
              : () => ref
                  .read(repositoryProvider)
                  .updateRoom(room.copyWith(catCount: cats - 1)),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$cats',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add),
          onPressed: cats >= 50
              ? null
              : () => ref
                  .read(repositoryProvider)
                  .updateRoom(room.copyWith(catCount: cats + 1)),
        ),
      ],
    );
  }
}

class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({required this.room});
  final BoxRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    return StreamBuilder<List<LitterBox>>(
      stream: repo.observeBoxesInRoom(room.id),
      builder: (context, boxesSnap) {
        final boxes = boxesSnap.data ?? const <LitterBox>[];
        if (room.catCount <= 0 || boxes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                room.catCount <= 0
                    ? 'Tell me how many cats use this room and I\'ll '
                        'suggest how often to change the litter.'
                    : 'Add a box to this room to get a litter change '
                        'recommendation.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        // Pull events covering the smell-sample window. Refreshed via key on
        // box ids so it re-fetches when boxes change.
        final cutoff = DateTime.now().millisecondsSinceEpoch -
            LitterRecommender.smellSampleWindow.inMilliseconds;
        return FutureBuilder<List<CleaningEvent>>(
          key: ValueKey('rec-${room.id}-${boxes.map((b) => b.id).join(",")}'),
          future: repo.db.eventsSince(cutoff),
          builder: (context, eventsSnap) {
            final boxIds = boxes.map((b) => b.id).toSet();
            final events = (eventsSnap.data ?? const <CleaningEvent>[])
                .where((e) => boxIds.contains(e.boxId))
                .toList();
            final r = LitterRecommender.recommend(
              cats: room.catCount,
              boxes: boxes,
              recentEvents: events,
              nowMs: DateTime.now().millisecondsSinceEpoch,
            );
            return _recCard(r);
          },
        );
      },
    );
  }

  Widget _recCard(LitterChangeRecommendation r) {
    final shrank = r.days != r.baseDays;
    final manualBoxes = r.boxes - r.automaticBoxes;
    final loadParts = <String>[
      if (manualBoxes > 0)
        '$manualBoxes manual box${manualBoxes == 1 ? "" : "es"}',
      if (r.automaticBoxes > 0)
        '${r.automaticBoxes} automatic box${r.automaticBoxes == 1 ? "" : "es"}',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Suggested litter change',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              'Every ${r.days} day${r.days == 1 ? "" : "s"}',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${r.cats} cat${r.cats == 1 ? "" : "s"} using ${loadParts.join(" + ")}.',
              style: const TextStyle(fontSize: 13),
            ),
            if (shrank) ...[
              const SizedBox(height: 6),
              Text(
                'Baseline ${r.baseDays} day${r.baseDays == 1 ? "" : "s"}; '
                'shaved off because ${(r.smellRate * 100).round()}% of recent '
                'cleanings (${r.sampledEvents}) were due to smell.',
                style: const TextStyle(
                    fontSize: 12, color: Colors.orange),
              ),
            ] else if (r.sampledEvents >= LitterRecommender.smellMinSample &&
                !r.smellRate.isNaN) ...[
              const SizedBox(height: 6),
              Text(
                'Smell rate (last 60 days): ${(r.smellRate * 100).round()}% '
                'of ${r.sampledEvents} — within normal.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoxList extends ConsumerWidget {
  const _BoxList({required this.roomId});

  final int roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    return StreamBuilder<List<LitterBox>>(
      stream: repo.observeBoxesInRoom(roomId),
      builder: (context, snapshot) {
        final boxes = snapshot.data ?? const [];
        if (boxes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No boxes in this room yet. Tap Add Box to create one.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return Column(
          children: [
            for (final box in boxes)
              Card(
                child: ListTile(
                  title: Text(box.name),
                  subtitle: Text(_subtitle(box)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => BoxConfigScreen(boxId: box.id),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDeleteBox(context, ref, box),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => BoxConfigScreen(boxId: box.id),
                    ));
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  String _subtitle(LitterBox box) {
    if (box.typeKind == BoxTypeKind.manualScoop) return 'Manual scooping';
    final model = '${box.brand} ${box.model}'.trim();
    return model.isEmpty ? 'Automatic' : 'Automatic · $model';
  }

  Future<void> _confirmDeleteBox(
      BuildContext context, WidgetRef ref, LitterBox box) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this box?'),
        content: Text(
            'All cleanings and maintenance items for ${box.name} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(repositoryProvider).deleteBox(box);
    }
  }
}
