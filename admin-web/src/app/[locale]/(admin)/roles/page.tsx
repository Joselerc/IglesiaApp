"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { deleteRole, listRoles, type Role } from "@/lib/services/roles";
import { Button, EmptyState, PageHeader, Table } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function RolesPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    setRoles(await listRoles());
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  if (!can("manage_roles")) {
    return <EmptyState message={t("auth.noAccess")} />;
  }

  return (
    <div>
      <PageHeader
        title={t("roles.title")}
        actions={
          <Link href="/roles/new">
            <Button>{t("roles.create")}</Button>
          </Link>
        }
      />
      {loading ? (
        <p>{t("common.loading")}</p>
      ) : roles.length === 0 ? (
        <EmptyState message={t("common.empty")} />
      ) : (
        <Table>
          <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
            <tr>
              <th className="px-4 py-3">{t("common.name")}</th>
              <th className="px-4 py-3">{t("common.description")}</th>
              <th className="px-4 py-3">{t("roles.permissions")}</th>
              <th className="px-4 py-3">{t("common.actions")}</th>
            </tr>
          </thead>
          <tbody>
            {roles.map((role) => (
              <tr key={role.id} className="border-b border-[var(--border)]">
                <td className="px-4 py-3 font-medium">{role.name}</td>
                <td className="px-4 py-3 text-[var(--muted)]">
                  {role.description || "—"}
                </td>
                <td className="px-4 py-3">{role.permissions.length}</td>
                <td className="px-4 py-3">
                  <div className="flex gap-2">
                    <Link href={`/roles/${role.id}`}>
                      <Button variant="secondary">{t("common.edit")}</Button>
                    </Link>
                    <Button
                      variant="danger"
                      onClick={async () => {
                        if (!confirm(t("common.confirmDelete"))) return;
                        await deleteRole(role.id);
                        load();
                      }}
                    >
                      {t("common.delete")}
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </div>
  );
}
