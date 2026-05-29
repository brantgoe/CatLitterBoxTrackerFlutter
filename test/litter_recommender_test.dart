import 'package:cat_litter_box_tracker/data/database.dart';
import 'package:cat_litter_box_tracker/services/litter_recommender.dart';
import 'package:flutter_test/flutter_test.dart';

LitterBox _box({bool automatic = false}) => LitterBox(
      id: 1,
      syncId: 'b-1',
      name: 'Box',
      position: 0,
      type: automatic ? 'AUTOMATIC' : 'MANUAL_SCOOP',
      warnThresholdHours: 24,
      overdueThresholdHours: 48,
      brand: '',
      model: '',
      roomId: 1,
      updatedAt: 0,
    );

CleaningEvent _event({required int timestamp, bool? smell}) => CleaningEvent(
      id: 1,
      syncId: 'e-${timestamp}_${smell ?? "_"}',
      boxId: 1,
      timestamp: timestamp,
      dueToSmell: smell,
      updatedAt: timestamp,
    );

void main() {
  group('LitterRecommender', () {
    const now = 1700000000000;

    test('1 cat + 1 manual box → 7 days', () {
      final r = LitterRecommender.recommend(
        cats: 1,
        boxes: [_box()],
        recentEvents: const [],
        nowMs: now,
      );
      expect(r.days, 7);
      expect(r.baseDays, 7);
      expect(r.isUseful, isTrue);
    });

    test('2 cats + 1 manual box → ~3 days (load doubled)', () {
      final r = LitterRecommender.recommend(
        cats: 2,
        boxes: [_box()],
        recentEvents: const [],
        nowMs: now,
      );
      // 7 / 2 = 3.5 → rounds to 4.
      expect(r.days, 4);
    });

    test('2 cats + 2 manual boxes → 7 days (load matched)', () {
      final r = LitterRecommender.recommend(
        cats: 2,
        boxes: [_box(), _box()],
        recentEvents: const [],
        nowMs: now,
      );
      expect(r.days, 7);
    });

    test('1 cat + 1 automatic box → ~11 days (auto has more capacity)', () {
      final r = LitterRecommender.recommend(
        cats: 1,
        boxes: [_box(automatic: true)],
        recentEvents: const [],
        nowMs: now,
      );
      expect(r.days, 11);
    });

    test('high smell rate shrinks the interval', () {
      // 5 of 5 recent events flagged due to smell — clearly running too long.
      final events = [
        for (var i = 0; i < 5; i++)
          _event(
            timestamp: now - Duration(days: i * 3).inMilliseconds,
            smell: true,
          ),
      ];
      final r = LitterRecommender.recommend(
        cats: 1,
        boxes: [_box()],
        recentEvents: events,
        nowMs: now,
      );
      expect(r.smellRate, closeTo(1.0, 1e-9));
      expect(r.sampledEvents, 5);
      // 100% smell rate at smellShrinkCeiling=0.4 → 7 × (1 - 0.4) = 4.2 → 4.
      expect(r.days, 4);
      expect(r.baseDays, 7);
    });

    test('low smell rate leaves the interval alone', () {
      // 1 smell-flagged out of 5 = 20%, below the 30% floor.
      final events = [
        _event(timestamp: now - 1, smell: true),
        for (var i = 1; i < 5; i++)
          _event(timestamp: now - i * 1000, smell: false),
      ];
      final r = LitterRecommender.recommend(
        cats: 1,
        boxes: [_box()],
        recentEvents: events,
        nowMs: now,
      );
      expect(r.days, r.baseDays); // no shrink applied
    });

    test('smell rate ignored when sample size below minimum', () {
      // 3 events, all smell-flagged — but sample size < 4, so no shrink.
      final events = [
        for (var i = 0; i < 3; i++)
          _event(timestamp: now - i * 1000, smell: true),
      ];
      final r = LitterRecommender.recommend(
        cats: 1,
        boxes: [_box()],
        recentEvents: events,
        nowMs: now,
      );
      expect(r.days, r.baseDays);
    });

    test('events older than 60d are excluded from smell rate', () {
      final tooOld = now - const Duration(days: 90).inMilliseconds;
      final fresh = now - const Duration(days: 5).inMilliseconds;
      final events = [
        _event(timestamp: tooOld, smell: true),
        _event(timestamp: tooOld, smell: true),
        _event(timestamp: tooOld, smell: true),
        _event(timestamp: fresh, smell: false),
      ];
      final r = LitterRecommender.recommend(
        cats: 1,
        boxes: [_box()],
        recentEvents: events,
        nowMs: now,
      );
      expect(r.sampledEvents, 1);
      // 1 event isn't enough to shrink even at 0% smell rate.
      expect(r.days, r.baseDays);
    });

    test('zero cats returns a sentinel (not useful)', () {
      final r = LitterRecommender.recommend(
        cats: 0,
        boxes: [_box()],
        recentEvents: const [],
        nowMs: now,
      );
      expect(r.isUseful, isFalse);
      expect(r.days, 0);
    });

    test('zero boxes returns a sentinel (not useful)', () {
      final r = LitterRecommender.recommend(
        cats: 2,
        boxes: const [],
        recentEvents: const [],
        nowMs: now,
      );
      expect(r.isUseful, isFalse);
    });

    test('5 cats + 1 manual box hits the 2-day floor', () {
      final r = LitterRecommender.recommend(
        cats: 5,
        boxes: [_box()],
        recentEvents: const [],
        nowMs: now,
      );
      // 7/5 = 1.4 → rounds to 1, clamped to floor of 2.
      expect(r.days, 2);
    });
  });
}
