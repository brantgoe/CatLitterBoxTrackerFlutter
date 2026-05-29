import '../data/database.dart';

/// A single recommendation for how often to do a full litter change in a room.
/// Returned from [LitterRecommender.recommend].
class LitterChangeRecommendation {
  const LitterChangeRecommendation({
    required this.days,
    required this.baseDays,
    required this.smellRate,
    required this.sampledEvents,
    required this.boxes,
    required this.automaticBoxes,
    required this.cats,
  });

  /// Final recommendation, in days. Always ≥ 2.
  final int days;

  /// What the calculator would have said with no smell adjustment.
  /// Useful to explain "we shaved off the smell-overdue penalty".
  final int baseDays;

  /// Share of recent changes that were flagged "due to smell".
  /// 0.0 .. 1.0, NaN if [sampledEvents] is 0.
  final double smellRate;

  /// How many recent events the smell rate was computed from.
  final int sampledEvents;

  /// Total boxes in the room.
  final int boxes;

  /// How many of those boxes are automatic.
  final int automaticBoxes;

  /// Cats living in the room.
  final int cats;

  /// True iff there was enough information to give a meaningful answer.
  bool get isUseful => cats > 0 && boxes > 0;
}

/// Pure-function calculator. No drift, no DateTime.now() — every input is
/// passed in, so it's trivially testable.
class LitterRecommender {
  /// Days a single fresh clumping-litter box can serve one cat before the
  /// litter is spent. This is the long-standing rule of thumb people quote
  /// when buying clumping litter; it assumes daily scooping.
  static const double manualBoxDaysPerCat = 7;

  /// Self-cleaning / automatic boxes redistribute waste and stay usable
  /// longer between full changes. ~1.5× the manual baseline matches what
  /// manufacturers like Whisker and PetPivot publish for "litter change
  /// frequency" in their docs.
  static const double automaticBoxDaysPerCat = 10.5;

  /// Smell rate at or below this is treated as the normal background — no
  /// adjustment applied.
  static const double smellRateFloor = 0.30;

  /// Above [smellRateFloor], the interval is shrunk; at smellRate=1.0 the
  /// final interval is (1 - smellShrinkCeiling) × baseline.
  static const double smellShrinkCeiling = 0.40;

  /// How recent an event has to be for the smell rate calculation.
  /// 60 days is long enough to smooth noise from a single bad week but
  /// short enough that "we fixed it three months ago" doesn't keep biasing.
  static const Duration smellSampleWindow = Duration(days: 60);

  /// Minimum sample size before smell rate is allowed to influence the
  /// recommendation. Two flagged events out of three is statistically
  /// meaningless.
  static const int smellMinSample = 4;

  /// Floor on the final recommendation, in days. 2 days protects against
  /// degenerate inputs (10 cats, 1 manual box) producing absurd 8-hour
  /// recommendations that no one would follow.
  static const int minDays = 2;

  static LitterChangeRecommendation recommend({
    required int cats,
    required List<LitterBox> boxes,
    required List<CleaningEvent> recentEvents,
    required int nowMs,
  }) {
    if (cats <= 0 || boxes.isEmpty) {
      return LitterChangeRecommendation(
        days: 0,
        baseDays: 0,
        smellRate: double.nan,
        sampledEvents: 0,
        boxes: boxes.length,
        automaticBoxes: boxes.where((b) => b.typeKind == BoxTypeKind.automatic).length,
        cats: cats,
      );
    }

    // Each box contributes a cat-day capacity to the room. Sum to get the
    // room's total weekly carrying capacity, then divide by cat count to
    // get the per-cat allowance.
    var totalCapacity = 0.0;
    var autoCount = 0;
    for (final b in boxes) {
      if (b.typeKind == BoxTypeKind.automatic) {
        totalCapacity += automaticBoxDaysPerCat;
        autoCount++;
      } else {
        totalCapacity += manualBoxDaysPerCat;
      }
    }
    final baseDays = totalCapacity / cats;

    // Smell adjustment: look at the past [smellSampleWindow] of events
    // across this room's boxes.
    final cutoff = nowMs - smellSampleWindow.inMilliseconds;
    final recent = recentEvents.where((e) => e.timestamp >= cutoff).toList();
    final flagged = recent.where((e) => e.dueToSmell == true).length;
    final smellRate =
        recent.isEmpty ? double.nan : flagged / recent.length;

    var adjusted = baseDays;
    if (recent.length >= smellMinSample &&
        !smellRate.isNaN &&
        smellRate > smellRateFloor) {
      // Linearly scale shrink between 0 at the floor and smellShrinkCeiling
      // at smellRate=1.0.
      final shrink =
          (smellRate - smellRateFloor) / (1 - smellRateFloor) * smellShrinkCeiling;
      adjusted = baseDays * (1 - shrink);
    }

    final rounded = adjusted.round();
    final finalDays = rounded < minDays ? minDays : rounded;

    return LitterChangeRecommendation(
      days: finalDays,
      baseDays: baseDays.round() < minDays ? minDays : baseDays.round(),
      smellRate: smellRate,
      sampledEvents: recent.length,
      boxes: boxes.length,
      automaticBoxes: autoCount,
      cats: cats,
    );
  }
}
