import {
  addDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  updateDoc,
  where,
} from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { col } from "@/lib/utils";

export type MembershipRequest = {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  userPhotoUrl?: string;
  entityId: string;
  entityType: "group" | "ministry";
  entityName: string;
  status: string;
  requestType: "join" | "invite" | string;
  invitedBy?: string;
  invitedByName?: string;
  message?: string;
};

export async function logMembershipRequest(input: {
  userId: string;
  entityId: string;
  entityType: "group" | "ministry";
  entityName: string;
  requestType?: "join" | "invite";
  message?: string;
  invitedBy?: string;
  invitedByName?: string;
}) {
  const userSnap = await getDoc(doc(db, "users", input.userId));
  const userData = userSnap.data() ?? {};
  await addDoc(col("membership_requests"), {
    userId: input.userId,
    entityId: input.entityId,
    entityType: input.entityType,
    entityName: input.entityName,
    status: "pending",
    requestTimestamp: serverTimestamp(),
    message: input.message ?? null,
    requestType: input.requestType ?? "join",
    invitedBy: input.invitedBy ?? null,
    invitedByName: input.invitedByName ?? null,
    userName: userData.name || userData.displayName || "Usuario",
    userEmail: userData.email || "",
    userPhotoUrl: userData.photoUrl || userData.photoURL || "",
  });
}

export async function findPendingRequest(
  userId: string,
  entityId: string,
  entityType: "group" | "ministry"
) {
  const snap = await getDocs(
    query(
      col("membership_requests"),
      where("userId", "==", userId),
      where("entityId", "==", entityId),
      where("entityType", "==", entityType),
      where("status", "==", "pending")
    )
  );
  return snap.docs[0] ?? null;
}

export async function listPendingRequests(
  entityId: string,
  entityType: "group" | "ministry"
): Promise<MembershipRequest[]> {
  const snap = await getDocs(
    query(
      col("membership_requests"),
      where("entityId", "==", entityId),
      where("entityType", "==", entityType),
      where("status", "==", "pending")
    )
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: String(data.userId || ""),
      userName: String(data.userName || ""),
      userEmail: String(data.userEmail || ""),
      userPhotoUrl: data.userPhotoUrl ? String(data.userPhotoUrl) : undefined,
      entityId: String(data.entityId || ""),
      entityType: data.entityType as "group" | "ministry",
      entityName: String(data.entityName || ""),
      status: String(data.status || "pending"),
      requestType: String(data.requestType || "join"),
      invitedBy: data.invitedBy ? String(data.invitedBy) : undefined,
      invitedByName: data.invitedByName
        ? String(data.invitedByName)
        : undefined,
      message: data.message ? String(data.message) : undefined,
    };
  });
}

export async function markRequest(
  requestId: string,
  status: "accepted" | "rejected"
) {
  await updateDoc(doc(col("membership_requests"), requestId), {
    status,
    responseTimestamp: serverTimestamp(),
    respondedBy: auth.currentUser?.uid ?? "system",
  });
}

export async function getInviterName(uid: string) {
  const snap = await getDoc(doc(db, "users", uid));
  const data = snap.data() ?? {};
  return String(data.name || data.displayName || "Administrador");
}
