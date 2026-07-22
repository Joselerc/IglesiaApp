"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { getUser, type AppUserDoc } from "@/lib/services/users";
import { getRole } from "@/lib/services/roles";
import { Card, EmptyState, PageHeader } from "@/components/ui";

export default function UserDetailPage() {
  const t = useTranslations();
  const params = useParams<{ id: string }>();
  const [user, setUser] = useState<AppUserDoc | null>(null);
  const [roleName, setRoleName] = useState<string>("");

  useEffect(() => {
    getUser(params.id).then(async (u) => {
      setUser(u);
      if (u?.roleId) {
        const role = await getRole(u.roleId);
        setRoleName(role?.name || u.roleId);
      }
    });
  }, [params.id]);

  if (!user) return <EmptyState message={t("common.loading")} />;

  return (
    <div>
      <PageHeader title={user.name} subtitle={user.email} />
      <Card className="space-y-2 text-sm">
        <p>
          <strong>ID:</strong> {user.id}
        </p>
        <p>
          <strong>{t("common.phone")}:</strong> {user.phone || "—"}
        </p>
        <p>
          <strong>{t("users.currentRole")}:</strong>{" "}
          {user.isSuperUser ? t("users.superUser") : roleName || t("users.noRole")}
        </p>
      </Card>
    </div>
  );
}
