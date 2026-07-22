"use client";

import { useEffect, useMemo, useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { listUsers, type AppUserDoc } from "@/lib/services/users";
import { listRoles, type Role } from "@/lib/services/roles";
import { EmptyState, Input, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function UsersInfoPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [users, setUsers] = useState<AppUserDoc[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [q, setQ] = useState("");

  useEffect(() => {
    Promise.all([listUsers(), listRoles()]).then(([u, r]) => {
      setUsers(u);
      setRoles(r);
    });
  }, []);

  const roleMap = useMemo(
    () => Object.fromEntries(roles.map((r) => [r.id, r.name])),
    [roles]
  );

  const filtered = useMemo(() => {
    const term = q.trim().toLowerCase();
    if (!term) return users;
    return users.filter(
      (u) =>
        u.name.toLowerCase().includes(term) ||
        u.email.toLowerCase().includes(term)
    );
  }, [users, q]);

  if (!can("view_user_details")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.userInfo")} />
      <div className="mb-4 max-w-md">
        <Input label={t("common.search")} value={q} onChange={(e) => setQ(e.target.value)} />
      </div>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.user")}</th>
            <th className="px-4 py-3">{t("common.email")}</th>
            <th className="px-4 py-3">{t("common.phone")}</th>
            <th className="px-4 py-3">{t("users.currentRole")}</th>
            <th className="px-4 py-3">{t("common.actions")}</th>
          </tr>
        </thead>
        <tbody>
          {filtered.slice(0, 150).map((u) => (
            <tr key={u.id} className="border-b border-[var(--border)]">
              <td className="px-4 py-3 font-medium">{u.name}</td>
              <td className="px-4 py-3">{u.email}</td>
              <td className="px-4 py-3">{u.phone || "—"}</td>
              <td className="px-4 py-3">
                {u.isSuperUser
                  ? t("users.superUser")
                  : u.roleId
                    ? roleMap[u.roleId] || u.roleId
                    : t("users.noRole")}
              </td>
              <td className="px-4 py-3">
                <Link className="text-[var(--primary)] underline" href={`/users/${u.id}`}>
                  {t("common.view")}
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
