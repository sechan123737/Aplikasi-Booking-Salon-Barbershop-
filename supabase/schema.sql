-- ============================================================
-- SALON / BARBERSHOP BOOKING APP - SUPABASE SCHEMA
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- PROFILES (extends auth.users)
-- ============================================================
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text not null,
  phone text,
  avatar_url text,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Admins can view all profiles" on public.profiles
  for select using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', '')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- SERVICES (layanan salon)
-- ============================================================
create table public.services (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  price numeric(10,2) not null default 0,
  duration_minutes int not null default 30,
  category text default 'general',
  image_url text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.services enable row level security;

create policy "Anyone can view active services" on public.services
  for select using (is_active = true);

create policy "Admins can manage services" on public.services
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Sample services
insert into public.services (name, description, price, duration_minutes, category) values
  ('Potong Rambut', 'Potong rambut reguler sesuai keinginan pelanggan', 35000, 30, 'rambut'),
  ('Cuci Rambut', 'Keramas dengan shampo premium + kondisioner', 25000, 20, 'rambut'),
  ('Creambath', 'Perawatan rambut dengan krim bergizi, termasuk pijat kepala', 75000, 60, 'rambut'),
  ('Cat Rambut', 'Pewarnaan rambut dengan bahan berkualitas', 150000, 90, 'rambut'),
  ('Smoothing', 'Pelurusan rambut semi-permanen', 250000, 120, 'rambut'),
  ('Facial', 'Perawatan wajah dasar: pembersihan + masker', 80000, 45, 'wajah'),
  ('Cukur Jenggot', 'Penataan & cukur jenggot profesional', 30000, 20, 'barbershop'),
  ('Gunting Kumis', 'Penataan & rapikan kumis', 20000, 15, 'barbershop'),
  ('Manicure', 'Perawatan kuku tangan', 45000, 30, 'kuku'),
  ('Pedicure', 'Perawatan kuku kaki', 50000, 40, 'kuku');

-- ============================================================
-- STAFF (karyawan salon)
-- ============================================================
create table public.staff (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  phone text,
  avatar_url text,
  specialization text[],
  bio text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.staff enable row level security;

create policy "Anyone can view active staff" on public.staff
  for select using (is_active = true);

create policy "Admins can manage staff" on public.staff
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Sample staff
insert into public.staff (name, specialization, bio) values
  ('Andi', array['rambut', 'barbershop'], 'Stylist berpengalaman 5 tahun'),
  ('Budi', array['barbershop'], 'Spesialis cukur pria & beard styling'),
  ('Citra', array['rambut', 'wajah', 'kuku'], 'Beauty therapist profesional'),
  ('Dewi', array['rambut', 'wajah'], 'Ahli perawatan rambut & facial');

-- ============================================================
-- WORKING HOURS (jam operasional)
-- ============================================================
create table public.working_hours (
  id uuid default uuid_generate_v4() primary key,
  day_of_week int not null check (day_of_week between 0 and 6), -- 0=Minggu, 1=Senin,...
  open_time time not null default '09:00',
  close_time time not null default '20:00',
  is_open boolean default true,
  slot_duration_minutes int default 30
);

alter table public.working_hours enable row level security;

create policy "Anyone can view working hours" on public.working_hours
  for select using (true);

create policy "Admins can manage working hours" on public.working_hours
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Default working hours (Senin-Sabtu 09:00-20:00, Minggu libur)
insert into public.working_hours (day_of_week, open_time, close_time, is_open) values
  (0, '09:00', '20:00', false), -- Minggu
  (1, '09:00', '20:00', true),  -- Senin
  (2, '09:00', '20:00', true),  -- Selasa
  (3, '09:00', '20:00', true),  -- Rabu
  (4, '09:00', '20:00', true),  -- Kamis
  (5, '09:00', '20:00', true),  -- Jumat
  (6, '09:00', '18:00', true);  -- Sabtu

-- ============================================================
-- BOOKINGS (reservasi)
-- ============================================================
create table public.bookings (
  id uuid default uuid_generate_v4() primary key,
  booking_code text unique not null default 'BK-' || upper(substr(md5(random()::text), 1, 8)),
  user_id uuid references public.profiles(id) on delete set null,
  -- Data pelanggan (untuk walk-in / guest)
  customer_name text not null,
  customer_phone text not null,
  customer_email text,
  -- Layanan & staff
  service_id uuid references public.services(id) on delete restrict not null,
  staff_id uuid references public.staff(id) on delete set null,
  -- Waktu
  booking_date date not null,
  booking_time time not null,
  end_time time,
  -- Status
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show')),
  -- Harga
  service_price numeric(10,2),
  -- Catatan
  notes text,
  admin_notes text,
  -- Reminder
  reminder_sent boolean default false,
  -- Timestamps
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.bookings enable row level security;

create policy "Users can view own bookings" on public.bookings
  for select using (auth.uid() = user_id);

create policy "Users can create bookings" on public.bookings
  for insert with check (true); -- allow guest booking too

create policy "Users can cancel own bookings" on public.bookings
  for update using (auth.uid() = user_id)
  with check (status = 'cancelled');

create policy "Admins can manage all bookings" on public.bookings
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Auto set end_time & service_price
create or replace function public.set_booking_defaults()
returns trigger as $$
declare
  svc record;
begin
  select price, duration_minutes into svc from public.services where id = new.service_id;
  new.service_price = svc.price;
  new.end_time = new.booking_time + (svc.duration_minutes || ' minutes')::interval;
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

create trigger booking_set_defaults
  before insert or update on public.bookings
  for each row execute procedure public.set_booking_defaults();

-- ============================================================
-- RATINGS & REVIEWS
-- ============================================================
create table public.reviews (
  id uuid default uuid_generate_v4() primary key,
  booking_id uuid references public.bookings(id) on delete cascade unique not null,
  user_id uuid references public.profiles(id) on delete set null,
  service_id uuid references public.services(id) on delete set null,
  staff_id uuid references public.staff(id) on delete set null,
  rating int not null check (rating between 1 and 5),
  comment text,
  is_public boolean default true,
  created_at timestamptz default now()
);

alter table public.reviews enable row level security;

create policy "Anyone can view public reviews" on public.reviews
  for select using (is_public = true);

create policy "Users can create review for own booking" on public.reviews
  for insert with check (
    auth.uid() = user_id and
    exists (
      select 1 from public.bookings
      where id = booking_id and user_id = auth.uid() and status = 'completed'
    )
  );

create policy "Admins can manage reviews" on public.reviews
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- BLOCKED DATES (tanggal tutup / libur)
-- ============================================================
create table public.blocked_dates (
  id uuid default uuid_generate_v4() primary key,
  blocked_date date not null unique,
  reason text,
  created_at timestamptz default now()
);

alter table public.blocked_dates enable row level security;

create policy "Anyone can view blocked dates" on public.blocked_dates
  for select using (true);

create policy "Admins can manage blocked dates" on public.blocked_dates
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- VIEW: available slots helper
-- ============================================================
create or replace view public.bookings_per_slot as
  select
    booking_date,
    booking_time,
    count(*) as booked_count
  from public.bookings
  where status not in ('cancelled', 'no_show')
  group by booking_date, booking_time;

-- ============================================================
-- NOTIFICATIONS LOG
-- ============================================================
create table public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  type text not null check (type in ('booking_confirmed', 'booking_reminder', 'booking_cancelled', 'booking_completed')),
  title text not null,
  message text not null,
  is_read boolean default false,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;

create policy "Users can view own notifications" on public.notifications
  for select using (auth.uid() = user_id);

create policy "Users can mark own notifications as read" on public.notifications
  for update using (auth.uid() = user_id);

create policy "Admins can manage notifications" on public.notifications
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- FUNCTION: get available time slots for a date
-- ============================================================
create or replace function public.get_available_slots(
  p_date date,
  p_service_id uuid,
  p_max_per_slot int default 2
)
returns table(slot_time time, available_count int, is_available boolean) as $$
declare
  v_day_of_week int;
  v_open_time time;
  v_close_time time;
  v_slot_duration int;
  v_service_duration int;
  v_current_slot time;
  v_booked_count int;
begin
  v_day_of_week := extract(dow from p_date)::int;

  select open_time, close_time, slot_duration_minutes
  into v_open_time, v_close_time, v_slot_duration
  from public.working_hours
  where day_of_week = v_day_of_week and is_open = true;

  if not found then
    return;
  end if;

  if exists (select 1 from public.blocked_dates where blocked_date = p_date) then
    return;
  end if;

  select duration_minutes into v_service_duration
  from public.services where id = p_service_id;

  v_current_slot := v_open_time;

  while v_current_slot + (v_service_duration || ' minutes')::interval <= v_close_time loop
    select coalesce(booked_count, 0) into v_booked_count
    from public.bookings_per_slot
    where booking_date = p_date and booking_time = v_current_slot;

    slot_time := v_current_slot;
    available_count := p_max_per_slot - coalesce(v_booked_count, 0);
    is_available := available_count > 0 and v_current_slot > current_time or p_date > current_date;

    return next;

    v_current_slot := v_current_slot + (v_slot_duration || ' minutes')::interval;
  end loop;
end;
$$ language plpgsql security definer;

-- ============================================================
-- INDEXES
-- ============================================================
create index idx_bookings_date on public.bookings(booking_date);
create index idx_bookings_user on public.bookings(user_id);
create index idx_bookings_status on public.bookings(status);
create index idx_reviews_service on public.reviews(service_id);
create index idx_notifications_user on public.notifications(user_id, is_read);
