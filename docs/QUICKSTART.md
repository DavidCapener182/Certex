# Get the app and database working

## 1. Finish migrations (one-time)

The shared database still has old migration versions. Repair them, then push your migrations:

```bash
./scripts/repair-remote-migrations.sh
```

This marks the old remote-only versions as reverted and runs `npx supabase db push`.  
If you see connection/SASL errors, wait a minute and run again:

```bash
npx supabase db push
```

## 2. App environment (for real auth and data)

Create a `.env` in the project root with your Supabase project keys:

```bash
VITE_SUPABASE_URL=https://wngqphzpxhderwfjjzla.supabase.co
VITE_SUPABASE_ANON_KEY=<your anon key>
```

Get the anon key: [Supabase Dashboard](https://app.supabase.com/project/wngqphzpxhderwfjjzla) → **Project Settings** → **API** → **Project API keys** → `anon` `public`.

## 3. Run the app

```bash
npm run dev
```

Open the URL (e.g. http://localhost:5173). Use **Debug: Enter App** on the landing page to get in without real auth.

## 4. (Optional) Seed an org and link your user

When you want real login and RLS to work:

1. Sign up or sign in once via the app (or Supabase Dashboard → Authentication).
2. In **Supabase Dashboard → SQL Editor**, run (replace the UUIDs):

```sql
insert into public.organizations (name, slug, org_type)
values ('Acme Logistics', 'acme-logistics', 'operator')
returning id;
-- Copy the returned id as <org_uuid>

insert into public.organization_memberships (organization_id, user_id, role, is_default)
values ('<org_uuid>', '<your-auth-user-uuid>', 'dutyholder_admin', true);
```

Your user UUID: **Authentication** → **Users** → click your user → copy **User UID**.

After that, logging in with that user will show data scoped to that org.
