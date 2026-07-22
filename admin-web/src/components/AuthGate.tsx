"use client";

import { useEffect } from "react";
import { useAuth } from "./AuthProvider";
import { usePathname, useRouter } from "@/i18n/navigation";

export function AuthGate({ children }: { children: React.ReactNode }) {
  const { loading, firebaseUser, appUser, hasAdminAccess } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (loading) return;

    if (!firebaseUser) {
      router.replace(`/login?next=${encodeURIComponent(pathname)}`);
      return;
    }

    // Solo denegar cuando el perfil ya cargó y no tiene acceso
    if (appUser && !hasAdminAccess) {
      router.replace("/login?error=no_access");
    }
  }, [loading, firebaseUser, appUser, hasAdminAccess, router, pathname]);

  if (loading || !firebaseUser || !appUser) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[var(--bg)] text-[var(--muted)]">
        Cargando...
      </div>
    );
  }

  if (!hasAdminAccess) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[var(--bg)] text-[var(--muted)]">
        Cargando...
      </div>
    );
  }

  return <>{children}</>;
}
