require("dotenv").config();

const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { createClient } = require("@supabase/supabase-js");

const app = express();
const PORT = process.env.API_PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET || "dev_secret_change_me";
const JWT_EXPIRES_IN = "15m";
const REFRESH_EXPIRES_IN = "7d";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("SUPABASE_URL atau SUPABASE_SERVICE_ROLE_KEY belum diset di .env");
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

app.use(cors({
  origin: "http://localhost:3000",
  credentials: false,
}));
app.use(express.json());

// In-memory refresh token store (UTS sederhana, tanpa DB tabel refresh token)
const refreshTokens = new Map(); // userId -> refreshToken string

function generateTokens(userId) {
  const accessToken = jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  });
  const refreshToken = jwt.sign({ userId, type: "refresh" }, JWT_SECRET, {
    expiresIn: REFRESH_EXPIRES_IN,
  });
  refreshTokens.set(userId, refreshToken);
  return { accessToken, refreshToken };
}

function authMiddleware(req, res, next) {
  const authHeader = req.headers["authorization"];
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Missing Authorization header" });
  }
  const token = authHeader.slice("Bearer ".length);
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.userId = payload.userId;
    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}

// Auth endpoints
app.post("/api/auth/register", async (req, res) => {
  const { name, email, password } = req.body || {};
  if (!name || !email || !password) {
    return res.status(400).json({ message: "name, email, password wajib diisi" });
  }

  try {
    const { data: existing, error: existingError } = await supabase
      .from("users")
      .select("id")
      .eq("email", email)
      .maybeSingle();

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
      .single();

    if (insertError || !inserted) {
      console.error("Supabase error (insert user)", insertError);
      return res.status(500).json({ message: "Gagal mendaftarkan pengguna" });
    }

    const tokens = generateTokens(inserted.id);
    res.status(201).json({
      user: inserted,
      ...tokens,
    });
  } catch (err) {
    console.error("Register error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat registrasi" });
  }
});

app.post("/api/auth/login", async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ message: "email dan password wajib diisi" });
  }

  try {
    const { data: user, error } = await supabase
      .from("users")
      .select("id, name, email, password_hash")
      .eq("email", email)
      .single();

    if (error || !user) {
      return res.status(401).json({ message: "Email atau password salah" });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ message: "Email atau password salah" });
    }

    const tokens = generateTokens(user.id);
    res.json({
      user: { id: user.id, name: user.name, email: user.email },
      ...tokens,
    });
  } catch (err) {
    console.error("Login error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat login" });
  }
});

app.post("/api/auth/refresh", (req, res) => {
  const { refreshToken } = req.body || {};
  if (!refreshToken) {
    return res.status(400).json({ message: "refreshToken wajib diisi" });
  }
  try {
    const payload = jwt.verify(refreshToken, JWT_SECRET);
    if (payload.type !== "refresh") {
      return res.status(400).json({ message: "Token bukan refresh token" });
    }
    const stored = refreshTokens.get(payload.userId);
    if (!stored || stored !== refreshToken) {
      return res.status(401).json({ message: "Refresh token tidak dikenal" });
    }
    const tokens = generateTokens(payload.userId);
    res.json(tokens);
  } catch {
    return res.status(401).json({ message: "Refresh token tidak valid atau kedaluwarsa" });
  }
});

app.post("/api/auth/logout", authMiddleware, (req, res) => {
  refreshTokens.delete(req.userId);
  res.json({ message: "Logout berhasil" });
});

// CRUD resource: Tugas
// Model Supabase: { id (uuid), user_id, title, description, deadline, completed }

// [CRUD] READ - list tasks
app.get("/api/tasks", authMiddleware, async (req, res) => {
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

    res.json(data || []);
  } catch (err) {
    console.error("Get tasks error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil tugas" });
  }
});

// [CRUD] CREATE - create task
app.post("/api/tasks", authMiddleware, async (req, res) => {
  const { title, description, deadline } = req.body || {};
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

    res.status(201).json(task);
  } catch (err) {
    console.error("Create task error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat membuat tugas" });
  }
});

// [CRUD] UPDATE - update task
app.put("/api/tasks/:id", authMiddleware, async (req, res) => {
  const { id } = req.params;
  const { title, description, deadline, completed } = req.body || {};

  const updateData = {};
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

    res.json(task);
  } catch (err) {
    console.error("Update task error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat mengubah tugas" });
  }
});

// [CRUD] DELETE - delete task
app.delete("/api/tasks/:id", authMiddleware, async (req, res) => {
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

    res.status(204).send();
  } catch (err) {
    console.error("Delete task error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat menghapus tugas" });
  }
});

function mapScheduleRow(row) {
  return {
    id: row.id,
    hari: row.hari,
    mataKuliah: row.mata_kuliah,
    ruang: row.ruang || "",
    jamMulai: row.jam_mulai,
    jamSelesai: row.jam_selesai,
  };
}

// CRUD resource: Jadwal
// Model Supabase: { id (uuid), user_id, hari, mata_kuliah, ruang, jam_mulai, jam_selesai }

// [CRUD] READ - list schedules
app.get("/api/schedules", authMiddleware, async (req, res) => {
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

    res.json((data || []).map(mapScheduleRow));
  } catch (err) {
    console.error("Get schedules error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil jadwal" });
  }
});

// [CRUD] CREATE - create schedule
app.post("/api/schedules", authMiddleware, async (req, res) => {
  const { hari, mataKuliah, ruang, jamMulai, jamSelesai } = req.body || {};
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
      .single();

    if (error || !schedule) {
      console.error("Supabase error (create schedule)", error);
      return res.status(500).json({ message: "Gagal membuat jadwal" });
    }

    res.status(201).json(mapScheduleRow(schedule));
  } catch (err) {
    console.error("Create schedule error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat membuat jadwal" });
  }
});

// [CRUD] UPDATE - update schedule
app.put("/api/schedules/:id", authMiddleware, async (req, res) => {
  const { id } = req.params;
  const { hari, mataKuliah, ruang, jamMulai, jamSelesai } = req.body || {};

  const updateData = {};
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
      .maybeSingle();

    if (error) {
      console.error("Supabase error (update schedule)", error);
      return res.status(500).json({ message: "Gagal mengubah jadwal" });
    }

    if (!schedule) {
      return res.status(404).json({ message: "Jadwal tidak ditemukan" });
    }

    res.json(mapScheduleRow(schedule));
  } catch (err) {
    console.error("Update schedule error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat mengubah jadwal" });
  }
});

// [CRUD] DELETE - delete schedule
app.delete("/api/schedules/:id", authMiddleware, async (req, res) => {
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

    res.status(204).send();
  } catch (err) {
    console.error("Delete schedule error", err);
    res.status(500).json({ message: "Terjadi kesalahan saat menghapus jadwal" });
  }
});

app.get("/api/health", (req, res) => {
  res.json({ status: "ok" });
});

app.listen(PORT, () => {
  console.log(`API server berjalan di http://localhost:${PORT}`);
});
