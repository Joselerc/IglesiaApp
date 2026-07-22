"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { listAllWorkInvites, type WorkInviteDoc } from "@/lib/services/schedules";
import { getUsersByIds, type AppUserDoc } from "@/lib/services/users";
import { Badge, EmptyState, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { formatDateTime } from "@/lib/utils";

export default function WorkInvitesPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [invites, setInvites] = useState<WorkInviteDoc[]>([]);
  const [users, setUsers] = useState<Record<string, AppUserDoc>>({});

  useEffect(() => {
    listAllWorkInvites().then(async (list) => {
      setInvites(list);
      const us = await getUsersByIds(list.map((i) => i.userId));
      setUsers(Object.fromEntries(us.map((u) => [u.id, u])));
    });
  }, []);

  if (!can("manage_cults")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.workInvites")} />
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.user")}</th>
            <th className="px-4 py-3">{t("nav.ministries")}</th>
            <th className="px-4 py-3">{t("common.role")}</th>
            <th className="px-4 py-3">{t("common.status")}</th>
            <th className="px-4 py-3">{t("common.start")}</th>
          </tr>
        </thead>
        <tbody>
          {invites.map((i) => (
            <tr key={i.id} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">
                {users[i.userId]?.name || i.userId}
              </td>
              <td className="px-4 py-3">{i.ministryName || i.ministryId}</td>
              <td className="px-4 py-3">{i.role}</td>
              <td className="px-4 py-3">
                <Badge
                  tone={
                    i.status === "accepted"
                      ? "success"
                      : i.status === "rejected"
                        ? "danger"
                        : "warning"
                  }
                >
                  {i.status}
                </Badge>
              </td>
              <td className="px-4 py-3">{formatDateTime(i.startTime)}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
