"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? "";

export default function RegisterPage() {
  const router = useRouter();
  const [theme, setTheme] = useState<"light" | "dark">(() => {
    if (typeof window === "undefined") return "light";
    const stored = window.localStorage.getItem("theme");
    if (stored === "light" || stored === "dark") return stored;
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  });
  const isDark = theme === "dark";

  useEffect(() => {
    if (typeof window === "undefined") return;
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem("theme", theme);
  }, [theme]);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    try {
      const res = await fetch(`${API_BASE}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, email, password }),
      });
      const data = await res.json().catch(() => null);
      if (!res.ok) {
        setMessage(data?.message || "Registrasi gagal");
        return;
      }
      if (typeof window !== "undefined") {
        window.localStorage.setItem("accessToken", data.accessToken);
        window.localStorage.setItem("refreshToken", data.refreshToken);
        window.localStorage.setItem("userEmail", data.user.email);
        if (data.user && data.user.name) {
          window.localStorage.setItem("userName", data.user.name);
        } else {
          window.localStorage.removeItem("userName");
        }

        // Simpan juga ke cookie sebagai bagian dari demonstrasi penggunaan cookie
        const fifteenMinutes = 15 * 60;
        const sevenDays = 7 * 24 * 60 * 60;
        document.cookie = `accessToken=${encodeURIComponent(
          data.accessToken,
        )}; Max-Age=${fifteenMinutes}; path=/`;
        document.cookie = `refreshToken=${encodeURIComponent(
          data.refreshToken,
        )}; Max-Age=${sevenDays}; path=/`;
        document.cookie = `userEmail=${encodeURIComponent(
          data.user.email,
        )}; Max-Age=${sevenDays}; path=/`;
        if (data.user && data.user.name) {
          document.cookie = `userName=${encodeURIComponent(
            data.user.name,
          )}; Max-Age=${sevenDays}; path=/`;
        } else {
          document.cookie = "userName=; Max-Age=0; path=/";
        }
      }
      setMessage("Registrasi berhasil, mengalihkan ke halaman utama...");
      router.push("/");
    } catch {
      setMessage("Gagal terhubung ke server API");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div
      className={`min-h-screen px-4 py-8 font-sans transition-colors ${
        isDark ? "bg-zinc-950 text-zinc-50" : "bg-zinc-50 text-zinc-900"
      }`}
    >
      <div
        className={`mx-auto max-w-md rounded-xl border p-6 shadow-sm ${
          isDark ? "border-zinc-800 bg-zinc-900" : "border-zinc-200 bg-white"
        }`}
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <div>
            <h1 className="mb-1 text-xl font-semibold">ZyaLog</h1>
            <p className="text-xs text-zinc-500">Register Mahasiswa</p>
          </div>
          <button
            type="button"
            onClick={() => setTheme(isDark ? "light" : "dark")}
            className={`flex h-8 w-8 items-center justify-center rounded-full border text-sm transition-colors ${
              isDark
                ? "border-zinc-600 bg-zinc-900 text-yellow-300 hover:bg-zinc-800"
                : "border-zinc-300 bg-white text-amber-500 hover:bg-zinc-100"
            }`}
            aria-label={isDark ? "Ubah ke mode terang" : "Ubah ke mode gelap"}
          >
            <span aria-hidden="true">{isDark ? "☀" : "🌙"}</span>
          </button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-3 text-sm">
          <div className="flex flex-col gap-1">
            <label className="text-xs font-medium text-zinc-600">Nama</label>
            <input
              className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                isDark
                  ? "border-zinc-700 bg-zinc-900 text-zinc-50 placeholder-zinc-500"
                  : "border-zinc-300 bg-white text-zinc-900 placeholder-zinc-400"
              }`}
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs font-medium text-zinc-600">Email</label>
            <input
              type="email"
              className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                isDark
                  ? "border-zinc-700 bg-zinc-900 text-zinc-50 placeholder-zinc-500"
                  : "border-zinc-300 bg-white text-zinc-900 placeholder-zinc-400"
              }`}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs font-medium text-zinc-600">Password</label>
            <input
              type="password"
              className={`rounded-lg border px-2 py-1.5 text-sm focus:border-zinc-900 focus:outline-none focus:ring-1 focus:ring-zinc-900 ${
                isDark
                  ? "border-zinc-700 bg-zinc-900 text-zinc-50 placeholder-zinc-500"
                  : "border-zinc-300 bg-white text-zinc-900 placeholder-zinc-400"
              }`}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="mt-2 inline-flex w-full items-center justify-center rounded-full bg-zinc-900 px-4 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-zinc-800 disabled:opacity-60"
          >
            {loading ? "Memproses..." : "Daftar"}
          </button>
        </form>
        {message && (
          <p className="mt-3 text-xs text-zinc-700">{message}</p>
        )}
        <p className="mt-4 text-[11px] text-zinc-500">
          Setelah berhasil register, token akan tersimpan di localStorage dan dapat digunakan pada halaman utama untuk mengelola tugas.
        </p>
      </div>
    </div>
  );
}
