"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import {
  acceptPrivatePrayer,
  listPrivatePrayers,
  respondPrivatePrayer,
} from "@/lib/services/content";
import { Badge, Button, EmptyState, Input, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { formatDateTime } from "@/lib/utils";

export default function PrayersPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [responses, setResponses] = useState<Record<string, string>>({});

  async function load() {
    setItems(await listPrivatePrayers());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_private_prayers")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.prayers")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.user")}</th>
            <th className="px-4 py-3">{t("common.description")}</th>
            <th className="px-4 py-3">{t("common.date")}</th>
            <th className="px-4 py-3">{t("common.status")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((p) => (
            <tr key={String(p.id)} className="border-b border-[var(--border)] align-top">
              <td className="px-4 py-3 text-sm">{String(p.userId || "")}</td>
              <td className="px-4 py-3 max-w-sm text-sm">{String(p.content || "")}</td>
              <td className="px-4 py-3">{formatDateTime(p.createdAt)}</td>
              <td className="px-4 py-3">
                <Badge tone={p.isAccepted ? "success" : "warning"}>
                  {p.isAccepted ? t("common.accepted") : t("common.pending")}
                </Badge>
              </td>
              <td className="px-4 py-3 space-y-2">
                {!p.isAccepted && (
                  <Button onClick={async () => { await acceptPrivatePrayer(String(p.id)); load(); }}>
                    {t("common.approve")}
                  </Button>
                )}
                <Input
                  placeholder="Response"
                  value={responses[String(p.id)] || ""}
                  onChange={(e) => setResponses({ ...responses, [String(p.id)]: e.target.value })}
                />
                <Button
                  variant="secondary"
                  onClick={async () => {
                    await respondPrivatePrayer(String(p.id), responses[String(p.id)] || "");
                    load();
                  }}
                >
                  {t("common.save")}
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
