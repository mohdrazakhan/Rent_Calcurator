// lib/src/models/reading.dart
// Models for meter readings: per-floor meter and the separate water meter.

import 'dart:math' as math;
import 'dart:convert';

/// Represents a single floor's electricity meter reading.
class MeterReading {
  final String floorName;
  final double lastReading;
  final double currentReading;

  /// Create a MeterReading.
  /// lastReading & currentReading should be >= 0 in normal use.
  const MeterReading({
    required this.floorName,
    required this.lastReading,
    required this.currentReading,
  });

  /// Units consumed according to this meter (current - last), clamped to >= 0.
  double get rawUnits => math.max(0.0, currentReading - lastReading);

  /// Whether the current reading is less than last reading (possible error).
  bool get isDecreasing => currentReading < lastReading;

  MeterReading copyWith({
    String? floorName,
    double? lastReading,
    double? currentReading,
  }) {
    return MeterReading(
      floorName: floorName ?? this.floorName,
      lastReading: lastReading ?? this.lastReading,
      currentReading: currentReading ?? this.currentReading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'floorName': floorName,
      'lastReading': lastReading,
      'currentReading': currentReading,
    };
  }

  factory MeterReading.fromMap(Map<String, dynamic> map) {
    return MeterReading(
      floorName: map['floorName'] ?? 'Floor',
      lastReading: (map['lastReading'] is num) ? (map['lastReading'] as num).toDouble() : double.tryParse('${map['lastReading']}') ?? 0.0,
      currentReading: (map['currentReading'] is num) ? (map['currentReading'] as num).toDouble() : double.tryParse('${map['currentReading']}') ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory MeterReading.fromJson(String source) => MeterReading.fromMap(json.decode(source));

  @override
  String toString() =>
      'MeterReading(floor: $floorName, last: $lastReading, current: $currentReading, rawUnits: ${rawUnits.toStringAsFixed(2)})';
}

/// Represents the separate water meter readings.
class WaterReading {
  final double lastReading;
  final double currentReading;

  const WaterReading({
    required this.lastReading,
    required this.currentReading,
  });

  /// Total water units consumed (clamped to >= 0).
  double get totalUnits => math.max(0.0, currentReading - lastReading);

  bool get isDecreasing => currentReading < lastReading;

  WaterReading copyWith({
    double? lastReading,
    double? currentReading,
  }) {
    return WaterReading(
      lastReading: lastReading ?? this.lastReading,
      currentReading: currentReading ?? this.currentReading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastReading': lastReading,
      'currentReading': currentReading,
    };
  }

  factory WaterReading.fromMap(Map<String, dynamic> map) {
    return WaterReading(
      lastReading: (map['lastReading'] is num) ? (map['lastReading'] as num).toDouble() : double.tryParse('${map['lastReading']}') ?? 0.0,
      currentReading: (map['currentReading'] is num) ? (map['currentReading'] as num).toDouble() : double.tryParse('${map['currentReading']}') ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory WaterReading.fromJson(String source) => WaterReading.fromMap(json.decode(source));

  @override
  String toString() => 'WaterReading(last: $lastReading, current: $currentReading, totalUnits: ${totalUnits.toStringAsFixed(2)})';
}
