export const PERMISSION_CATEGORIES: Record<string, string[]> = {
  general: [
    "manage_roles",
    "assign_user_roles",
    "manage_users",
    "view_user_list",
    "view_user_details",
    "send_push_notifications",
  ],
  home: [
    "manage_home_sections",
    "manage_pages",
    "manage_donations_config",
    "manage_livestream_config",
  ],
  content: [
    "manage_announcements",
    "manage_videos",
    "manage_cults",
    "manage_event_tickets",
    "manage_event_attendance",
    "create_events",
    "delete_events",
    "manage_courses",
  ],
  groups: ["create_group", "delete_group"],
  ministries: ["create_ministry", "delete_ministry"],
  counseling: [
    "manage_counseling_availability",
    "manage_counseling_requests",
    "manage_private_prayers",
    "assign_cult_to_prayer",
  ],
  reports: [
    "view_ministry_stats",
    "view_group_stats",
    "view_schedule_stats",
    "view_course_stats",
    "view_church_statistics",
    "view_cult_stats",
    "view_work_stats",
  ],
  mykids: ["manage_family_profiles", "manage_checkin_rooms"],
  families: ["manage_families_admin"],
  other: ["manage_profile_fields", "manage_church_locations"],
};

export const ALL_PERMISSIONS = Object.values(PERMISSION_CATEGORIES).flat();

export const ADMIN_NAV: {
  href: string;
  permission: string | string[];
  labelKey: string;
  section: string;
}[] = [
  { href: "/donations", permission: "manage_donations_config", labelKey: "nav.donations", section: "config" },
  { href: "/locations", permission: "manage_church_locations", labelKey: "nav.locations", section: "config" },
  { href: "/livestream", permission: "manage_livestream_config", labelKey: "nav.livestream", section: "config" },
  { href: "/courses", permission: "manage_courses", labelKey: "nav.courses", section: "content" },
  { href: "/home-sections", permission: "manage_home_sections", labelKey: "nav.homeSections", section: "config" },
  { href: "/families", permission: "manage_families_admin", labelKey: "nav.families", section: "community" },
  { href: "/pages", permission: "manage_pages", labelKey: "nav.pages", section: "content" },
  { href: "/counseling/availability", permission: "manage_counseling_availability", labelKey: "nav.counselingAvailability", section: "pastoral" },
  { href: "/profile-fields", permission: "manage_profile_fields", labelKey: "nav.profileFields", section: "config" },
  { href: "/users/roles", permission: "assign_user_roles", labelKey: "nav.assignRoles", section: "users" },
  { href: "/roles", permission: "manage_roles", labelKey: "nav.roles", section: "users" },
  { href: "/announcements", permission: "manage_announcements", labelKey: "nav.announcements", section: "content" },
  { href: "/events", permission: "create_events", labelKey: "nav.events", section: "content" },
  { href: "/videos", permission: "manage_videos", labelKey: "nav.videos", section: "content" },
  { href: "/cults", permission: "manage_cults", labelKey: "nav.cults", section: "schedules" },
  { href: "/work-invites", permission: "manage_cults", labelKey: "nav.workInvites", section: "schedules" },
  { href: "/ministries", permission: ["create_ministry", "delete_ministry"], labelKey: "nav.ministries", section: "community" },
  { href: "/groups", permission: ["create_group", "delete_group"], labelKey: "nav.groups", section: "community" },
  { href: "/counseling/requests", permission: "manage_counseling_requests", labelKey: "nav.counselingRequests", section: "pastoral" },
  { href: "/prayers", permission: "manage_private_prayers", labelKey: "nav.prayers", section: "pastoral" },
  { href: "/push", permission: "send_push_notifications", labelKey: "nav.push", section: "users" },
  { href: "/events/attendance", permission: "manage_event_attendance", labelKey: "nav.eventAttendance", section: "reports" },
  { href: "/stats/ministries", permission: "view_ministry_stats", labelKey: "nav.ministryStats", section: "reports" },
  { href: "/stats/groups", permission: "view_group_stats", labelKey: "nav.groupStats", section: "reports" },
  { href: "/stats/schedules", permission: "view_schedule_stats", labelKey: "nav.scheduleStats", section: "reports" },
  { href: "/stats/courses", permission: "view_course_stats", labelKey: "nav.courseStats", section: "reports" },
  { href: "/users", permission: "view_user_details", labelKey: "nav.userInfo", section: "users" },
  { href: "/stats/church", permission: "view_church_statistics", labelKey: "nav.churchStats", section: "reports" },
  { href: "/mykids/families", permission: "manage_family_profiles", labelKey: "nav.mykidsFamilies", section: "mykids" },
  { href: "/mykids/rooms", permission: "manage_checkin_rooms", labelKey: "nav.mykidsRooms", section: "mykids" },
];

export function hasPermission(
  isSuperUser: boolean,
  permissions: string[],
  key: string | string[]
): boolean {
  if (isSuperUser) return true;
  const keys = Array.isArray(key) ? key : [key];
  return keys.some((k) => permissions.includes(k));
}

export function hasAnyAdminAccess(isSuperUser: boolean, permissions: string[]): boolean {
  if (isSuperUser) return true;
  if (permissions.length > 0) return true;
  return false;
}
