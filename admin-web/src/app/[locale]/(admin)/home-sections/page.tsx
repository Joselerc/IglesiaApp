"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { listHomeSections, updateHomeSection } from "@/lib/services/content";
import { Button, EmptyState, Input, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function HomeSectionsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);

  async function load() {
    setItems(await listHomeSections());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_home_sections")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.homeSections")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.type")}</th>
            <th className="px-4 py-3">{t("common.order")}</th>
            <th className="px-4 py-3">{t("common.active")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((s) => (
            <tr key={String(s.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">
                <Input
                  defaultValue={String(s.title || "")}
                  onBlur={async (e) => {
                    await updateHomeSection(String(s.id), { title: e.target.value });
                  }}
                />
              </td>
              <td className="px-4 py-3">{String(s.type || "")}</td>
              <td className="px-4 py-3">{String(s.order ?? "")}</td>
              <td className="px-4 py-3">{s.isActive === false ? t("common.no") : t("common.yes")}</td>
              <td className="px-4 py-3">
                <Button
                  variant="secondary"
                  onClick={async () => {
                    await updateHomeSection(String(s.id), { isActive: s.isActive === false });
                    load();
                  }}
                >
                  {t("common.edit")}
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
