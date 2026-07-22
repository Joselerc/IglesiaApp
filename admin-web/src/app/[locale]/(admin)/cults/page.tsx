"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import {
  createCult,
  createService,
  listCultsByService,
  listServices,
  type CultDoc,
  type ServiceDoc,
} from "@/lib/services/schedules";
import {
  Button,
  Card,
  EmptyState,
  Input,
  PageHeader,
  Select,
} from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";
import { formatDate } from "@/lib/utils";

export default function CultsPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [services, setServices] = useState<ServiceDoc[]>([]);
  const [selectedService, setSelectedService] = useState("");
  const [cults, setCults] = useState<CultDoc[]>([]);
  const [serviceName, setServiceName] = useState("");
  const [cultDate, setCultDate] = useState("");
  const [start, setStart] = useState("09:00");
  const [end, setEnd] = useState("11:00");

  async function loadServices() {
    const s = await listServices();
    setServices(s);
    if (!selectedService && s[0]) setSelectedService(s[0].id);
  }

  async function loadCults(serviceId: string) {
    if (!serviceId) return setCults([]);
    setCults(await listCultsByService(serviceId));
  }

  useEffect(() => {
    loadServices();
  }, []);

  useEffect(() => {
    loadCults(selectedService);
  }, [selectedService]);

  if (!can("manage_cults")) return <EmptyState message={t("auth.noAccess")} />;

  async function onCreateService(e: FormEvent) {
    e.preventDefault();
    const id = await createService(serviceName);
    setServiceName("");
    await loadServices();
    setSelectedService(id);
  }

  async function onCreateCult(e: FormEvent) {
    e.preventDefault();
    if (!selectedService || !cultDate) return;
    const [sh, sm] = start.split(":").map(Number);
    const [eh, em] = end.split(":").map(Number);
    const date = new Date(`${cultDate}T00:00:00`);
    const startTime = new Date(date);
    startTime.setHours(sh, sm, 0, 0);
    const endTime = new Date(date);
    endTime.setHours(eh, em, 0, 0);
    await createCult({
      serviceId: selectedService,
      date,
      startTime,
      endTime,
    });
    setCultDate("");
    loadCults(selectedService);
  }

  return (
    <div className="space-y-6">
      <PageHeader title={t("cults.title")} subtitle={t("cults.services")} />

      <Card>
        <form onSubmit={onCreateService} className="flex flex-wrap items-end gap-3">
          <div className="min-w-[220px] flex-1">
            <Input
              label={t("cults.createService")}
              value={serviceName}
              onChange={(e) => setServiceName(e.target.value)}
              required
            />
          </div>
          <Button type="submit">{t("common.create")}</Button>
        </form>
      </Card>

      <Card className="space-y-4">
        <Select
          label={t("cults.services")}
          value={selectedService}
          onChange={(e) => setSelectedService(e.target.value)}
        >
          {services.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name}
            </option>
          ))}
        </Select>

        <form onSubmit={onCreateCult} className="grid gap-3 md:grid-cols-4">
          <Input
            label={t("common.date")}
            type="date"
            value={cultDate}
            onChange={(e) => setCultDate(e.target.value)}
            required
          />
          <Input
            label={t("common.start")}
            type="time"
            value={start}
            onChange={(e) => setStart(e.target.value)}
          />
          <Input
            label={t("common.end")}
            type="time"
            value={end}
            onChange={(e) => setEnd(e.target.value)}
          />
          <div className="flex items-end">
            <Button type="submit" className="w-full">
              {t("cults.createCult")}
            </Button>
          </div>
        </form>

        <div className="divide-y divide-[var(--border)]">
          {cults.length === 0 ? (
            <p className="py-6 text-sm text-[var(--muted)]">{t("common.empty")}</p>
          ) : (
            cults.map((c) => (
              <Link
                key={c.id}
                href={`/cults/${c.id}`}
                className="flex items-center justify-between py-3 hover:bg-[var(--bg)]"
              >
                <div>
                  <p className="font-medium">{formatDate(c.date)}</p>
                  <p className="text-xs text-[var(--muted)]">{c.status || "scheduled"}</p>
                </div>
                <span className="text-sm text-[var(--primary)]">{t("common.view")} →</span>
              </Link>
            ))
          )}
        </div>
      </Card>
    </div>
  );
}
