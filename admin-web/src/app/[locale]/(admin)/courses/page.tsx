"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { deleteCourse, listCourses, saveCourse } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Select, Table, TextArea } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function CoursesPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [form, setForm] = useState({
    title: "",
    description: "",
    category: "",
    status: "draft",
    instructorName: "",
  });

  async function load() {
    setItems(await listCourses());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_courses")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await saveCourse(null, {
      ...form,
      imageUrl: "",
      isFeatured: false,
      commentsEnabled: true,
      totalDuration: 0,
    });
    setForm({ title: "", description: "", category: "", status: "draft", instructorName: "" });
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.courses")} />
      <Card>
        <form onSubmit={onCreate} className="grid gap-3 md:grid-cols-2">
          <Input label={t("common.title")} required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          <Input label="Instructor" value={form.instructorName} onChange={(e) => setForm({ ...form, instructorName: e.target.value })} />
          <Input label={t("common.type")} value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} />
          <Select label={t("common.status")} value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })}>
            <option value="draft">draft</option>
            <option value="published">published</option>
            <option value="upcoming">upcoming</option>
            <option value="archived">archived</option>
          </Select>
          <TextArea className="md:col-span-2" label={t("common.description")} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <Button type="submit">{t("common.create")}</Button>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.status")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((c) => (
            <tr key={String(c.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(c.title || "")}</td>
              <td className="px-4 py-3">{String(c.status || "")}</td>
              <td className="px-4 py-3">
                <Button variant="danger" onClick={async () => { if (!confirm(t("common.confirmDelete"))) return; await deleteCourse(String(c.id)); load(); }}>
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
