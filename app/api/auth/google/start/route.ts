import { NextRequest, NextResponse } from "next/server";

import {
  encodeState,
  getGoogleClientId,
  getGoogleClientSecret,
  googleAuthClient,
} from "@/lib/server/auth";

export const runtime = "nodejs";

export async function GET(req: NextRequest) {
  if (!googleAuthClient || !getGoogleClientId() || !getGoogleClientSecret()) {
    return NextResponse.json(
      { message: "Google OAuth belum lengkap. Set GOOGLE_CLIENT_ID dan GOOGLE_CLIENT_SECRET" },
      { status: 500 },
    );
  }

  const from = req.nextUrl.searchParams.get("from") === "register" ? "register" : "login";
  const authUrl = googleAuthClient.generateAuthUrl({
    access_type: "offline",
    prompt: "select_account",
    include_granted_scopes: true,
    scope: ["openid", "email", "profile"],
    state: encodeState({ from }),
  });

  return NextResponse.redirect(authUrl);
}
