"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";

type DayKey = "senin" | "selasa" | "rabu" | "kamis" | "jumat" | "sabtu" | "minggu";

type JadwalKuliah = {
  id: string;
  hari: DayKey;
  mataKuliah: string;
  ruang: string;
  jamMulai: string; // HH:MM
  jamSelesai: string; // HH:MM
};

type TugasKuliah = {
  id: string;
  mataKuliah: string;
  deskripsi: string;
  tenggat: string; // ISO string
  sudahSelesai: boolean;
};

type Theme = "light" | "dark";
type TaskFilter = "all" | "pending" | "done";

const HARI_LABEL: Record<DayKey, string> = {
  senin: "Senin",
  selasa: "Selasa",
  rabu: "Rabu",
  kamis: "Kamis",
  jumat: "Jumat",
  sabtu: "Sabtu",
  minggu: "Minggu",
};

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? "";

function formatDateTimeForInput(date: Date) {
  const pad = (n: number) => n.toString().padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function isWithinNextHours(targetIso: string, hours: number) {
  const now = new Date();
  const target = new Date(targetIso);
  const diffMs = target.getTime() - now.getTime();
  return diffMs > 0 && diffMs <= hours * 60 * 60 * 1000;
}

export default function Home() {
  // Jadwal dikelola via API (Supabase)
  const [jadwal, setJadwal] = useState<JadwalKuliah[]>([]);
  // Tugas dikelola via API sebagai resource utama
  const [tugas, setTugas] = useState<TugasKuliah[]>([]);

  const [theme, setTheme] = useState<Theme>(() => {
    if (typeof window === "undefined") return "light";
    const stored = window.localStorage.getItem("theme");
    if (stored === "light" || stored === "dark") return stored;
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  });

  const [taskFilter, setTaskFilter] = useState<TaskFilter>("all");

  const [accessToken, setAccessToken] = useState<string | null>(
    () => (typeof window !== "undefined" ? window.localStorage.getItem("accessToken") : null)
  );
  const [refreshToken, setRefreshToken] = useState<string | null>(
    () => (typeof window !== "undefined" ? window.localStorage.getItem("refreshToken") : null)
  );
  const [currentUserEmail, setCurrentUserEmail] = useState<string | null>(
    () => (typeof window !== "undefined" ? window.localStorage.getItem("userEmail") : null)
  );
  const [currentUserName, setCurrentUserName] = useState<string | null>(
    () => (typeof window !== "undefined" ? window.localStorage.getItem("userName") : null)
  );
  const [authError, setAuthError] = useState<string | null>(null);

  const [hariBaru, setHariBaru] = useState<DayKey>("senin");
  const [mataKuliahBaru, setMataKuliahBaru] = useState("");
  const [ruangBaru, setRuangBaru] = useState("");
  const [jamMulaiBaru, setJamMulaiBaru] = useState("");
  const [jamSelesaiBaru, setJamSelesaiBaru] = useState("");
  const [editingJadwalId, setEditingJadwalId] = useState<string | null>(null);

  const [tugasMataKuliah, setTugasMataKuliah] = useState("");
  const [tugasDeskripsi, setTugasDeskripsi] = useState("");
  const [tugasTenggat, setTugasTenggat] = useState<string>(() => {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    d.setHours(23, 59, 0, 0);
    return formatDateTimeForInput(d);
  });
  const [editingTugasId, setEditingTugasId] = useState<string | null>(null);

  const tugasSegera = useMemo(
    () => tugas.filter((t) => !t.sudahSelesai && isWithinNextHours(t.tenggat, 24)),
    [tugas]
  );

  const totalTugas = tugas.length;
  const selesaiTugas = tugas.filter((t) => t.sudahSelesai).length;
  const belumSelesaiTugas = totalTugas - selesaiTugas;
  const progressTugas = totalTugas === 0 ? 0 : selesaiTugas / totalTugas;

  // Sinkronkan tema ke attribute data-theme di html root
  useEffect(() => {
    if (typeof window === "undefined") return;
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem("theme", theme);
  }, [theme]);

  async function refreshAuthTokens() {
    if (!refreshToken) return null;
    const r = await fetch(`${API_BASE}/api/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });
    if (!r.ok) return null;
    const data = await r.json();
    const newAccess = data.accessToken as string;
    const newRefresh = data.refreshToken as string;
    setAccessToken(newAccess);
    setRefreshToken(newRefresh);
    if (typeof window !== "undefined") {
      window.localStorage.setItem("accessToken", newAccess);
      window.localStorage.setItem("refreshToken", newRefresh);
    }
    return data as { accessToken: string; refreshToken: string };
  }

  function clearAuthSession() {
    setAuthError("Sesi login kedaluwarsa, silakan login ulang.");
    setAccessToken(null);
    setRefreshToken(null);
    if (typeof window !== "undefined") {
      window.localStorage.removeItem("accessToken");
      window.localStorage.removeItem("refreshToken");
    }
  }

  // Ambil tugas & jadwal dari API ketika sudah login
  useEffect(() => {
    async function fetchTasksAndSchedules() {
      if (!accessToken) return;
      try {
        let tokenToUse = accessToken;

        let res = await fetch(`${API_BASE}/api/tasks`, {
          headers: { Authorization: `Bearer ${tokenToUse}` },
        });
        if (res.status === 401) {
          const refreshed = await refreshAuthTokens();
          if (!refreshed) {
            clearAuthSession();
            return;
          }
          tokenToUse = refreshed.accessToken;
          res = await fetch(`${API_BASE}/api/tasks`, {
            headers: { Authorization: `Bearer ${tokenToUse}` },
          });
        }

        if (res.ok) {
          const tasksFromApi: {
            id: string;
            title: string;
            description: string;
            deadline: string;
            completed: boolean;
          }[] = await res.json();
          setTugas(
            tasksFromApi.map((t) => ({
              id: t.id,
              mataKuliah: t.title,
              deskripsi: t.description,
              tenggat: t.deadline,
              sudahSelesai: t.completed,
            }))
          );
        }

        let scheduleRes = await fetch(`${API_BASE}/api/schedules`, {
          headers: { Authorization: `Bearer ${tokenToUse}` },
        });
        if (scheduleRes.status === 401) {
          const refreshed = await refreshAuthTokens();
          if (!refreshed) {
            clearAuthSession();
            return;
          }
          tokenToUse = refreshed.accessToken;
          scheduleRes = await fetch(`${API_BASE}/api/schedules`, {
            headers: { Authorization: `Bearer ${tokenToUse}` },
          });
        }

        if (scheduleRes.ok) {
          const schedulesFromApi: JadwalKuliah[] = await scheduleRes.json();
          setJadwal(schedulesFromApi);
        }
      } catch (err) {
        console.error("Gagal mengambil data", err);
      }
    }
    fetchTasksAndSchedules();
  }, [accessToken, refreshToken]);

  useEffect(() => {
    if (tugasSegera.length === 0) return;
    const next = tugasSegera[0];
    const tenggat = new Date(next.tenggat).toLocaleString("id-ID", {
      dateStyle: "medium",
      timeStyle: "short",
    });
    // Pengingat sederhana via alert browser
    // (akan muncul setiap refresh bila masih dalam 24 jam dan belum selesai)
    alert(`Pengingat tugas segera:\n${next.mataKuliah} - ${next.deskripsi}\nTenggat: ${tenggat}`);
  }, [tugasSegera]);

  const byHari = useMemo(() => {
    const map: Record<DayKey, JadwalKuliah[]> = {
      senin: [],
      selasa: [],
      rabu: [],
      kamis: [],
      jumat: [],
      sabtu: [],
      minggu: [],
    };
    for (const j of jadwal) {
      map[j.hari].push(j);
    }
    (Object.keys(map) as DayKey[]).forEach((k) => {
      map[k].sort((a, b) => a.jamMulai.localeCompare(b.jamMulai));
    });
    return map;
  }, [jadwal]);

  function handleTambahJadwal(e: React.FormEvent) {
    e.preventDefault();
    if (!mataKuliahBaru || !jamMulaiBaru || !jamSelesaiBaru) return;
    if (!accessToken) {
      setAuthError("Harus login dulu sebelum menambah jadwal.");
      return;
    }
    (async () => {
      try {
        const isEdit = !!editingJadwalId;
        const url = isEdit
          ? `${API_BASE}/api/schedules/${editingJadwalId}`
          : `${API_BASE}/api/schedules`;
        const method = isEdit ? "PUT" : "POST";
        const res = await fetch(url, {
          method,
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            hari: hariBaru,
            mataKuliah: mataKuliahBaru,
            ruang: ruangBaru,
            jamMulai: jamMulaiBaru,
            jamSelesai: jamSelesaiBaru,
          }),
        });
        if (!res.ok) {
          const data = await res.json().catch(() => null);
          setAuthError(
            data?.message || (isEdit ? "Gagal mengubah jadwal di API" : "Gagal menambah jadwal ke API"),
          );
          return;
        }
        const baru: JadwalKuliah = await res.json();
        setJadwal((prev) => {
          if (!isEdit) return [...prev, baru];
          return prev.map((j) => (j.id === editingJadwalId ? baru : j));
        });
        setMataKuliahBaru("");
        setRuangBaru("");
        setJamMulaiBaru("");
        setJamSelesaiBaru("");
        setEditingJadwalId(null);
      } catch {
        setAuthError("Gagal terhubung ke server API");
      }
    })();
  }

  function handleHapusJadwal(id: string) {
    setJadwal((prev) => prev.filter((j) => j.id !== id));
    if (!accessToken) return;
    (async () => {
      try {
        await fetch(`${API_BASE}/api/schedules/${id}`, {
          method: "DELETE",
          headers: { Authorization: `Bearer ${accessToken}` },
        });
      } catch {}
    })();
  }

  function handleEditJadwal(item: JadwalKuliah) {
    setHariBaru(item.hari);
    setMataKuliahBaru(item.mataKuliah);
    setRuangBaru(item.ruang);
    setJamMulaiBaru(item.jamMulai);
    setJamSelesaiBaru(item.jamSelesai);
    setEditingJadwalId(item.id);
  }

  function handleTambahTugas(e: React.FormEvent) {
    e.preventDefault();
    if (!tugasMataKuliah || !tugasDeskripsi || !tugasTenggat) return;
    if (!accessToken) {
      setAuthError("Harus login dulu sebelum menambah tugas.");
      return;
    }
    const iso = new Date(tugasTenggat).toISOString();
    (async () => {
      try {
        const isEdit = !!editingTugasId;
        const url = isEdit
          ? `${API_BASE}/api/tasks/${editingTugasId}`
          : `${API_BASE}/api/tasks`;
        const method = isEdit ? "PUT" : "POST";
        const res = await fetch(url, {
          method,
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            title: tugasMataKuliah,
            description: tugasDeskripsi,
            deadline: iso,
          }),
        });
        if (!res.ok) {
          const data = await res.json().catch(() => null);
          setAuthError(
            data?.message || (isEdit ? "Gagal mengubah tugas di API" : "Gagal menambah tugas ke API"),
          );
          return;
        }
        const t = await res.json();
        const baru: TugasKuliah = {
          id: t.id,
          mataKuliah: t.title,
          deskripsi: t.description,
          tenggat: t.deadline,
          sudahSelesai: t.completed,
        };
        setTugas((prev) => {
          if (!isEdit) return [...prev, baru];
          return prev.map((task) => (task.id === editingTugasId ? baru : task));
        });
        setTugasMataKuliah("");
        setTugasDeskripsi("");
        setEditingTugasId(null);
      } catch {
        setAuthError("Gagal terhubung ke server API");
      }
    })();
  }

  function handleToggleSelesai(id: string) {
    const target = tugas.find((t) => t.id === id);
    if (!target || !accessToken) return;
    const baruStatus = !target.sudahSelesai;
    setTugas((prev) =>
      prev.map((t) => (t.id === id ? { ...t, sudahSelesai: baruStatus } : t))
    );
    (async () => {
      try {
        await fetch(`${API_BASE}/api/tasks/${id}`, {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({ completed: baruStatus }),
        });
      } catch {}
    })();
  }

  function handleHapusTugas(id: string) {
    setTugas((prev) => prev.filter((t) => t.id !== id));
    if (!accessToken) return;
    (async () => {
      try {
        await fetch(`${API_BASE}/api/tasks/${id}`, {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        });
      } catch {}
    })();
  }

  const tugasTerurut = useMemo(
    () => {
      const filtered = tugas.filter((t) => {
        if (taskFilter === "pending") return !t.sudahSelesai;
        if (taskFilter === "done") return t.sudahSelesai;
        return true;
      });
      return filtered.sort(
        (a, b) => new Date(a.tenggat).getTime() - new Date(b.tenggat).getTime()
      );
    },
    [tugas, taskFilter]
  );

  const isDark = theme === "dark";

  const dapatTambahJadwal =
    mataKuliahBaru.trim() !== "" &&
    jamMulaiBaru.trim() !== "" &&
    jamSelesaiBaru.trim() !== "" &&
    !!accessToken;

  const dapatTambahTugas =
    tugasMataKuliah.trim() !== "" &&
    tugasDeskripsi.trim() !== "" &&
    tugasTenggat.trim() !== "" &&
    !!accessToken;

  return (
    <div
      className={`min-h-screen px-4 py-8 font-sans transition-colors ${
        isDark ? "bg-zinc-950 text-zinc-50" : "bg-zinc-50 text-zinc-900"
      }`}
    >
      <div className="mx-auto flex max-w-6xl flex-col gap-6 md:flex-row">
        <aside
          className={`mb-4 w-full rounded-2xl border px-4 py-4 text-xs shadow-sm md:mb-0 md:w-64 ${
            isDark ? "border-zinc-800 bg-zinc-900" : "border-zinc-200 bg-white"
          }`}
        >
          <h2 className="mb-4 text-sm font-semibold tracking-tight">
            ✨ Panel Tugas
          </h2>
          <div className="mb-4 grid grid-cols-3 gap-2 text-center">
            <div
              className={`rounded-xl px-2 py-2 ${
                isDark ? "bg-zinc-800" : "bg-zinc-50"
              }`}
            >
              <div className="text-base font-semibold">{totalTugas}</div>
              <div className="text-[10px] text-zinc-500">Semua</div>
            </div>
            <div
              className={`rounded-xl px-2 py-2 ${
                isDark ? "bg-zinc-800" : "bg-zinc-50"
              }`}
            >
              <div className="text-base font-semibold">{belumSelesaiTugas}</div>
              <div className="text-[10px] text-zinc-500">Belum</div>
            </div>
            <div
              className={`rounded-xl px-2 py-2 ${
                isDark ? "bg-zinc-800" : "bg-zinc-50"
              }`}
            >
              <div className="text-base font-semibold">{selesaiTugas}</div>
              <div className="text-[10px] text-zinc-500">Selesai</div>
            </div>
          </div>
          <div className="mb-2 text-[10px] font-semibold tracking-wide text-zinc-500">
            KATEGORI
          </div>
          <nav className="flex flex-col gap-1 text-[11px]">
            <button
              type="button"
              onClick={() => setTaskFilter("all")}
              className={`flex items-center justify-between rounded-lg px-3 py-1.5 text-left transition-colors ${
                taskFilter === "all"
                  ? "bg-red-500/10 text-red-400"
                  : isDark
                  ? "text-zinc-300 hover:bg-zinc-800"
                  : "text-zinc-700 hover:bg-zinc-100"
              }`}
            >
              <span>Semua Tugas</span>
            </button>
            <button
              type="button"
              onClick={() => setTaskFilter("pending")}
              className={`flex items-center justify-between rounded-lg px-3 py-1.5 text-left transition-colors ${
                taskFilter === "pending"
                  ? "bg-red-500/10 text-red-400"
                  : isDark
                  ? "text-zinc-300 hover:bg-zinc-800"
                  : "text-zinc-700 hover:bg-zinc-100"
              }`}
            >
              <span>Belum Selesai</span>
            </button>
            <button
              type="button"
              onClick={() => setTaskFilter("done")}
              className={`flex items-center justify-between rounded-lg px-3 py-1.5 text-left transition-colors ${
                taskFilter === "done"
                  ? "bg-red-500/10 text-red-400"
                  : isDark
                  ? "text-zinc-300 hover:bg-zinc-800"
                  : "text-zinc-700 hover:bg-zinc-100"
              }`}
            >
              <span>Selesai</span>
            </button>
          </nav>
          <div className="mt-3 flex flex-col gap-2">
            <div className="flex items-center justify-between">
              <div className="text-[11px] font-medium text-zinc-500">
                Daftar Tugas
              </div>
              <div className="flex flex-col items-end gap-1">
                <p className="text-[11px] text-zinc-400">
                  {tugas.filter((t) => !t.sudahSelesai).length} belum selesai
                </p>
                <div className="flex items-center gap-2">
                  <div
                    className={`h-1 w-16 overflow-hidden rounded-full ${
                      isDark ? "bg-zinc-800" : "bg-zinc-200"
                    }`}
                  >
                    <div
                      className="h-full rounded-full bg-emerald-500 transition-all"
                      style={{ width: `${Math.round(progressTugas * 100)}%` }}
                    />
                  </div>
                  <span className="text-[10px] text-zinc-500">
                    {Math.round(progressTugas * 100)}%
                  </span>
                </div>
              </div>
            </div>
            {tugasTerurut.length > 0 && (
              <ul className="mt-1 space-y-1 text-[11px] text-zinc-400">
                {tugasTerurut.slice(0, 3).map((t) => {
                  const tenggatLabel = new Date(t.tenggat).toLocaleString("id-ID", {
                    dateStyle: "medium",
                    timeStyle: "short",
                  });
                  return (
                    <li key={t.id} className="border-l border-zinc-700 pl-2">
                      <p className={t.sudahSelesai ? "line-through text-zinc-500" : "font-medium text-zinc-200"}>
                        {t.mataKuliah}
                      </p>
                      <p>{t.deskripsi}</p>
                      <p className="text-[10px] text-zinc-500">Tenggat: {tenggatLabel}</p>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
          <hr className="my-4 border-zinc-800/60" />
        </aside>

        <div className="flex flex-1 flex-col gap-4">
          <header className="flex flex-col gap-3 border-b border-zinc-200 pb-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h1 className="text-3xl font-semibold tracking-tight">
                ZyaLog 
              </h1>
              <p className="text-sm text-zinc-600">
                Kelola jadwal mingguan dan tenggat tugas
              </p>
            </div>
            <div className="flex flex-col items-end gap-2 text-right text-xs text-zinc-500">
              {currentUserEmail ? (
                <div className="flex flex-col items-end gap-1">
                  <p className="font-medium text-zinc-700">
                    {currentUserName || currentUserEmail}
                  </p>
                  {currentUserName && (
                    <p className="text-[11px] text-zinc-500">{currentUserEmail}</p>
                  )}
                  <button
                    type="button"
                    onClick={async () => {
                      try {
                        if (accessToken) {
                          await fetch(`${API_BASE}/api/auth/logout`, {
                            method: "POST",
                            headers: { Authorization: `Bearer ${accessToken}` },
                          });
                        }
                      } catch {}
                      setAccessToken(null);
                      setRefreshToken(null);
                      setCurrentUserEmail(null);
                      setCurrentUserName(null);
                      setJadwal([]);
                      setTugas([]);
                      setEditingJadwalId(null);
                      setEditingTugasId(null);
                      if (typeof window !== "undefined") {
                        window.localStorage.removeItem("accessToken");
                        window.localStorage.removeItem("refreshToken");
                        window.localStorage.removeItem("userEmail");
                        window.localStorage.removeItem("userName");
                        // Hapus juga cookie yang digunakan saat login/register
                        document.cookie = "accessToken=; Max-Age=0; path=/";
                        document.cookie = "refreshToken=; Max-Age=0; path=/";
                        document.cookie = "userEmail=; Max-Age=0; path=/";
                        document.cookie = "userName=; Max-Age=0; path=/";
                        window.location.reload();
                      }
                    }}
                    className="rounded-full border border-zinc-300 px-3 py-0.5 text-[11px] font-medium text-zinc-700 hover:bg-zinc-100"
                  >
                    Logout
                  </button>
                </div>
              ) : (
                <div className="flex flex-col items-end gap-1">
                  <div className="flex gap-2">
                    <Link
                      href="/auth/login"
                      className="rounded-full border border-zinc-300 px-3 py-1 text-[11px] font-medium text-zinc-700 hover:bg-zinc-100"
                    >
                      Login
                    </Link>
                    <Link
                      href="/auth/register"
                      className="rounded-full bg-zinc-900 px-3 py-1 text-[11px] font-medium text-white shadow-sm hover:bg-zinc-800"
                    >
                      Register
                    </Link>
                  </div>
                </div>
              )}
              <button
                type="button"
                onClick={() => setTheme(isDark ? "light" : "dark")}
                className={`mt-2 flex h-8 w-8 items-center justify-center rounded-full border text-sm transition-colors ${
                  isDark
                    ? "border-zinc-600 bg-zinc-900 text-yellow-300 hover:bg-zinc-800"
                    : "border-zinc-300 bg-white text-amber-500 hover:bg-zinc-100"
                }`}
                aria-label={isDark ? "Ubah ke mode terang" : "Ubah ke mode gelap"}
              >
                <span aria-hidden="true">{isDark ? "☀" : "🌙"}</span>
              </button>
            </div>
          </header>

          {authError && (
            <div className="rounded-md bg-red-50 px-3 py-2 text-xs text-red-700">
              {authError}
            </div>
          )}

          <main className="grid gap-6 lg:grid-cols-5">
            <section className="lg:col-span-3 flex flex-col gap-4">
              <h2 className="text-xl font-semibold">Jadwal Mingguan</h2>
              <div
                className={`rounded-xl border p-4 shadow-sm ${
                  isDark ? "border-zinc-800 bg-zinc-900" : "border-zinc-200 bg-white"
                }`}
              >
                <form
                  onSubmit={handleTambahJadwal}
                  className="mb-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4"
                >
                  <div className="flex flex-col gap-1">
                    <label
                      className={`text-xs font-medium ${
                        isDark ? "text-zinc-300" : "text-zinc-600"
                      }`}
                    >
                      Hari
                    </label>
                    <select
                      className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                        isDark
                          ? "border-zinc-700 bg-zinc-900 text-zinc-50"
                          : "border-zinc-300 bg-white text-zinc-900"
                      }`}
                      value={hariBaru}
                      onChange={(e) => setHariBaru(e.target.value as DayKey)}
                    >
                      {(Object.keys(HARI_LABEL) as DayKey[]).map((k) => (
                        <option key={k} value={k}>
                          {HARI_LABEL[k]}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="flex flex-col gap-1">
                    <label
                      className={`text-xs font-medium ${
                        isDark ? "text-zinc-300" : "text-zinc-600"
                      }`}
                    >
                      Mata Kuliah
                    </label>
                    <input
                      className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                        isDark
                          ? "border-zinc-700 bg-zinc-900 text-zinc-50 placeholder-zinc-500"
                          : "border-zinc-300 bg-white text-zinc-900 placeholder-zinc-400"
                      }`}
                      value={mataKuliahBaru}
                      onChange={(e) => setMataKuliahBaru(e.target.value)}
                      placeholder="Contoh: PABP"
                    />
                  </div>
                  <div className="flex flex-col gap-1">
                    <label
                      className={`text-xs font-medium ${
                        isDark ? "text-zinc-300" : "text-zinc-600"
                      }`}
                    >
                      Ruang (opsional)
                    </label>
                    <input
                      className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                        isDark
                          ? "border-zinc-700 bg-zinc-900 text-zinc-50 placeholder-zinc-500"
                          : "border-zinc-300 bg-white text-zinc-900 placeholder-zinc-400"
                      }`}
                      value={ruangBaru}
                      onChange={(e) => setRuangBaru(e.target.value)}
                      placeholder="Contoh: Lab 3"
                    />
                  </div>
                  <div className="flex flex-col gap-1 sm:col-span-2 lg:col-span-1">
                    <label
                      className={`text-xs font-medium ${
                        isDark ? "text-zinc-300" : "text-zinc-600"
                      }`}
                    >
                      Jam
                    </label>
                    <div className="flex flex-wrap items-center gap-1">
                      <input
                        type="time"
                        className={`min-w-[90px] flex-1 rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                          isDark
                            ? "border-zinc-700 bg-zinc-900 text-zinc-50"
                            : "border-zinc-300 bg-white text-zinc-900"
                        }`}
                        value={jamMulaiBaru}
                        onChange={(e) => setJamMulaiBaru(e.target.value)}
                      />
                      <span className="text-xs text-zinc-500">s/d</span>
                      <input
                        type="time"
                        className={`min-w-[90px] flex-1 rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                          isDark
                            ? "border-zinc-700 bg-zinc-900 text-zinc-50"
                            : "border-zinc-300 bg-white text-zinc-900"
                        }`}
                        value={jamSelesaiBaru}
                        onChange={(e) => setJamSelesaiBaru(e.target.value)}
                      />
                    </div>
                  </div>
                  <div className="sm:col-span-2 lg:col-span-4 flex justify-end">
                    <button
                      type="submit"
                      disabled={!dapatTambahJadwal}
                      className={`mt-1 inline-flex items-center justify-center rounded-full px-4 py-1.5 text-xs font-medium text-white shadow-sm transition-colors ${
                        dapatTambahJadwal
                          ? "bg-zinc-900 hover:bg-zinc-800"
                          : "bg-zinc-400 cursor-not-allowed"
                      }`}
                    >
                      {editingJadwalId ? "Simpan Perubahan" : "+ Tambah Jadwal"}
                    </button>
                  </div>
                </form>

                      {!accessToken && (
                        <p className="mt-1 text-[11px] text-red-600">
                          Anda harus login terlebih dahulu sebelum menambah jadwal.
                        </p>
                      )}

                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  {(Object.keys(HARI_LABEL) as DayKey[]).map((hari) => (
                    <div
                      key={hari}
                      className={`rounded-xl border p-3 shadow-sm ${
                        isDark
                          ? "border-zinc-800 bg-zinc-900"
                          : "border-zinc-200 bg-white"
                      }`}
                    >
                      <h3 className="mb-2 text-sm font-semibold uppercase tracking-wide text-zinc-700">
                        {HARI_LABEL[hari]}
                      </h3>
                      {byHari[hari].length === 0 ? (
                        <div className="flex items-center gap-2 text-xs text-zinc-500">
                          <span className="inline-block h-4 w-4 rounded-full border border-dashed border-zinc-400" />
                          <span>Belum ada jadwal.</span>
                        </div>
                      ) : (
                        <ul className="flex flex-col gap-1.5 text-xs">
                          {byHari[hari].map((item) => (
                            <li
                              key={item.id}
                              className={`flex items-center justify-between rounded-md px-2 py-1.5 shadow-sm ${
                                isDark ? "bg-zinc-800" : "bg-white"
                              }`}
                            >
                              <div>
                                <p className="font-medium">{item.mataKuliah}</p>
                                <p className="text-[11px] text-zinc-500">
                                  {item.jamMulai} - {item.jamSelesai}
                                  {item.ruang ? ` · ${item.ruang}` : ""}
                                </p>
                              </div>
                              <div className="flex flex-col items-end gap-1 text-[11px]">
                                <button
                                  type="button"
                                  onClick={() => handleEditJadwal(item)}
                                  className="font-medium text-zinc-600 hover:text-zinc-900"
                                >
                                  Edit
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleHapusJadwal(item.id)}
                                  className="font-medium text-red-500 hover:text-red-600"
                                >
                                  Hapus
                                </button>
                              </div>
                            </li>
                          ))}
                        </ul>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            </section>

            <section className="lg:col-span-2 flex flex-col gap-4">
              <div
                className={`rounded-xl border p-4 shadow-sm ${
                  isDark ? "border-zinc-800 bg-zinc-900" : "border-zinc-200 bg-white"
                }`}
              >
                <h2 className="mb-3 text-lg font-semibold">Tugas Kuliah</h2>
                <form onSubmit={handleTambahTugas} className="mb-4 space-y-2">
                  <div className="flex flex-col gap-1">
                    <label className="text-xs font-medium text-zinc-600">
                      Mata Kuliah
                    </label>
                    <input
                      id="form-tugas"
                      className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                        isDark
                          ? "border-zinc-700 bg-zinc-900 text-zinc-50 placeholder-zinc-500"
                          : "border-zinc-300 bg-white text-zinc-900 placeholder-zinc-400"
                      }`}
                      value={tugasMataKuliah}
                      onChange={(e) => setTugasMataKuliah(e.target.value)}
                      placeholder="Contoh: PABP"
                    />
                  </div>
                  <div className="flex flex-col gap-1">
                    <label className="text-xs font-medium text-zinc-600">
                      Deskripsi Tugas
                    </label>
                    <textarea
                      className={`min-h-[60px] rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                        isDark
                          ? "border-zinc-700 bg-zinc-900 text-zinc-50 placeholder-zinc-500"
                          : "border-zinc-300 bg-white text-zinc-900 placeholder-zinc-400"
                      }`}
                      value={tugasDeskripsi}
                      onChange={(e) => setTugasDeskripsi(e.target.value)}
                      placeholder="Contoh: Buat aplikasi pencatatan jadwal..."
                    />
                  </div>
                  <div className="flex flex-col gap-1">
                    <label className="text-xs font-medium text-zinc-600">
                      Tenggat
                    </label>
                    <input
                      type="datetime-local"
                      className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                        isDark
                          ? "border-zinc-700 bg-zinc-900 text-zinc-50"
                          : "border-zinc-300 bg-white text-zinc-900"
                      }`}
                      value={tugasTenggat}
                      onChange={(e) => setTugasTenggat(e.target.value)}
                    />
                  </div>
                  <div className="flex justify-end pt-1">
                    <button
                      type="submit"
                      disabled={!dapatTambahTugas}
                      className={`inline-flex items-center justify-center rounded-full px-4 py-1.5 text-xs font-medium text-white shadow-sm transition-colors ${
                        dapatTambahTugas
                          ? "bg-emerald-600 hover:bg-emerald-500"
                          : "bg-emerald-300 cursor-not-allowed"
                      }`}
                    >
                      {editingTugasId ? "Simpan Perubahan" : "+ Tambah Tugas"}
                    </button>
                  </div>
                </form>

                {editingTugasId && (
                  <p className="mt-1 text-[11px] text-zinc-500">
                    Sedang mengedit tugas yang sudah tersimpan.
                  </p>
                )}

                {!accessToken && (
                  <p className="mt-1 text-[11px] text-red-600">
                    Anda harus login terlebih dahulu sebelum menambah tugas.
                  </p>
                )}

                <div className="mb-2 flex items-center justify-between">
                  <h3 className="text-sm font-semibold">Daftar Tugas</h3>
                  <div className="flex flex-col items-end gap-1">
                    <p className="text-[11px] text-zinc-500">
                      {tugas.filter((t) => !t.sudahSelesai).length} belum selesai
                    </p>
                    <div className="flex items-center gap-2">
                      <div
                        className={`h-1.5 w-24 overflow-hidden rounded-full ${
                          isDark ? "bg-zinc-800" : "bg-zinc-200"
                        }`}
                      >
                        <div
                          className="h-full rounded-full bg-emerald-500 transition-all"
                          style={{ width: `${Math.round(progressTugas * 100)}%` }}
                        />
                      </div>
                      <span className="text-[10px] text-zinc-500">
                        {Math.round(progressTugas * 100)}%
                      </span>
                    </div>
                  </div>
                </div>

                {tugasTerurut.length === 0 ? (
                  <p className="text-xs text-zinc-500">Belum ada tugas tercatat.</p>
                ) : (
                  <ul className="flex max-h-80 flex-col gap-2 overflow-y-auto pr-1 text-xs">
                    {tugasTerurut.map((t) => {
                      const tenggatLabel = new Date(t.tenggat).toLocaleString(
                        "id-ID",
                        { dateStyle: "medium", timeStyle: "short" }
                      );
                      const isSegera = isWithinNextHours(t.tenggat, 24);
                      const isLewat = new Date(t.tenggat).getTime() < new Date().getTime();
                      return (
                        <li
                          key={t.id}
                          className={`flex items-start justify-between gap-2 rounded-md px-2 py-1.5 ${
                            isDark ? "bg-zinc-800" : "bg-zinc-50"
                          }`}
                        >
                          <div className="flex flex-1 items-start gap-2">
                            <input
                              type="checkbox"
                              className="mt-1 h-3.5 w-3.5 rounded border-zinc-400 text-emerald-600 focus:ring-emerald-500"
                              checked={t.sudahSelesai}
                              onChange={() => handleToggleSelesai(t.id)}
                            />
                            <div>
                              <p
                                className={`font-medium ${
                                  t.sudahSelesai ? "line-through text-zinc-400" : ""
                                }`}
                              >
                                {t.mataKuliah}
                              </p>
                              <p
                                className={`text-[11px] ${
                                  t.sudahSelesai ? "text-zinc-400" : "text-zinc-700"
                                }`}
                              >
                                {t.deskripsi}
                              </p>
                              <p
                                className={`mt-0.5 text-[11px] ${
                                  !t.sudahSelesai && isSegera
                                    ? "text-amber-700"
                                    : !t.sudahSelesai && isLewat
                                    ? "text-red-600"
                                    : "text-zinc-500"
                                }`}
                              >
                                Tenggat: {tenggatLabel}
                                {isSegera && !t.sudahSelesai && (
                                  <span className="ml-1 rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-semibold text-amber-700">
                                    &lt; 24 jam!
                                  </span>
                                )}
                              </p>
                            </div>
                          </div>
                          <div className="mt-0.5 flex flex-col items-end gap-1 text-[11px]">
                            <button
                              type="button"
                              onClick={() => {
                                setTugasMataKuliah(t.mataKuliah);
                                setTugasDeskripsi(t.deskripsi);
                                setTugasTenggat(formatDateTimeForInput(new Date(t.tenggat)));
                                setEditingTugasId(t.id);
                              }}
                              className="font-medium text-zinc-600 hover:text-zinc-900"
                            >
                              Edit
                            </button>
                            <button
                              type="button"
                              onClick={() => handleHapusTugas(t.id)}
                              className="font-medium text-red-500 hover:text-red-600"
                            >
                              Hapus
                            </button>
                          </div>
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>

              {tugasSegera.length > 0 && (
                <div className="rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-900">
                  <p className="font-semibold">Tugas dalam 24 jam ke depan:</p>
                  <ul className="mt-1 list-disc pl-4">
                    {tugasSegera.map((t) => (
                      <li key={t.id}>
                        <span className="font-medium">{t.mataKuliah}</span> - {t.deskripsi}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </section>
          </main>
        </div>
      </div>
    </div>
  );
}
