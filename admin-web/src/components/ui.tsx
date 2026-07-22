import { cn } from "@/lib/utils";

export function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
}) {
  return (
    <div className="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div className="min-w-0">
        <h1
          className="text-[1.75rem] font-semibold tracking-tight text-[var(--text)] md:text-[2rem]"
          style={{ fontFamily: "var(--font-display), Georgia, serif" }}
        >
          {title}
        </h1>
        {subtitle && (
          <p className="mt-1.5 max-w-2xl text-sm leading-relaxed text-[var(--muted)]">
            {subtitle}
          </p>
        )}
      </div>
      {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
    </div>
  );
}

export function Card({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-[var(--radius)] border border-[var(--border)] bg-[var(--surface)] p-5 shadow-[var(--shadow)]",
        className
      )}
    >
      {children}
    </div>
  );
}

export function Button({
  children,
  variant = "primary",
  className,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "danger" | "ghost";
}) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center gap-2 rounded-lg px-3.5 py-2 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-50",
        variant === "primary" &&
          "bg-[var(--primary)] text-white hover:bg-[var(--primary-hover)]",
        variant === "secondary" &&
          "border border-[var(--border-strong)] bg-white text-[var(--text)] hover:bg-[var(--surface-2)]",
        variant === "danger" &&
          "border border-red-200 bg-[var(--danger-soft)] text-[var(--danger)] hover:bg-red-100",
        variant === "ghost" &&
          "text-[var(--muted)] hover:bg-[var(--primary-soft)] hover:text-[var(--primary)]",
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
}

export function Input(
  props: React.InputHTMLAttributes<HTMLInputElement> & { label?: string }
) {
  const { label, className, id, ...rest } = props;
  return (
    <label className="block space-y-1.5 text-sm">
      {label && (
        <span className="text-xs font-semibold uppercase tracking-wide text-[var(--muted)]">
          {label}
        </span>
      )}
      <input
        id={id}
        className={cn(
          "w-full rounded-lg border border-[var(--border)] bg-white px-3.5 py-2.5 text-[var(--text)] outline-none transition placeholder:text-[var(--muted)]/70 focus:border-[var(--primary)] focus:ring-4 focus:ring-[var(--primary)]/10",
          className
        )}
        {...rest}
      />
    </label>
  );
}

export function TextArea(
  props: React.TextareaHTMLAttributes<HTMLTextAreaElement> & { label?: string }
) {
  const { label, className, ...rest } = props;
  return (
    <label className="block space-y-1.5 text-sm">
      {label && (
        <span className="text-xs font-semibold uppercase tracking-wide text-[var(--muted)]">
          {label}
        </span>
      )}
      <textarea
        className={cn(
          "w-full rounded-lg border border-[var(--border)] bg-white px-3.5 py-2.5 outline-none transition focus:border-[var(--primary)] focus:ring-4 focus:ring-[var(--primary)]/10",
          className
        )}
        {...rest}
      />
    </label>
  );
}

export function Select(
  props: React.SelectHTMLAttributes<HTMLSelectElement> & { label?: string }
) {
  const { label, className, children, ...rest } = props;
  return (
    <label className="block space-y-1.5 text-sm">
      {label && (
        <span className="text-xs font-semibold uppercase tracking-wide text-[var(--muted)]">
          {label}
        </span>
      )}
      <select
        className={cn(
          "w-full rounded-lg border border-[var(--border)] bg-white px-3.5 py-2.5 outline-none transition focus:border-[var(--primary)] focus:ring-4 focus:ring-[var(--primary)]/10",
          className
        )}
        {...rest}
      >
        {children}
      </select>
    </label>
  );
}

export function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "success" | "warning" | "danger";
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-[11px] font-semibold tracking-wide",
        tone === "neutral" && "bg-[var(--primary-soft)] text-[var(--primary)]",
        tone === "success" && "bg-emerald-50 text-emerald-800",
        tone === "warning" && "bg-amber-50 text-amber-800",
        tone === "danger" && "bg-red-50 text-red-700"
      )}
    >
      {children}
    </span>
  );
}

export function EmptyState({ message }: { message: string }) {
  return (
    <div className="rounded-[var(--radius)] border border-dashed border-[var(--border-strong)] bg-[var(--surface)]/70 px-4 py-14 text-center text-sm text-[var(--muted)]">
      {message}
    </div>
  );
}

export function Table({ children }: { children: React.ReactNode }) {
  return (
    <div className="overflow-x-auto rounded-[var(--radius)] border border-[var(--border)] bg-[var(--surface)] shadow-[var(--shadow)]">
      <table className="min-w-full text-left text-sm">{children}</table>
    </div>
  );
}
