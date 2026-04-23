import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/schedules_repository.dart';
import '../models/schedule_model.dart';
import 'schedules_state.dart';

class SchedulesController extends StateNotifier<SchedulesState> {
  SchedulesController(this._repository) : super(const SchedulesState.initial()) {
    loadSchedules();
  }

  final SchedulesRepository _repository;

  Future<void> loadSchedules() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await _repository.getSchedules();
      state = state.copyWith(
        isLoading: false,
        items: items,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  Future<void> createSchedule({
    required String hari,
    required String mataKuliah,
    required String ruang,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.createSchedule(
        hari: hari,
        mataKuliah: mataKuliah,
        ruang: ruang,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
      );
      await loadSchedules();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.updateSchedule(schedule);
      await loadSchedules();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  Future<void> deleteSchedule(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.deleteSchedule(id);
      await loadSchedules();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(error),
      );
    }
  }

  String _parseError(Object error) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    return 'Gagal memuat jadwal kuliah.';
  }
}
