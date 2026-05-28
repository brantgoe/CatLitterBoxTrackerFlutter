import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

enum FreshnessLevel { ok, warn, overdue }

class Freshness {
  Freshness(this.level, this.color);
  final FreshnessLevel level;
  final Color color;
}

Freshness freshnessFor({
  required int elapsedMs,
  required int warnHours,
  required int overdueHours,
}) {
  final warnMs = warnHours * 60 * 60 * 1000;
  final overdueMs = overdueHours * 60 * 60 * 1000;
  if (elapsedMs >= overdueMs) {
    return Freshness(FreshnessLevel.overdue, AppColors.statusOverdue);
  }
  if (elapsedMs >= warnMs) {
    return Freshness(FreshnessLevel.warn, AppColors.statusWarn);
  }
  return Freshness(FreshnessLevel.ok, AppColors.statusOk);
}

String formatElapsed(int elapsedMs) {
  if (elapsedMs < 60 * 1000) return 'just now';
  final totalMinutes = elapsedMs ~/ (60 * 1000);
  final days = totalMinutes ~/ (60 * 24);
  final hours = (totalMinutes ~/ 60) % 24;
  final minutes = totalMinutes % 60;
  final buf = StringBuffer();
  if (days > 0) buf.write('${days}d ');
  if (days > 0 || hours > 0) buf.write('${hours}h ');
  buf.write('${minutes}m ago');
  return buf.toString();
}

final _timeOnly = DateFormat('h:mm a');
final _dayAndTime = DateFormat('EEE, MMM d · h:mm a');

String formatHistoryRow(int timestamp, int now) {
  final today = DateTime.fromMillisecondsSinceEpoch(now);
  final event = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final isToday = today.year == event.year &&
      today.month == event.month &&
      today.day == event.day;
  final yesterday = today.subtract(const Duration(days: 1));
  final isYesterday = yesterday.year == event.year &&
      yesterday.month == event.month &&
      yesterday.day == event.day;
  final core = isToday
      ? 'Today, ${_timeOnly.format(event)}'
      : isYesterday
          ? 'Yesterday, ${_timeOnly.format(event)}'
          : _dayAndTime.format(event);
  final elapsed = now - timestamp;
  return '$core  ·  ${formatElapsed(elapsed)}';
}
