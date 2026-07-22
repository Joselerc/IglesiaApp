"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { Timestamp } from "firebase/firestore";
import { deleteEvent, listEvents, saveEvent } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Select, Table, TextArea } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { formatDate } from "@/lib/utils";

export default function EventsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [form, setForm] = useState({
    title: "",
    description: "",
    category: "geral",
    eventType: "presential",
    startDate: "",
    endDate: "",
  });

  async function load() {
    setItems(await listEvents());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("create_events")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await saveEvent(null, {
      title: form.title,
      description: form.description,
      category: form.category,
      eventType: form.eventType,
      imageUrl: "",
      hasTickets: false,
      startDate: form.startDate ? Timestamp.fromDate(new Date(form.startDate)) : Timestamp.now(),
      endDate: form.endDate ? Timestamp.fromDate(new Date(form.endDate)) : Timestamp.now(),
    });
    setForm({ title: "", description: "", category: "geral", eventType: "presential", startDate: "", endDate: "" });
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.events")} />
      <Card>
        <form onSubmit={onCreate} className="grid gap-3 md:grid-cols-2">
          <Input label={t("common.title")} required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          <Input label={t("common.type")} value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} />
          <Select label="Event type" value={form.eventType} onChange={(e) => setForm({ ...form, eventType: e.target.value })}>
            <option value="presential">presential</option>
            <option value="online">online</option>
            <option value="hybrid">hybrid</option>
          </Select>
          <Input label={t("common.start")} type="datetime-local" value={form.startDate} onChange={(e) => setForm({ ...form, startDate: e.target.value })} />
          <Input label={t("common.end")} type="datetime-local" value={form.endDate} onChange={(e) => setForm({ ...form, endDate: e.target.value })} />
          <TextArea className="md:col-span-2" label={t("common.description")} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <Button type="submit">{t("common.create")}</Button>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.date")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((ev) => (
            <tr key={String(ev.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(ev.title || "")}</td>
              <td className="px-4 py-3">{formatDate(ev.startDate)}</td>
              <td className="px-4 py-3">
                {can("delete_events") && (
                  <Button variant="danger" onClick={async () => { if (!confirm(t("common.confirmDelete"))) return; await deleteEvent(String(ev.id)); load(); }}>
                    {t("common.delete")}
                  </Button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
