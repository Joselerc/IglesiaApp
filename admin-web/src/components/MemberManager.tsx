"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslations } from "next-intl";
import {
  Crown,
  MailPlus,
  Search,
  Trash2,
  UserMinus,
  UserPlus,
  Users,
} from "lucide-react";
import { searchUsersByName, type AppUserDoc } from "@/lib/services/users";
import {
  listPendingRequests,
  type MembershipRequest,
} from "@/lib/services/membership";
import { Badge, Button, Card, EmptyState, Input } from "@/components/ui";
import { cn } from "@/lib/utils";

type Tab = "members" | "pending" | "add";

type Props = {
  entityType: "group" | "ministry";
  entityId: string;
  memberIds: string[];
  adminIds: string[];
  members: AppUserDoc[];
  onInvite: (userId: string) => Promise<void>;
  onAddDirect: (userId: string) => Promise<void>;
  onRemove: (userId: string) => Promise<void>;
  onPromote: (userId: string) => Promise<void>;
  onDemote: (userId: string) => Promise<void>;
  onApprove: (userId: string) => Promise<void>;
  onReject: (userId: string) => Promise<void>;
  onChanged: () => Promise<void> | void;
};

export function MemberManager({
  entityType,
  entityId,
  memberIds,
  adminIds,
  members,
  onInvite,
  onAddDirect,
  onRemove,
  onPromote,
  onDemote,
  onApprove,
  onReject,
  onChanged,
}: Props) {
  const t = useTranslations();
  const [tab, setTab] = useState<Tab>("members");
  const [memberFilter, setMemberFilter] = useState("");
  const [search, setSearch] = useState("");
  const [results, setResults] = useState<AppUserDoc[]>([]);
  const [pending, setPending] = useState<MembershipRequest[]>([]);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState("");
  const [toast, setToast] = useState("");

  const loadPending = useCallback(async () => {
    setPending(await listPendingRequests(entityId, entityType));
  }, [entityId, entityType]);

  useEffect(() => {
    loadPending();
  }, [loadPending]);

  const filteredMembers = useMemo(() => {
    const q = memberFilter.trim().toLowerCase();
    if (!q) return members;
    return members.filter(
      (m) =>
        m.name.toLowerCase().includes(q) || m.email.toLowerCase().includes(q)
    );
  }, [members, memberFilter]);

  const pendingIds = useMemo(
    () => new Set(pending.map((p) => p.userId)),
    [pending]
  );

  async function run(userId: string, fn: () => Promise<void>, okMsg: string) {
    setBusyId(userId);
    setError("");
    try {
      await fn();
      setToast(okMsg);
      setSearch("");
      setResults([]);
      await onChanged();
      await loadPending();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusyId(null);
    }
  }

  const tabs: { id: Tab; label: string; count?: number }[] = [
    { id: "members", label: t("common.members"), count: members.length },
    {
      id: "pending",
      label: t("members.pending"),
      count: pending.length,
    },
    { id: "add", label: t("members.inviteAdd") },
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-1.5 border-b border-[var(--border)] pb-3">
        {tabs.map((item) => (
          <button
            key={item.id}
            type="button"
            onClick={() => setTab(item.id)}
            className={cn(
              "rounded-lg px-3.5 py-2 text-sm transition",
              tab === item.id
                ? "bg-[var(--primary)] font-semibold text-white shadow-sm"
                : "font-medium text-[var(--muted)] hover:bg-[var(--primary-soft)] hover:text-[var(--primary)]"
            )}
          >
            {item.label}
            {typeof item.count === "number" && (
              <span className="ml-1.5 opacity-80">({item.count})</span>
            )}
          </button>
        ))}
      </div>

      {error && (
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </p>
      )}
      {toast && (
        <p className="rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
          {toast}
        </p>
      )}

      {tab === "members" && (
        <Card className="space-y-3 p-0 overflow-hidden">
          <div className="border-b border-[var(--border)] p-4">
            <div className="relative max-w-md">
              <Search
                size={16}
                className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[var(--muted)]"
              />
              <input
                className="w-full rounded-lg border border-[var(--border)] bg-white py-2 pl-9 pr-3 text-sm outline-none focus:border-[var(--primary)]"
                placeholder={t("common.search")}
                value={memberFilter}
                onChange={(e) => setMemberFilter(e.target.value)}
              />
            </div>
          </div>
          {filteredMembers.length === 0 ? (
            <div className="p-8">
              <EmptyState message={t("common.empty")} />
            </div>
          ) : (
            <ul className="divide-y divide-[var(--border)]">
              {filteredMembers.map((m) => {
                const isAdmin = adminIds.includes(m.id);
                return (
                  <li
                    key={m.id}
                    className="flex flex-col gap-3 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
                  >
                    <div className="flex min-w-0 items-center gap-3">
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[var(--primary)]/10 text-sm font-semibold text-[var(--primary)]">
                        {(m.name || "?").slice(0, 1).toUpperCase()}
                      </div>
                      <div className="min-w-0">
                        <p className="truncate font-medium">{m.name}</p>
                        <p className="truncate text-xs text-[var(--muted)]">
                          {m.email || m.id}
                        </p>
                      </div>
                      <Badge tone={isAdmin ? "success" : "neutral"}>
                        {isAdmin ? (
                          <span className="inline-flex items-center gap-1">
                            <Crown size={12} /> {t("common.admins")}
                          </span>
                        ) : (
                          t("common.members")
                        )}
                      </Badge>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {isAdmin ? (
                        <Button
                          variant="secondary"
                          disabled={busyId === m.id}
                          onClick={() =>
                            run(
                              m.id,
                              () => onDemote(m.id),
                              t("members.demoted")
                            )
                          }
                        >
                          <UserMinus size={14} />
                          {t("common.demote")}
                        </Button>
                      ) : (
                        <Button
                          variant="secondary"
                          disabled={busyId === m.id}
                          onClick={() =>
                            run(
                              m.id,
                              () => onPromote(m.id),
                              t("members.promoted")
                            )
                          }
                        >
                          <Crown size={14} />
                          {t("common.promote")}
                        </Button>
                      )}
                      <Button
                        variant="danger"
                        disabled={busyId === m.id}
                        onClick={() => {
                          if (!confirm(t("members.confirmRemove"))) return;
                          run(m.id, () => onRemove(m.id), t("members.removed"));
                        }}
                      >
                        <Trash2 size={14} />
                        {t("common.remove")}
                      </Button>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </Card>
      )}

      {tab === "pending" && (
        <Card className="p-0 overflow-hidden">
          {pending.length === 0 ? (
            <div className="p-8">
              <EmptyState message={t("members.noPending")} />
            </div>
          ) : (
            <ul className="divide-y divide-[var(--border)]">
              {pending.map((p) => (
                <li
                  key={p.id}
                  className="flex flex-col gap-3 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div>
                    <p className="font-medium">{p.userName || p.userId}</p>
                    <p className="text-xs text-[var(--muted)]">
                      {p.userEmail || p.userId}
                    </p>
                    <div className="mt-1 flex flex-wrap gap-2">
                      <Badge
                        tone={p.requestType === "invite" ? "warning" : "neutral"}
                      >
                        {p.requestType === "invite"
                          ? t("members.inviteType")
                          : t("members.joinType")}
                      </Badge>
                      {p.invitedByName && (
                        <span className="text-xs text-[var(--muted)]">
                          {t("members.invitedBy")}: {p.invitedByName}
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      disabled={busyId === p.userId}
                      onClick={() =>
                        run(
                          p.userId,
                          () => onApprove(p.userId),
                          t("members.approved")
                        )
                      }
                    >
                      {t("common.approve")}
                    </Button>
                    <Button
                      variant="danger"
                      disabled={busyId === p.userId}
                      onClick={() =>
                        run(
                          p.userId,
                          () => onReject(p.userId),
                          t("members.rejected")
                        )
                      }
                    >
                      {t("common.reject")}
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>
      )}

      {tab === "add" && (
        <Card className="space-y-4">
          <div className="flex items-start gap-3 rounded-lg bg-[var(--bg)] p-3 text-sm text-[var(--muted)]">
            <Users size={18} className="mt-0.5 shrink-0 text-[var(--primary)]" />
            <p>{t("members.help")}</p>
          </div>
          <div className="relative">
            <Search
              size={16}
              className="pointer-events-none absolute left-3 top-[2.35rem] text-[var(--muted)]"
            />
            <Input
              label={t("common.search")}
              className="pl-9"
              value={search}
              onChange={async (e) => {
                const v = e.target.value;
                setSearch(v);
                setToast("");
                setError("");
                if (v.trim().length < 2) {
                  setResults([]);
                  return;
                }
                const found = await searchUsersByName(v);
                setResults(
                  found.filter(
                    (u) => !memberIds.includes(u.id) && !pendingIds.has(u.id)
                  )
                );
              }}
              placeholder={t("members.searchPlaceholder")}
            />
          </div>
          {results.length === 0 && search.trim().length >= 2 ? (
            <EmptyState message={t("members.noResults")} />
          ) : (
            <ul className="divide-y divide-[var(--border)] rounded-xl border border-[var(--border)]">
              {results.slice(0, 12).map((u) => (
                <li
                  key={u.id}
                  className="flex flex-col gap-3 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--primary)]/10 text-sm font-semibold text-[var(--primary)]">
                      {(u.name || "?").slice(0, 1).toUpperCase()}
                    </div>
                    <div>
                      <p className="font-medium">{u.name}</p>
                      <p className="text-xs text-[var(--muted)]">{u.email}</p>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Button
                      variant="secondary"
                      disabled={busyId === u.id}
                      onClick={() =>
                        run(u.id, () => onInvite(u.id), t("members.invited"))
                      }
                    >
                      <MailPlus size={14} />
                      {t("members.invite")}
                    </Button>
                    <Button
                      disabled={busyId === u.id}
                      onClick={() =>
                        run(u.id, () => onAddDirect(u.id), t("members.added"))
                      }
                    >
                      <UserPlus size={14} />
                      {t("members.addDirect")}
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>
      )}
    </div>
  );
}
