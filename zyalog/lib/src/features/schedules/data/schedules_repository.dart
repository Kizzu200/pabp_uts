import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../models/schedule_model.dart';

class SchedulesRepository {
  SchedulesRepository(this._dio);

  final Dio _dio;

  Future<List<ScheduleModel>> getSchedules() async {
    final response = await _dio.get<dynamic>(ApiConstants.schedules);
    final list = _extractList(response.data, ['schedules', 'data']);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ScheduleModel.fromJson)
        .toList();
  }

  Future<ScheduleModel> createSchedule({
    required String hari,
    required String mataKuliah,
    required String ruang,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.schedules,
      data: {
        'hari': hari,
        'mataKuliah': mataKuliah,
        'ruang': ruang,
        'jamMulai': jamMulai,
        'jamSelesai': jamSelesai,
      },
    );

    final map = _extractMap(response.data, ['schedule', 'data']);
    return ScheduleModel.fromJson(map);
  }

  Future<ScheduleModel> updateSchedule(ScheduleModel schedule) async {
    final response = await _dio.put<dynamic>(
      '${ApiConstants.schedules}/${schedule.id}',
      data: {
        'hari': schedule.hari,
        'mataKuliah': schedule.mataKuliah,
        'ruang': schedule.ruang,
        'jamMulai': schedule.jamMulai,
        'jamSelesai': schedule.jamSelesai,
      },
    );

    final map = _extractMap(response.data, ['schedule', 'data']);
    return ScheduleModel.fromJson(map);
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete<void>('${ApiConstants.schedules}/$id');
  }

  List<dynamic> _extractList(dynamic body, List<String> keys) {
    if (body is List) {
      return body;
    }

    if (body is Map<String, dynamic>) {
      for (final key in keys) {
        final dynamic value = body[key];
        if (value is List) {
          return value;
        }
      }
    }

    return <dynamic>[];
  }

  Map<String, dynamic> _extractMap(dynamic body, List<String> keys) {
    if (body is Map<String, dynamic>) {
      for (final key in keys) {
        final dynamic value = body[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
      }
      return body;
    }

    return <String, dynamic>{};
  }
}
