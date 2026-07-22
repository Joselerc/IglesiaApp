"use client";

import { useEffect } from "react";
import { useAuth } from "./AuthProvider";
import { usePathname, useRouter } from "@/i18n/navigation";

export function AuthGate({ children }: { children: React.ReactNode }) {
  const { loading, firebaseUser, hasAdminAccess } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (loading) return;
    if (!firebaseUser) {
      router.replace(`/login?next=${encodeURIComponent(pathname)}`);
      return;
    }
    if (!hasAdminAccess) {
      router.replace("/login?error=no_access");
    }
  }, [loading, firebaseUser, hasAdminAccess, router, pathname]);

  if (loading || !firebaseUser || !hasAdminAccess) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[var(--bg)] text-[var(--muted)]">
        Cargando...
      </div>
    );
  }

  return <>{children}</>;
}
