// lib/src/providers/bill_provider.dart
//
// Provider for bill calculation & state management.
// Uses Provider (ChangeNotifier) pattern and SharedPreferences for optional persistence.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reading.dart';
import '../models/bill_result.dart';

/// Keys used for SharedPreferences storage.
const String _kPrefsHistoryKey = 'bill_history_v1';
const String _kPrefsDefaultsKey = 'bill_defaults_v1';

/// A ChangeNotifier provider which:
/// - Holds meter readings (floors + water),
/// - Holds calculation settings (rate, rent, includeRent),
/// - Performs the calculation and returns a BillResult,
/// - Optionally persists history and defaults to SharedPreferences.
class BillProvider extends ChangeNotifier {
  // ----- State -----
  /// Ordered list of floor readings. Index 0 is typically "Ground".
  List<MeterReading> _floors = [
    MeterReading(floorName: 'Ground', lastReading: 0.0, currentReading: 0.0),
    MeterReading(floorName: 'First', lastReading: 0.0, currentReading: 0.0),
    MeterReading(floorName: 'Second', lastReading: 0.0, currentReading: 0.0),
  ];

  WaterReading _water = WaterReading(lastReading: 0.0, currentReading: 0.0);

  double _ratePerUnit = 10.0;
  double _rentAmount = 19000.0;
  bool _rentIncludedInGround = true;
  bool _usePerFloorRent = false;

  /// Mirrors floors length; only used when _usePerFloorRent=true.
  List<double> _perFloorRent = [0.0, 0.0, 0.0];

  /// Computed last result (null until first compute).
  BillResult? _lastResult;

  /// History of saved BillResult JSON strings (most recent first).
  List<String> _history = [];

  // ----- Constructors & initialization -----
  BillProvider() {
    _loadDefaults();
    _loadHistory();
  }

  // ----- Public getters -----
  List<MeterReading> get floors => List.unmodifiable(_floors);
  WaterReading get water => _water;
  double get ratePerUnit => _ratePerUnit;
  double get rentAmount => _rentAmount;
  bool get rentIncludedInGround => _rentIncludedInGround;
  bool get usePerFloorRent => _usePerFloorRent;
  List<double> get perFloorRent => List.unmodifiable(_perFloorRent);
  BillResult? get lastResult => _lastResult;
  List<BillResult> get history =>
      _history.map((s) => BillResult.fromJson(s)).toList(growable: false);

  int get floorCount => _floors.length;

  // ----- Mutations -----

  /// Update a floor reading at [index].
  void updateFloorReading({
    required int index,
    String? floorName,
    double? lastReading,
    double? currentReading,
  }) {
    if (index < 0 || index >= _floors.length) return;
    final old = _floors[index];
    _floors[index] = old.copyWith(
      floorName: floorName ?? old.floorName,
      lastReading: lastReading ?? old.lastReading,
      currentReading: currentReading ?? old.currentReading,
    );
    notifyListeners();
  }

  /// Replace entire floors list (useful for dynamic floor changes).
  void setFloors(List<MeterReading> newFloors) {
    _floors = List.from(newFloors);
    notifyListeners();
  }

  /// Add a new floor (name optional). New floor starts with 0 readings.
  void addFloor({String? name}) {
    final idx = _floors.length + 1;
    _floors.add(
      MeterReading(
        floorName: name ?? 'Floor $idx',
        lastReading: 0.0,
        currentReading: 0.0,
      ),
    );
    if (_usePerFloorRent) _perFloorRent.add(0.0);
    notifyListeners();
  }

  /// Remove floor at index (keeps at least 1 floor).
  void removeFloor(int index) {
    if (_floors.length <= 1) return;
    _floors.removeAt(index);
    if (_usePerFloorRent && index < _perFloorRent.length) {
      _perFloorRent.removeAt(index);
    }
    notifyListeners();
  }

  void setWaterReading({double? last, double? current}) {
    _water = _water.copyWith(
      lastReading: last ?? _water.lastReading,
      currentReading: current ?? _water.currentReading,
    );
    notifyListeners();
  }

  void setRatePerUnit(double rate) {
    _ratePerUnit = rate;
    notifyListeners();
  }

  void setRentAmount(double rent) {
    _rentAmount = rent;
    notifyListeners();
  }

  void setRentIncluded(bool included) {
    _rentIncludedInGround = included;
    notifyListeners();
  }

  void setUsePerFloorRent(bool v) {
    if (_usePerFloorRent == v) return;
    _usePerFloorRent = v;
    // ensure list size matches floors
    if (_usePerFloorRent) {
      if (_perFloorRent.length != _floors.length) {
        _perFloorRent = List<double>.filled(_floors.length, 0.0);
      }
    }
    notifyListeners();
  }

  void setPerFloorRent(int index, double value) {
    if (!_usePerFloorRent) return;
    if (index < 0 || index >= _perFloorRent.length) return;
    _perFloorRent[index] = value;
    notifyListeners();
  }

  /// Reset readings to zeros (does not change settings).
  void resetReadings() {
    for (var i = 0; i < _floors.length; i++) {
      _floors[i] = _floors[i].copyWith(lastReading: 0.0, currentReading: 0.0);
    }
    _water = WaterReading(lastReading: 0.0, currentReading: 0.0);
    _lastResult = null;
    notifyListeners();
  }

  // ----- Core calculation -----

  /// Compute bill using current state and return BillResult.
  /// Logic:
  /// 1. rawUnits per floor = max(0, current - last)
  /// 2. waterTotal = max(0, water.current - water.last)
  /// 3. perFloorWaterShare = waterTotal / floorCount
  /// 4. adjustedGround = groundRaw - waterTotal + perFloorWaterShare
  /// 5. adjustedOther = rawOther + perFloorWaterShare
  /// 6. cost = adjusted * rate
  BillResult computeBill({String groundFloorName = 'Ground'}) {
    final rawUnits = <String, double>{};
    for (final f in _floors) {
      rawUnits[f.floorName] = _clampToZero(f.currentReading - f.lastReading);
    }

    final waterTotal = _clampToZero(_water.currentReading - _water.lastReading);
    final perFloorWaterShare = (floorCount > 0) ? waterTotal / floorCount : 0.0;

    // New approach: Distribute water equally; do not subtract entire water from ground.
    final adjusted = <String, double>{};
    for (var i = 0; i < _floors.length; i++) {
      final name = _floors[i].floorName;
      final base = rawUnits[name] ?? 0.0;
      adjusted[name] = _clampToZero(base + perFloorWaterShare);
    }

    final costs = <String, double>{};
    adjusted.forEach((k, v) {
      costs[k] = v * _ratePerUnit;
    });

    Map<String, double>? rentMap;
    if (_usePerFloorRent) {
      rentMap = {};
      for (var i = 0; i < _floors.length; i++) {
        rentMap[_floors[i].floorName] = _perFloorRent.length > i
            ? _perFloorRent[i]
            : 0.0;
      }
    }

    final result = BillResult(
      adjustedUnits: adjusted,
      electricityCostPerFloor: costs,
      waterTotalUnits: waterTotal,
      perFloorWaterShare: perFloorWaterShare,
      ratePerUnit: _ratePerUnit,
      rentAmount: _rentAmount,
      rentIncludedInGround: _rentIncludedInGround,
      groundFloorName: groundFloorName,
      rentPerFloor: rentMap,
    );

    _lastResult = result;
    notifyListeners();
    return result;
  }

  double _clampToZero(double v) => v.isFinite ? (v < 0 ? 0.0 : v) : 0.0;

  // ----- Persistence (SharedPreferences) -----

  /// Save last result into history (most recent first).
  Future<void> saveLastResultToHistory() async {
    if (_lastResult == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = _lastResult!.toJson();
    // prepend and trim history to reasonable size (e.g., 30)
    _history.insert(0, jsonStr);
    if (_history.length > 30) _history = _history.sublist(0, 30);
    await prefs.setStringList(_kPrefsHistoryKey, _history);
    notifyListeners();
  }

  /// Remove an entry from history by index.
  Future<void> removeHistoryAt(int index) async {
    if (index < 0 || index >= _history.length) return;
    _history.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefsHistoryKey, _history);
    notifyListeners();
  }

  /// Clear entire history.
  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefsHistoryKey);
    notifyListeners();
  }

  /// Save current settings & floors as defaults.
  Future<void> saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> m = {
      'ratePerUnit': _ratePerUnit,
      'rentAmount': _rentAmount,
      'rentIncludedInGround': _rentIncludedInGround,
      'usePerFloorRent': _usePerFloorRent,
      'perFloorRent': _usePerFloorRent ? _perFloorRent : null,
      'floors': _floors.map((f) => f.toMap()).toList(),
      'water': _water.toMap(),
    };
    await prefs.setString(_kPrefsDefaultsKey, json.encode(m));
  }

  Future<void> _loadDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_kPrefsDefaultsKey)) return;
      final raw = prefs.getString(_kPrefsDefaultsKey);
      if (raw == null) return;
      final Map decoded = json.decode(raw);
      _ratePerUnit = (decoded['ratePerUnit'] is num)
          ? (decoded['ratePerUnit'] as num).toDouble()
          : _ratePerUnit;
      _rentAmount = (decoded['rentAmount'] is num)
          ? (decoded['rentAmount'] as num).toDouble()
          : _rentAmount;
      _rentIncludedInGround = decoded['rentIncludedInGround'] == true;
      _usePerFloorRent = decoded['usePerFloorRent'] == true;
      if (_usePerFloorRent) {
        if (decoded['perFloorRent'] is List) {
          final l = decoded['perFloorRent'] as List;
          _perFloorRent = l
              .map(
                (e) => (e is num) ? e.toDouble() : double.tryParse('$e') ?? 0.0,
              )
              .toList();
        } else {
          _perFloorRent = List<double>.filled(_floors.length, 0.0);
        }
        if (_perFloorRent.length != _floors.length) {
          // Resize gracefully
          final resized = List<double>.filled(_floors.length, 0.0);
          for (var i = 0; i < resized.length && i < _perFloorRent.length; i++) {
            resized[i] = _perFloorRent[i];
          }
          _perFloorRent = resized;
        }
      }

      if (decoded['floors'] is List) {
        final List list = decoded['floors'] as List;
        _floors = list
            .map((e) => MeterReading.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (decoded['water'] is Map) {
        _water = WaterReading.fromMap(
          Map<String, dynamic>.from(decoded['water']),
        );
      }

      notifyListeners();
    } catch (e) {
      // ignore load errors and keep defaults
      if (kDebugMode) print('Failed to load defaults: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kPrefsHistoryKey);
      if (list != null && list.isNotEmpty) {
        _history = List<String>.from(list);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load history: $e');
    }
  }
}
