"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { getPastorAvailability, savePastorAvailability } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

const DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] as const;

export default function CounselingAvailabilityPage() {
  const t = useTranslations();
  const { can, appUser } = useAuth();
  const [sessionDuration, setSessionDuration] = useState(60);
  const [isAcceptingOnline, setIsAcceptingOnline] = useState(true);
  const [isAcceptingInPerson, setIsAcceptingInPerson] = useState(true);
  const [location, setLocation] = useState("");
  const [days, setDays] = useState<Record<string, boolean>>(
    Object.fromEntries(DAYS.map((d) => [d, false]))
  );

  useEffect(() => {
    if (!appUser) return;
    getPastorAvailability(appUser.uid).then((data) => {
      if (!data) return;
      setSessionDuration(Number(data.sessionDuration || 60));
      setIsAcceptingOnline(data.isAcceptingOnline !== false);
      setIsAcceptingInPerson(data.isAcceptingInPerson !== false);
      setLocation(String(data.location || ""));
      const next = { ...days };
      for (const d of DAYS) {
        const day = data[d] as { isWorking?: boolean } | undefined;
        next[d] = day?.isWorking === true;
      }
      setDays(next);
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [appUser]);

  if (!can("manage_counseling_availability")) return <EmptyState message={t("auth.noAccess")} />;

  async function onSave(e: FormEvent) {
    e.preventDefault();
    if (!appUser) return;
    const payload: Record<string, unknown> = {
      sessionDuration,
      breakDuration: 15,
      isAcceptingOnline,
      isAcceptingInPerson,
      location,
      unavailableDates: [],
      weekSchedules: [],
    };
    for (const d of DAYS) {
      payload[d] = {
        isWorking: days[d],
        timeSlots: days[d]
          ? [{ start: "09:00", end: "17:00", isOnline: true, isInPerson: true }]
          : [],
      };
    }
    await savePastorAvailability(appUser.uid, payload);
    alert(t("common.saved"));
  }

  return (
    <div>
      <PageHeader title={t("nav.counselingAvailability")} />
      <Card>
        <form onSubmit={onSave} className="space-y-4">
          <Input label="Session duration (min)" type="number" value={sessionDuration} onChange={(e) => setSessionDuration(Number(e.target.value))} />
          <Input label={t("common.location")} value={location} onChange={(e) => setLocation(e.target.value)} />
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={isAcceptingOnline} onChange={(e) => setIsAcceptingOnline(e.target.checked)} /> Online
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={isAcceptingInPerson} onChange={(e) => setIsAcceptingInPerson(e.target.checked)} /> In person
          </label>
          <div className="grid gap-2 sm:grid-cols-2">
            {DAYS.map((d) => (
              <label key={d} className="flex items-center gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm capitalize">
                <input type="checkbox" checked={!!days[d]} onChange={(e) => setDays({ ...days, [d]: e.target.checked })} />
                {d}
              </label>
            ))}
          </div>
          <Button type="submit">{t("common.save")}</Button>
        </form>
      </Card>
    </div>
  );
}
