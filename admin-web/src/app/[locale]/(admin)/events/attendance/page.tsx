"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { listMinistryGroupEvents } from "@/lib/services/content";
import { EmptyState, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { formatDate } from "@/lib/utils";

export default function EventAttendancePage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<
    { id: string; source: string; title: string; attendees: number; date: unknown }[]
  >([]);

  useEffect(() => {
    listMinistryGroupEvents().then(setItems);
  }, []);

  if (!can("manage_event_attendance")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.eventAttendance")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.type")}</th>
            <th className="px-4 py-3">{t("common.date")}</th>
            <th className="px-4 py-3">Attendees</th>
          </tr>
        </thead>
        <tbody>
          {items.map((e) => (
            <tr key={`${e.source}-${e.id}`} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{e.title}</td>
              <td className="px-4 py-3">{e.source}</td>
              <td className="px-4 py-3">{formatDate(e.date)}</td>
              <td className="px-4 py-3">{e.attendees}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
