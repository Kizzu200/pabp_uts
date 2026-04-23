import bcrypt from "bcryptjs";
import { NextResponse } from "next/server";

import { generateTokens, supabase } from "@/lib/server/auth";

export const runtime = "nodejs";

export async function POST(req: Request) {
  const { email, password } = (await req.json().catch(() => ({}))) as {
    email?: string;
    password?: string;
  };

  if (!email || !password) {
    return NextResponse.json({ message: "email dan password wajib diisi" }, { status: 400 });
  }

  try {
    const { data: user, error } = await supabase
      .from("users")
      .select("id, name, email, password_hash")
      .eq("email", email)
      .single<{ id: string; name: string; email: string; password_hash: string }>();

    if (error || !user) {
      return NextResponse.json({ message: "Email atau password salah" }, { status: 401 });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return NextResponse.json({ message: "Email atau password salah" }, { status: 401 });
    }

    const tokens = generateTokens(user.id);
    return NextResponse.json({
      user: { id: user.id, name: user.name, email: user.email },
      ...tokens,
    });
  } catch {
    return NextResponse.json({ message: "Terjadi kesalahan saat login" }, { status: 500 });
  }
}
