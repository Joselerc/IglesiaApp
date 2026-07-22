import {
  Timestamp,
  addDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  deleteDoc,
  where,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { auth, db, functions } from "@/lib/firebase";
import { col, refId, userRef } from "@/lib/utils";

export async function getDonationsSettings() {
  const snap = await getDoc(doc(db, "donationsPage", "settings"));
  return snap.exists()
    ? ({ id: snap.id, ...snap.data() } as Record<string, unknown> & { id: string })
    : null;
}

export async function saveDonationsSettings(data: Record<string, unknown>) {
  await setDoc(
    doc(db, "donationsPage", "settings"),
    { ...data, updatedAt: serverTimestamp() },
    { merge: true }
  );
}

export async function listChurchLocations() {
  const snap = await getDocs(col("churchLocations"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function saveChurchLocation(
  id: string | null,
  data: Record<string, unknown>
) {
  if (id) {
    await updateDoc(doc(col("churchLocations"), id), {
      ...data,
      updatedAt: serverTimestamp(),
    });
    return id;
  }
  const ref = await addDoc(col("churchLocations"), {
    ...data,
    country: data.country || "Brasil",
    isDefault: false,
    createdAt: serverTimestamp(),
    createdBy: auth.currentUser?.uid,
  });
  return ref.id;
}

export async function deleteChurchLocation(id: string) {
  await deleteDoc(doc(col("churchLocations"), id));
}

export async function getLivestreamConfig() {
  const snap = await getDoc(doc(db, "app_config", "live_stream"));
  return snap.exists() ? (snap.data() as Record<string, unknown>) : null;
}

export async function saveLivestreamConfig(data: Record<string, unknown>) {
  await setDoc(
    doc(db, "app_config", "live_stream"),
    { ...data, updatedAt: serverTimestamp() },
    { merge: true }
  );
}

export async function listCourses() {
  const snap = await getDocs(col("courses"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function saveCourse(id: string | null, data: Record<string, unknown>) {
  if (id) {
    await updateDoc(doc(col("courses"), id), {
      ...data,
      updatedAt: serverTimestamp(),
    });
    return id;
  }
  const ref = await addDoc(col("courses"), {
    ...data,
    enrolledUsers: [],
    totalModules: 0,
    totalLessons: 0,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return ref.id;
}

export async function deleteCourse(id: string) {
  await deleteDoc(doc(col("courses"), id));
}

export async function listHomeSections() {
  const snap = await getDocs(query(col("homeScreenSections"), orderBy("order")));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function updateHomeSection(id: string, data: Record<string, unknown>) {
  await updateDoc(doc(col("homeScreenSections"), id), data);
}

export async function listPages() {
  const snap = await getDocs(col("pageContent"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function savePage(id: string | null, data: Record<string, unknown>) {
  if (id) {
    await updateDoc(doc(col("pageContent"), id), {
      ...data,
      lastUpdatedAt: serverTimestamp(),
    });
    return id;
  }
  const ref = await addDoc(col("pageContent"), {
    ...data,
    elements: data.elements ?? [],
    lastUpdatedAt: serverTimestamp(),
  });
  return ref.id;
}

export async function deletePage(id: string) {
  await deleteDoc(doc(col("pageContent"), id));
}

export async function listProfileFields() {
  const snap = await getDocs(query(col("profileFields"), orderBy("order")));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function saveProfileField(
  id: string | null,
  data: Record<string, unknown>
) {
  if (id) {
    await updateDoc(doc(col("profileFields"), id), data);
    return id;
  }
  const ref = await addDoc(col("profileFields"), {
    ...data,
    createdAt: serverTimestamp(),
    createdBy: auth.currentUser?.uid,
  });
  return ref.id;
}

export async function deleteProfileField(id: string) {
  await deleteDoc(doc(col("profileFields"), id));
}

export async function listAnnouncements() {
  const snap = await getDocs(col("announcements"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function createAnnouncement(data: {
  title: string;
  description: string;
  imageUrl?: string;
}) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Unauthenticated");
  const now = Timestamp.now();
  const ref = await addDoc(col("announcements"), {
    title: data.title,
    description: data.description,
    imageUrl: data.imageUrl || "",
    date: now,
    startDate: now,
    createdAt: serverTimestamp(),
    createdBy: userRef(uid),
    isActive: true,
    type: "regular",
  });
  return ref.id;
}

export async function updateAnnouncement(id: string, data: Record<string, unknown>) {
  await updateDoc(doc(col("announcements"), id), data);
}

export async function deleteAnnouncement(id: string) {
  await deleteDoc(doc(col("announcements"), id));
}

export async function listEvents() {
  const snap = await getDocs(col("events"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function saveEvent(id: string | null, data: Record<string, unknown>) {
  const uid = auth.currentUser?.uid;
  if (id) {
    await updateDoc(doc(col("events"), id), data);
    return id;
  }
  const ref = await addDoc(col("events"), {
    ...data,
    isActive: true,
    createdAt: serverTimestamp(),
    createdBy: uid ? userRef(uid) : null,
  });
  return ref.id;
}

export async function deleteEvent(id: string) {
  await deleteDoc(doc(col("events"), id));
}

export async function listVideoSections() {
  const snap = await getDocs(query(col("videoSections"), orderBy("order")));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function saveVideoSection(
  id: string | null,
  data: Record<string, unknown>
) {
  if (id) {
    await updateDoc(doc(col("videoSections"), id), data);
    return id;
  }
  const ref = await addDoc(col("videoSections"), {
    ...data,
    videoIds: data.videoIds ?? [],
  });
  return ref.id;
}

export async function listVideos() {
  const snap = await getDocs(col("videos"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function createVideo(data: Record<string, unknown>) {
  const ref = await addDoc(col("videos"), {
    ...data,
    likes: 0,
    likedByUsers: [],
    createdAt: serverTimestamp(),
    uploadDate: serverTimestamp(),
    createdBy: auth.currentUser?.uid,
  });
  return ref.id;
}

export async function listFamilyGroups() {
  const snap = await getDocs(col("family_groups"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function getPastorAvailability(pastorId: string) {
  const snap = await getDoc(doc(db, "pastor_availability", pastorId));
  return snap.exists()
    ? ({ id: snap.id, ...snap.data() } as Record<string, unknown> & { id: string })
    : null;
}

export async function savePastorAvailability(
  pastorId: string,
  data: Record<string, unknown>
) {
  await setDoc(
    doc(db, "pastor_availability", pastorId),
    {
      ...data,
      userId: userRef(pastorId),
      updatedAt: serverTimestamp(),
    },
    { merge: true }
  );
}

export async function listCounselingAppointments() {
  const snap = await getDocs(col("counseling_appointments"));
  return snap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
    userId: refId(d.data().userId),
    pastorId: refId(d.data().pastorId),
  }));
}

export async function updateCounselingStatus(id: string, status: string) {
  await updateDoc(doc(col("counseling_appointments"), id), {
    status,
    updatedAt: serverTimestamp(),
  });
}

export async function listPrivatePrayers() {
  const snap = await getDocs(col("private_prayers"));
  return snap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
    userId: refId(d.data().userId),
  }));
}

export async function acceptPrivatePrayer(id: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Unauthenticated");
  await updateDoc(doc(col("private_prayers"), id), {
    isAccepted: true,
    acceptedBy: userRef(uid),
  });
}

export async function respondPrivatePrayer(id: string, response: string) {
  await updateDoc(doc(col("private_prayers"), id), {
    pastorResponse: response,
    respondedAt: serverTimestamp(),
  });
}

export async function sendPushNotification(input: {
  userIds: string[];
  title: string;
  body: string;
  imageUrl?: string;
}) {
  const callable = httpsCallable(functions, "sendPushNotifications");
  return callable({
    userIds: input.userIds,
    notification: {
      title: input.title,
      body: input.body,
      imageUrl: input.imageUrl,
    },
    data: {
      type: "custom_push",
      sender: auth.currentUser?.uid ?? "",
    },
  });
}

export async function listMyKidsFamilies() {
  const snap = await getDocs(col("families"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function saveMyKidsFamily(
  id: string | null,
  data: Record<string, unknown>
) {
  if (id) {
    await updateDoc(doc(col("families"), id), {
      ...data,
      updatedAt: serverTimestamp(),
    });
    return id;
  }
  const ref = await addDoc(col("families"), {
    ...data,
    childIds: data.childIds ?? [],
    guardianUserIds: data.guardianUserIds ?? [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return ref.id;
}

export async function listScheduledRooms() {
  const snap = await getDocs(col("scheduledRooms"));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function saveScheduledRoom(
  id: string | null,
  data: Record<string, unknown>
) {
  if (id) {
    await updateDoc(doc(col("scheduledRooms"), id), {
      ...data,
      updatedAt: serverTimestamp(),
    });
    return id;
  }
  const ref = await addDoc(col("scheduledRooms"), {
    ...data,
    isOpen: data.isOpen ?? true,
    checkedInChildIds: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return ref.id;
}

export async function deleteScheduledRoom(id: string) {
  await deleteDoc(doc(col("scheduledRooms"), id));
}

export async function churchStatsSummary() {
  const [users, groups, ministries, cults, events] = await Promise.all([
    getDocs(col("users")),
    getDocs(col("groups")),
    getDocs(col("ministries")),
    getDocs(col("cults")),
    getDocs(col("events")),
  ]);
  return {
    users: users.size,
    groups: groups.size,
    ministries: ministries.size,
    cults: cults.size,
    events: events.size,
  };
}

export async function entityMemberStats(collectionName: "groups" | "ministries") {
  const snap = await getDocs(col(collectionName));
  return snap.docs.map((d) => {
    const data = d.data();
    const members = Array.isArray(data.members) ? data.members.length : 0;
    return { id: d.id, name: data.name ?? d.id, members };
  });
}

export async function scheduleStatsSummary() {
  const [assignments, invites] = await Promise.all([
    getDocs(query(col("work_assignments"), where("isActive", "==", true))),
    getDocs(col("work_invites")),
  ]);
  let pending = 0;
  let accepted = 0;
  let rejected = 0;
  for (const d of assignments.docs) {
    const s = d.data().status;
    if (s === "accepted") accepted++;
    else if (s === "rejected") rejected++;
    else pending++;
  }
  return {
    assignments: assignments.size,
    invites: invites.size,
    pending,
    accepted,
    rejected,
  };
}

export async function courseStatsSummary() {
  const courses = await getDocs(col("courses"));
  return courses.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      title: data.title ?? d.id,
      enrolled: Array.isArray(data.enrolledUsers) ? data.enrolledUsers.length : 0,
      status: data.status ?? "draft",
    };
  });
}

export async function listMinistryGroupEvents() {
  const [m, g] = await Promise.all([
    getDocs(col("ministry_events")),
    getDocs(col("group_events")),
  ]);
  return [
    ...m.docs.map((d) => ({
      id: d.id,
      source: "ministry" as const,
      title: d.data().title,
      attendees: Array.isArray(d.data().attendees) ? d.data().attendees.length : 0,
      date: d.data().date,
    })),
    ...g.docs.map((d) => ({
      id: d.id,
      source: "group" as const,
      title: d.data().title,
      attendees: Array.isArray(d.data().attendees) ? d.data().attendees.length : 0,
      date: d.data().date,
    })),
  ];
}
