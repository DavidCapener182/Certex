# Database Migration Contract

Every feature that changes data behavior must ship with a new SQL migration in this folder.

## Rules

1. Never edit an old migration after it has been applied outside local development.
2. Add one new file per feature or fix, named:
   - `YYYYMMDDHHMMSS_<short_description>.sql`
3. Make migrations idempotent where practical (`if exists` / `if not exists`).
4. Include all of the following when relevant:
   - schema changes (tables/columns/indexes)
   - RLS policy changes
   - function/RPC changes
   - grants
   - backfill/data migration steps
5. If a new feature needs new access paths, update both:
   - `RLS` policies
   - audit logging points (triggers or RPC usage)
6. If realtime UX is added for a table, add it to `supabase_realtime` publication.

## Suggested Workflow

1. Create migration SQL file in this folder.
2. Apply locally with Supabase CLI (`supabase db reset` or `supabase db push`) or SQL editor.
3. Validate:
   - schema and indexes
   - RLS behavior for each role
   - RPC grants (`anon` / `authenticated`)
4. Commit migration together with app/backend code.

## Feature-to-Migration Mapping

Use this template in PR descriptions:

- Feature:
- Migration file:
- Tables touched:
- Policies touched:
- Functions touched:
- Backfill required: yes/no
- Rollback note:
