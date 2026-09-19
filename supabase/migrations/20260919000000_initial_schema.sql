create extension if not exists "pgcrypto";

create type public.user_role as enum ('USER', 'ADMIN');
create type public.item_type as enum ('LOST', 'FOUND');
create type public.item_status as enum (
  'ACTIVE', 'PENDING_CLAIM', 'MATCHED', 'CLAIMED', 'RECOVERED', 'CLOSED', 'REMOVED'
);
create type public.claim_status as enum ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
create type public.report_status as enum ('PENDING', 'UNDER_REVIEW', 'RESOLVED', 'DISMISSED');

create sequence if not exists public.item_reference_seq start 1;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  phone text,
  institution_id text,
  account_type text not null default 'STUDENT',
  role public.user_role not null default 'USER',
  is_active boolean not null default true,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete restrict,
  item_type public.item_type not null,
  title text not null check (char_length(title) between 2 and 120),
  category_id uuid not null references public.categories(id),
  description text not null check (char_length(description) between 2 and 3000),
  date_lost_or_found date not null,
  time_lost_or_found time,
  location text not null,
  specific_location text,
  color text,
  brand text,
  model text,
  serial_number text,
  identifying_features text,
  additional_notes text,
  preferred_contact_method text not null default 'IN_APP',
  status public.item_status not null default 'ACTIVE',
  reference_number text not null unique default (
    'LF-' || extract(year from now())::text || '-' ||
    lpad(nextval('public.item_reference_seq')::text, 6, '0')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.item_images (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  storage_path text not null,
  public_url text,
  created_at timestamptz not null default now()
);

create table public.claims (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  claimant_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  identifying_characteristics text not null,
  ownership_proof text,
  additional_information text,
  status public.claim_status not null default 'PENDING',
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (item_id, claimant_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  kind text not null,
  entity_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.saved_items (
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

create table public.moderation_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  item_id uuid references public.items(id) on delete cascade,
  reason text not null,
  description text not null,
  status public.report_status not null default 'PENDING',
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index items_search_idx on public.items using gin (
  to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, '') ||
  ' ' || coalesce(location, '') || ' ' || coalesce(brand, '') || ' ' || coalesce(reference_number, ''))
);
create index items_type_status_idx on public.items(item_type, status, created_at desc);
create index notifications_user_read_idx on public.notifications(user_id, is_read, created_at desc);
create index messages_participants_idx on public.messages(sender_id, receiver_id, created_at desc);

insert into public.categories (name, sort_order) values
  ('Phones', 1), ('Laptops', 2), ('Tablets', 3), ('Electronics', 4),
  ('Identification Documents', 5), ('Books', 6), ('Bags', 7), ('Wallets', 8),
  ('Keys', 9), ('Clothing', 10), ('Jewelry', 11), ('Stationery', 12),
  ('Accessories', 13), ('Other', 14)
on conflict (name) do nothing;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'ADMIN' and is_active = true
  );
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Campus member'),
    new.email
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.items enable row level security;
alter table public.item_images enable row level security;
alter table public.claims enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.saved_items enable row level security;
alter table public.moderation_reports enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles are visible to signed-in users"
  on public.profiles for select to authenticated using (true);
create policy "users update their own profile"
  on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "categories are visible to signed-in users"
  on public.categories for select to authenticated using (is_active or public.is_admin());
create policy "public active listings are readable"
  on public.items for select to authenticated using (status <> 'REMOVED' or user_id = auth.uid() or public.is_admin());
create policy "users create their own listings"
  on public.items for insert to authenticated with check (user_id = auth.uid());
create policy "users update their own listings"
  on public.items for update to authenticated using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy "users delete their own listings"
  on public.items for delete to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "item images follow listing visibility"
  on public.item_images for select to authenticated using (
    exists (select 1 from public.items where id = item_id and (status <> 'REMOVED' or user_id = auth.uid() or public.is_admin()))
  );
create policy "owners add item images"
  on public.item_images for insert to authenticated with check (
    exists (select 1 from public.items where id = item_id and user_id = auth.uid())
  );
create policy "claimants read their claims"
  on public.claims for select to authenticated using (claimant_id = auth.uid() or public.is_admin());
create policy "users submit claims"
  on public.claims for insert to authenticated with check (claimant_id = auth.uid());
create policy "admins review claims"
  on public.claims for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "message participants can read"
  on public.messages for select to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid() or public.is_admin());
create policy "users send messages as themselves"
  on public.messages for insert to authenticated with check (sender_id = auth.uid());
create policy "users read their notifications"
  on public.notifications for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "users update their notifications"
  on public.notifications for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage saved items"
  on public.saved_items for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users create moderation reports"
  on public.moderation_reports for insert to authenticated with check (reporter_id = auth.uid());
create policy "users read own moderation reports"
  on public.moderation_reports for select to authenticated using (reporter_id = auth.uid() or public.is_admin());
create policy "admins manage moderation reports"
  on public.moderation_reports for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins read audit logs"
  on public.audit_logs for select to authenticated using (public.is_admin());

insert into storage.buckets (id, name, public) values
  ('item-images', 'item-images', true),
  ('profile-images', 'profile-images', false)
on conflict (id) do nothing;

create policy "signed-in users upload item images"
  on storage.objects for insert to authenticated with check (
    bucket_id = 'item-images' and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "public can view item images"
  on storage.objects for select to public using (bucket_id = 'item-images');
create policy "users manage own item images"
  on storage.objects for delete to authenticated using (
    bucket_id = 'item-images' and (storage.foldername(name))[1] = auth.uid()::text
  );