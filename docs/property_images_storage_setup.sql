-- FINAL AUDIT NOTE (22 November 2026): working Storage isolation was reported
-- live-tested by the project owner. Do not reapply this historical setup script.
-- Current database roles are renter/partner. The property_manager string below
-- is historical compatibility, not a role migration or provisioning instruction.
-- REQUIRED SUPABASE STORAGE SETUP
-- Manual setup only: this script was not executed against Supabase.
-- First run these read-only queries and review any existing bucket/policies.
select id, name, public, allowed_mime_types, file_size_limit
from storage.buckets where id = 'property-images';

select policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'storage' and tablename = 'objects';

-- Apply the following transaction only if the bucket/policy is missing.
-- Existing permissive policies can broaden access: audit them first.
-- Do not replace working unrelated policies or disable Storage RLS.
-- If the bucket already exists, this leaves its settings unchanged. Verify it
-- is public in Dashboard > Storage > property-images > Configuration, and that
-- its MIME/size limits accept the chosen photo. Only property photos belong here.
-- Public means anyone with an image URL can view that image.

begin;

insert into storage.buckets (id, name, public, allowed_mime_types)
values (
  'property-images',
  'property-images',
  true,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

create policy "Property managers upload images in their own folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'property-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid())
      and p.role::text in ('partner', 'property_manager')
  )
);

commit;

-- Preconditions: profiles SELECT must allow each user to read their own role;
-- users must not be allowed to promote their own profile role. The working
-- login flow already requires own-profile SELECT. Keep role assignment trusted.
-- No UPDATE/DELETE/SELECT Storage policy is needed by this implementation:
-- it inserts unique objects with x-upsert:false and serves public image URLs.
-- Public download does not grant permission to list, overwrite, or delete files.
-- Existing property table owner policies remain required for POST/PATCH.
-- No property schema changes are required. image_url remains the existing column.

-- Manual verification with ordinary user JWTs (never a privileged key):
-- 1. Manager A uploads to A's folder: succeeds.
-- 2. Manager A uploads to B's folder: denied.
-- 3. Renter uploads to their own folder: denied.
-- 4. Public URL loads without auth; Add/Edit stores exactly that URL.
-- 5. Manager B cannot PATCH A's property to change its image_url.
-- 6. Cancel gallery / deny permission / fail upload: no successful property save.
-- 7. Edit without choosing a replacement keeps the image; Remove stores null.
-- Old or orphaned objects are intentionally retained after replacement/removal
-- or an abandoned property save. Review references before any manual cleanup.

-- Official references:
-- https://supabase.com/docs/guides/storage/security/access-control
-- https://supabase.com/docs/guides/storage/serving/downloads
