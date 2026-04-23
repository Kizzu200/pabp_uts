"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { GoogleLogo } from "@/components/google-logo";

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? "";
const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";

function persistSession(data: {
  accessToken: string;
  refreshToken: string;
  user: { email: string; name?: string | null };
}) {
  if (typeof window === "undefined") return;

  window.localStorage.setItem("accessToken", data.accessToken);
  window.localStorage.setItem("refreshToken", data.refreshToken);
  window.localStorage.setItem("userEmail", data.user.email);
  if (data.user.name) {
    window.localStorage.setItem("userName", data.user.name);
  } else {
    window.localStorage.removeItem("userName");
  }

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
  if (data.user.name) {
    document.cookie = `userName=${encodeURIComponent(
      data.user.name,
    )}; Max-Age=${sevenDays}; path=/`;
  } else {
    document.cookie = "userName=; Max-Age=0; path=/";
  }
}

export default function LoginPage() {
  const router = useRouter();
  const [theme, setTheme] = useState<"light" | "dark">("light");
  const [mounted, setMounted] = useState(false);
  const isDark = theme === "dark";

  useEffect(() => {
    if (typeof window === "undefined") return;
    const stored = window.localStorage.getItem("theme");
    if (stored === "light" || stored === "dark") {
      setTheme(stored);
    } else if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
      setTheme("dark");
    }
    setMounted(true);
  }, []);

  useEffect(() => {
    if (typeof window === "undefined" || !mounted) return;
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem("theme", theme);
  }, [theme, mounted]);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!mounted || typeof window === "undefined") return;

    const url = new URL(window.location.href);
    const oauth = url.searchParams.get("oauth");
    if (!oauth) return;

    if (oauth === "success") {
      const accessToken = url.searchParams.get("accessToken") || "";
      const refreshToken = url.searchParams.get("refreshToken") || "";
      const userEmail = url.searchParams.get("userEmail") || "";
      const userName = url.searchParams.get("userName") || "";

      if (accessToken && refreshToken && userEmail) {
        persistSession({
          accessToken,
          refreshToken,
          user: { email: userEmail, name: userName || null },
        });
        router.replace("/");
        return;
      }
      setMessage("Data callback Google tidak lengkap");
    } else {
      setMessage(url.searchParams.get("message") || "Login Google gagal");
    }

    router.replace("/auth/login");
  }, [mounted, router]);

  const googleAuthUrl = "/api/auth/google/start?from=login";

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    try {
      const res = await fetch(`${API_BASE}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json().catch(() => null);
      if (!res.ok) {
        setMessage(data?.message || "Login gagal");
        return;
      }
      persistSession(data);
      setMessage("Login berhasil, mengalihkan ke halaman utama...");
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
            <p className="text-xs text-zinc-500">Login Mahasiswa</p>
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
            {loading ? "Memproses..." : "Masuk"}
          </button>
        </form>
        <div className="my-4 flex items-center gap-2">
          <div className="h-px flex-1 bg-zinc-300" />
          <span className="text-[11px] text-zinc-500">atau</span>
          <div className="h-px flex-1 bg-zinc-300" />
        </div>
        {!GOOGLE_CLIENT_ID ? (
          <p className="text-xs text-amber-600">
            NEXT_PUBLIC_GOOGLE_CLIENT_ID belum diisi di .env
          </p>
        ) : (
          <a
            href={googleAuthUrl}
            className="inline-flex w-full items-center justify-center gap-2 rounded-full border border-zinc-300 px-4 py-2 text-xs font-medium hover:bg-zinc-100"
          >
            <GoogleLogo />
            Masuk dengan Google
          </a>
        )}
        {message && (
          <p className="mt-3 text-xs text-zinc-700">{message}</p>
        )}
      </div>
    </div>
  );
}
