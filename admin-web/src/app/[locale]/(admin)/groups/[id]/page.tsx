"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import {
  addMember,
  approveRequest,
  demoteAdmin,
  getGroup,
  inviteMember,
  promoteAdmin,
  rejectRequest,
  removeMember,
  type GroupDoc,
} from "@/lib/services/groups";
import { getUsersByIds, type AppUserDoc } from "@/lib/services/users";
import { MemberManager } from "@/components/MemberManager";
import { Button, EmptyState, PageHeader } from "@/components/ui";
import { ArrowLeft } from "lucide-react";

export default function GroupDetailPage() {
  const t = useTranslations();
  const params = useParams<{ id: string }>();
  const [group, setGroup] = useState<GroupDoc | null>(null);
  const [members, setMembers] = useState<AppUserDoc[]>([]);

  async function load() {
    const g = await getGroup(params.id);
    setGroup(g);
    if (g) setMembers(await getUsersByIds(g.memberIds));
  }

  useEffect(() => {
    load();
  }, [params.id]);

  if (!group) return <EmptyState message={t("common.loading")} />;

  return (
    <div className="space-y-6">
      <PageHeader
        title={group.name}
        subtitle={group.description || t("groups.detail")}
        actions={
          <Link href="/groups">
            <Button variant="secondary">
              <ArrowLeft size={14} />
              {t("common.back")}
            </Button>
          </Link>
        }
      />

      <div className="grid gap-3 sm:grid-cols-3">
        <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4">
          <p className="text-xs uppercase tracking-wide text-[var(--muted)]">
            {t("common.members")}
          </p>
          <p className="mt-1 text-2xl font-semibold">{group.memberIds.length}</p>
        </div>
        <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4">
          <p className="text-xs uppercase tracking-wide text-[var(--muted)]">
            {t("common.admins")}
          </p>
          <p className="mt-1 text-2xl font-semibold">{group.adminIds.length}</p>
        </div>
        <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4">
          <p className="text-xs uppercase tracking-wide text-[var(--muted)]">
            {t("members.pending")}
          </p>
          <p className="mt-1 text-2xl font-semibold">
            {Object.keys(group.pendingRequests || {}).length}
          </p>
        </div>
      </div>

      <MemberManager
        entityType="group"
        entityId={group.id}
        memberIds={group.memberIds}
        adminIds={group.adminIds}
        members={members}
        onInvite={(userId) => inviteMember(group.id, userId)}
        onAddDirect={(userId) => addMember(group.id, userId)}
        onRemove={(userId) => removeMember(group.id, userId)}
        onPromote={(userId) => promoteAdmin(group.id, userId)}
        onDemote={(userId) => demoteAdmin(group.id, userId)}
        onApprove={(userId) => approveRequest(group.id, userId)}
        onReject={(userId) => rejectRequest(group.id, userId)}
        onChanged={load}
      />
    </div>
  );
}
