"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { scheduleStatsSummary } from "@/lib/services/content";
import { Card, EmptyState, PageHeader } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function ScheduleStatsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [stats, setStats] = useState<Record<string, number> | null>(null);

  useEffect(() => {
    scheduleStatsSummary().then(setStats);
  }, []);

  if (!can("view_schedule_stats")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.scheduleStats")} />
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
