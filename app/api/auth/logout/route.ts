import { NextResponse } from "next/server";

import { clearRefreshToken, verifyAccessToken } from "@/lib/server/auth";

export const runtime = "nodejs";

export async function POST(req: Request) {
  const userId = verifyAccessToken(req.headers.get("authorization"));
  if (!userId) {
    return NextResponse.json({ message: "Missing Authorization header" }, { status: 401 });
  }

  clearRefreshToken(userId);
  return NextResponse.json({ message: "Logout berhasil" });
}
