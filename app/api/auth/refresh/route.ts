import { NextResponse } from "next/server";

import { refreshSessionToken } from "@/lib/server/auth";

export const runtime = "nodejs";

export async function POST(req: Request) {
  const { refreshToken } = (await req.json().catch(() => ({}))) as { refreshToken?: string };

  if (!refreshToken) {
    return NextResponse.json({ message: "refreshToken wajib diisi" }, { status: 400 });
  }

  const tokens = refreshSessionToken(refreshToken);
  if (!tokens) {
    return NextResponse.json({ message: "Refresh token tidak valid atau kedaluwarsa" }, { status: 401 });
  }

  return NextResponse.json(tokens);
}
