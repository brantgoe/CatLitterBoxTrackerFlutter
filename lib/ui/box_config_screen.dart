import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'box_presets.dart';

class BoxConfigScreen extends ConsumerStatefulWidget {
  const BoxConfigScreen({super.key, required this.boxId});

  final int boxId;

  @override
  ConsumerState<BoxConfigScreen> createState() => _BoxConfigScreenState();
}

class _BoxConfigScreenState extends ConsumerState<BoxConfigScreen> {
  LitterBox? _box;
  bool _hydrated = false;

  final _nameCtrl = TextEditingController();
  final _warnCtrl = TextEditingController();
  final _overdueCtrl = TextEditingController();
  BoxTypeKind _type = BoxTypeKind.manualScoop;
  BoxPreset _preset = BoxPresets.custom;
  String _brand = BoxPresets.otherBrand;
  int? _selectedRoomId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _warnCtrl.dispose();
    _overdueCtrl.dispose();
    super.dispose();
  }

  int _hoursToDays(int hours) {
    final d = ((hours + 12) ~/ 24);
    return d < 1 ? 1 : d;
  }

  void _hydrate(LitterBox box) {
    _box = box;
    _nameCtrl.text = box.name;
    _warnCtrl.text = _hoursToDays(box.warnThresholdHours).toString();
    _overdueCtrl.text = _hoursToDays(box.overdueThresholdHours).toString();
    _type = box.typeKind;
    _preset = BoxPresets.match(box.brand, box.model);
    _brand = box.brand.isEmpty ? BoxPresets.otherBrand : box.brand;
    _selectedRoomId = box.roomId;
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final rooms = ref.watch(roomsProvider).value ?? const [];

    return StreamBuilder<List<LitterBox>>(
      stream: repo.observeAllBoxes(),
      builder: (context, snapshot) {
        final boxes = snapshot.data ?? const [];
        final box = boxes.where((b) => b.id == widget.boxId).firstOrNull;
        if (box == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!_hydrated) _hydrate(box);

        return Scaffold(
          appBar: AppBar(
            title: Text(_box?.name ?? 'Box settings'),
            actions: [
              TextButton(
                onPressed: () => _saveAndExit(repo),
                child: const Text('SAVE'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Name / location'),
              TextField(controller: _nameCtrl),
              const SizedBox(height: 16),
              const Text('In room'),
              DropdownButton<int>(
                value: _selectedRoomId,
                isExpanded: true,
                items: rooms
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoomId = v),
              ),
              const SizedBox(height: 16),
              const Text('Box type'),
              SegmentedButton<BoxTypeKind>(
                segments: const [
                  ButtonSegment(
                      value: BoxTypeKind.manualScoop,
                      label: Text('Manual scooping')),
                  ButtonSegment(
                      value: BoxTypeKind.automatic,
                      label: Text('Automatic')),
                ],
                selected: {_type},
                onSelectionChanged: (s) =>
                    setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              const Text('Alert thresholds (days)'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _warnCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Warn after'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _overdueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Overdue after'),
                    ),
                  ),
                ],
              ),
              if (_type == BoxTypeKind.automatic) ...[
                const SizedBox(height: 24),
                const Text('Manufacturer'),
                DropdownButton<String>(
                  value: _brand,
                  isExpanded: true,
                  items: BoxPresets.brandsForUi
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => _onBrandChanged(v),
                ),
                if (_brand != BoxPresets.otherBrand) ...[
                  const SizedBox(height: 12),
                  const Text('Model'),
                  DropdownButton<String>(
                    value: BoxPresets.modelsForBrand(_brand)
                            .any((p) => p.model == _preset.model)
                        ? _preset.model
                        : null,
                    isExpanded: true,
                    hint: const Text('Select model'),
                    items: BoxPresets.modelsForBrand(_brand)
                        .map((p) => DropdownMenuItem(
                              value: p.model,
                              child: Text(p.model),
                            ))
                        .toList(),
                    onChanged: (v) => _onModelChanged(v),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _preset.maintenanceItems.isEmpty
                      ? null
                      : () => _confirmLoadPreset(repo),
                  child: const Text('Load preset maintenance items'),
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    const Expanded(child: Text('Maintenance items')),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      onPressed: () => _showEditTaskDialog(repo, null),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MaintenanceList(
                  boxId: widget.boxId,
                  onEdit: (t) => _showEditTaskDialog(repo, t),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _onBrandChanged(String? brand) {
    setState(() {
      _brand = brand ?? BoxPresets.otherBrand;
      if (_brand == BoxPresets.otherBrand) {
        _preset = BoxPresets.custom;
      } else if (_preset.brand != _brand) {
        // Don't auto-pick a model — let the user choose explicitly. Until
        // they do, treat this as "brand selected, no model yet" — _preset
        // sits on custom so Load preset stays disabled.
        _preset = BoxPresets.custom;
      }
    });
  }

  void _onModelChanged(String? model) {
    if (model == null) return;
    final found = BoxPresets.modelsForBrand(_brand)
        .firstWhere((p) => p.model == model, orElse: () => BoxPresets.custom);
    setState(() => _preset = found);
  }

  Future<void> _confirmLoadPreset(Repository repo) async {
    // The currently-saved brand/model on the box — what the maintenance list
    // was previously seeded for, if anything. Lets us recognize leftover
    // tasks from a previous preset by name and clear them out instead of
    // piling new items on top.
    final previousPreset =
        BoxPresets.match(_box?.brand ?? '', _box?.model ?? '');
    final tasks = await repo.db.tasksForBoxOnce(widget.boxId);
    final existingNames =
        tasks.map<String>((t) => t.name.trim().toLowerCase()).toSet();

    final leftover = previousPreset.displayName != _preset.displayName
        ? tasks.where((t) {
            final n = t.name.trim().toLowerCase();
            return previousPreset.maintenanceItems
                .any((p) => p.name.trim().toLowerCase() == n);
          }).toList()
        : <MaintenanceTask>[];

    final newToAdd = _preset.maintenanceItems
        .where((p) => !existingNames.contains(p.name.trim().toLowerCase()) ||
            leftover.any((t) =>
                t.name.trim().toLowerCase() ==
                p.name.trim().toLowerCase()))
        .toList();

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load preset maintenance items?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leftover.isNotEmpty) ...[
              Text(
                'Will remove ${leftover.length} leftover item(s) from the '
                'previous "${previousPreset.displayName}" preset:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              for (final t in leftover) Text('• ${t.name}'),
              const SizedBox(height: 12),
            ],
            Text(
              newToAdd.isEmpty
                  ? 'No new items to add — all "${_preset.displayName}" '
                      'items are already in your list.'
                  : 'Will add ${newToAdd.length} item(s) from '
                      '"${_preset.displayName}":',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (newToAdd.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final p in newToAdd) Text('• ${p.name}'),
            ],
            const SizedBox(height: 12),
            const Text(
              'Items you added yourself are kept.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('APPLY')),
        ],
      ),
    );
    if (confirm != true) return;

    for (final t in leftover) {
      await repo.deleteMaintenanceTask(t);
    }
    for (final p in newToAdd) {
      await repo.addMaintenanceTask(MaintenanceTasksCompanion.insert(
        boxId: widget.boxId,
        name: p.name,
        intervalCleanings: p.intervalCleanings,
        anchorTimestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    if (mounted) {
      final removed = leftover.length;
      final added = newToAdd.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(removed > 0
              ? 'Removed $removed leftover item(s), added $added new'
              : 'Added $added preset maintenance item(s)'),
        ),
      );
    }
  }

  Future<void> _showEditTaskDialog(
      Repository repo, MaintenanceTask? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final intervalCtrl = TextEditingController(
        text: existing?.intervalCleanings.toString() ?? '');
    String? nameError;
    String? intervalError;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(existing == null
                ? 'Add maintenance item'
                : 'Edit maintenance item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'What to do',
                    errorText: nameError,
                  ),
                ),
                TextField(
                  controller: intervalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Every N cleanings',
                    errorText: intervalError,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final interval = int.tryParse(intervalCtrl.text);
                  setLocal(() {
                    nameError =
                        name.isEmpty ? 'Name is required' : null;
                    if (interval == null || interval <= 0) {
                      intervalError = 'Must be 1 or more';
                    } else if (interval > 999) {
                      intervalError = 'Must be 999 or fewer';
                    } else {
                      intervalError = null;
                    }
                  });
                  if (nameError == null && intervalError == null) {
                    Navigator.pop(ctx, true);
                    Future<void>.microtask(() async {
                      if (existing == null) {
                        await repo.addMaintenanceTask(
                          MaintenanceTasksCompanion.insert(
                            boxId: widget.boxId,
                            name: name,
                            intervalCleanings: interval!,
                            anchorTimestamp:
                                DateTime.now().millisecondsSinceEpoch,
                          ),
                        );
                      } else {
                        await repo.updateMaintenanceTask(existing.copyWith(
                          name: name,
                          intervalCleanings: interval!,
                        ));
                      }
                    });
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        });
      },
    );
    nameCtrl.dispose();
    intervalCtrl.dispose();
    if (result != true) return;
  }

  Future<void> _saveAndExit(Repository repo) async {
    final box = _box;
    if (box == null) return;

    // Switching from automatic to manual scoop hides the maintenance list
    // section, but the preset items stay in the database and keep firing.
    // Offer to remove leftover preset items so the box doesn't drag forever
    // along the "deep clean drum" item it can no longer reach.
    if (box.typeKind == BoxTypeKind.automatic &&
        _type == BoxTypeKind.manualScoop) {
      final previousPreset = BoxPresets.match(box.brand, box.model);
      if (previousPreset.maintenanceItems.isNotEmpty) {
        final tasks = await repo.db.tasksForBoxOnce(widget.boxId);
        final leftover = tasks.where((t) {
          final n = t.name.trim().toLowerCase();
          return previousPreset.maintenanceItems
              .any((p) => p.name.trim().toLowerCase() == n);
        }).toList();
        if (leftover.isNotEmpty) {
          if (!mounted) return;
          final choice = await showDialog<_PresetCleanupChoice>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove preset items?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Switching to manual scoop. You have ${leftover.length} '
                    'maintenance item(s) from the '
                    '"${previousPreset.displayName}" preset:',
                  ),
                  const SizedBox(height: 6),
                  for (final t in leftover) Text('• ${t.name}'),
                  const SizedBox(height: 10),
                  const Text(
                    'Items you added yourself are kept either way.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _PresetCleanupChoice.cancel),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _PresetCleanupChoice.keep),
                  child: const Text('KEEP'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _PresetCleanupChoice.remove),
                  child: const Text('REMOVE'),
                ),
              ],
            ),
          );
          if (choice == null || choice == _PresetCleanupChoice.cancel) return;
          if (choice == _PresetCleanupChoice.remove) {
            for (final t in leftover) {
              await repo.deleteMaintenanceTask(t);
            }
          }
        }
      }
    }

    final name = _nameCtrl.text.trim().isEmpty ? box.name : _nameCtrl.text.trim();
    final warnDays = int.tryParse(_warnCtrl.text) ?? _hoursToDays(box.warnThresholdHours);
    final overdueDays = int.tryParse(_overdueCtrl.text) ??
        _hoursToDays(box.overdueThresholdHours);
    final warn = (warnDays.clamp(1, 999)) * 24;
    final overdue = (overdueDays.clamp(warnDays + 1, 9999)) * 24;
    final updated = box.copyWith(
      name: name,
      warnThresholdHours: warn,
      overdueThresholdHours: overdue,
      type: _type.storage,
      brand: _type == BoxTypeKind.automatic ? _preset.brand : '',
      model: _type == BoxTypeKind.automatic ? _preset.model : '',
      roomId: Value(_selectedRoomId ?? box.roomId),
    );
    await repo.updateBox(updated);
    if (mounted) Navigator.of(context).pop();
  }
}

enum _PresetCleanupChoice { cancel, keep, remove }

class _MaintenanceList extends ConsumerWidget {
  const _MaintenanceList({required this.boxId, required this.onEdit});
  final int boxId;
  final void Function(MaintenanceTask task) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    return StreamBuilder<List<MaintenanceTask>>(
      stream: repo.observeMaintenanceTasks(boxId),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? const [];
        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No maintenance items yet.'),
          );
        }
        return Column(
          children: [
            for (final t in tasks)
              Card(
                child: ListTile(
                  title: Text(t.name),
                  subtitle: Text('Every ${t.intervalCleanings} cleanings'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => onEdit(t),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete item'),
                              content: Text(t.name),
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
                            await repo.deleteMaintenanceTask(t);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
