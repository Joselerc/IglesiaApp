"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { deleteProfileField, listProfileFields, saveProfileField } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Select, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function ProfileFieldsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [form, setForm] = useState({ name: "", description: "", type: "text", order: 0, isRequired: false, isActive: true });

  async function load() {
    setItems(await listProfileFields());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_profile_fields")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await saveProfileField(null, form);
    setForm({ name: "", description: "", type: "text", order: 0, isRequired: false, isActive: true });
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.profileFields")} />
      <Card>
        <form onSubmit={onCreate} className="grid gap-3 md:grid-cols-2">
          <Input label={t("common.name")} required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <Input label={t("common.description")} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <Select label={t("common.type")} value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
            <option value="text">text</option>
            <option value="number">number</option>
            <option value="select">select</option>
            <option value="date">date</option>
            <option value="boolean">boolean</option>
          </Select>
          <Input label={t("common.order")} type="number" value={form.order} onChange={(e) => setForm({ ...form, order: Number(e.target.value) })} />
          <Button type="submit">{t("common.create")}</Button>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.name")}</th>
            <th className="px-4 py-3">{t("common.type")}</th>
            <th className="px-4 py-3">{t("common.order")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((f) => (
            <tr key={String(f.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(f.name || "")}</td>
              <td className="px-4 py-3">{String(f.type || "")}</td>
              <td className="px-4 py-3">{String(f.order ?? "")}</td>
              <td className="px-4 py-3">
                <Button variant="danger" onClick={async () => { if (!confirm(t("common.confirmDelete"))) return; await deleteProfileField(String(f.id)); load(); }}>
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
