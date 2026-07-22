"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  User,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
} from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { hasPermission, hasAnyAdminAccess } from "@/lib/permissions";

export type AppUser = {
  uid: string;
  email: string | null;
  displayName: string | null;
  isSuperUser: boolean;
  roleId: string | null;
  permissions: string[];
  roleName: string | null;
};

type AuthContextValue = {
  firebaseUser: User | null;
  appUser: AppUser | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<AppUser>;
  signOut: () => Promise<void>;
  can: (key: string | string[]) => boolean;
  hasAdminAccess: boolean;
  refresh: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function loadAppUser(user: User): Promise<AppUser> {
  const userSnap = await getDoc(doc(db, "users", user.uid));
  const data = userSnap.data() ?? {};
  const isSuperUser = data.isSuperUser === true;
  const roleId = (data.roleId as string | undefined) ?? null;
  let permissions: string[] = [];
  let roleName: string | null = null;

  if (roleId) {
    const roleSnap = await getDoc(doc(db, "roles", roleId));
    if (roleSnap.exists()) {
      const role = roleSnap.data();
      permissions = Array.isArray(role.permissions)
        ? role.permissions.map(String)
        : [];
      roleName = (role.name as string) ?? null;
    }
  }

  return {
    uid: user.uid,
    email: user.email,
    displayName:
      (data.displayName as string) ||
      (data.name as string) ||
      user.displayName ||
      user.email,
    isSuperUser,
    roleId,
    permissions,
    roleName,
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [firebaseUser, setFirebaseUser] = useState<User | null>(null);
  const [appUser, setAppUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const u = auth.currentUser;
    if (!u) {
      setAppUser(null);
      return;
    }
    setAppUser(await loadAppUser(u));
  }, []);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setFirebaseUser(null);
        setAppUser(null);
        setLoading(false);
        return;
      }
      setLoading(true);
      setFirebaseUser(user);
      try {
        setAppUser(await loadAppUser(user));
      } catch (e) {
        console.error(e);
        setAppUser(null);
      } finally {
        setLoading(false);
      }
    });
    return () => unsub();
  }, []);

  const signIn = async (email: string, password: string) => {
    setLoading(true);
    try {
      const cred = await signInWithEmailAndPassword(auth, email, password);
      setFirebaseUser(cred.user);
      const profile = await loadAppUser(cred.user);
      setAppUser(profile);
      return profile;
    } catch (e) {
      setLoading(false);
      throw e;
    } finally {
      setLoading(false);
    }
  };

  const signOut = async () => {
    await firebaseSignOut(auth);
    setFirebaseUser(null);
    setAppUser(null);
  };

  const can = useCallback(
    (key: string | string[]) => {
      if (!appUser) return false;
      return hasPermission(appUser.isSuperUser, appUser.permissions, key);
    },
    [appUser]
  );

  const hasAdminAccess = useMemo(() => {
    if (!appUser) return false;
    return hasAnyAdminAccess(appUser.isSuperUser, appUser.permissions);
  }, [appUser]);

  const value = useMemo(
    () => ({
      firebaseUser,
      appUser,
      loading,
      signIn,
      signOut,
      can,
      hasAdminAccess,
      refresh,
    }),
    [firebaseUser, appUser, loading, can, hasAdminAccess, refresh]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
