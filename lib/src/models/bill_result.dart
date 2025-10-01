// lib/src/models/bill_result.dart
// Model that holds the computed billing result after applying the business logic.

import 'dart:convert';

/// Holds per-floor computed results and overall totals.
class BillResult {
  /// Map from floor name (e.g. "Ground", "First") to adjusted units (after water split).
  final Map<String, double> adjustedUnits;

  /// Map from floor name to electricity cost (adjustedUnits * ratePerUnit).
  final Map<String, double> electricityCostPerFloor;

  /// Provided inputs / metadata
  final double waterTotalUnits;
  final double perFloorWaterShare;
  final double ratePerUnit;
  final double rentAmount;
  final bool rentIncludedInGround;
  final String groundFloorName; // e.g. "Ground"
  /// Optional per-floor rent map (overrides [rentAmount]/[rentIncludedInGround] logic if provided).
  final Map<String, double>? rentPerFloor;

  BillResult({
    required this.adjustedUnits,
    required this.electricityCostPerFloor,
    required this.waterTotalUnits,
    required this.perFloorWaterShare,
    required this.ratePerUnit,
    required this.rentAmount,
    required this.rentIncludedInGround,
    this.groundFloorName = 'Ground',
    this.rentPerFloor,
  });

  /// Total electricity cost across all floors (without rent).
  double get totalElectricityCost =>
      electricityCostPerFloor.values.fold(0.0, (a, b) => a + b);

  /// Final charge for Ground floor (electricity + rent if included).
  double get groundFinalTotal {
    final elec = electricityCostPerFloor[groundFloorName] ?? 0.0;
    if (rentPerFloor != null) {
      return elec + (rentPerFloor![groundFloorName] ?? 0.0);
    }
    return elec + (rentIncludedInGround ? rentAmount : 0.0);
  }

  /// Final totals per floor including rent only for ground (if enabled).
  Map<String, double> get finalPerFloorTotals {
    final Map<String, double> map = {};
    electricityCostPerFloor.forEach((floor, cost) {
      double rentAdd = 0.0;
      if (rentPerFloor != null) {
        rentAdd = rentPerFloor![floor] ?? 0.0;
      } else if (rentIncludedInGround && floor == groundFloorName) {
        rentAdd = rentAmount;
      }
      map[floor] = cost + rentAdd;
    });
    return map;
  }

  /// Grand total (electricity + rent if included).
  double get grandTotal {
    if (rentPerFloor != null) {
      final rentSum = rentPerFloor!.values.fold(0.0, (a, b) => a + b);
      return totalElectricityCost + rentSum;
    }
    final rentPart = rentIncludedInGround ? rentAmount : 0.0;
    return totalElectricityCost + rentPart;
  }

  BillResult copyWith({
    Map<String, double>? adjustedUnits,
    Map<String, double>? electricityCostPerFloor,
    double? waterTotalUnits,
    double? perFloorWaterShare,
    double? ratePerUnit,
    double? rentAmount,
    bool? rentIncludedInGround,
    String? groundFloorName,
    Map<String, double>? rentPerFloor,
  }) {
    return BillResult(
      adjustedUnits:
          adjustedUnits ?? Map<String, double>.from(this.adjustedUnits),
      electricityCostPerFloor:
          electricityCostPerFloor ??
          Map<String, double>.from(this.electricityCostPerFloor),
      waterTotalUnits: waterTotalUnits ?? this.waterTotalUnits,
      perFloorWaterShare: perFloorWaterShare ?? this.perFloorWaterShare,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      rentAmount: rentAmount ?? this.rentAmount,
      rentIncludedInGround: rentIncludedInGround ?? this.rentIncludedInGround,
      groundFloorName: groundFloorName ?? this.groundFloorName,
      rentPerFloor:
          rentPerFloor ??
          (this.rentPerFloor == null
              ? null
              : Map<String, double>.from(this.rentPerFloor!)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adjustedUnits': adjustedUnits.map((k, v) => MapEntry(k, v)),
      'electricityCostPerFloor': electricityCostPerFloor.map(
        (k, v) => MapEntry(k, v),
      ),
      'waterTotalUnits': waterTotalUnits,
      'perFloorWaterShare': perFloorWaterShare,
      'ratePerUnit': ratePerUnit,
      'rentAmount': rentAmount,
      'rentIncludedInGround': rentIncludedInGround,
      'groundFloorName': groundFloorName,
      if (rentPerFloor != null) 'rentPerFloor': rentPerFloor,
    };
  }

  factory BillResult.fromMap(Map<String, dynamic> map) {
    final adjusted = <String, double>{};
    final costs = <String, double>{};

    if (map['adjustedUnits'] != null && map['adjustedUnits'] is Map) {
      (map['adjustedUnits'] as Map).forEach((k, v) {
        adjusted['$k'] = (v is num)
            ? v.toDouble()
            : double.tryParse('$v') ?? 0.0;
      });
    }

    if (map['electricityCostPerFloor'] != null &&
        map['electricityCostPerFloor'] is Map) {
      (map['electricityCostPerFloor'] as Map).forEach((k, v) {
        costs['$k'] = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      });
    }

    Map<String, double>? rentMap;
    if (map['rentPerFloor'] is Map) {
      rentMap = {};
      (map['rentPerFloor'] as Map).forEach((k, v) {
        rentMap!["$k"] = (v is num)
            ? v.toDouble()
            : double.tryParse('$v') ?? 0.0;
      });
    }

    return BillResult(
      adjustedUnits: adjusted,
      electricityCostPerFloor: costs,
      waterTotalUnits: (map['waterTotalUnits'] is num)
          ? (map['waterTotalUnits'] as num).toDouble()
          : double.tryParse('${map['waterTotalUnits']}') ?? 0.0,
      perFloorWaterShare: (map['perFloorWaterShare'] is num)
          ? (map['perFloorWaterShare'] as num).toDouble()
          : double.tryParse('${map['perFloorWaterShare']}') ?? 0.0,
      ratePerUnit: (map['ratePerUnit'] is num)
          ? (map['ratePerUnit'] as num).toDouble()
          : double.tryParse('${map['ratePerUnit']}') ?? 0.0,
      rentAmount: (map['rentAmount'] is num)
          ? (map['rentAmount'] as num).toDouble()
          : double.tryParse('${map['rentAmount']}') ?? 0.0,
      rentIncludedInGround: map['rentIncludedInGround'] == true,
      groundFloorName: map['groundFloorName'] ?? 'Ground',
      rentPerFloor: rentMap,
    );
  }

  String toJson() => json.encode(toMap());

  factory BillResult.fromJson(String source) =>
      BillResult.fromMap(json.decode(source));

  @override
  String toString() {
    return 'BillResult(totalElectricity: ${totalElectricityCost.toStringAsFixed(2)}, waterTotal: ${waterTotalUnits.toStringAsFixed(2)}, grandTotal: ${grandTotal.toStringAsFixed(2)})';
  }
}
