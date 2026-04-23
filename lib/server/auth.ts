import bcrypt from "bcryptjs";
import jwt, { type JwtPayload, type SignOptions } from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";
import { createClient } from "@supabase/supabase-js";

export type OAuthFrom = "login" | "register";

type UserRow = {
  id: string;
  name: string | null;
  email: string;
};

type AppJwtPayload = JwtPayload & {
  userId?: string;
  type?: string;
};

const JWT_SECRET = process.env.JWT_SECRET || "dev_secret_change_me";
const JWT_EXPIRES_IN = "15m";
const REFRESH_EXPIRES_IN = "7d";

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
export const GOOGLE_REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || "http://localhost:3000/api/auth/google/callback";
export const FRONTEND_BASE_URL = process.env.FRONTEND_BASE_URL || "http://localhost:3000";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("SUPABASE_URL atau SUPABASE_SERVICE_ROLE_KEY belum diset di .env");
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

export const googleAuthClient = GOOGLE_CLIENT_ID && GOOGLE_CLIENT_SECRET
  ? new OAuth2Client(GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_REDIRECT_URI)
  : null;

export const googleTokenVerifier = GOOGLE_CLIENT_ID
  ? new OAuth2Client(GOOGLE_CLIENT_ID)
  : null;

const globalStore = globalThis as unknown as {
  __refreshTokens?: Map<string, string>;
};

const refreshTokens = globalStore.__refreshTokens || new Map<string, string>();
globalStore.__refreshTokens = refreshTokens;

export function generateTokens(userId: string) {
  const accessToken = jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  } as SignOptions);
  const refreshToken = jwt.sign({ userId, type: "refresh" }, JWT_SECRET, {
    expiresIn: REFRESH_EXPIRES_IN,
  } as SignOptions);
  refreshTokens.set(userId, refreshToken);
  return { accessToken, refreshToken };
}

export function verifyAccessToken(authHeader: string | null): string | null {
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  const token = authHeader.slice("Bearer ".length);
  try {
    const payload = jwt.verify(token, JWT_SECRET) as AppJwtPayload;
    return payload.userId || null;
  } catch {
    return null;
  }
}

export function refreshSessionToken(refreshToken: string): { accessToken: string; refreshToken: string } | null {
  try {
    const payload = jwt.verify(refreshToken, JWT_SECRET) as AppJwtPayload;
    if (payload.type !== "refresh" || !payload.userId) {
      return null;
    }
    const stored = refreshTokens.get(payload.userId);
    if (!stored || stored !== refreshToken) {
      return null;
    }
    return generateTokens(payload.userId);
  } catch {
    return null;
  }
}

export function clearRefreshToken(userId: string) {
  refreshTokens.delete(userId);
}

function normalizeName(email: string, nameFromGoogle: unknown) {
  if (nameFromGoogle && String(nameFromGoogle).trim()) {
    return String(nameFromGoogle).trim();
  }
  return String(email || "pengguna").split("@")[0] || "pengguna";
}

export async function upsertGoogleUser(params: {
  email: string;
  nameFromGoogle?: unknown;
  googleSub: string;
}) {
  const { email, nameFromGoogle, googleSub } = params;
  const name = normalizeName(email, nameFromGoogle);

  const { data: existing, error: existingError } = await supabase
    .from("users")
    .select("id, name, email")
    .eq("email", email)
    .maybeSingle<UserRow>();

  if (existingError) {
    throw new Error("Gagal memeriksa pengguna Google");
  }

  if (existing) {
    if ((!existing.name || !String(existing.name).trim()) && name) {
      await supabase
        .from("users")
        .update({ name })
        .eq("id", existing.id);
      return { ...existing, name };
    }
    return existing;
  }

  const generatedPassword = `google_oauth_${googleSub}_${Date.now()}`;
  const hash = await bcrypt.hash(generatedPassword, 10);

  const { data: inserted, error: insertError } = await supabase
    .from("users")
    .insert({ name, email, password_hash: hash })
    .select("id, name, email")
    .single<UserRow>();

  if (insertError || !inserted) {
    throw new Error("Gagal membuat pengguna dari Google");
  }

  return inserted;
}

export function decodeState(state: string | null): { from: OAuthFrom } {
  try {
    const raw = Buffer.from(String(state || ""), "base64url").toString("utf8");
    const parsed = JSON.parse(raw) as { from?: string };
    if (parsed.from === "register") {
      return { from: "register" };
    }
    return { from: "login" };
  } catch {
    return { from: "login" };
  }
}

export function encodeState(payload: { from: OAuthFrom }): string {
  return Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
}

export function authPageUrl(from: OAuthFrom): string {
  if (from === "register") return `${FRONTEND_BASE_URL}/auth/register`;
  return `${FRONTEND_BASE_URL}/auth/login`;
}

export function getGoogleClientId(): string | null {
  return GOOGLE_CLIENT_ID || null;
}

export function getGoogleClientSecret(): string | null {
  return GOOGLE_CLIENT_SECRET || null;
}
