export type ScheduleRow = {
  id: string;
  hari: string;
  mata_kuliah: string;
  ruang: string | null;
  jam_mulai: string;
  jam_selesai: string;
};

export function mapScheduleRow(row: ScheduleRow) {
  return {
    id: row.id,
    hari: row.hari,
    mataKuliah: row.mata_kuliah,
    ruang: row.ruang || "",
    jamMulai: row.jam_mulai,
    jamSelesai: row.jam_selesai,
  };
}
