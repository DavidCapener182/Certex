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

## 4. First sign-in provisions org + role automatically

After you run the latest migrations, signing up or signing in from the app now auto-provisions:

1. `public.profiles` entry for the user.
2. A default organization (company/auditor/audit-company/insurer based on account type) when no membership exists.
3. A default membership role with tenant-scoped RLS access.
4. A `public.signup_requests` row so non-InCert accounts require InCert approval before using the workspace.
5. First-login organization profile capture (`public.organization_directory_profiles`) for company/auditor/audit-company accounts.

Special case:
- `capener182@googlemail.com` is automatically elevated to `platform_admin` in the `InCert Team` platform organization so the account has global InCert visibility.
