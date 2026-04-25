// lib/services/schedule_service.dart

import '../core/api_client.dart';
import '../models/schedule.dart';

class ScheduleService {
  /// GET /api/schedules
  static Future<List<ScheduleModel>> fetchAll() async {
    final data = await ApiClient.get('/api/schedules') as List<dynamic>;
    return data
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/schedules
  static Future<ScheduleModel> create({
    required String hari,
    required String mataKuliah,
    required String ruang,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    final data = await ApiClient.post('/api/schedules', {
      'hari': hari,
      'mataKuliah': mataKuliah,
      'ruang': ruang,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
    }) as Map<String, dynamic>;
    return ScheduleModel.fromJson(data);
  }

  /// PUT /api/schedules/:id
  static Future<ScheduleModel> update({
    required String id,
    required String hari,
    required String mataKuliah,
    required String ruang,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    final data = await ApiClient.put('/api/schedules/$id', {
      'hari': hari,
      'mataKuliah': mataKuliah,
      'ruang': ruang,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
    }) as Map<String, dynamic>;
    return ScheduleModel.fromJson(data);
  }

  /// DELETE /api/schedules/:id
  static Future<void> delete(String id) async {
    await ApiClient.delete('/api/schedules/$id');
  }
}
