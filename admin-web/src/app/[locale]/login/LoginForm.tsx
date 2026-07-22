"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations, useLocale } from "next-intl";
import { useSearchParams } from "next/navigation";
import { FirebaseError } from "firebase/app";
import { useAuth } from "@/components/AuthProvider";
import { useRouter } from "@/i18n/navigation";
import { hasAnyAdminAccess } from "@/lib/permissions";
import { Button, Card, Input } from "@/components/ui";

export default function LoginForm() {
  const t = useTranslations();
  const { signIn, hasAdminAccess, appUser, loading } = useAuth();
  const router = useRouter();
  const locale = useLocale();
  const params = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!loading && appUser && hasAdminAccess) {
      const next = params.get("next") || "/dashboard";
      router.replace(next.startsWith("/") ? next : "/dashboard");
    }
  }, [loading, appUser, hasAdminAccess, router, params]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      const profile = await signIn(email.trim(), password);
      if (!hasAnyAdminAccess(profile.isSuperUser, profile.permissions)) {
        setError(t("auth.noAccess"));
        return;
      }
      // La redirección la hace el useEffect cuando el estado ya está listo
    } catch (err) {
      // Solo errores de Auth de Firebase = credenciales inválidas
      if (err instanceof FirebaseError && err.code.startsWith("auth/")) {
        setError(t("auth.invalid"));
      } else {
        console.error(err);
        setError(t("auth.invalid"));
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden px-4">
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse at 20% 20%, #d8ddd0 0%, transparent 50%), radial-gradient(ellipse at 80% 0%, #e8e4d8 0%, transparent 45%), linear-gradient(160deg, #f7f5f0, #ece8df)",
        }}
      />
      <Card className="relative z-10 w-full max-w-md p-7 shadow-[var(--shadow)]">
        <div className="mb-7">
          <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-[var(--primary)]">
            {t("app.name")}
          </p>
          <h1
            className="mt-2 text-3xl font-semibold tracking-tight"
            style={{ fontFamily: "var(--font-display), Georgia, serif" }}
          >
            {t("auth.login")}
          </h1>
          <p className="mt-2 text-sm text-[var(--muted)]">{t("app.tagline")}</p>
        </div>
        {(error || params.get("error") === "no_access") && (
          <p className="mb-4 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
            {error || t("auth.noAccess")}
          </p>
        )}
        <form onSubmit={onSubmit} className="space-y-4">
          <Input
            label={t("auth.email")}
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="email"
          />
          <Input
            label={t("auth.password")}
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
          />
          <Button type="submit" className="w-full" disabled={busy || loading}>
            {busy || loading ? t("auth.loading") : t("auth.signIn")}
          </Button>
        </form>
        <p className="mt-4 text-center text-xs text-[var(--muted)]">
          {locale.toUpperCase()}
        </p>
      </Card>
    </div>
  );
}
