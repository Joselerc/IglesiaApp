"use client";

import { useMemo, useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import {
  LayoutDashboard,
  LogOut,
  Menu,
  X,
  ChevronDown,
} from "lucide-react";
import { Link, usePathname, useRouter } from "@/i18n/navigation";
import { useAuth } from "./AuthProvider";
import { ADMIN_NAV } from "@/lib/permissions";
import { cn } from "@/lib/utils";

const SECTION_ORDER = [
  "users",
  "schedules",
  "community",
  "content",
  "config",
  "pastoral",
  "reports",
  "mykids",
] as const;

export function AdminShell({ children }: { children: React.ReactNode }) {
  const t = useTranslations();
  const { appUser, signOut, can } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const locale = useLocale();
  const [open, setOpen] = useState(false);

  const items = useMemo(
    () => ADMIN_NAV.filter((item) => can(item.permission)),
    [can]
  );

  const bySection = useMemo(() => {
    const map: Record<string, typeof items> = {};
    for (const item of items) {
      (map[item.section] ??= []).push(item);
    }
    return map;
  }, [items]);

  return (
    <div className="min-h-screen text-[var(--text)]">
      <div className="flex min-h-screen">
        <aside
          className={cn(
            "fixed inset-y-0 left-0 z-40 flex w-[280px] flex-col bg-[var(--sidebar)] text-[var(--sidebar-text)] transition-transform lg:static lg:translate-x-0",
            open ? "translate-x-0" : "-translate-x-full"
          )}
        >
          <div className="flex h-[4.25rem] items-center justify-between border-b border-white/10 px-5">
            <div>
              <p
                className="text-[15px] font-semibold tracking-tight text-white"
                style={{ fontFamily: "var(--font-display), serif" }}
              >
                {t("app.name")}
              </p>
              <p className="text-[11px] text-[var(--sidebar-muted)]">
                {t("app.tagline")}
              </p>
            </div>
            <button
              className="rounded-md p-1 text-[var(--sidebar-muted)] hover:bg-white/10 lg:hidden"
              onClick={() => setOpen(false)}
            >
              <X size={18} />
            </button>
          </div>

          <nav className="sidebar-scroll flex-1 overflow-y-auto px-3 py-4">
            <Link
              href="/dashboard"
              onClick={() => setOpen(false)}
              className={cn(
                "mb-5 flex items-center gap-2.5 rounded-lg px-3 py-2.5 text-[13.5px] font-medium transition",
                pathname === "/dashboard"
                  ? "bg-[var(--sidebar-active)] text-white shadow-sm"
                  : "text-[var(--sidebar-text)] hover:bg-[var(--sidebar-hover)]"
              )}
            >
              <LayoutDashboard size={16} strokeWidth={1.75} />
              {t("common.dashboard")}
            </Link>

            {SECTION_ORDER.map((section) => {
              const sectionItems = bySection[section];
              if (!sectionItems?.length) return null;
              return (
                <div key={section} className="mb-5">
                  <p className="mb-2 px-3 text-[11px] font-bold uppercase tracking-[0.14em] text-white/55">
                    {t(`nav.sections.${section}`)}
                  </p>
                  <ul className="space-y-0.5">
                    {sectionItems.map((item) => {
                      const active =
                        pathname === item.href ||
                        pathname.startsWith(`${item.href}/`);
                      return (
                        <li key={item.href}>
                          <Link
                            href={item.href}
                            onClick={() => setOpen(false)}
                            className={cn(
                              "block rounded-lg px-3 py-2 text-[13.5px] font-normal transition",
                              active
                                ? "bg-white/12 font-medium text-white"
                                : "text-[var(--sidebar-muted)] hover:bg-[var(--sidebar-hover)] hover:text-[var(--sidebar-text)]"
                            )}
                          >
                            {t(item.labelKey)}
                          </Link>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              );
            })}
          </nav>

          <div className="border-t border-white/10 p-4">
            <div className="rounded-xl bg-white/5 px-3 py-2.5">
              <p className="truncate text-sm font-medium text-white">
                {appUser?.displayName}
              </p>
              <p className="truncate text-[11px] text-[var(--sidebar-muted)]">
                {appUser?.isSuperUser
                  ? t("users.superUser")
                  : appUser?.roleName ?? t("users.noRole")}
              </p>
            </div>
          </div>
        </aside>

        {open && (
          <div
            className="fixed inset-0 z-30 bg-black/40 backdrop-blur-[2px] lg:hidden"
            onClick={() => setOpen(false)}
          />
        )}

        <div className="flex min-h-screen min-w-0 flex-1 flex-col">
          <header className="sticky top-0 z-20 flex h-[4.25rem] items-center gap-3 border-b border-[var(--border)] bg-[var(--surface)]/85 px-4 backdrop-blur-md md:px-6">
            <button
              className="rounded-lg border border-[var(--border)] p-2 lg:hidden"
              onClick={() => setOpen(true)}
            >
              <Menu size={18} />
            </button>

            <div className="ml-auto flex items-center gap-2.5">
              <div className="relative">
                <select
                  className="appearance-none rounded-lg border border-[var(--border)] bg-[var(--surface-2)] py-2 pl-3 pr-8 text-sm font-medium"
                  value={locale}
                  onChange={(e) => {
                    router.replace(pathname, {
                      locale: e.target.value as "es" | "pt",
                    });
                  }}
                >
                  <option value="pt">PT</option>
                  <option value="es">ES</option>
                </select>
                <ChevronDown
                  size={14}
                  className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-[var(--muted)]"
                />
              </div>
              <button
                onClick={() => signOut()}
                className="inline-flex items-center gap-1.5 rounded-lg border border-[var(--border)] bg-white px-3 py-2 text-sm font-medium text-[var(--text)] transition hover:bg-[var(--surface-2)]"
              >
                <LogOut size={14} />
                <span className="hidden sm:inline">{t("auth.signOut")}</span>
              </button>
            </div>
          </header>

          <main className="flex-1 p-4 md:p-7 lg:p-8">
            <div className="mx-auto max-w-7xl">{children}</div>
          </main>
        </div>
      </div>
    </div>
  );
}
