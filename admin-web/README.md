# Más Iglesia Admin Web

Panel de administración Next.js conectado al mismo Firebase que la app Flutter (`igreja-amor-em-movimento`).

## Stack

- Next.js 15 (App Router) + TypeScript + Tailwind
- Firebase Auth / Firestore / Storage / Functions
- next-intl (`es` / `pt`)
- Deploy: Vercel (Root Directory = `admin-web`)

## Desarrollo local

```bash
cd admin-web
cp .env.local.example .env.local
npm install
npm run dev
```

Abre `http://localhost:3000/pt/login` (o `/es/login`).

## Vercel

1. Importa el repo en Vercel.
2. **Root Directory:** `admin-web`
3. Añade las variables `NEXT_PUBLIC_FIREBASE_*` (ver `.env.local.example`).
4. En Firebase Console → Authentication → Settings → Authorized domains, añade el dominio de Vercel.

## Paridad con la app

Las escrituras respetan los mismos nombres de campo que Flutter, incluyendo:

- `groupAdmin` (grupos)
- `ministrieAdmin` (ministerios, typo histórico)
- Jerarquía de escalas: `services` → `cults` → `time_slots` → `available_roles` + `work_assignments` / `work_invites`

Los permisos se evalúan igual que en móvil: `users.isSuperUser` o `roles/{roleId}.permissions`.
