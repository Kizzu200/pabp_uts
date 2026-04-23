import { NextResponse } from "next/server";

import { mapScheduleRow } from "@/lib/server/schedules";
import { supabase, verifyAccessToken } from "@/lib/server/auth";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ message: "Missing Authorization header" }, { status: 401 });
}

export async function GET(req: Request) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) return unauthorized();

  try {
    const { data, error } = await supabase
      .from("schedules")
      .select("id, hari, mata_kuliah, ruang, jam_mulai, jam_selesai")
      .eq("user_id", userId)
      .order("hari", { ascending: true })
      .order("jam_mulai", { ascending: true });

    if (error) {
      return NextResponse.json({ message: "Gagal mengambil jadwal" }, { status: 500 });
    }

    return NextResponse.json((data || []).map((row) => mapScheduleRow(row)));
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat mengambil jadwal" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) return unauthorized();

  const { hari, mataKuliah, ruang, jamMulai, jamSelesai } = (await req.json().catch(() => ({}))) as {
    hari?: string;
    mataKuliah?: string;
    ruang?: string;
    jamMulai?: string;
    jamSelesai?: string;
  };

  if (!hari || !mataKuliah || !jamMulai || !jamSelesai) {
    return NextResponse.json({ message: "hari, mataKuliah, jamMulai, jamSelesai wajib diisi" }, { status: 400 });
  }

  try {
    const { data: schedule, error } = await supabase
      .from("schedules")
      .insert({
        user_id: userId,
        hari,
        mata_kuliah: mataKuliah,
        ruang: ruang || "",
        jam_mulai: jamMulai,
        jam_selesai: jamSelesai,
      })
      .select("id, hari, mata_kuliah, ruang, jam_mulai, jam_selesai")
      .single();

    if (error || !schedule) {
      return NextResponse.json({ message: "Gagal membuat jadwal" }, { status: 500 });
    }

    return NextResponse.json(mapScheduleRow(schedule), { status: 201 });
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat membuat jadwal" }, { status: 500 });
  }
}
