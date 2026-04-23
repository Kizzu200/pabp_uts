class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.hari,
    required this.mataKuliah,
    required this.ruang,
    required this.jamMulai,
    required this.jamSelesai,
  });

  final String id;
  final String hari;
  final String mataKuliah;
  final String ruang;
  final String jamMulai;
  final String jamSelesai;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      hari: (json['hari'] ?? '').toString(),
      mataKuliah: (json['mataKuliah'] ?? '').toString(),
      ruang: (json['ruang'] ?? '').toString(),
      jamMulai: (json['jamMulai'] ?? '').toString(),
      jamSelesai: (json['jamSelesai'] ?? '').toString(),
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hari': hari,
      'mataKuliah': mataKuliah,
      'ruang': ruang,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
    };
  }
}
