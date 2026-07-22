"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { listFamilyGroups } from "@/lib/services/content";
import { EmptyState, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { refsToIds } from "@/lib/utils";

export default function FamiliesPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);

  useEffect(() => {
    listFamilyGroups().then(setItems);
  }, []);

  if (!can("manage_families_admin")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.families")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.name")}</th>
            <th className="px-4 py-3">{t("common.members")}</th>
            <th className="px-4 py-3">{t("common.admins")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((f) => (
            <tr key={String(f.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(f.name || "")}</td>
              <td className="px-4 py-3">{refsToIds(f.members as unknown[]).length}</td>
              <td className="px-4 py-3">{refsToIds(f.admins as unknown[]).length}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
