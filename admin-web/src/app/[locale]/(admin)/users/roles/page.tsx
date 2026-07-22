"use client";

import { useEffect, useMemo, useState } from "react";
import { useTranslations } from "next-intl";
import { assignUserRole, listUsers, type AppUserDoc } from "@/lib/services/users";
import { listRoles, type Role } from "@/lib/services/roles";
import { Badge, EmptyState, Input, PageHeader, Select, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function AssignRolesPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [users, setUsers] = useState<AppUserDoc[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [q, setQ] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([listUsers(), listRoles()]).then(([u, r]) => {
      setUsers(u);
      setRoles(r);
    });
  }, []);

  const filtered = useMemo(() => {
    const term = q.trim().toLowerCase();
    if (!term) return users;
    return users.filter(
      (u) =>
        u.name.toLowerCase().includes(term) ||
        u.email.toLowerCase().includes(term)
    );
  }, [users, q]);

  const roleMap = useMemo(
    () => Object.fromEntries(roles.map((r) => [r.id, r.name])),
    [roles]
  );

  if (!can("assign_user_roles")) return <EmptyState message={t("auth.noAccess")} />;

  return (
    <div>
      <PageHeader title={t("nav.assignRoles")} />
      <div className="mb-4 max-w-md">
        <Input
          label={t("common.search")}
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.user")}</th>
            <th className="px-4 py-3">{t("common.email")}</th>
            <th className="px-4 py-3">{t("users.currentRole")}</th>
            <th className="px-4 py-3">{t("users.assignRole")}</th>
          </tr>
        </thead>
        <tbody>
          {filtered.slice(0, 100).map((user) => (
            <tr key={user.id} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">
                <div className="font-medium">{user.name}</div>
                {user.isSuperUser && <Badge tone="warning">{t("users.superUser")}</Badge>}
              </td>
              <td className="px-4 py-3 text-[var(--muted)]">{user.email}</td>
              <td className="px-4 py-3">
                {user.roleId ? roleMap[user.roleId] || user.roleId : t("users.noRole")}
              </td>
              <td className="px-4 py-3">
                <div className="flex max-w-xs items-center gap-2">
                  <Select
                    value={user.roleId || ""}
                    onChange={async (e) => {
                      const roleId = e.target.value || null;
                      setBusyId(user.id);
                      await assignUserRole(user.id, roleId);
                      setUsers((prev) =>
                        prev.map((u) =>
                          u.id === user.id ? { ...u, roleId } : u
                        )
                      );
                      setBusyId(null);
                    }}
                    disabled={busyId === user.id}
                  >
                    <option value="">{t("users.noRole")}</option>
                    {roles.map((r) => (
                      <option key={r.id} value={r.id}>
                        {r.name}
                      </option>
                    ))}
                  </Select>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
