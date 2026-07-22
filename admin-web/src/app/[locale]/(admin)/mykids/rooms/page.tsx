"use client";

import { FormEvent, useEffect, useState } from "react";
import { Timestamp } from "firebase/firestore";
import { useTranslations } from "next-intl";
import {
  deleteScheduledRoom,
  listScheduledRooms,
  saveScheduledRoom,
} from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { formatDateTime } from "@/lib/utils";

export default function MyKidsRoomsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [form, setForm] = useState({
    description: "",
    date: "",
    startTime: "",
    endTime: "",
    ageRange: "",
    maxChildren: 20,
  });

  async function load() {
    setItems(await listScheduledRooms());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_checkin_rooms")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await saveScheduledRoom(null, {
      description: form.description,
      ageRange: form.ageRange,
      maxChildren: form.maxChildren,
      repeatWeekly: false,
      date: form.date ? Timestamp.fromDate(new Date(form.date)) : Timestamp.now(),
      startTime: form.startTime ? Timestamp.fromDate(new Date(form.startTime)) : Timestamp.now(),
      endTime: form.endTime ? Timestamp.fromDate(new Date(form.endTime)) : Timestamp.now(),
    });
    setForm({ description: "", date: "", startTime: "", endTime: "", ageRange: "", maxChildren: 20 });
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.mykidsRooms")} />
      <Card>
        <form onSubmit={onCreate} className="grid gap-3 md:grid-cols-2">
          <Input label={t("common.description")} required value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <Input label="Age range" value={form.ageRange} onChange={(e) => setForm({ ...form, ageRange: e.target.value })} />
          <Input label={t("common.date")} type="date" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} />
          <Input label="Max children" type="number" value={form.maxChildren} onChange={(e) => setForm({ ...form, maxChildren: Number(e.target.value) })} />
          <Input label={t("common.start")} type="datetime-local" value={form.startTime} onChange={(e) => setForm({ ...form, startTime: e.target.value })} />
          <Input label={t("common.end")} type="datetime-local" value={form.endTime} onChange={(e) => setForm({ ...form, endTime: e.target.value })} />
          <Button type="submit">{t("common.create")}</Button>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.description")}</th>
            <th className="px-4 py-3">{t("common.start")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((r) => (
            <tr key={String(r.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(r.description || "")}</td>
              <td className="px-4 py-3">{formatDateTime(r.startTime)}</td>
              <td className="px-4 py-3">
                <Button variant="danger" onClick={async () => { if (!confirm(t("common.confirmDelete"))) return; await deleteScheduledRoom(String(r.id)); load(); }}>
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
