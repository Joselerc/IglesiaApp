"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { listCounselingAppointments, updateCounselingStatus } from "@/lib/services/content";
import { Badge, Button, EmptyState, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { formatDateTime } from "@/lib/utils";

export default function CounselingRequestsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);

  async function load() {
    setItems(await listCounselingAppointments());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_counseling_requests")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.counselingRequests")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">User</th>
            <th className="px-4 py-3">{t("common.date")}</th>
            <th className="px-4 py-3">{t("common.status")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((a) => (
            <tr key={String(a.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3 text-sm">{String(a.userId || "")}</td>
              <td className="px-4 py-3">{formatDateTime(a.date)}</td>
              <td className="px-4 py-3"><Badge>{String(a.status || "")}</Badge></td>
              <td className="px-4 py-3">
                <div className="flex gap-2">
                  <Button onClick={async () => { await updateCounselingStatus(String(a.id), "confirmed"); load(); }}>{t("common.approve")}</Button>
                  <Button variant="danger" onClick={async () => { await updateCounselingStatus(String(a.id), "cancelled"); load(); }}>{t("common.reject")}</Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
