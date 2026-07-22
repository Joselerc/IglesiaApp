"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { deletePage, listPages, savePage } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function PagesAdminPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [title, setTitle] = useState("");

  async function load() {
    setItems(await listPages());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_pages")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await savePage(null, { title, cardDisplayType: "icon", elements: [] });
    setTitle("");
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.pages")} />
      <Card>
        <form onSubmit={onCreate} className="flex flex-wrap gap-3">
          <div className="min-w-[240px] flex-1">
            <Input label={t("common.title")} required value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="flex items-end">
            <Button type="submit">{t("common.create")}</Button>
          </div>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((p) => (
            <tr key={String(p.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(p.title || "")}</td>
              <td className="px-4 py-3">
                <Button variant="danger" onClick={async () => { if (!confirm(t("common.confirmDelete"))) return; await deletePage(String(p.id)); load(); }}>
                  {t("common.delete")}
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
