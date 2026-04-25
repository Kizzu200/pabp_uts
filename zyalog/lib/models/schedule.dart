// lib/models/schedule.dart

class ScheduleModel {
  final String id;
  final String hari;
  final String mataKuliah;
  final String ruang;
  final String jamMulai;
  final String jamSelesai;

  const ScheduleModel({
    required this.id,
    required this.hari,
    required this.mataKuliah,
    required this.ruang,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String? ?? '',
      hari: json['hari'] as String? ?? 'senin',
      mataKuliah: json['mataKuliah'] as String? ?? '',
      ruang: json['ruang'] as String? ?? '',
      jamMulai: json['jamMulai'] as String? ?? '00:00',
      jamSelesai: json['jamSelesai'] as String? ?? '00:00',
    );
  }

  Map<String, dynamic> toJson() => {
        'hari': hari,
        'mataKuliah': mataKuliah,
        'ruang': ruang,
        'jamMulai': jamMulai,
        'jamSelesai': jamSelesai,
      };

  ScheduleModel copyWith({
    String? id,
    String? hari,
    String? mataKuliah,
    String? ruang,
    String? jamMulai,
    String? jamSelesai,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      hari: hari ?? this.hari,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      ruang: ruang ?? this.ruang,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
    );
  }
}
