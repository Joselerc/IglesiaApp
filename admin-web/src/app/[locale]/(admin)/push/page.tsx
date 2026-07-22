"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { useTranslations } from "next-intl";
import { sendPushNotification } from "@/lib/services/content";
import { listUsers, type AppUserDoc } from "@/lib/services/users";
import { Button, Card, EmptyState, Input, PageHeader, TextArea } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function PushPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [users, setUsers] = useState<AppUserDoc[]>([]);
  const [q, setQ] = useState("");
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    listUsers().then(setUsers);
  }, []);

  const filtered = useMemo(() => {
    const term = q.trim().toLowerCase();
    if (!term) return users.slice(0, 40);
    return users
      .filter((u) => u.name.toLowerCase().includes(term) || u.email.toLowerCase().includes(term))
      .slice(0, 40);
  }, [users, q]);

  if (!can("send_push_notifications")) return <EmptyState message={t("auth.noAccess")} />;

  async function onSend(e: FormEvent) {
    e.preventDefault();
    const userIds = Object.entries(selected).filter(([, v]) => v).map(([k]) => k);
    if (!userIds.length) {
      setMsg("Select users");
      return;
    }
    setBusy(true);
    setMsg("");
    try {
      await sendPushNotification({ userIds, title, body });
      setMsg(t("common.success"));
      setTitle("");
      setBody("");
      setSelected({});
    } catch (err) {
      setMsg(String(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.push")} />
      <Card>
        <form onSubmit={onSend} className="space-y-3">
          <Input label={t("common.title")} required value={title} onChange={(e) => setTitle(e.target.value)} />
          <TextArea label={t("common.description")} required value={body} onChange={(e) => setBody(e.target.value)} />
          <Input label={t("common.search")} value={q} onChange={(e) => setQ(e.target.value)} />
          <div className="max-h-64 space-y-1 overflow-y-auto rounded-lg border border-[var(--border)] p-2">
            {filtered.map((u) => (
              <label key={u.id} className="flex items-center gap-2 rounded px-2 py-1 text-sm hover:bg-[var(--bg)]">
                <input
                  type="checkbox"
                  checked={!!selected[u.id]}
                  onChange={(e) => setSelected({ ...selected, [u.id]: e.target.checked })}
                />
                {u.name} <span className="text-[var(--muted)]">({u.email})</span>
              </label>
            ))}
          </div>
          {msg && <p className="text-sm text-[var(--muted)]">{msg}</p>}
          <Button type="submit" disabled={busy}>{t("common.confirm")}</Button>
        </form>
      </Card>
    </div>
  );
}
