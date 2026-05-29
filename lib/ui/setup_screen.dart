import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
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
          ? BoxRoom(id: 0, name: '', updatedAt: 0)
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
