"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import {
  createAnnouncement,
  deleteAnnouncement,
  listAnnouncements,
  updateAnnouncement,
} from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Table, TextArea } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function AnnouncementsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");

  async function load() {
    setItems(await listAnnouncements());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_announcements")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await createAnnouncement({ title, description });
    setTitle("");
    setDescription("");
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.announcements")} />
      <Card>
        <form onSubmit={onCreate} className="space-y-3">
          <Input label={t("common.title")} required value={title} onChange={(e) => setTitle(e.target.value)} />
          <TextArea label={t("common.description")} value={description} onChange={(e) => setDescription(e.target.value)} />
          <Button type="submit">{t("common.create")}</Button>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.active")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((a) => (
            <tr key={String(a.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(a.title || "")}</td>
              <td className="px-4 py-3">{a.isActive === false ? t("common.no") : t("common.yes")}</td>
              <td className="px-4 py-3">
                <div className="flex gap-2">
                  <Button variant="secondary" onClick={async () => { await updateAnnouncement(String(a.id), { isActive: a.isActive === false }); load(); }}>
                    {t("common.edit")}
                  </Button>
                  <Button variant="danger" onClick={async () => { if (!confirm(t("common.confirmDelete"))) return; await deleteAnnouncement(String(a.id)); load(); }}>
                    {t("common.delete")}
                  </Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
