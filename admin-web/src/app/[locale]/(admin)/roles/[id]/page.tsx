"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { useParams } from "next/navigation";
import { useRouter } from "@/i18n/navigation";
import {
  ALL_PERMISSIONS,
  PERMISSION_CATEGORIES,
} from "@/lib/permissions";
import {
  createRole,
  getRole,
  updateRole,
} from "@/lib/services/roles";
import { Button, Card, Input, PageHeader, TextArea } from "@/components/ui";

export default function RoleFormPage() {
  const t = useTranslations();
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const isNew = params.id === "new";
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const init: Record<string, boolean> = {};
    for (const p of ALL_PERMISSIONS) init[p] = false;
    if (isNew) {
      setSelected(init);
      return;
    }
    getRole(params.id).then((role) => {
      if (!role) return;
      setName(role.name);
      setDescription(role.description || "");
      for (const p of ALL_PERMISSIONS) {
        init[p] = role.permissions.includes(p);
      }
      setSelected({ ...init });
    });
  }, [isNew, params.id]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    const permissions = Object.entries(selected)
      .filter(([, v]) => v)
      .map(([k]) => k);
    try {
      if (isNew) {
        await createRole({ name, description, permissions });
      } else {
        await updateRole({
          id: params.id,
          name,
          description,
          permissions,
        });
      }
      router.push("/roles");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader title={isNew ? t("roles.create") : t("roles.edit")} />
      <form onSubmit={onSubmit} className="space-y-4">
        <Card className="space-y-3">
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
            rows={3}
          />
        </Card>
        <Card>
          <h2 className="mb-4 font-semibold">{t("roles.permissions")}</h2>
          <div className="space-y-6">
            {Object.entries(PERMISSION_CATEGORIES).map(([cat, perms]) => (
              <div key={cat}>
                <h3 className="mb-2 text-sm font-semibold text-[var(--muted)]">
                  {t(`roles.categories.${cat}`)}
                </h3>
                <div className="grid gap-2 sm:grid-cols-2">
                  {perms.map((p) => (
                    <label
                      key={p}
                      className="flex items-center gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
                    >
                      <input
                        type="checkbox"
                        checked={!!selected[p]}
                        onChange={(e) =>
                          setSelected((s) => ({ ...s, [p]: e.target.checked }))
                        }
                      />
                      {t(`permissions.${p}`)}
                    </label>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </Card>
        <div className="flex gap-2">
          <Button type="submit" disabled={busy}>
            {t("common.save")}
          </Button>
          <Button type="button" variant="secondary" onClick={() => router.back()}>
            {t("common.cancel")}
          </Button>
        </div>
      </form>
    </div>
  );
}
