"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import {
  deleteChurchLocation,
  listChurchLocations,
  saveChurchLocation,
} from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function LocationsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [form, setForm] = useState({ name: "", address: "", city: "", state: "" });

  async function load() {
    setItems(await listChurchLocations());
  }

  useEffect(() => {
    load();
  }, []);

  if (!can("manage_church_locations")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await saveChurchLocation(null, form);
    setForm({ name: "", address: "", city: "", state: "" });
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.locations")} />
      <Card>
        <form onSubmit={onCreate} className="grid gap-3 md:grid-cols-2">
          <Input label={t("common.name")} required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <Input label={t("common.location")} value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} />
          <Input label="City" value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
          <Input label="State" value={form.state} onChange={(e) => setForm({ ...form, state: e.target.value })} />
          <Button type="submit">{t("common.create")}</Button>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.name")}</th>
            <th className="px-4 py-3">{t("common.location")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => (
            <tr key={String(item.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(item.name || "")}</td>
              <td className="px-4 py-3">{String(item.address || item.city || "")}</td>
              <td className="px-4 py-3">
                <Button
                  variant="danger"
                  onClick={async () => {
                    if (!confirm(t("common.confirmDelete"))) return;
                    await deleteChurchLocation(String(item.id));
                    load();
                  }}
                >
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
