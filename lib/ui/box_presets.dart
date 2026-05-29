class PresetMaintenanceItem {
  const PresetMaintenanceItem(this.name, this.intervalCleanings);
  final String name;
  final int intervalCleanings;
}

class BoxPreset {
  const BoxPreset({
    required this.brand,
    required this.model,
    required this.displayName,
    required this.maintenanceItems,
  });

  final String brand;
  final String model;
  final String displayName;
  final List<PresetMaintenanceItem> maintenanceItems;
}

class BoxPresets {
  static const petPivotAs11 = BoxPreset(
    brand: 'PetPivot',
    model: 'AutoScooper 11 (AS11)',
    displayName: 'PetPivot · AutoScooper 11 (AS11)',
    maintenanceItems: [
      PresetMaintenanceItem('Full litter replacement', 2),
      PresetMaintenanceItem('Wipe down interior', 4),
      PresetMaintenanceItem('Clean IR & Hall sensors', 4),
      PresetMaintenanceItem('Deep clean drum / litter chamber', 8),
      PresetMaintenanceItem('Replace litter chamber pad', 52),
    ],
  );

  static const litterRobot3 = BoxPreset(
    brand: 'Whisker',
    model: 'Litter-Robot 3',
    displayName: 'Whisker · Litter-Robot 3',
    maintenanceItems: [
      PresetMaintenanceItem('Wipe step ledge & interior', 4),
      PresetMaintenanceItem('Replace carbon filter', 6),
      PresetMaintenanceItem('Deep clean globe (wash)', 24),
      PresetMaintenanceItem('Inspect / replace seal strips', 52),
    ],
  );

  static const custom = BoxPreset(
    brand: '',
    model: '',
    displayName: 'Other / Custom (no preset)',
    maintenanceItems: [],
  );

  /// Sentinel value shown in the Brand dropdown for any box that doesn't
  /// match a known preset. Selecting this puts the box into custom mode and
  /// hides the Model dropdown.
  static const otherBrand = 'Other / Custom';

  static const List<BoxPreset> all = [petPivotAs11, litterRobot3, custom];

  static BoxPreset match(String brand, String model) {
    for (final p in all) {
      if (p.brand == brand && p.model == model) return p;
    }
    return custom;
  }

  /// Unique brand names that have at least one model preset, alphabetised,
  /// with the [otherBrand] sentinel at the end.
  static List<String> get brandsForUi {
    final brands = all
        .where((p) => p.brand.isNotEmpty)
        .map((p) => p.brand)
        .toSet()
        .toList()
      ..sort();
    return [...brands, otherBrand];
  }

  /// All preset models under [brand]. Empty for the [otherBrand] sentinel.
  static List<BoxPreset> modelsForBrand(String brand) {
    if (brand == otherBrand) return const [];
    return all.where((p) => p.brand == brand).toList();
  }
}
