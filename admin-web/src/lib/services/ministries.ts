import {
  Timestamp,
  addDoc,
  arrayRemove,
  arrayUnion,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  updateDoc,
} from "firebase/firestore";
import { auth } from "@/lib/firebase";
import { col, refId, refsToIds, userRef } from "@/lib/utils";
import {
  findPendingRequest,
  getInviterName,
  logMembershipRequest,
  markRequest,
} from "./membership";

export type MinistryDoc = {
  id: string;
  name: string;
  description: string;
  imageUrl: string;
  memberIds: string[];
  adminIds: string[];
  pendingRequests: Record<string, unknown>;
  rejectedRequests: Record<string, unknown>;
  createdBy?: string;
};

function mapMinistry(id: string, data: Record<string, unknown>): MinistryDoc {
  return {
    id,
    name: (data.name as string) || "",
    description: (data.description as string) || "",
    imageUrl: (data.imageUrl as string) || "",
    memberIds: refsToIds(data.members as unknown[]),
    adminIds: refsToIds(data.ministrieAdmin as unknown[]),
    pendingRequests: (data.pendingRequests as Record<string, unknown>) || {},
    rejectedRequests: (data.rejectedRequests as Record<string, unknown>) || {},
    createdBy: data.createdBy ? refId(data.createdBy) : undefined,
  };
}

export async function listMinistries(): Promise<MinistryDoc[]> {
  const snap = await getDocs(col("ministries"));
  return snap.docs
    .map((d) => mapMinistry(d.id, d.data() as Record<string, unknown>))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export async function getMinistry(id: string): Promise<MinistryDoc | null> {
  const snap = await getDoc(doc(col("ministries"), id));
  if (!snap.exists()) return null;
  return mapMinistry(snap.id, snap.data() as Record<string, unknown>);
}

export async function createMinistry(input: {
  name: string;
  description: string;
  adminIds?: string[];
}) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Unauthenticated");
  const creator = userRef(uid);
  const adminRefs = [
    creator,
    ...(input.adminIds || [])
      .filter((id) => id !== uid)
      .map((id) => userRef(id)),
  ];
  const ref = await addDoc(col("ministries"), {
    name: input.name.trim(),
    description: input.description.trim(),
    imageUrl: "",
    createdAt: serverTimestamp(),
    createdBy: creator,
    members: adminRefs,
    ministrieAdmin: adminRefs,
  });
  return ref.id;
}

export async function deleteMinistry(id: string) {
  await deleteDoc(doc(col("ministries"), id));
}

export async function updateMinistry(
  id: string,
  data: Partial<{ name: string; description: string; imageUrl: string }>
) {
  await updateDoc(doc(col("ministries"), id), data);
}

export async function addMinistryMember(
  ministryId: string,
  userId: string,
  asAdmin = false
) {
  const ministry = await getMinistry(ministryId);
  if (!ministry) throw new Error("Ministry not found");
  if (ministry.memberIds.includes(userId)) throw new Error("Already member");

  const updates: Record<string, unknown> = {
    members: arrayUnion(userRef(userId)),
    [`pendingRequests.${userId}`]: deleteField(),
  };
  if (asAdmin) updates.ministrieAdmin = arrayUnion(userRef(userId));
  await updateDoc(doc(col("ministries"), ministryId), updates);

  const pending = await findPendingRequest(userId, ministryId, "ministry");
  if (pending) await markRequest(pending.id, "accepted");

  await addDoc(col("membership_logs"), {
    userId: userRef(userId),
    entityType: "ministry",
    entityId: ministryId,
    action: "join",
    role: asAdmin ? "admin" : "member",
    initiatedBy: "admin",
    actorId: auth.currentUser?.uid ?? "system",
    createdAt: serverTimestamp(),
  });
}

export async function inviteMinistryMember(ministryId: string, userId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Unauthenticated");
  const ministry = await getMinistry(ministryId);
  if (!ministry) throw new Error("Ministry not found");
  if (ministry.memberIds.includes(userId)) throw new Error("Already member");
  if (ministry.pendingRequests[userId]) throw new Error("Already pending");

  await updateDoc(doc(col("ministries"), ministryId), {
    [`pendingRequests.${userId}`]: Timestamp.now(),
  });

  const invitedByName = await getInviterName(uid);
  await logMembershipRequest({
    userId,
    entityId: ministryId,
    entityType: "ministry",
    entityName: ministry.name,
    requestType: "invite",
    invitedBy: uid,
    invitedByName,
  });
}

export async function removeMinistryMember(ministryId: string, userId: string) {
  const ministry = await getMinistry(ministryId);
  await updateDoc(doc(col("ministries"), ministryId), {
    members: arrayRemove(userRef(userId)),
  });
  if (ministry?.adminIds.includes(userId)) {
    await updateDoc(doc(col("ministries"), ministryId), {
      ministrieAdmin: arrayRemove(userRef(userId)),
    });
  }
  await addDoc(col("membership_logs"), {
    userId: userRef(userId),
    entityType: "ministry",
    entityId: ministryId,
    action: "leave",
    initiatedBy: "admin",
    actorId: auth.currentUser?.uid ?? "system",
    createdAt: serverTimestamp(),
  });
}

export async function promoteMinistryAdmin(ministryId: string, userId: string) {
  await updateDoc(doc(col("ministries"), ministryId), {
    ministrieAdmin: arrayUnion(userRef(userId)),
  });
}

export async function demoteMinistryAdmin(ministryId: string, userId: string) {
  await updateDoc(doc(col("ministries"), ministryId), {
    ministrieAdmin: arrayRemove(userRef(userId)),
  });
}

export async function approveMinistryRequest(
  ministryId: string,
  userId: string
) {
  await addMinistryMember(ministryId, userId);
}

export async function rejectMinistryRequest(
  ministryId: string,
  userId: string
) {
  const pending = await findPendingRequest(userId, ministryId, "ministry");
  if (pending) await markRequest(pending.id, "rejected");
  await updateDoc(doc(col("ministries"), ministryId), {
    [`pendingRequests.${userId}`]: deleteField(),
    [`rejectedRequests.${userId}`]: {
      rejectedAt: serverTimestamp(),
      rejectedBy: auth.currentUser?.uid,
    },
  });
}
