import { NextResponse } from "next/server";

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
      .from("tasks")
      .select("id, title, description, deadline, completed")
      .eq("user_id", userId)
      .order("deadline", { ascending: true });

    if (error) {
      return NextResponse.json({ message: "Gagal mengambil tugas" }, { status: 500 });
    }

    return NextResponse.json(data || []);
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat mengambil tugas" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) return unauthorized();

  const { title, description, deadline } = (await req.json().catch(() => ({}))) as {
    title?: string;
    description?: string;
    deadline?: string;
  };

  if (!title || !deadline) {
    return NextResponse.json({ message: "title dan deadline wajib diisi" }, { status: 400 });
  }

  try {
    const { data: task, error } = await supabase
      .from("tasks")
      .insert({
        user_id: userId,
        title,
        description: description || "",
        deadline,
        completed: false,
      })
      .select("id, user_id, title, description, deadline, completed")
      .single();

    if (error || !task) {
      return NextResponse.json({ message: "Gagal membuat tugas" }, { status: 500 });
    }

    return NextResponse.json(task, { status: 201 });
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat membuat tugas" }, { status: 500 });
  }
}
