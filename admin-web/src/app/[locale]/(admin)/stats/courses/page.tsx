"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { courseStatsSummary } from "@/lib/services/content";
import { EmptyState, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function CourseStatsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<{ id: string; title: string; enrolled: number; status: string }[]>([]);

  useEffect(() => {
    courseStatsSummary().then(setItems);
  }, []);

  if (!can("view_course_stats")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.courseStats")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.status")}</th>
            <th className="px-4 py-3">Enrolled</th>
          </tr>
        </thead>
        <tbody>
          {items.map((i) => (
            <tr key={i.id} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{i.title}</td>
              <td className="px-4 py-3">{i.status}</td>
              <td className="px-4 py-3">{i.enrolled}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
