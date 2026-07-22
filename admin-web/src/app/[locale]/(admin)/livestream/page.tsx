"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { getLivestreamConfig, saveLivestreamConfig } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, TextArea } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function LivestreamPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [form, setForm] = useState({
    sectionTitle: "",
    description: "",
    imageTitle: "",
    url: "",
    imageUrl: "",
    isActive: true,
  });

  useEffect(() => {
    getLivestreamConfig().then((c) => {
      if (!c) return;
      setForm({
        sectionTitle: String(c.sectionTitle || ""),
        description: String(c.description || ""),
        imageTitle: String(c.imageTitle || ""),
        url: String(c.url || ""),
        imageUrl: String(c.imageUrl || ""),
        isActive: c.isActive !== false,
      });
    });
  }, []);

  if (!can("manage_livestream_config")) return <EmptyState message={t("auth.noAccess")} />;

  async function onSave(e: FormEvent) {
    e.preventDefault();
    await saveLivestreamConfig(form);
    alert(t("common.saved"));
  }

  return (
    <div>
      <PageHeader title={t("nav.livestream")} />
      <Card>
        <form onSubmit={onSave} className="space-y-3">
          <Input label={t("common.title")} value={form.sectionTitle} onChange={(e) => setForm({ ...form, sectionTitle: e.target.value })} />
          <TextArea label={t("common.description")} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <Input label={t("common.url")} value={form.url} onChange={(e) => setForm({ ...form, url: e.target.value })} />
          <Input label={t("common.imageUrl")} value={form.imageUrl} onChange={(e) => setForm({ ...form, imageUrl: e.target.value })} />
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} />
            {t("common.active")}
          </label>
          <Button type="submit">{t("common.save")}</Button>
        </form>
      </Card>
    </div>
  );
}
