"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { churchStatsSummary } from "@/lib/services/content";
import { Card, EmptyState, PageHeader } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function ChurchStatsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [stats, setStats] = useState<Record<string, number> | null>(null);

  useEffect(() => {
    churchStatsSummary().then(setStats);
  }, []);

  if (!can("view_church_statistics")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.churchStats")} />
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
        {stats &&
          Object.entries(stats).map(([k, v]) => (
            <Card key={k}>
              <p className="text-xs uppercase text-[var(--muted)]">{k}</p>
              <p className="mt-1 text-2xl font-semibold">{v}</p>
            </Card>
          ))}
      </div>
    </div>
  );
}
