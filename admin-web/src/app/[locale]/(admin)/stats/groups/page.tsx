"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { entityMemberStats } from "@/lib/services/content";
import { EmptyState, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function GroupStatsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<{ id: string; name: string; members: number }[]>([]);

  useEffect(() => {
    entityMemberStats("groups").then(setItems);
  }, []);

  if (!can("view_group_stats")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.groupStats")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.name")}</th>
            <th className="px-4 py-3">{t("common.members")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((i) => (
            <tr key={i.id} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{i.name}</td>
              <td className="px-4 py-3">{i.members}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
