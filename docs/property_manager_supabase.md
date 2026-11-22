# Property Manager Supabase checks

Current deployment note (22 November 2026): the project owner reports successful live cross-manager property/viewing isolation and renter Pending-only/status restrictions. These results are recorded in SECURITY_LIVE_TEST_CHECKLIST.md. The current database role constraint allows `renter` and `partner`; Property Manager is the display label. Client compatibility with `property_manager` is not a request to migrate or provision that database value.

The SQL below is historical, conditional setup guidance, not the exact deployed policy export. Working live policies must be preserved. No SQL, grants, schema or policies were executed or changed during the final audit. In particular, the proposed manager policy alone does not capture all deployed renter status/column protections.

## Read-only inspection

```sql
select tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('properties', 'viewings', 'profiles')
order by tablename, policyname;

select c.relname, c.relrowsecurity
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('properties', 'viewings', 'profiles');

select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('properties', 'viewings')
order by table_name, ordinal_position;

select conrelid::regclass as table_name, conname,
       pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid in ('public.properties'::regclass, 'public.viewings'::regclass);

select table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('properties', 'viewings', 'profiles')
  and grantee in ('anon', 'authenticated');
```

Check that:

- RLS is enabled. Retain existing renter read, favorite, viewing, profile, and
  manager contact access.
- Existing property INSERT uses `partner_id = auth.uid()` in WITH CHECK;
  UPDATE checks ownership in both USING and WITH CHECK; DELETE checks ownership
  in USING. Owners must also be able to SELECT their rows.
- Property columns not supplied by the new form are nullable or have defaults.
  The form uses only the requested existing columns; it does not send rating,
  bathrooms, size_sqm, IDs, or timestamps.
- `viewings.status` uses exact `Pending`, `Approved`, `Rejected` values. Flutter retains display support for legacy `Cancelled`, but current cancellation deletes an owned Pending row; it does not require a new Cancelled database value. Do not rename statuses or replace constraints.
- Property foreign keys do not silently cascade deletion of renter data. The
  app handles a restrictive FK rejection (23503), but cannot prevent a cascade
  already configured in the database. Review any existing CASCADE before the
  live delete demo; no FK was changed by this task.
- Existing policies do not grant unrelated users broad viewing access.
  Adding a scoped permissive policy does not narrow another permissive policy.

The REST calls match the existing `partner_id = auth.uid()` ownership model:
the public key and logged-in user's JWT are sent on every manager request.
Property updates and deletes filter both ID and owner; viewing decisions also
recheck ownership immediately before PATCH. Database ownership policies must
still enforce access independently of Flutter.

## REQUIRED SUPABASE SQL — only if manager viewing access is missing

These two policies add owned-property viewing access without changing existing
renter policies. Review the audit results first; do not add duplicate policies
if equivalent policies already exist. The SELECT policy is needed for reads
and returned UPDATE rows. The UPDATE policy checks Pending on the old row and
Approved/Rejected plus ownership on the resulting row. This follows
[Supabase's SELECT and UPDATE policy guidance](https://supabase.com/docs/guides/database/postgres/row-level-security).

```sql
begin;

create policy "Managers read viewings for owned properties"
on public.viewings
for select to authenticated
using (
  exists (
    select 1 from public.properties p
    where p.id = viewings.property_id
      and p.partner_id = (select auth.uid())
  )
);

create policy "Managers decide pending viewings for owned properties"
on public.viewings
for update to authenticated
using (
  status = 'Pending'
  and exists (
    select 1 from public.properties p
    where p.id = viewings.property_id
      and p.partner_id = (select auth.uid())
  )
)
with check (
  status in ('Approved', 'Rejected')
  and exists (
    select 1 from public.properties p
    where p.id = viewings.property_id
      and p.partner_id = (select auth.uid())
  )
);

commit;
```

This SQL assumes existing authenticated SELECT/UPDATE grants and enabled RLS,
as used by the working renter flow. It grants access by property ownership;
neither the login role selector nor a client-provided role is a security boundary.
Profile roles and property ownership must remain protected by existing policies.
No secrets, privileged RPC, disabled RLS, or unrestricted manager policy is used.

RLS scopes rows, not editable columns. Flutter sends only `status` for decisions.
If database enforcement of status-only changes is required, review existing
column grants/triggers separately; do not revoke the renter's date/time/message
update access globally. These policies alone do not enforce column immutability.

Renter contact lookup is optional: the app requests only IDs from the manager's
own filtered viewing requests, selecting `id,full_name,email`. If current profile
RLS hides them, the card says “Renter information unavailable” and decisions
still work. No broad profile policy is needed or provided for the MVP.

## Manual live test steps

1. Use an existing renter and two existing manager accounts. Use the actual stored manager role `partner` for both accounts; do not create `property_manager` against the current constraint.
   Confirm renter navigation still has Home, Search, Favorites, My Viewings,
   Profile, and manager navigation has Properties, Viewing Requests, Profile.
2. Manager A adds a property with required fields, then edits its details and
   availability. Verify `partner_id` equals A's auth user ID and the renter can
   see the new available property. Confirm renter favorites and manager contact
   still work.
3. The renter requests a viewing. Manager A refreshes Viewing Requests and
   approves it. The renter reopens My Viewings and sees Approved. Repeat with
   another request and Reject. Decide buttons should disappear after success.
4. Manager B must not see A's requests or properties in the manager area. Using
   B's normal access token and the public key in a REST client, attempt PATCH
   against A's viewing and property IDs, and DELETE against A's property ID.
   Expect a rejected request or zero returned rows; verify A's rows unchanged.
   Also confirm a renter cannot alter someone else's requests. Do not use an
   admin/service token for these checks.
5. Delete a newly created property with no dependent records: Cancel preserves
   it, Delete removes it after confirmation. Attempt deletion with restrictive
   related records and verify the related-records error and unchanged renter
   data. Confirm FK behavior first as described above.
6. Test empty properties/viewings, network failure and Retry, failed decisions,
   and a narrow device. Profile shows real name/email and “Property Manager”.
   Logout clears the session and returns to Login.

Mock tests cannot establish live RLS behavior or actual schema compatibility.
Only mark the live flow verified after completing these checks with real accounts.
