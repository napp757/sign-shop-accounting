-- บัญชีร้านป้าย: ตั้งค่าฐานข้อมูล Supabase
-- วางทั้งไฟล์ใน Supabase > SQL Editor แล้วกด Run
-- ก่อนกด Run ให้แก้อีเมลด้านล่าง (บรรทัด insert into allowed_users) เป็นอีเมลที่ใช้ล็อกอินจริง

create table if not exists allowed_users (
  email text primary key
);

create table if not exists jobs (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists expenses (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- เปิด Row Level Security: ไม่มีนโยบาย = ไม่มีใครอ่านหรือเขียนได้
alter table allowed_users enable row level security;
alter table jobs enable row level security;
alter table expenses enable row level security;

-- อนุญาตเฉพาะผู้ที่ล็อกอินแล้วและอีเมลอยู่ในรายชื่อ allowed_users
create or replace function is_allowed() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from allowed_users
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

drop policy if exists jobs_all on jobs;
create policy jobs_all on jobs for all to authenticated
  using (is_allowed()) with check (is_allowed());

drop policy if exists expenses_all on expenses;
create policy expenses_all on expenses for all to authenticated
  using (is_allowed()) with check (is_allowed());

-- รายชื่อผู้ใช้ที่ได้รับอนุญาต (แก้อีเมลก่อนรัน เพิ่มได้หลายบรรทัด)
insert into allowed_users (email) values ('อีเมลของคุณ@example.com')
on conflict do nothing;
