"use client";

import { useMemo } from "react";
import { useTranslations } from "next-intl";
import { ArrowUpRight } from "lucide-react";
import { Link } from "@/i18n/navigation";
import { useAuth } from "@/components/AuthProvider";
import { ADMIN_NAV } from "@/lib/permissions";
import { Card, PageHeader } from "@/components/ui";

export default function DashboardPage() {
  const t = useTranslations();
  const { can, appUser } = useAuth();
  const items = useMemo(
    () => ADMIN_NAV.filter((i) => can(i.permission)),
    [can]
  );

  return (
    <div>
      <PageHeader
        title={`${t("dashboard.welcome")}${appUser?.displayName ? `, ${appUser.displayName.split(" ")[0]}` : ""}`}
        subtitle={t("dashboard.subtitle")}
      />
      <h2 className="mb-4 text-[11px] font-bold uppercase tracking-[0.14em] text-[var(--muted)]">
        {t("dashboard.modules")} · {items.length}
      </h2>
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {items.map((item) => (
          <Link key={item.href} href={item.href} className="group">
            <Card className="h-full transition group-hover:-translate-y-0.5 group-hover:border-[var(--border-strong)]">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-[11px] font-bold uppercase tracking-[0.12em] text-[var(--muted)]">
                    {t(`nav.sections.${item.section}`)}
                  </p>
                  <p className="mt-2 text-[15px] font-semibold tracking-tight">
                    {t(item.labelKey)}
                  </p>
                </div>
                <ArrowUpRight
                  size={16}
                  className="mt-1 shrink-0 text-[var(--muted)] opacity-0 transition group-hover:opacity-100"
                />
              </div>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
