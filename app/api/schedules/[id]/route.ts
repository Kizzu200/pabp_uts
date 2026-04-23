import { NextResponse } from "next/server";

import { mapScheduleRow } from "@/lib/server/schedules";
import { supabase, verifyAccessToken } from "@/lib/server/auth";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ message: "Missing Authorization header" }, { status: 401 });
}

export async function PUT(req: Request, context: { params: Promise<{ id: string }> }) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) return unauthorized();

  const { id } = await context.params;
  const { hari, mataKuliah, ruang, jamMulai, jamSelesai } = (await req.json().catch(() => ({}))) as {
    hari?: string;
    mataKuliah?: string;
    ruang?: string;
    jamMulai?: string;
    jamSelesai?: string;
  };

  const updateData: Record<string, string> = {};
  if (hari !== undefined) updateData.hari = hari;
  if (mataKuliah !== undefined) updateData.mata_kuliah = mataKuliah;
  if (ruang !== undefined) updateData.ruang = ruang;
  if (jamMulai !== undefined) updateData.jam_mulai = jamMulai;
  if (jamSelesai !== undefined) updateData.jam_selesai = jamSelesai;

  try {
    const { data: schedule, error } = await supabase
      .from("schedules")
      .update(updateData)
      .eq("id", id)
      .eq("user_id", userId)
      .select("id, hari, mata_kuliah, ruang, jam_mulai, jam_selesai")
      .maybeSingle();

    if (error) {
      return NextResponse.json({ message: "Gagal mengubah jadwal" }, { status: 500 });
    }

    if (!schedule) {
      return NextResponse.json({ message: "Jadwal tidak ditemukan" }, { status: 404 });
    }

    return NextResponse.json(mapScheduleRow(schedule));
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat mengubah jadwal" }, { status: 500 });
  }
}

export async function DELETE(req: Request, context: { params: Promise<{ id: string }> }) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) return unauthorized();

  const { id } = await context.params;

  try {
    const { data, error } = await supabase
      .from("schedules")
      .delete()
      .eq("id", id)
      .eq("user_id", userId)
      .select("id")
      .maybeSingle();

    if (error) {
      return NextResponse.json({ message: "Gagal menghapus jadwal" }, { status: 500 });
    }

    if (!data) {
      return NextResponse.json({ message: "Jadwal tidak ditemukan" }, { status: 404 });
    }

    return new NextResponse(null, { status: 204 });
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat menghapus jadwal" }, { status: 500 });
  }
}
