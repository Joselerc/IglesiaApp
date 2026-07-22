import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  updateDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { refId } from "@/lib/utils";

export type AppUserDoc = {
  id: string;
  name: string;
  email: string;
  roleId: string | null;
  isSuperUser: boolean;
  phone?: string;
  photoUrl?: string;
};

function mapUser(id: string, data: Record<string, unknown>): AppUserDoc {
  return {
    id,
    name:
      (data.displayName as string) ||
      (data.name as string) ||
      (data.email as string) ||
      id,
    email: (data.email as string) || "",
    roleId: (data.roleId as string) || null,
    isSuperUser: data.isSuperUser === true,
    phone: (data.phone as string) || (data.phoneNumber as string) || undefined,
    photoUrl: (data.photoUrl as string) || (data.photoURL as string) || undefined,
  };
}

export async function listUsers(max = 500): Promise<AppUserDoc[]> {
  const snap = await getDocs(query(collection(db, "users"), limit(max)));
  return snap.docs
    .map((d) => mapUser(d.id, d.data() as Record<string, unknown>))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export async function searchUsersByName(term: string): Promise<AppUserDoc[]> {
  const all = await listUsers(800);
  const t = term.trim().toLowerCase();
  if (!t) return all.slice(0, 50);
  return all
    .filter(
      (u) =>
        u.name.toLowerCase().includes(t) ||
        u.email.toLowerCase().includes(t) ||
        u.id.includes(t)
    )
    .slice(0, 50);
}

export async function getUser(id: string): Promise<AppUserDoc | null> {
  const snap = await getDoc(doc(db, "users", id));
  if (!snap.exists()) return null;
  return mapUser(snap.id, snap.data() as Record<string, unknown>);
}

export async function assignUserRole(userId: string, roleId: string | null) {
  await updateDoc(doc(db, "users", userId), { roleId: roleId || null });
}

export async function getUsersByIds(ids: string[]): Promise<AppUserDoc[]> {
  const unique = [...new Set(ids.filter(Boolean))];
  const results = await Promise.all(unique.map((id) => getUser(id)));
  return results.filter(Boolean) as AppUserDoc[];
}

export async function listUsersInMinistry(ministryId: string) {
  const snap = await getDoc(doc(db, "ministries", ministryId));
  if (!snap.exists()) return [];
  const members = (snap.data().members as unknown[]) || [];
  return getUsersByIds(members.map(refId));
}
