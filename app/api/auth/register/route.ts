import bcrypt from "bcryptjs";
import { NextResponse } from "next/server";

import { generateTokens, supabase } from "@/lib/server/auth";

export const runtime = "nodejs";

export async function POST(req: Request) {
  const { name, email, password } = (await req.json().catch(() => ({}))) as {
    name?: string;
    email?: string;
    password?: string;
  };

  if (!name || !email || !password) {
    return NextResponse.json({ message: "name, email, password wajib diisi" }, { status: 400 });
  }

  try {
    const { data: existing, error: existingError } = await supabase
      .from("users")
      .select("id")
      .eq("email", email)
      .maybeSingle<{ id: string }>();

    if (existingError) {
      return NextResponse.json({ message: "Gagal memeriksa pengguna" }, { status: 500 });
    }

    if (existing) {
      return NextResponse.json({ message: "Email sudah terdaftar" }, { status: 409 });
    }

    const hash = await bcrypt.hash(password, 10);

    const { data: inserted, error: insertError } = await supabase
      .from("users")
      .insert({ name, email, password_hash: hash })
      .select("id, name, email")
      .single<{ id: string; name: string; email: string }>();

    if (insertError || !inserted) {
      return NextResponse.json({ message: "Gagal mendaftarkan pengguna" }, { status: 500 });
    }

    const tokens = generateTokens(inserted.id);
    return NextResponse.json({ user: inserted, ...tokens }, { status: 201 });
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat registrasi" }, { status: 500 });
  }
}
