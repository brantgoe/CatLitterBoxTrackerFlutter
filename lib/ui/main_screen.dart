import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../state/providers.dart';
import 'box_card.dart';
import 'dev_menu_screen.dart';
import 'setup_screen.dart';
import 'theme.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _loggingInProgress = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(boxStatesProvider);
    final room = ref.watch(activeRoomProvider).value;
    // Keep roomsProvider subscribed so the switcher dialog has data ready.
    ref.watch(roomsProvider);
    final states = statesAsync.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showRoomSwitcher,
          child: Text(
            (room?.name ?? '').toUpperCase(),
            style: const TextStyle(letterSpacing: 1.5, fontSize: 16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.build_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DevMenuScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SetupScreen(),
              ));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Column(
          children: [
            Expanded(child: _cardsRow(states)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 72,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36),
                  ),
                ),
                onPressed: states.isEmpty || _loggingInProgress
                    ? null
                    : _showCleaningTargetPicker,
                child: Text(
                  _bigButtonLabel(states),
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardsRow(List<BoxScreenState> states) {
    if (states.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No boxes in this room yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SetupScreen(),
                  ));
                },
                child: const Text('Open setup'),
              ),
            ],
          ),
        ),
      );
    }
    final cards = <Widget>[];
    for (var i = 0; i < states.length; i++) {
      cards.add(Expanded(
        child: SingleChildScrollView(
          child: BoxCard(
            state: states[i],
            onDeleteEvent: _confirmDeleteEvent,
            onMaintenanceTap: _confirmMaintenanceComplete,
          ),
        ),
      ));
      if (i < states.length - 1) cards.add(const SizedBox(width: 12));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards);
  }

  String _bigButtonLabel(List<BoxScreenState> states) {
    if (states.length != 1) return 'JUST CLEANED';
    final box = states.first.box;
    switch (box.typeKind) {
      case BoxTypeKind.automatic:
        return 'JUST CHANGED LITTER';
      case BoxTypeKind.manualScoop:
        return 'JUST SCOOPED';
    }
  }

  void _showCleaningTargetPicker() {
    final states = ref.read(boxStatesProvider).value ?? const [];
    if (states.length <= 1) {
      _onJustCleanedTapped(null);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Log cleaning for…'),
        children: [
          SimpleDialogOption(
            child: const Text('All boxes'),
            onPressed: () {
              Navigator.pop(ctx);
              _onJustCleanedTapped(null);
            },
          ),
          for (final s in states)
            SimpleDialogOption(
              child: Text(s.box.name),
              onPressed: () {
                Navigator.pop(ctx);
                _onJustCleanedTapped(s.box.id);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _onJustCleanedTapped(int? boxId) async {
    if (_loggingInProgress) return;
    setState(() => _loggingInProgress = true);
    try {
      final snapshot = ref.read(boxStatesProvider).value ?? const [];
      final repo = ref.read(repositoryProvider);
      final cleanedBoxIds = boxId == null
          ? snapshot.map((s) => s.box.id).toList()
          : <int>[boxId];

      List<int> eventIds;
      if (boxId == null) {
        final room = ref.read(activeRoomProvider).value ??
            await repo.ensureRoomExists();
        eventIds = await repo.logCleaningInRoom(room.id);
        if (eventIds.isEmpty) return;
      } else {
        eventIds = [await repo.logCleaning(boxId)];
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged cleaning'),
            duration: Duration(seconds: 2)),
      );
      await _promptMaintenanceThenSmell(eventIds, cleanedBoxIds, snapshot);
    } finally {
      if (mounted) setState(() => _loggingInProgress = false);
    }
  }

  Future<void> _promptMaintenanceThenSmell(
    List<int> eventIds,
    List<int> cleanedBoxIds,
    List<BoxScreenState> snapshot,
  ) async {
    final pending = <_PromptItem>[];
    final upcoming = <_PromptItem>[];
    for (final state in snapshot) {
      if (!cleanedBoxIds.contains(state.box.id)) continue;
      for (final item in state.maintenance) {
        if (item.remaining <= 0) {
          pending.add(_PromptItem(state.box.name, item));
        } else if (item.remaining == 2) {
          upcoming.add(_PromptItem(state.box.name, item));
        }
      }
    }
    pending.sort((a, b) => a.item.remaining.compareTo(b.item.remaining));
    upcoming.sort((a, b) => a.item.task.name.compareTo(b.item.task.name));
    final multiBox = cleanedBoxIds.length > 1;

    if (pending.isNotEmpty) {
      final completed = await _showMaintenancePendingDialog(pending, multiBox);
      if (completed != null) {
        final repo = ref.read(repositoryProvider);
        for (final taskId in completed) {
          await repo.markMaintenanceComplete(taskId);
        }
      }
    }
    if (!mounted) return;
    if (upcoming.isNotEmpty) {
      await _showMaintenanceUpcomingDialog(upcoming, multiBox);
    }
    if (!mounted) return;
    await _showSmellDialog(eventIds);
  }

  Future<List<int>?> _showMaintenancePendingDialog(
    List<_PromptItem> pending,
    bool multiBox,
  ) {
    final checked = List<bool>.filled(pending.length, false);
    return showDialog<List<int>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Did you also do these?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < pending.length; i++)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: checked[i],
                      onChanged: (v) => setLocal(() => checked[i] = v ?? false),
                      title: Text(
                        multiBox
                            ? '${pending[i].boxName}: ${pending[i].item.task.name}'
                            : pending[i].item.task.name,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop<List<int>>(ctx, const []),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  final ids = <int>[];
                  for (var i = 0; i < pending.length; i++) {
                    if (checked[i]) ids.add(pending[i].item.task.id);
                  }
                  Navigator.pop<List<int>>(ctx, ids);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showMaintenanceUpcomingDialog(
    List<_PromptItem> upcoming,
    bool multiBox,
  ) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Heads up: due next cleaning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in upcoming)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  multiBox
                      ? '• ${p.boxName}: ${p.item.task.name}'
                      : '• ${p.item.task.name}',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSmellDialog(List<int> eventIds) async {
    final repo = ref.read(repositoryProvider);
    final result = await showDialog<_SmellResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Was this changed due to smell?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _SmellResult.exit),
            child: const Text('EXIT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _SmellResult.no),
            child: const Text('NO, SCHEDULED'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _SmellResult.yes),
            child: const Text('YES, SMELL'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (result) {
      case _SmellResult.yes:
        await repo.updateCleaningSmellForRoom(eventIds, true);
        break;
      case _SmellResult.no:
        await repo.updateCleaningSmellForRoom(eventIds, false);
        break;
      case _SmellResult.exit:
        await _confirmExitWithoutLogging(eventIds);
        break;
      case null:
        break;
    }
  }

  Future<void> _confirmExitWithoutLogging(List<int> eventIds) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(
            'If you exit, this cleaning will not be logged. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXIT'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) {
      await ref.read(repositoryProvider).deleteCleaningsByIds(eventIds);
    } else {
      await _showSmellDialog(eventIds);
    }
  }

  Future<void> _confirmMaintenanceComplete(MaintenanceItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark complete?'),
        content: Text('Mark "${item.task.name}" as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(repositoryProvider).markMaintenanceComplete(item.task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked complete')),
        );
      }
    }
  }

  Future<void> _confirmDeleteEvent(CleaningEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This removes the cleaning record from history.'),
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
    if (confirm == true && mounted) {
      final repo = ref.read(repositoryProvider);
      await repo.deleteCleaning(event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entry deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () => repo.reinsertCleaning(event),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showRoomSwitcher() async {
    final rooms = ref.read(roomsProvider).value ?? const [];
    final activeId = ref.read(activeRoomProvider).value?.id;
    if (!mounted) return;
    final action = await showDialog<_RoomAction>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Switch room'),
        children: [
          for (final r in rooms)
            SimpleDialogOption(
              child: Text(r.id == activeId ? '✓ ${r.name}' : r.name),
              onPressed: () =>
                  Navigator.pop(ctx, _RoomAction.select(r)),
            ),
          SimpleDialogOption(
            child: const Text('+ Create new room'),
            onPressed: () => Navigator.pop(ctx, _RoomAction.create()),
          ),
          if (rooms.length > 1)
            SimpleDialogOption(
              child: const Text('× Delete a room…'),
              onPressed: () => Navigator.pop(ctx, _RoomAction.delete()),
            ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    final repo = ref.read(repositoryProvider);
    switch (action.kind) {
      case _RoomActionKind.select:
        repo.setActiveRoomId(action.room!.id);
        break;
      case _RoomActionKind.create:
        await _promptNewRoom();
        break;
      case _RoomActionKind.delete:
        await _showDeleteRoomPicker();
        break;
    }
  }

  Future<void> _promptNewRoom() async {
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
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    final id = await repo.insertRoom(name);
    repo.setActiveRoomId(id);
  }

  Future<void> _showDeleteRoomPicker() async {
    final rooms = ref.read(roomsProvider).value ?? const [];
    if (rooms.length <= 1) return;
    final picked = await showDialog<BoxRoom>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose a room to delete'),
        children: [
          for (final r in rooms)
            SimpleDialogOption(
              child: Text(r.name),
              onPressed: () => Navigator.pop(ctx, r),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this room?'),
        content: Text(
            '${picked.name} and all its boxes/history will be removed.'),
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
      await ref.read(repositoryProvider).deleteRoom(picked);
    }
  }
}

class _PromptItem {
  _PromptItem(this.boxName, this.item);
  final String boxName;
  final MaintenanceItem item;
}

enum _SmellResult { yes, no, exit }

enum _RoomActionKind { select, create, delete }

class _RoomAction {
  _RoomAction.select(BoxRoom this.room) : kind = _RoomActionKind.select;
  _RoomAction.create()
      : kind = _RoomActionKind.create,
        room = null;
  _RoomAction.delete()
      : kind = _RoomActionKind.delete,
        room = null;

  final _RoomActionKind kind;
  final BoxRoom? room;
}
