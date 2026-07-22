"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { Users } from "lucide-react";
import {
  createGroup,
  deleteGroup,
  listGroups,
  type GroupDoc,
} from "@/lib/services/groups";
import {
  Button,
  Card,
  EmptyState,
  Input,
  PageHeader,
  TextArea,
} from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function GroupsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [groups, setGroups] = useState<GroupDoc[]>([]);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [q, setQ] = useState("");

  async function load() {
    setGroups(await listGroups());
  }

  useEffect(() => {
    load();
  }, []);

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    await createGroup({ name, description });
    setName("");
    setDescription("");
    setShowForm(false);
    load();
  }

  if (!can(["create_group", "delete_group"])) {
    return <EmptyState message={t("auth.noAccess")} />;
  }

  const filtered = groups.filter((g) =>
    g.name.toLowerCase().includes(q.trim().toLowerCase())
  );

  return (
    <div>
      <PageHeader
        title={t("groups.title")}
        actions={
          can("create_group") && (
            <Button onClick={() => setShowForm((v) => !v)}>
              {t("groups.create")}
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
          {filtered.map((g) => (
            <Card
              key={g.id}
              className="flex flex-col justify-between gap-5 transition hover:-translate-y-0.5 hover:border-[var(--border-strong)]"
            >
              <div>
                <div className="mb-3 flex h-11 w-11 items-center justify-center rounded-xl bg-[var(--primary-soft)] text-[var(--primary)]">
                  <Users size={18} strokeWidth={1.75} />
                </div>
                <h2 className="text-lg font-semibold tracking-tight">{g.name}</h2>
                <p className="mt-1.5 line-clamp-2 text-sm leading-relaxed text-[var(--muted)]">
                  {g.description || "—"}
                </p>
                <p className="mt-4 text-xs font-medium text-[var(--muted)]">
                  {g.memberIds.length} {t("common.members").toLowerCase()} ·{" "}
                  {g.adminIds.length} {t("common.admins").toLowerCase()}
                  {Object.keys(g.pendingRequests || {}).length > 0 &&
                    ` · ${Object.keys(g.pendingRequests).length} ${t("members.pending").toLowerCase()}`}
                </p>
              </div>
              <div className="flex flex-wrap gap-2 border-t border-[var(--border)] pt-4">
                <Link href={`/groups/${g.id}`}>
                  <Button variant="secondary">{t("groups.manage")}</Button>
                </Link>
                {can("delete_group") && (
                  <Button
                    variant="danger"
                    onClick={async () => {
                      if (!confirm(t("common.confirmDelete"))) return;
                      await deleteGroup(g.id);
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
