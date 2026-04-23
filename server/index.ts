import "dotenv/config";

import express, { type NextFunction, type Request, type Response } from "express";
import cors from "cors";
import bcrypt from "bcryptjs";
import jwt, { type JwtPayload } from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";
import { createClient } from "@supabase/supabase-js";

declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

type OAuthFrom = "login" | "register";

type UserRow = {
  id: string;
  name: string | null;
  email: string;
  password_hash?: string;
};

type ScheduleRow = {
  id: string;
  hari: string;
  mata_kuliah: string;
  ruang: string | null;
  jam_mulai: string;
  jam_selesai: string;
};

type AppJwtPayload = JwtPayload & {
  userId?: string;
  type?: string;
};

const app = express();
const PORT = Number(process.env.API_PORT ?? 4000);
const JWT_SECRET = process.env.JWT_SECRET || "dev_secret_change_me";
const JWT_EXPIRES_IN = "15m";
const REFRESH_EXPIRES_IN = "7d";
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const GOOGLE_REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || "http://localhost:3000/api/auth/google/callback";
const FRONTEND_BASE_URL = process.env.FRONTEND_BASE_URL || "http://localhost:3000";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("SUPABASE_URL atau SUPABASE_SERVICE_ROLE_KEY belum diset di .env");
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const googleAuthClient = GOOGLE_CLIENT_ID && GOOGLE_CLIENT_SECRET
  ? new OAuth2Client(GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_REDIRECT_URI)
  : null;
const googleTokenVerifier = GOOGLE_CLIENT_ID ? new OAuth2Client(GOOGLE_CLIENT_ID) : null;

app.use(cors({
  origin: "http://localhost:3000",
  credentials: false,
}));
app.use(express.json());

// In-memory refresh token store (UTS sederhana, tanpa DB tabel refresh token)
const refreshTokens = new Map<string, string>();

function generateTokens(userId: string) {
  const accessToken = jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  });
  const refreshToken = jwt.sign({ userId, type: "refresh" }, JWT_SECRET, {
    expiresIn: REFRESH_EXPIRES_IN,
  });
  refreshTokens.set(userId, refreshToken);
  return { accessToken, refreshToken };
}

function normalizeName(email: string, nameFromGoogle: unknown) {
  if (nameFromGoogle && String(nameFromGoogle).trim()) {
    return String(nameFromGoogle).trim();
  }
  return String(email || "pengguna").split("@")[0] || "pengguna";
}

async function upsertGoogleUser({ email, name, googleSub }: { email: string; name: string; googleSub: string }) {
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
      const { error: updateError } = await supabase
        .from("users")
        .update({ name })
        .eq("id", existing.id);
      if (updateError) {
        console.error("Supabase error (update nama user google)", updateError);
      }
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
    console.error("Supabase error (insert user google)", insertError);
    throw new Error("Gagal membuat pengguna dari Google");
  }

  return inserted;
}

function encodeState(payload: { from: OAuthFrom }) {
  return Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
}

function decodeState(state: unknown): { from: OAuthFrom } {
  try {
    const raw = Buffer.from(String(state || ""), "base64url").toString("utf8");
    const parsed = JSON.parse(raw) as { from?: string };
    if (parsed && (parsed.from === "login" || parsed.from === "register")) {
      return { from: parsed.from };
    }
    return { from: "login" };
  } catch {
    return { from: "login" };
  }
}

function authPageUrl(from: OAuthFrom) {
  if (from === "register") {
    return `${FRONTEND_BASE_URL}/auth/register`;
  }
  return `${FRONTEND_BASE_URL}/auth/login`;
}

function redirectWithParams(res: Response, from: OAuthFrom, params: Record<string, string>) {
  const target = new URL(authPageUrl(from));
  Object.entries(params).forEach(([key, value]) => {
    target.searchParams.set(key, value);
  });
  return res.redirect(target.toString());
}

function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Missing Authorization header" });
  }
  const token = authHeader.slice("Bearer ".length);
  try {
    const payload = jwt.verify(token, JWT_SECRET) as AppJwtPayload;
    if (!payload.userId) {
      return res.status(401).json({ message: "Invalid or expired token" });
    }
    req.userId = payload.userId;
    next();
  } catch {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}

app.post("/api/auth/register", async (req: Request, res: Response) => {
  const { name, email, password } = (req.body || {}) as { name?: string; email?: string; password?: string };
  if (!name || !email || !password) {
    return res.status(400).json({ message: "name, email, password wajib diisi" });
  }

  try {
    const { data: existing, error: existingError } = await supabase
      .from("users")
      .select("id")
      .eq("email", email)
      .maybeSingle<{ id: string }>();

    if (existingError) {
      console.error("Supabase error (cek email)", existingError);
      return res.status(500).json({ message: "Gagal memeriksa pengguna" });
    }

    if (existing) {
      return res.status(409).json({ message: "Email sudah terdaftar" });
    }

    const hash = await bcrypt.hash(password, 10);

    const { data: inserted, error: insertError } = await supabase
      .from("users")
      .insert({ name, email, password_hash: hash })
      .select("id, name, email")
      .single<UserRow>();

    if (insertError || !inserted) {
      console.error("Supabase error (insert user)", insertError);
      return res.status(500).json({ message: "Gagal mendaftarkan pengguna" });
    }

    const tokens = generateTokens(inserted.id);
    return res.status(201).json({
      user: inserted,
      ...tokens,
    });
  } catch (err) {
    console.error("Register error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat registrasi" });
  }
});

app.post("/api/auth/login", async (req: Request, res: Response) => {
  const { email, password } = (req.body || {}) as { email?: string; password?: string };
  if (!email || !password) {
    return res.status(400).json({ message: "email dan password wajib diisi" });
  }

  try {
    const { data: user, error } = await supabase
      .from("users")
      .select("id, name, email, password_hash")
      .eq("email", email)
      .single<UserRow>();

    if (error || !user) {
      return res.status(401).json({ message: "Email atau password salah" });
    }

    const ok = await bcrypt.compare(password, user.password_hash || "");
    if (!ok) {
      return res.status(401).json({ message: "Email atau password salah" });
    }

    const tokens = generateTokens(user.id);
    return res.json({
      user: { id: user.id, name: user.name, email: user.email },
      ...tokens,
    });
  } catch (err) {
    console.error("Login error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat login" });
  }
});

app.get("/api/auth/google/start", (req: Request, res: Response) => {
  if (!googleAuthClient || !GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    return res.status(500).json({
      message: "Google OAuth belum lengkap. Set GOOGLE_CLIENT_ID dan GOOGLE_CLIENT_SECRET",
    });
  }

  const from: OAuthFrom = req.query.from === "register" ? "register" : "login";
  const state = encodeState({ from });
  const authUrl = googleAuthClient.generateAuthUrl({
    access_type: "offline",
    prompt: "select_account",
    include_granted_scopes: true,
    scope: ["openid", "email", "profile"],
    state,
  });

  return res.redirect(authUrl);
});

app.get("/api/auth/google/callback", async (req: Request, res: Response) => {
  const { code, state, error } = req.query;
  const { from } = decodeState(state);

  if (!googleAuthClient || !googleTokenVerifier || !GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    return redirectWithParams(res, from, {
      oauth: "error",
      message: "Google OAuth belum lengkap di server",
    });
  }

  if (error) {
    return redirectWithParams(res, from, {
      oauth: "error",
      message: `Google OAuth dibatalkan: ${String(error)}`,
    });
  }

  if (!code) {
    return redirectWithParams(res, from, {
      oauth: "error",
      message: "Kode OAuth Google tidak ditemukan",
    });
  }

  try {
    const { tokens } = await googleAuthClient.getToken(String(code));
    if (!tokens || !tokens.id_token) {
      return redirectWithParams(res, from, {
        oauth: "error",
        message: "Google tidak mengembalikan id_token",
      });
    }

    const ticket = await googleTokenVerifier.verifyIdToken({
      idToken: tokens.id_token,
      audience: GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();

    if (!payload || !payload.email || !payload.sub || !payload.email_verified) {
      return redirectWithParams(res, from, {
        oauth: "error",
        message: "Profil Google tidak valid atau email belum verifikasi",
      });
    }

    const normalizedName = normalizeName(payload.email, payload.name);
    const user = await upsertGoogleUser({
      email: payload.email,
      name: normalizedName,
      googleSub: payload.sub,
    });
    const appTokens = generateTokens(user.id);

    return redirectWithParams(res, from, {
      oauth: "success",
      accessToken: appTokens.accessToken,
      refreshToken: appTokens.refreshToken,
      userEmail: user.email,
      userName: user.name || "",
    });
  } catch (err) {
    console.error("Google callback error", err);
    return redirectWithParams(res, from, {
      oauth: "error",
      message: "Autentikasi Google gagal",
    });
  }
});

app.post("/api/auth/refresh", (req: Request, res: Response) => {
  const { refreshToken } = (req.body || {}) as { refreshToken?: string };
  if (!refreshToken) {
    return res.status(400).json({ message: "refreshToken wajib diisi" });
  }
  try {
    const payload = jwt.verify(refreshToken, JWT_SECRET) as AppJwtPayload;
    if (payload.type !== "refresh" || !payload.userId) {
      return res.status(400).json({ message: "Token bukan refresh token" });
    }
    const stored = refreshTokens.get(payload.userId);
    if (!stored || stored !== refreshToken) {
      return res.status(401).json({ message: "Refresh token tidak dikenal" });
    }
    const tokens = generateTokens(payload.userId);
    return res.json(tokens);
  } catch {
    return res.status(401).json({ message: "Refresh token tidak valid atau kedaluwarsa" });
  }
});

app.post("/api/auth/logout", authMiddleware, (req: Request, res: Response) => {
  if (req.userId) {
    refreshTokens.delete(req.userId);
  }
  return res.json({ message: "Logout berhasil" });
});

app.get("/api/tasks", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from("tasks")
      .select("id, title, description, deadline, completed")
      .eq("user_id", req.userId)
      .order("deadline", { ascending: true });

    if (error) {
      console.error("Supabase error (get tasks)", error);
      return res.status(500).json({ message: "Gagal mengambil tugas" });
    }

    return res.json(data || []);
  } catch (err) {
    console.error("Get tasks error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat mengambil tugas" });
  }
});

app.post("/api/tasks", authMiddleware, async (req: Request, res: Response) => {
  const { title, description, deadline } = (req.body || {}) as {
    title?: string;
    description?: string;
    deadline?: string;
  };
  if (!title || !deadline) {
    return res.status(400).json({ message: "title dan deadline wajib diisi" });
  }

  try {
    const { data: task, error } = await supabase
      .from("tasks")
      .insert({
        user_id: req.userId,
        title,
        description: description || "",
        deadline,
        completed: false,
      })
      .select("id, user_id, title, description, deadline, completed")
      .single();

    if (error || !task) {
      console.error("Supabase error (create task)", error);
      return res.status(500).json({ message: "Gagal membuat tugas" });
    }

    return res.status(201).json(task);
  } catch (err) {
    console.error("Create task error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat membuat tugas" });
  }
});

app.put("/api/tasks/:id", authMiddleware, async (req: Request, res: Response) => {
  const { id } = req.params;
  const { title, description, deadline, completed } = (req.body || {}) as {
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
      .eq("user_id", req.userId)
      .select("id, user_id, title, description, deadline, completed")
      .maybeSingle();

    if (error) {
      console.error("Supabase error (update task)", error);
      return res.status(500).json({ message: "Gagal mengubah tugas" });
    }

    if (!task) {
      return res.status(404).json({ message: "Tugas tidak ditemukan" });
    }

    return res.json(task);
  } catch (err) {
    console.error("Update task error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat mengubah tugas" });
  }
});

app.delete("/api/tasks/:id", authMiddleware, async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from("tasks")
      .delete()
      .eq("id", id)
      .eq("user_id", req.userId)
      .select("id")
      .maybeSingle();

    if (error) {
      console.error("Supabase error (delete task)", error);
      return res.status(500).json({ message: "Gagal menghapus tugas" });
    }

    if (!data) {
      return res.status(404).json({ message: "Tugas tidak ditemukan" });
    }

    return res.status(204).send();
  } catch (err) {
    console.error("Delete task error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat menghapus tugas" });
  }
});

function mapScheduleRow(row: ScheduleRow) {
  return {
    id: row.id,
    hari: row.hari,
    mataKuliah: row.mata_kuliah,
    ruang: row.ruang || "",
    jamMulai: row.jam_mulai,
    jamSelesai: row.jam_selesai,
  };
}

app.get("/api/schedules", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from("schedules")
      .select("id, hari, mata_kuliah, ruang, jam_mulai, jam_selesai")
      .eq("user_id", req.userId)
      .order("hari", { ascending: true })
      .order("jam_mulai", { ascending: true });

    if (error) {
      console.error("Supabase error (get schedules)", error);
      return res.status(500).json({ message: "Gagal mengambil jadwal" });
    }

    return res.json((data || []).map((row) => mapScheduleRow(row as ScheduleRow)));
  } catch (err) {
    console.error("Get schedules error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat mengambil jadwal" });
  }
});

app.post("/api/schedules", authMiddleware, async (req: Request, res: Response) => {
  const { hari, mataKuliah, ruang, jamMulai, jamSelesai } = (req.body || {}) as {
    hari?: string;
    mataKuliah?: string;
    ruang?: string;
    jamMulai?: string;
    jamSelesai?: string;
  };
  if (!hari || !mataKuliah || !jamMulai || !jamSelesai) {
    return res.status(400).json({ message: "hari, mataKuliah, jamMulai, jamSelesai wajib diisi" });
  }

  try {
    const { data: schedule, error } = await supabase
      .from("schedules")
      .insert({
        user_id: req.userId,
        hari,
        mata_kuliah: mataKuliah,
        ruang: ruang || "",
        jam_mulai: jamMulai,
        jam_selesai: jamSelesai,
      })
      .select("id, hari, mata_kuliah, ruang, jam_mulai, jam_selesai")
      .single<ScheduleRow>();

    if (error || !schedule) {
      console.error("Supabase error (create schedule)", error);
      return res.status(500).json({ message: "Gagal membuat jadwal" });
    }

    return res.status(201).json(mapScheduleRow(schedule));
  } catch (err) {
    console.error("Create schedule error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat membuat jadwal" });
  }
});

app.put("/api/schedules/:id", authMiddleware, async (req: Request, res: Response) => {
  const { id } = req.params;
  const { hari, mataKuliah, ruang, jamMulai, jamSelesai } = (req.body || {}) as {
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
      .eq("user_id", req.userId)
      .select("id, hari, mata_kuliah, ruang, jam_mulai, jam_selesai")
      .maybeSingle<ScheduleRow>();

    if (error) {
      console.error("Supabase error (update schedule)", error);
      return res.status(500).json({ message: "Gagal mengubah jadwal" });
    }

    if (!schedule) {
      return res.status(404).json({ message: "Jadwal tidak ditemukan" });
    }

    return res.json(mapScheduleRow(schedule));
  } catch (err) {
    console.error("Update schedule error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat mengubah jadwal" });
  }
});

app.delete("/api/schedules/:id", authMiddleware, async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from("schedules")
      .delete()
      .eq("id", id)
      .eq("user_id", req.userId)
      .select("id")
      .maybeSingle();

    if (error) {
      console.error("Supabase error (delete schedule)", error);
      return res.status(500).json({ message: "Gagal menghapus jadwal" });
    }

    if (!data) {
      return res.status(404).json({ message: "Jadwal tidak ditemukan" });
    }

    return res.status(204).send();
  } catch (err) {
    console.error("Delete schedule error", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat menghapus jadwal" });
  }
});

app.get("/api/health", (_req: Request, res: Response) => {
  return res.json({ status: "ok" });
});

app.listen(PORT, () => {
  console.log(`API server berjalan di http://localhost:${PORT}`);
});
