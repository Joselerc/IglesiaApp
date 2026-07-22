"use client";

import { FormEvent, useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useTranslations } from "next-intl";
import {
  assignMinistryToCult,
  createAvailableRole,
  createTimeSlot,
  createWorkAssignment,
  deleteAssignment,
  deleteTimeSlot,
  getCult,
  listAssignments,
  listAvailableRoles,
  listCultMinistries,
  listTimeSlots,
  setAttendance,
  type AvailableRoleDoc,
  type TimeSlotDoc,
  type WorkAssignmentDoc,
} from "@/lib/services/schedules";
import { listMinistries, type MinistryDoc } from "@/lib/services/ministries";
import { getUsersByIds, searchUsersByName, type AppUserDoc } from "@/lib/services/users";
import {
  Badge,
  Button,
  Card,
  EmptyState,
  Input,
  PageHeader,
  Select,
} from "@/components/ui";
import { formatDateTime } from "@/lib/utils";

export default function CultDetailPage() {
  const t = useTranslations();
  const params = useParams<{ id: string }>();
  const cultId = params.id;

  const [cult, setCult] = useState<Record<string, unknown> | null>(null);
  const [slots, setSlots] = useState<TimeSlotDoc[]>([]);
  const [selectedSlot, setSelectedSlot] = useState("");
  const [roles, setRoles] = useState<AvailableRoleDoc[]>([]);
  const [assignments, setAssignments] = useState<WorkAssignmentDoc[]>([]);
  const [assignees, setAssignees] = useState<Record<string, AppUserDoc>>({});
  const [ministries, setMinistries] = useState<MinistryDoc[]>([]);
  const [cultMinistries, setCultMinistries] = useState<
    { id: string; ministryId: string; name: string }[]
  >([]);

  const [slotName, setSlotName] = useState("Culto");
  const [slotStart, setSlotStart] = useState("");
  const [slotEnd, setSlotEnd] = useState("");
  const [roleName, setRoleName] = useState("");
  const [roleMinistry, setRoleMinistry] = useState("");
  const [capacity, setCapacity] = useState(1);
  const [assignRole, setAssignRole] = useState("");
  const [assignMinistry, setAssignMinistry] = useState("");
  const [userSearch, setUserSearch] = useState("");
  const [userResults, setUserResults] = useState<AppUserDoc[]>([]);
  const [ministryToAdd, setMinistryToAdd] = useState("");

  async function loadBase() {
    const [c, s, m, cm] = await Promise.all([
      getCult(cultId),
      listTimeSlots(cultId),
      listMinistries(),
      listCultMinistries(cultId),
    ]);
    setCult(c);
    setSlots(s);
    setMinistries(m);
    setCultMinistries(cm);
    if (!selectedSlot && s[0]) setSelectedSlot(s[0].id);
  }

  async function loadSlotData(slotId: string) {
    if (!slotId) {
      setRoles([]);
      setAssignments([]);
      return;
    }
    const [r, a] = await Promise.all([
      listAvailableRoles(slotId),
      listAssignments(slotId),
    ]);
    setRoles(r);
    setAssignments(a);
    const users = await getUsersByIds(a.map((x) => x.userId));
    setAssignees(Object.fromEntries(users.map((u) => [u.id, u])));
  }

  useEffect(() => {
    loadBase();
  }, [cultId]);

  useEffect(() => {
    loadSlotData(selectedSlot);
  }, [selectedSlot]);

  if (!cult) return <EmptyState message={t("common.loading")} />;

  async function onCreateSlot(e: FormEvent) {
    e.preventDefault();
    if (!slotStart || !slotEnd) return;
    const id = await createTimeSlot({
      entityId: cultId,
      entityType: "cult",
      name: slotName,
      startTime: new Date(slotStart),
      endTime: new Date(slotEnd),
    });
    setSlotStart("");
    setSlotEnd("");
    await loadBase();
    setSelectedSlot(id);
  }

  async function onCreateRole(e: FormEvent) {
    e.preventDefault();
    if (!selectedSlot || !roleMinistry || !roleName) return;
    await createAvailableRole({
      timeSlotId: selectedSlot,
      ministryId: roleMinistry,
      role: roleName,
      capacity,
    });
    setRoleName("");
    loadSlotData(selectedSlot);
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={`${t("cults.title")} · ${cultId.slice(0, 8)}`}
        subtitle={String(cult.status || "scheduled")}
      />

      <Card>
        <h2 className="mb-3 font-semibold">{t("cults.ministries")}</h2>
        <div className="mb-3 flex flex-wrap gap-2">
          {cultMinistries.map((cm) => (
            <Badge key={cm.id}>{cm.name || cm.ministryId}</Badge>
          ))}
        </div>
        <div className="flex flex-wrap gap-2">
          <Select
            value={ministryToAdd}
            onChange={(e) => setMinistryToAdd(e.target.value)}
          >
            <option value="">—</option>
            {ministries.map((m) => (
              <option key={m.id} value={m.id}>
                {m.name}
              </option>
            ))}
          </Select>
          <Button
            onClick={async () => {
              if (!ministryToAdd) return;
              await assignMinistryToCult(cultId, ministryToAdd);
              setMinistryToAdd("");
              loadBase();
            }}
          >
            {t("common.add")}
          </Button>
        </div>
      </Card>

      <Card>
        <h2 className="mb-3 font-semibold">{t("cults.timeSlots")}</h2>
        <form onSubmit={onCreateSlot} className="mb-4 grid gap-3 md:grid-cols-4">
          <Input
            label={t("common.name")}
            value={slotName}
            onChange={(e) => setSlotName(e.target.value)}
          />
          <Input
            label={t("common.start")}
            type="datetime-local"
            value={slotStart}
            onChange={(e) => setSlotStart(e.target.value)}
            required
          />
          <Input
            label={t("common.end")}
            type="datetime-local"
            value={slotEnd}
            onChange={(e) => setSlotEnd(e.target.value)}
            required
          />
          <div className="flex items-end">
            <Button type="submit" className="w-full">
              {t("cults.createSlot")}
            </Button>
          </div>
        </form>

        <Select
          label={t("cults.timeSlots")}
          value={selectedSlot}
          onChange={(e) => setSelectedSlot(e.target.value)}
        >
          {slots.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name} · {formatDateTime(s.startTime)}
            </option>
          ))}
        </Select>
        {selectedSlot && (
          <Button
            className="mt-3"
            variant="danger"
            onClick={async () => {
              if (!confirm(t("common.confirmDelete"))) return;
              await deleteTimeSlot(selectedSlot);
              setSelectedSlot("");
              loadBase();
            }}
          >
            {t("common.delete")}
          </Button>
        )}
      </Card>

      {selectedSlot && (
        <>
          <Card>
            <h2 className="mb-3 font-semibold">{t("cults.availableRoles")}</h2>
            <form onSubmit={onCreateRole} className="mb-4 grid gap-3 md:grid-cols-4">
              <Select
                label={t("nav.ministries")}
                value={roleMinistry}
                onChange={(e) => setRoleMinistry(e.target.value)}
                required
              >
                <option value="">—</option>
                {ministries.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.name}
                  </option>
                ))}
              </Select>
              <Input
                label={t("common.role")}
                value={roleName}
                onChange={(e) => setRoleName(e.target.value)}
                required
              />
              <Input
                label={t("common.capacity")}
                type="number"
                min={1}
                value={capacity}
                onChange={(e) => setCapacity(Number(e.target.value))}
              />
              <div className="flex items-end">
                <Button type="submit" className="w-full">
                  {t("common.create")}
                </Button>
              </div>
            </form>
            <div className="space-y-2">
              {roles.map((r) => (
                <div
                  key={r.id}
                  className="flex items-center justify-between rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
                >
                  <span>
                    {r.role} · {ministries.find((m) => m.id === r.ministryId)?.name || r.ministryId}
                  </span>
                  <Badge>
                    {r.current}/{r.capacity}
                  </Badge>
                </div>
              ))}
            </div>
          </Card>

          <Card>
            <h2 className="mb-3 font-semibold">{t("cults.assignPerson")}</h2>
            <div className="mb-3 grid gap-3 md:grid-cols-3">
              <Select
                label={t("nav.ministries")}
                value={assignMinistry}
                onChange={(e) => setAssignMinistry(e.target.value)}
              >
                <option value="">—</option>
                {ministries.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.name}
                  </option>
                ))}
              </Select>
              <Select
                label={t("common.role")}
                value={assignRole}
                onChange={(e) => setAssignRole(e.target.value)}
              >
                <option value="">—</option>
                {roles
                  .filter((r) => !assignMinistry || r.ministryId === assignMinistry)
                  .map((r) => (
                    <option key={r.id} value={r.role}>
                      {r.role}
                    </option>
                  ))}
              </Select>
              <Input
                label={t("common.search")}
                value={userSearch}
                onChange={async (e) => {
                  setUserSearch(e.target.value);
                  setUserResults(await searchUsersByName(e.target.value));
                }}
              />
            </div>
            <div className="mb-4 flex flex-wrap gap-2">
              {userResults.slice(0, 8).map((u) => (
                <Button
                  key={u.id}
                  variant="secondary"
                  onClick={async () => {
                    if (!assignMinistry || !assignRole) {
                      alert("Select ministry and role");
                      return;
                    }
                    await createWorkAssignment({
                      timeSlotId: selectedSlot,
                      ministryId: assignMinistry,
                      userId: u.id,
                      role: assignRole,
                    });
                    setUserSearch("");
                    setUserResults([]);
                    loadSlotData(selectedSlot);
                  }}
                >
                  {t("common.assign")} {u.name}
                </Button>
              ))}
            </div>

            <h3 className="mb-2 text-sm font-semibold">{t("cults.assignments")}</h3>
            <div className="space-y-2">
              {assignments.map((a) => (
                <div
                  key={a.id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
                >
                  <div>
                    <p className="font-medium">
                      {assignees[a.userId]?.name || a.userId}
                    </p>
                    <p className="text-xs text-[var(--muted)]">
                      {a.role} · {a.status}
                      {a.isAttendanceConfirmed ? " · ✓" : ""}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      variant="secondary"
                      onClick={async () => {
                        await setAttendance(a.id, !a.isAttendanceConfirmed);
                        loadSlotData(selectedSlot);
                      }}
                    >
                      {t("common.confirm")}
                    </Button>
                    <Button
                      variant="danger"
                      onClick={async () => {
                        await deleteAssignment(a.id);
                        loadSlotData(selectedSlot);
                      }}
                    >
                      {t("common.remove")}
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </>
      )}
    </div>
  );
}

