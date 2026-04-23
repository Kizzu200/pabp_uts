import { NextResponse } from "next/server";

import { supabase, verifyAccessToken } from "@/lib/server/auth";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ message: "Missing Authorization header" }, { status: 401 });
}

export async function PUT(req: Request, context: { params: Promise<{ id: string }> }) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) return unauthorized();

  const { id } = await context.params;
  const { title, description, deadline, completed } = (await req.json().catch(() => ({}))) as {
    title?: string;
    description?: string;
    deadline?: string;
    completed?: boolean;
  };

  const updateData: Record<string, string | boolean> = {};
  if (title !== undefined) updateData.title = title;
  if (description !== undefined) updateData.description = description;
  if (deadline !== undefined) updateData.deadline = deadline;
  if (completed !== undefined) updateData.completed = completed;

  try {
    const { data: task, error } = await supabase
      .from("tasks")
      .update(updateData)
      .eq("id", id)
      .eq("user_id", userId)
      .select("id, user_id, title, description, deadline, completed")
      .maybeSingle();

    if (error) {
      return NextResponse.json({ message: "Gagal mengubah tugas" }, { status: 500 });
    }

    if (!task) {
      return NextResponse.json({ message: "Tugas tidak ditemukan" }, { status: 404 });
    }

    return NextResponse.json(task);
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat mengubah tugas" }, { status: 500 });
  }
}

export async function DELETE(req: Request, context: { params: Promise<{ id: string }> }) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) return unauthorized();

  const { id } = await context.params;

  try {
    const { data, error } = await supabase
      .from("tasks")
      .delete()
      .eq("id", id)
      .eq("user_id", userId)
      .select("id")
      .maybeSingle();

    if (error) {
      return NextResponse.json({ message: "Gagal menghapus tugas" }, { status: 500 });
    }

    if (!data) {
      return NextResponse.json({ message: "Tugas tidak ditemukan" }, { status: 404 });
    }

    return new NextResponse(null, { status: 204 });
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat menghapus tugas" }, { status: 500 });
  }
}
