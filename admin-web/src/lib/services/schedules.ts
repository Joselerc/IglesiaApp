import {
  Timestamp,
  addDoc,
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { col, refId, userRef } from "@/lib/utils";

export type ServiceDoc = {
  id: string;
  name: string;
  description?: string;
  isActive?: boolean;
};

export type CultDoc = {
  id: string;
  serviceId: string;
  name?: string;
  date: unknown;
  startTime?: unknown;
  endTime?: unknown;
  status?: string;
};

export type TimeSlotDoc = {
  id: string;
  entityId: string;
  entityType: string;
  name: string;
  startTime: unknown;
  endTime: unknown;
  description?: string;
  isActive: boolean;
};

export type AvailableRoleDoc = {
  id: string;
  timeSlotId: string;
  ministryId: string;
  role: string;
  capacity: number;
  current: number;
};

export type WorkAssignmentDoc = {
  id: string;
  timeSlotId: string;
  ministryId: string;
  userId: string;
  role: string;
  status: string;
  isActive: boolean;
  isAttendanceConfirmed?: boolean;
  notes?: string;
};

export type WorkInviteDoc = {
  id: string;
  assignmentId?: string;
  timeSlotId: string;
  entityId?: string;
  userId: string;
  ministryId: string;
  ministryName?: string;
  role: string;
  status: string;
  isVisible?: boolean;
  isActive?: boolean;
  startTime?: unknown;
  endTime?: unknown;
};

export async function listServices(): Promise<ServiceDoc[]> {
  const snap = await getDocs(col("services"));
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      name: data.name ?? data.title ?? d.id,
      description: data.description,
      isActive: data.isActive !== false,
    };
  });
}

export async function createService(name: string, description = "") {
  const ref = await addDoc(col("services"), {
    name,
    description,
    isActive: true,
    createdAt: serverTimestamp(),
    createdBy: auth.currentUser ? userRef(auth.currentUser.uid) : null,
  });
  return ref.id;
}

export async function listCultsByService(serviceId: string): Promise<CultDoc[]> {
  const snap = await getDocs(
    query(col("cults"), where("serviceId", "==", serviceId))
  );
  return snap.docs
    .map((d) => {
      const data = d.data();
      return {
        id: d.id,
        serviceId: data.serviceId,
        name: data.name,
        date: data.date,
        startTime: data.startTime,
        endTime: data.endTime,
        status: data.status,
      } as CultDoc;
    })
    .sort((a, b) => {
      const da = a.date instanceof Timestamp ? a.date.toMillis() : 0;
      const dbv = b.date instanceof Timestamp ? b.date.toMillis() : 0;
      return dbv - da;
    });
}

export async function createCult(input: {
  serviceId: string;
  name?: string;
  date: Date;
  startTime: Date;
  endTime: Date;
}) {
  const ref = await addDoc(col("cults"), {
    serviceId: input.serviceId,
    name: input.name || "",
    date: Timestamp.fromDate(input.date),
    startTime: Timestamp.fromDate(input.startTime),
    endTime: Timestamp.fromDate(input.endTime),
    status: "scheduled",
    createdAt: serverTimestamp(),
    createdBy: auth.currentUser ? userRef(auth.currentUser.uid) : null,
  });
  return ref.id;
}

export async function getCult(id: string) {
  const snap = await getDoc(doc(col("cults"), id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() };
}

export async function deleteCult(cultId: string) {
  const slots = await getDocs(
    query(
      col("time_slots"),
      where("entityId", "==", cultId),
      where("entityType", "==", "cult")
    )
  );
  const batch = writeBatch(db);
  for (const s of slots.docs) {
    batch.update(s.ref, { isActive: false });
  }
  batch.delete(doc(col("cults"), cultId));
  await batch.commit();
}

export async function listTimeSlots(cultId: string): Promise<TimeSlotDoc[]> {
  const snap = await getDocs(
    query(
      col("time_slots"),
      where("entityId", "==", cultId),
      where("entityType", "==", "cult"),
      where("isActive", "==", true)
    )
  );
  return snap.docs
    .map((d) => {
      const data = d.data();
      return {
        id: d.id,
        entityId: data.entityId,
        entityType: data.entityType,
        name: data.name ?? "",
        startTime: data.startTime,
        endTime: data.endTime,
        description: data.description,
        isActive: data.isActive !== false,
      } as TimeSlotDoc;
    })
    .sort((a, b) => {
      const sa = a.startTime instanceof Timestamp ? a.startTime.toMillis() : 0;
      const sb = b.startTime instanceof Timestamp ? b.startTime.toMillis() : 0;
      return sa - sb;
    });
}

export async function createTimeSlot(input: {
  entityId: string;
  entityType: string;
  name: string;
  startTime: Date;
  endTime: Date;
  description?: string;
}) {
  if (input.startTime >= input.endTime) {
    throw new Error("Start must be before end");
  }
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Unauthenticated");
  const ref = await addDoc(col("time_slots"), {
    entityId: input.entityId,
    entityType: input.entityType,
    name: input.name,
    startTime: Timestamp.fromDate(input.startTime),
    endTime: Timestamp.fromDate(input.endTime),
    description: input.description || "",
    isActive: true,
    createdAt: Timestamp.fromDate(new Date()),
    createdBy: userRef(uid),
  });
  return ref.id;
}

export async function deleteTimeSlot(timeSlotId: string) {
  await updateDoc(doc(col("time_slots"), timeSlotId), { isActive: false });
  const assignments = await getDocs(
    query(
      col("work_assignments"),
      where("timeSlotId", "==", timeSlotId),
      where("isActive", "==", true)
    )
  );
  const batch = writeBatch(db);
  for (const a of assignments.docs) {
    batch.update(a.ref, { isActive: false });
  }
  await batch.commit();
}

export async function listAvailableRoles(timeSlotId: string) {
  const snap = await getDocs(
    query(col("available_roles"), where("timeSlotId", "==", timeSlotId))
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      timeSlotId: data.timeSlotId,
      ministryId: refId(data.ministryId),
      role: data.role ?? "",
      capacity: Number(data.capacity ?? 1),
      current: Number(data.current ?? data.acceptedCount ?? 0),
    } as AvailableRoleDoc;
  });
}

export async function createAvailableRole(input: {
  timeSlotId: string;
  ministryId: string;
  role: string;
  capacity: number;
}) {
  const ref = await addDoc(col("available_roles"), {
    timeSlotId: input.timeSlotId,
    ministryId: doc(db, "ministries", input.ministryId),
    role: input.role,
    capacity: input.capacity,
    current: 0,
    createdAt: serverTimestamp(),
  });
  // Persist reusable ministry role (soft catalog)
  const existing = await getDocs(
    query(
      col("ministry_roles"),
      where("ministryId", "==", input.ministryId),
      where("name", "==", input.role)
    )
  );
  if (existing.empty) {
    await addDoc(col("ministry_roles"), {
      ministryId: input.ministryId,
      name: input.role,
      description: "",
      isActive: true,
      createdAt: serverTimestamp(),
    });
  }
  return ref.id;
}

export async function listAssignments(timeSlotId: string): Promise<WorkAssignmentDoc[]> {
  const snap = await getDocs(
    query(
      col("work_assignments"),
      where("timeSlotId", "==", timeSlotId),
      where("isActive", "==", true)
    )
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      timeSlotId: data.timeSlotId,
      ministryId: refId(data.ministryId),
      userId: refId(data.userId),
      role: data.role ?? "",
      status: data.status ?? "pending",
      isActive: data.isActive !== false,
      isAttendanceConfirmed: data.isAttendanceConfirmed === true,
      notes: data.notes,
    };
  });
}

export async function createWorkAssignment(input: {
  timeSlotId: string;
  ministryId: string;
  userId: string;
  role: string;
  notes?: string;
}) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Unauthenticated");

  const timeSlotSnap = await getDoc(doc(col("time_slots"), input.timeSlotId));
  if (!timeSlotSnap.exists()) throw new Error("Time slot not found");
  const timeSlotData = timeSlotSnap.data();
  if (timeSlotData.isActive === false) throw new Error("Time slot inactive");

  const userR = userRef(input.userId);
  const ministryRef = doc(db, "ministries", input.ministryId);

  const existing = await getDocs(
    query(
      col("work_assignments"),
      where("timeSlotId", "==", input.timeSlotId),
      where("userId", "==", userR)
    )
  );

  for (const d of existing.docs) {
    const data = d.data();
    const sameMinistry = refId(data.ministryId) === input.ministryId;
    const sameRole = data.role === input.role;
    if (
      data.isActive !== false &&
      data.status !== "rejected" &&
      sameMinistry &&
      sameRole
    ) {
      throw new Error("Active assignment already exists for this role");
    }
    if (
      data.isActive !== false &&
      data.status === "rejected" &&
      sameMinistry &&
      sameRole
    ) {
      await updateDoc(d.ref, {
        status: "pending",
        updatedAt: serverTimestamp(),
      });
      const invites = await getDocs(
        query(
          col("work_invites"),
          where("assignmentId", "==", d.id)
        )
      );
      if (!invites.empty) {
        await updateDoc(invites.docs[0].ref, {
          status: "pending",
          isRejected: false,
          isVisible: true,
          updatedAt: serverTimestamp(),
        });
      } else {
        await createInviteForAssignment({
          assignmentId: d.id,
          timeSlotId: input.timeSlotId,
          timeSlotData,
          ministryId: input.ministryId,
          userId: input.userId,
          role: input.role,
          sentBy: uid,
        });
      }
      return d.id;
    }
  }

  const assignmentRef = await addDoc(col("work_assignments"), {
    timeSlotId: input.timeSlotId,
    ministryId: ministryRef,
    userId: userR,
    role: input.role,
    status: "pending",
    createdAt: serverTimestamp(),
    invitedBy: userRef(uid),
    isActive: true,
    notes: input.notes || "",
  });

  await createInviteForAssignment({
    assignmentId: assignmentRef.id,
    timeSlotId: input.timeSlotId,
    timeSlotData,
    ministryId: input.ministryId,
    userId: input.userId,
    role: input.role,
    sentBy: uid,
  });

  return assignmentRef.id;
}

async function createInviteForAssignment(opts: {
  assignmentId: string;
  timeSlotId: string;
  timeSlotData: Record<string, unknown>;
  ministryId: string;
  userId: string;
  role: string;
  sentBy: string;
}) {
  const ministrySnap = await getDoc(doc(db, "ministries", opts.ministryId));
  const ministryName = ministrySnap.exists()
    ? (ministrySnap.data().name as string) || "Ministério"
    : "Ministério";

  await addDoc(col("work_invites"), {
    assignmentId: opts.assignmentId,
    timeSlotId: opts.timeSlotId,
    entityId: opts.timeSlotData.entityId,
    entityType: "cult",
    entityName: "",
    userId: userRef(opts.userId),
    ministryId: doc(db, "ministries", opts.ministryId),
    ministryName,
    role: opts.role,
    status: "pending",
    isRead: false,
    isActive: true,
    isVisible: true,
    startTime: opts.timeSlotData.startTime,
    endTime: opts.timeSlotData.endTime,
    createdAt: serverTimestamp(),
    sentBy: userRef(opts.sentBy),
  });
}

export async function setAttendance(assignmentId: string, confirmed: boolean) {
  await updateDoc(doc(col("work_assignments"), assignmentId), {
    isAttendanceConfirmed: confirmed,
    status: confirmed ? "accepted" : "pending",
    updatedAt: serverTimestamp(),
  });
}

export async function deleteAssignment(assignmentId: string) {
  await updateDoc(doc(col("work_assignments"), assignmentId), {
    isActive: false,
    updatedAt: serverTimestamp(),
  });
  const invites = await getDocs(
    query(col("work_invites"), where("assignmentId", "==", assignmentId))
  );
  for (const inv of invites.docs) {
    await updateDoc(inv.ref, { isActive: false, isVisible: false });
  }
}

export async function listAllWorkInvites(): Promise<WorkInviteDoc[]> {
  const snap = await getDocs(
    query(collection(db, "work_invites"), orderBy("createdAt", "desc"))
  );
  return snap.docs.slice(0, 300).map((d) => {
    const data = d.data();
    return {
      id: d.id,
      assignmentId: data.assignmentId,
      timeSlotId: data.timeSlotId,
      entityId: data.entityId,
      userId: refId(data.userId),
      ministryId: refId(data.ministryId),
      ministryName: data.ministryName,
      role: data.role ?? "",
      status: data.status ?? "pending",
      isVisible: data.isVisible !== false,
      isActive: data.isActive !== false,
      startTime: data.startTime,
      endTime: data.endTime,
    };
  });
}

export async function listCultMinistries(cultId: string) {
  const snap = await getDocs(
    query(col("cult_ministries"), where("cultId", "==", cultId))
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      cultId: data.cultId,
      ministryId: refId(data.ministryId),
      name: data.name || data.ministryName || "",
      isTemporary: data.isTemporary === true,
    };
  });
}

export async function assignMinistryToCult(cultId: string, ministryId: string) {
  const ministry = await getDoc(doc(db, "ministries", ministryId));
  const name = ministry.exists() ? ministry.data().name : "";
  await addDoc(col("cult_ministries"), {
    cultId,
    ministryId: doc(db, "ministries", ministryId),
    name,
    ministryName: name,
    isTemporary: false,
    createdAt: serverTimestamp(),
  });
}
