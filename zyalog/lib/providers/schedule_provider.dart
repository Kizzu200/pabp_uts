// lib/providers/schedule_provider.dart

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

class ScheduleProvider extends ChangeNotifier {
  List<ScheduleModel> _schedules = [];
  bool _loading = false;
  String? _error;

  List<ScheduleModel> get schedules => _schedules;
  bool get loading => _loading;
  String? get error => _error;

  /// Kelompokkan jadwal per hari, diurutkan berdasarkan jam mulai
  Map<String, List<ScheduleModel>> get byHari {
    final map = <String, List<ScheduleModel>>{};
    for (final k in kHariKeys) {
      map[k] = [];
    }
    for (final s in _schedules) {
      map.putIfAbsent(s.hari, () => []).add(s);
    }
    for (final k in map.keys) {
      map[k]!.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
    }
    return map;
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchSchedules() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _schedules = await ScheduleService.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<bool> addSchedule({
    required String hari,
    required String mataKuliah,
    required String ruang,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    try {
      final s = await ScheduleService.create(
        hari: hari,
        mataKuliah: mataKuliah,
        ruang: ruang,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
      );
      _schedules.add(s);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<bool> updateSchedule({
    required String id,
    required String hari,
    required String mataKuliah,
    required String ruang,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    try {
      final updated = await ScheduleService.update(
        id: id,
        hari: hari,
        mataKuliah: mataKuliah,
        ruang: ruang,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
      );
      final idx = _schedules.indexWhere((s) => s.id == id);
      if (idx != -1) _schedules[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteSchedule(String id) async {
    final backup = List<ScheduleModel>.from(_schedules);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
    try {
      await ScheduleService.delete(id);
    } catch (_) {
      _schedules = backup;
      notifyListeners();
    }
  }

  void clear() {
    _schedules = [];
    _error = null;
    notifyListeners();
  }
}
