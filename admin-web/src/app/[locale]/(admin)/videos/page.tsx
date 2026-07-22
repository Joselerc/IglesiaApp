"use client";

import { FormEvent, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { createVideo, listVideoSections, listVideos, saveVideoSection } from "@/lib/services/content";
import { Button, Card, EmptyState, Input, PageHeader, Table, TextArea } from "@/components/ui";
import { useAuth } from "@/components/AuthProvider";

export default function VideosPage() {
  const t = useTranslations();
  const { can } = useAuth();
  const [sections, setSections] = useState<Record<string, unknown>[]>([]);
  const [videos, setVideos] = useState<Record<string, unknown>[]>([]);
  const [sectionTitle, setSectionTitle] = useState("");
  const [videoForm, setVideoForm] = useState({ title: "", description: "", youtubeUrl: "", thumbnailUrl: "" });

  async function load() {
    setSections(await listVideoSections());
    setVideos(await listVideos());
  }
  useEffect(() => {
    load();
  }, []);

  if (!can("manage_videos")) return <EmptyState message={t("auth.noAccess")} />;

  async function onSection(e: FormEvent) {
    e.preventDefault();
    await saveVideoSection(null, { title: sectionTitle, type: "custom", order: sections.length });
    setSectionTitle("");
    load();
  }

  async function onVideo(e: FormEvent) {
    e.preventDefault();
    await createVideo(videoForm);
    setVideoForm({ title: "", description: "", youtubeUrl: "", thumbnailUrl: "" });
    load();
  }

  return (
    <div className="space-y-4">
      <PageHeader title={t("nav.videos")} />
      <Card>
        <form onSubmit={onSection} className="flex flex-wrap gap-3">
          <div className="min-w-[220px] flex-1">
            <Input label="Section" required value={sectionTitle} onChange={(e) => setSectionTitle(e.target.value)} />
          </div>
          <div className="flex items-end"><Button type="submit">{t("common.create")}</Button></div>
        </form>
      </Card>
      <Card>
        <form onSubmit={onVideo} className="grid gap-3 md:grid-cols-2">
          <Input label={t("common.title")} required value={videoForm.title} onChange={(e) => setVideoForm({ ...videoForm, title: e.target.value })} />
          <Input label="YouTube URL" value={videoForm.youtubeUrl} onChange={(e) => setVideoForm({ ...videoForm, youtubeUrl: e.target.value })} />
          <Input label={t("common.imageUrl")} value={videoForm.thumbnailUrl} onChange={(e) => setVideoForm({ ...videoForm, thumbnailUrl: e.target.value })} />
          <TextArea label={t("common.description")} value={videoForm.description} onChange={(e) => setVideoForm({ ...videoForm, description: e.target.value })} />
          <Button type="submit">{t("common.add")}</Button>
        </form>
      </Card>
      <Table>
        <thead className="border-b border-[var(--border)] bg-[var(--bg)] text-xs uppercase text-[var(--muted)]">
          <tr>
            <th className="px-4 py-3">{t("common.title")}</th>
            <th className="px-4 py-3">{t("common.url")}</th>
          </tr>
        </thead>
        <tbody>
          {videos.map((v) => (
            <tr key={String(v.id)} className="border-b border-[var(--border)]">
              <td className="px-4 py-3">{String(v.title || "")}</td>
              <td className="px-4 py-3 text-sm text-[var(--muted)]">{String(v.youtubeUrl || "")}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}
