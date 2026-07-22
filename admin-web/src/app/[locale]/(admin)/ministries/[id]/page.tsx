"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import {
  addMinistryMember,
  approveMinistryRequest,
  demoteMinistryAdmin,
  getMinistry,
  inviteMinistryMember,
  promoteMinistryAdmin,
  rejectMinistryRequest,
  removeMinistryMember,
  type MinistryDoc,
} from "@/lib/services/ministries";
import { getUsersByIds, type AppUserDoc } from "@/lib/services/users";
import { MemberManager } from "@/components/MemberManager";
import { Button, EmptyState, PageHeader } from "@/components/ui";
import { ArrowLeft } from "lucide-react";

export default function MinistryDetailPage() {
  const t = useTranslations();
  const params = useParams<{ id: string }>();
  const [ministry, setMinistry] = useState<MinistryDoc | null>(null);
  const [members, setMembers] = useState<AppUserDoc[]>([]);

  async function load() {
    const m = await getMinistry(params.id);
    setMinistry(m);
    if (m) setMembers(await getUsersByIds(m.memberIds));
  }

  useEffect(() => {
    load();
  }, [params.id]);

  if (!ministry) return <EmptyState message={t("common.loading")} />;

  return (
    <div className="space-y-6">
      <PageHeader
        title={ministry.name}
        subtitle={ministry.description || t("ministries.detail")}
        actions={
          <Link href="/ministries">
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
          <p className="mt-1 text-2xl font-semibold">
            {ministry.memberIds.length}
          </p>
        </div>
        <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4">
          <p className="text-xs uppercase tracking-wide text-[var(--muted)]">
            {t("common.admins")}
          </p>
          <p className="mt-1 text-2xl font-semibold">
            {ministry.adminIds.length}
          </p>
        </div>
        <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4">
          <p className="text-xs uppercase tracking-wide text-[var(--muted)]">
            {t("members.pending")}
          </p>
          <p className="mt-1 text-2xl font-semibold">
            {Object.keys(ministry.pendingRequests || {}).length}
          </p>
        </div>
      </div>

      <MemberManager
        entityType="ministry"
        entityId={ministry.id}
        memberIds={ministry.memberIds}
        adminIds={ministry.adminIds}
        members={members}
        onInvite={(userId) => inviteMinistryMember(ministry.id, userId)}
        onAddDirect={(userId) => addMinistryMember(ministry.id, userId)}
        onRemove={(userId) => removeMinistryMember(ministry.id, userId)}
        onPromote={(userId) => promoteMinistryAdmin(ministry.id, userId)}
        onDemote={(userId) => demoteMinistryAdmin(ministry.id, userId)}
        onApprove={(userId) => approveMinistryRequest(ministry.id, userId)}
        onReject={(userId) => rejectMinistryRequest(ministry.id, userId)}
        onChanged={load}
      />
    </div>
  );
}
