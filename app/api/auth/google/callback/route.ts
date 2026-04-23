import { NextRequest, NextResponse } from "next/server";

import {
  authPageUrl,
  decodeState,
  generateTokens,
  getGoogleClientId,
  getGoogleClientSecret,
  googleAuthClient,
  googleTokenVerifier,
  upsertGoogleUser,
} from "@/lib/server/auth";

export const runtime = "nodejs";

function redirectWithParams(req: NextRequest, from: "login" | "register", params: Record<string, string>) {
  const target = new URL(authPageUrl(from), req.url);
  for (const [key, value] of Object.entries(params)) {
    target.searchParams.set(key, value);
  }
  return NextResponse.redirect(target.toString());
}

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;
  const code = searchParams.get("code");
  const error = searchParams.get("error");
  const { from } = decodeState(searchParams.get("state"));

  if (!googleAuthClient || !googleTokenVerifier || !getGoogleClientId() || !getGoogleClientSecret()) {
    return redirectWithParams(req, from, {
      oauth: "error",
      message: "Google OAuth belum lengkap di server",
    });
  }

  if (error) {
    return redirectWithParams(req, from, {
      oauth: "error",
      message: `Google OAuth dibatalkan: ${error}`,
    });
  }

  if (!code) {
    return redirectWithParams(req, from, {
      oauth: "error",
      message: "Kode OAuth Google tidak ditemukan",
    });
  }

  try {
    const { tokens } = await googleAuthClient.getToken(code);
    if (!tokens.id_token) {
      return redirectWithParams(req, from, {
        oauth: "error",
        message: "Google tidak mengembalikan id_token",
      });
    }

    const ticket = await googleTokenVerifier.verifyIdToken({
      idToken: tokens.id_token,
      audience: getGoogleClientId() || undefined,
    });
    const payload = ticket.getPayload();

    if (!payload || !payload.email || !payload.sub || !payload.email_verified) {
      return redirectWithParams(req, from, {
        oauth: "error",
        message: "Profil Google tidak valid atau email belum verifikasi",
      });
    }

    const user = await upsertGoogleUser({
      email: payload.email,
      nameFromGoogle: payload.name,
      googleSub: payload.sub,
    });
    const appTokens = generateTokens(user.id);

    return redirectWithParams(req, from, {
      oauth: "success",
      accessToken: appTokens.accessToken,
      refreshToken: appTokens.refreshToken,
      userEmail: user.email,
      userName: user.name || "",
    });
  } catch {
    return redirectWithParams(req, from, {
      oauth: "error",
      message: "Autentikasi Google gagal",
    });
  }
}
