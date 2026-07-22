"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { listMyKidsFamilies, saveMyKidsFamily } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function MyKidsFamiliesPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<Record<string, unknown>[]>([]);
  const [familyName, setFamilyName] = useState("");

  async function load() {
    setItems(await listMyKidsFamilies());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_family_profiles")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await saveMyKidsFamily(null, { familyName });
    setFamilyName("");
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.mykidsFamilies")} />
      <Card>
        <form onSubmit={onCreate} className="flex flex-wrap gap-3">
          <div className="min-w-[240px] flex-1">
            <Input label={t("common.name")} required value={familyName} onChange={(e) => setFamilyName(e.target.value)} />
          </div>
          <div className="flex items-end"><Button type="submit">{t("common.create")}</Button></div>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.name")}</th>
            <th className="px-4 py-3">Children</th>
            <th className="px-4 py-3">Guardians</th>
          </tr>
        </thead>
        <tbody>
          {items.map((f) => (
            <tr key={String(f.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(f.familyName || "")}</td>
              <td className="px-4 py-3">{Array.isArray(f.childIds) ? f.childIds.length : 0}</td>
              <td className="px-4 py-3">{Array.isArray(f.guardianUserIds) ? f.guardianUserIds.length : 0}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
