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

export type GroupDoc = {
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

function mapGroup(id: string, data: Record<string, unknown>): GroupDoc {
  return {
    id,
    name: (data.name as string) || "",
    description: (data.description as string) || "",
    imageUrl: (data.imageUrl as string) || "",
    memberIds: refsToIds(data.members as unknown[]),
    adminIds: refsToIds(data.groupAdmin as unknown[]),
    pendingRequests: (data.pendingRequests as Record<string, unknown>) || {},
    rejectedRequests: (data.rejectedRequests as Record<string, unknown>) || {},
    createdBy: data.createdBy ? refId(data.createdBy) : undefined,
  };
}

export async function listGroups(): Promise<GroupDoc[]> {
  const snap = await getDocs(col("groups"));
  return snap.docs
    .map((d) => mapGroup(d.id, d.data() as Record<string, unknown>))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export async function getGroup(id: string): Promise<GroupDoc | null> {
  const snap = await getDoc(doc(col("groups"), id));
  if (!snap.exists()) return null;
  return mapGroup(snap.id, snap.data() as Record<string, unknown>);
}

export async function createGroup(input: {
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
  const ref = await addDoc(col("groups"), {
    name: input.name.trim(),
    description: input.description.trim(),
    imageUrl: "",
    createdAt: serverTimestamp(),
    createdBy: creator,
    members: adminRefs,
    groupAdmin: adminRefs,
  });
  return ref.id;
}

export async function deleteGroup(id: string) {
  await deleteDoc(doc(col("groups"), id));
}

export async function updateGroup(
  id: string,
  data: Partial<{ name: string; description: string; imageUrl: string }>
) {
  await updateDoc(doc(col("groups"), id), data);
}

export async function addMember(
  groupId: string,
  userId: string,
  asAdmin = false
) {
  const group = await getGroup(groupId);
  if (!group) throw new Error("Group not found");
  if (group.memberIds.includes(userId)) throw new Error("Already member");

  const updates: Record<string, unknown> = {
    members: arrayUnion(userRef(userId)),
    [`pendingRequests.${userId}`]: deleteField(),
  };
  if (asAdmin) updates.groupAdmin = arrayUnion(userRef(userId));
  await updateDoc(doc(col("groups"), groupId), updates);

  const pending = await findPendingRequest(userId, groupId, "group");
  if (pending) await markRequest(pending.id, "accepted");

  await addDoc(col("membership_logs"), {
    userId: userRef(userId),
    entityType: "group",
    entityId: groupId,
    action: "join",
    role: asAdmin ? "admin" : "member",
    initiatedBy: "admin",
    actorId: auth.currentUser?.uid ?? "system",
    createdAt: serverTimestamp(),
  });
}

/** Invita sin añadir: pendingRequests + membership_requests (requestType: invite) */
export async function inviteMember(groupId: string, userId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Unauthenticated");
  const group = await getGroup(groupId);
  if (!group) throw new Error("Group not found");
  if (group.memberIds.includes(userId)) throw new Error("Already member");
  if (group.pendingRequests[userId]) throw new Error("Already pending");

  await updateDoc(doc(col("groups"), groupId), {
    [`pendingRequests.${userId}`]: Timestamp.now(),
  });

  const invitedByName = await getInviterName(uid);
  await logMembershipRequest({
    userId,
    entityId: groupId,
    entityType: "group",
    entityName: group.name,
    requestType: "invite",
    invitedBy: uid,
    invitedByName,
  });
}

export async function removeMember(groupId: string, userId: string) {
  const group = await getGroup(groupId);
  await updateDoc(doc(col("groups"), groupId), {
    members: arrayRemove(userRef(userId)),
  });
  if (group?.adminIds.includes(userId)) {
    await updateDoc(doc(col("groups"), groupId), {
      groupAdmin: arrayRemove(userRef(userId)),
    });
  }
  await addDoc(col("membership_logs"), {
    userId: userRef(userId),
    entityType: "group",
    entityId: groupId,
    action: "leave",
    initiatedBy: "admin",
    actorId: auth.currentUser?.uid ?? "system",
    createdAt: serverTimestamp(),
  });
}

export async function promoteAdmin(groupId: string, userId: string) {
  await updateDoc(doc(col("groups"), groupId), {
    groupAdmin: arrayUnion(userRef(userId)),
  });
}

export async function demoteAdmin(groupId: string, userId: string) {
  await updateDoc(doc(col("groups"), groupId), {
    groupAdmin: arrayRemove(userRef(userId)),
  });
}

export async function approveRequest(groupId: string, userId: string) {
  await addMember(groupId, userId);
}

export async function rejectRequest(groupId: string, userId: string) {
  const pending = await findPendingRequest(userId, groupId, "group");
  if (pending) await markRequest(pending.id, "rejected");
  await updateDoc(doc(col("groups"), groupId), {
    [`pendingRequests.${userId}`]: deleteField(),
    [`rejectedRequests.${userId}`]: {
      rejectedAt: serverTimestamp(),
      rejectedBy: auth.currentUser?.uid,
    },
  });
}
