"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { getDonationsSettings, saveDonationsSettings } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, TextArea } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function DonationsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [sectionTitle, setSectionTitle] = useState("");
  const [description, setDescription] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [bankAccounts, setBankAccounts] = useState("");
  const [pixKeys, setPixKeys] = useState("");

  useEffect(() => {
    getDonationsSettings().then((s) => {
      if (!s) return;
      setSectionTitle(String(s.sectionTitle || ""));
      setDescription(String(s.description || ""));
      setImageUrl(String(s.imageUrl || ""));
      setBankAccounts(Array.isArray(s.bankAccounts) ? s.bankAccounts.join("\n") : "");
      setPixKeys(
        Array.isArray(s.pixKeys)
          ? s.pixKeys.map((p: { type?: string; key?: string }) => `${p.type || "PIX"}:${p.key || ""}`).join("\n")
          : ""
      );
    });
  }, []);

  if (!can("manage_donations_config")) return <EmptyState message={t("auth.noAccess")} />;

  async function onSave(e: FormEvent) {
    e.preventDefault();
    await saveDonationsSettings({
      sectionTitle,
      description,
      imageUrl,
      bankAccounts: bankAccounts.split("\n").map((x) => x.trim()).filter(Boolean),
      pixKeys: pixKeys
        .split("\n")
        .map((line) => line.trim())
        .filter(Boolean)
        .map((line) => {
          const [type, ...rest] = line.split(":");
          return { type: type || "PIX", key: rest.join(":") };
        }),
    });
    alert(t("common.saved"));
  }

  return (
    <div>
      <PageHeader title={t("nav.donations")} />
      <Card>
        <form onSubmit={onSave} className="space-y-3">
          <Input label={t("common.title")} value={sectionTitle} onChange={(e) => setSectionTitle(e.target.value)} />
          <TextArea label={t("common.description")} value={description} onChange={(e) => setDescription(e.target.value)} />
          <Input label={t("common.imageUrl")} value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} />
          <TextArea label="Bank accounts (one per line)" value={bankAccounts} onChange={(e) => setBankAccounts(e.target.value)} />
          <TextArea label="PIX (type:key per line)" value={pixKeys} onChange={(e) => setPixKeys(e.target.value)} />
          <Button type="submit">{t("common.save")}</Button>
        </form>
      </Card>
    </div>
  );
}
