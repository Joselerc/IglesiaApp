import {
  addDoc,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  updateDoc,
} from "firebase/firestore";
import { col } from "@/lib/utils";

export type Role = {
  id: string;
  name: string;
  description?: string | null;
  permissions: string[];
};

export async function listRoles(): Promise<Role[]> {
  const snap = await getDocs(query(col("roles"), orderBy("name")));
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      name: data.name ?? "",
      description: data.description ?? null,
      permissions: Array.isArray(data.permissions) ? data.permissions.map(String) : [],
    };
  });
}

export async function getRole(id: string): Promise<Role | null> {
  const snap = await getDoc(doc(col("roles"), id));
  if (!snap.exists()) return null;
  const data = snap.data();
  return {
    id: snap.id,
    name: data.name ?? "",
    description: data.description ?? null,
    permissions: Array.isArray(data.permissions) ? data.permissions.map(String) : [],
  };
}

export async function createRole(input: Omit<Role, "id">) {
  const ref = await addDoc(col("roles"), {
    name: input.name,
    description: input.description ?? null,
    permissions: input.permissions,
  });
  return ref.id;
}

export async function updateRole(role: Role) {
  await updateDoc(doc(col("roles"), role.id), {
    name: role.name,
    description: role.description ?? null,
    permissions: role.permissions,
  });
}

export async function deleteRole(id: string) {
  await deleteDoc(doc(col("roles"), id));
}
