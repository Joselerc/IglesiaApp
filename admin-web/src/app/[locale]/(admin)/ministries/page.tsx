"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { Church } from "lucide-react";
import {
  createMinistry,
  deleteMinistry,
  listMinistries,
  type MinistryDoc,
} from "@/lib/services/ministries";
import {
  Button,
  Card,
  EmptyState,
  Input,
  PageHeader,
  TextArea,
} from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function MinistriesPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [items, setItems] = useState<MinistryDoc[]>([]);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [q, setQ] = useState("");

  async function load() {
    setItems(await listMinistries());
  }

  useEffect(() => {
    load();
  }, []);

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await createMinistry({ name, description });
    setName("");
    setDescription("");
    setShowForm(false);
    load();
  }

  if (!can(["create_ministry", "delete_ministry"])) {
    return <EmptyState message={t("auth.noAccess")} />;
  }

  const filtered = items.filter((m) =>
    m.name.toLowerCase().includes(q.trim().toLowerCase())
  );

  return (
    <div>
      <PageHeader
        title={t("ministries.title")}
        actions={
          can("create_ministry") && (
            <Button onClick={() => setShowForm((v) => !v)}>
              {t("ministries.create")}
            </Button>
          )
        }
      />
      {showForm && (
        <Card className="mb-4">
          <form onSubmit={onCreate} className="grid gap-3 md:grid-cols-2">
            <Input
              label={t("common.name")}
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
            <TextArea
              label={t("common.description")}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
            <div className="md:col-span-2">
              <Button type="submit">{t("common.create")}</Button>
            </div>
          </form>
        </Card>
      )}

      <div className="mb-4 max-w-md">
        <Input
          label={t("common.search")}
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>

      {filtered.length === 0 ? (
        <EmptyState message={t("common.empty")} />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {filtered.map((m) => (
            <Card
              key={m.id}
              className="flex flex-col justify-between gap-5 transition hover:-translate-y-0.5 hover:border-[var(--border-strong)]"
            >
              <div>
                <div className="mb-3 flex h-11 w-11 items-center justify-center rounded-xl bg-[var(--primary-soft)] text-[var(--primary)]">
                  <Church size={18} strokeWidth={1.75} />
                </div>
                <h2 className="text-lg font-semibold tracking-tight">{m.name}</h2>
                <p className="mt-1.5 line-clamp-2 text-sm leading-relaxed text-[var(--muted)]">
                  {m.description || "—"}
                </p>
                <p className="mt-4 text-xs font-medium text-[var(--muted)]">
                  {m.memberIds.length} {t("common.members").toLowerCase()} ·{" "}
                  {m.adminIds.length} {t("common.admins").toLowerCase()}
                  {Object.keys(m.pendingRequests || {}).length > 0 &&
                    ` · ${Object.keys(m.pendingRequests).length} ${t("members.pending").toLowerCase()}`}
                </p>
              </div>
              <div className="flex flex-wrap gap-2 border-t border-[var(--border)] pt-4">
                <Link href={`/ministries/${m.id}`}>
                  <Button variant="secondary">{t("ministries.manage")}</Button>
                </Link>
                {can("delete_ministry") && (
                  <Button
                    variant="danger"
                    onClick={async () => {
                      if (!confirm(t("common.confirmDelete"))) return;
                      await deleteMinistry(m.id);
                      load();
                    }}
                  >
                    {t("common.delete")}
                  </Button>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
