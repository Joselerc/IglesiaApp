import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import {
  DocumentReference,
  Timestamp,
  collection,
  doc,
} from "firebase/firestore";
import { db } from "./firebase";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function userRef(uid: string): DocumentReference {
  return doc(db, "users", uid);
}

export function refId(value: unknown): string {
  if (!value) return "";
  if (typeof value === "string") {
    const parts = value.split("/");
    return parts[parts.length - 1] || value;
  }
  if (typeof value === "object" && value !== null && "id" in value) {
    return String((value as { id: string }).id);
  }
  return String(value);
}

export function refsToIds(values: unknown[] | undefined): string[] {
  if (!values) return [];
  return values.map(refId).filter(Boolean);
}

export function toDate(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string" || typeof value === "number") {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  if (typeof value === "object" && value !== null && "seconds" in value) {
    return new Date((value as { seconds: number }).seconds * 1000);
  }
  return null;
}

export function formatDateTime(value: unknown, locale = "pt-BR"): string {
  const d = toDate(value);
  if (!d) return "—";
  return d.toLocaleString(locale, {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDate(value: unknown, locale = "pt-BR"): string {
  const d = toDate(value);
  if (!d) return "—";
  return d.toLocaleDateString(locale, {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}

export function col(name: string) {
  return collection(db, name);
}
