-- ============================================================
--  CHAALON SALON BOOKING — COMPLETE DATABASE SETUP
--  Salin semua isi file ini ke Supabase SQL Editor → Run
--  Versi: 2.0 (include semua fix: real-time slots, multi-layanan,
--              total_duration, timezone WIB, overlap check)
-- ============================================================


-- ============================================================
-- 0. EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================
-- 1. PROFILES (extends auth.users)
-- ============================================================
CREATE TABLE public.profiles (
  id         uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name  text NOT NULL,
  phone      text,
  avatar_url text,
  role       text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Fix: hindari infinite recursion dengan auth.jwt()
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    (auth.jwt() ->> 'role') = 'admin'
    OR auth.uid() = id
  );

-- View publik: hanya expose full_name & avatar_url (untuk nama reviewer)
CREATE OR REPLACE VIEW public.profiles_public AS
  SELECT id, full_name, avatar_url
  FROM public.profiles;

GRANT SELECT ON public.profiles_public TO anon, authenticated;

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.raw_user_meta_data->>'phone', '')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ============================================================
-- 2. SERVICES (layanan salon)
-- ============================================================
CREATE TABLE public.services (
  id               uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name             text NOT NULL,
  description      text,
  price            numeric(10,2) NOT NULL DEFAULT 0,
  duration_minutes int NOT NULL DEFAULT 30,
  category         text DEFAULT 'general',
  image_url        text,
  is_active        boolean DEFAULT true,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active services" ON public.services
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage services" ON public.services
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Sample services
INSERT INTO public.services (name, description, price, duration_minutes, category) VALUES
  ('Potong Rambut',  'Potong rambut reguler sesuai keinginan pelanggan',           35000,  30, 'rambut'),
  ('Cuci Rambut',    'Keramas dengan shampo premium + kondisioner',                 25000,  20, 'rambut'),
  ('Creambath',      'Perawatan rambut dengan krim bergizi, termasuk pijat kepala', 75000,  60, 'rambut'),
  ('Cat Rambut',     'Pewarnaan rambut dengan bahan berkualitas',                  150000,  90, 'rambut'),
  ('Smoothing',      'Pelurusan rambut semi-permanen',                             250000, 120, 'rambut'),
  ('Facial',         'Perawatan wajah dasar: pembersihan + masker',                 80000,  45, 'wajah'),
  ('Cukur Jenggot',  'Penataan & cukur jenggot profesional',                        30000,  20, 'barbershop'),
  ('Gunting Kumis',  'Penataan & rapikan kumis',                                    20000,  15, 'barbershop'),
  ('Manicure',       'Perawatan kuku tangan',                                       45000,  30, 'kuku'),
  ('Pedicure',       'Perawatan kuku kaki',                                         50000,  40, 'kuku');


-- ============================================================
-- 3. STAFF (karyawan salon)
-- ============================================================
CREATE TABLE public.staff (
  id             uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name           text NOT NULL,
  phone          text,
  avatar_url     text,
  specialization text[],
  bio            text,
  is_active      boolean DEFAULT true,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active staff" ON public.staff
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage staff" ON public.staff
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Sample staff Sechan
INSERT INTO public.staff (name, specialization, bio) VALUES
  ('Sechan',  ARRAY['rambut', 'barbershop'],        'Stylist berpengalaman 5 tahun'),
  ('SechanKembar',  ARRAY['barbershop'],                  'Spesialis cukur pria & beard styling'),
  ('SechanGanteng', ARRAY['rambut', 'wajah', 'kuku'],     'Beauty therapist profesional'),
  ('SechanImut',  ARRAY['rambut', 'wajah'],             'Ahli perawatan rambut & facial');


-- ============================================================
-- 4. WORKING HOURS (jam operasional)
-- ============================================================
CREATE TABLE public.working_hours (
  id                    uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  day_of_week           int NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  open_time             time NOT NULL DEFAULT '09:00',
  close_time            time NOT NULL DEFAULT '20:00',
  is_open               boolean DEFAULT true,
  slot_duration_minutes int DEFAULT 30
);

ALTER TABLE public.working_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view working hours" ON public.working_hours
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage working hours" ON public.working_hours
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Default: Senin–Jumat 09:00–20:00, Sabtu 09:00–18:00, Minggu tutup
INSERT INTO public.working_hours (day_of_week, open_time, close_time, is_open) VALUES
  (0, '09:00', '20:00', false),
  (1, '09:00', '20:00', true),
  (2, '09:00', '20:00', true),
  (3, '09:00', '20:00', true),
  (4, '09:00', '20:00', true),
  (5, '09:00', '20:00', true),
  (6, '09:00', '18:00', true);


-- ============================================================
-- 5. VOUCHERS (diskon)
-- ============================================================
CREATE TABLE public.vouchers (
  id             uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  code           text NOT NULL UNIQUE,
  name           text,
  discount_type  text NOT NULL DEFAULT 'percent'
                   CHECK (discount_type IN ('percent', 'fixed')),
  discount_value numeric(10,2) NOT NULL,
  max_discount   numeric(10,2),
  min_purchase   numeric(10,2),
  valid_from     date,
  valid_until    date,
  max_uses       int,
  used_count     int NOT NULL DEFAULT 0,
  is_active      boolean NOT NULL DEFAULT true,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage vouchers" ON public.vouchers
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Anyone can view active vouchers" ON public.vouchers
  FOR SELECT USING (true);

CREATE INDEX IF NOT EXISTS idx_vouchers_code   ON public.vouchers(code);
CREATE INDEX IF NOT EXISTS idx_vouchers_active ON public.vouchers(is_active);

-- Sample vouchers
INSERT INTO public.vouchers (code, name, discount_type, discount_value, max_discount, min_purchase, valid_until, max_uses) VALUES
  ('WELCOME10', 'Diskon Pelanggan Baru 10%', 'percent', 10,    20000,  30000,  now() + interval '90 days', 100),
  ('DISKON20',  'Promo 20% Semua Layanan',   'percent', 20,    50000,  50000,  now() + interval '30 days', 50),
  ('HEMAT50K',  'Potongan Rp 50.000',        'fixed',   50000, null,   100000, now() + interval '30 days', 30),
  ('RAMBUT15',  'Diskon 15% Layanan Rambut', 'percent', 15,    30000,  25000,  now() + interval '60 days', null),
  ('FLASHSALE', 'Flash Sale Rp 25.000',      'fixed',   25000, null,   null,   now() + interval '7 days',  20)
ON CONFLICT (code) DO NOTHING;

-- Function: increment used_count
CREATE OR REPLACE FUNCTION public.increment_voucher_usage(v_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.vouchers
  SET used_count = used_count + 1,
      updated_at = now()
  WHERE id = v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 6. BOOKINGS (reservasi)
-- ============================================================
CREATE TABLE public.bookings (
  id               uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  booking_code     text UNIQUE NOT NULL DEFAULT 'BK-' || upper(substr(md5(random()::text), 1, 8)),
  user_id          uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  -- Pelanggan
  customer_name    text NOT NULL,
  customer_phone   text NOT NULL,
  customer_email   text,
  -- Layanan & staff
  service_id       uuid REFERENCES public.services(id) ON DELETE RESTRICT NOT NULL,
  staff_id         uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  -- Waktu
  booking_date     date NOT NULL,
  booking_time     time NOT NULL,
  end_time         time,
  -- Durasi total (untuk multi-layanan, dipakai overlap check)
  total_duration   int,
  -- Status booking
  status           text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show')),
  -- Harga
  service_price    numeric(10,2),
  voucher_code     text,
  discount_amount  numeric(10,2) DEFAULT 0,
  final_price      numeric(10,2),
  -- Pembayaran
  payment_status   text DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'waiting_verification', 'paid', 'failed')),
  payment_method   text,
  payment_proof    text,
  paid_at          timestamptz,
  -- Refund
  refund_status    text DEFAULT NULL
    CHECK (refund_status IN ('requested', 'approved', 'rejected', 'completed')),
  refund_amount    numeric(10,2) DEFAULT NULL,
  refund_method    text DEFAULT NULL,
  refund_notes     text DEFAULT NULL,
  refund_at        timestamptz DEFAULT NULL,
  -- Catatan
  notes            text,
  admin_notes      text,
  reminder_sent    boolean DEFAULT false,
  -- Timestamps
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_own_bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "insert_bookings_open" ON public.bookings
  FOR INSERT WITH CHECK (true);

CREATE POLICY "update_bookings" ON public.bookings
  FOR UPDATE USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "delete_bookings_admin" ON public.bookings
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can delete own cancelled bookings" ON public.bookings
  FOR DELETE USING (
    auth.uid() = user_id AND status = 'cancelled'
  );

GRANT ALL    ON public.bookings TO authenticated;
GRANT INSERT, SELECT ON public.bookings TO anon;
GRANT USAGE  ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Trigger: set end_time & service_price
CREATE OR REPLACE FUNCTION public.set_booking_defaults()
RETURNS trigger AS $$
DECLARE
  svc record;
BEGIN
  IF new.service_id IS NOT NULL THEN
    SELECT price, duration_minutes INTO svc
    FROM public.services WHERE id = new.service_id;

    IF FOUND THEN
      new.service_price := svc.price;
      -- end_time pakai total_duration jika multi-layanan, fallback ke durasi layanan tunggal
      new.end_time := new.booking_time +
        (COALESCE(new.total_duration, svc.duration_minutes) || ' minutes')::interval;
    END IF;
  END IF;

  -- Isi final_price jika belum ada
  IF new.final_price IS NULL THEN
    new.final_price := COALESCE(new.service_price, 0);
  END IF;

  new.updated_at := now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS booking_set_defaults ON public.bookings;
CREATE TRIGGER booking_set_defaults
  BEFORE INSERT OR UPDATE ON public.bookings
  FOR EACH ROW EXECUTE PROCEDURE public.set_booking_defaults();

-- Index bookings
CREATE INDEX idx_bookings_date           ON public.bookings(booking_date);
CREATE INDEX idx_bookings_user           ON public.bookings(user_id);
CREATE INDEX idx_bookings_status         ON public.bookings(status);
CREATE INDEX idx_bookings_payment_status ON public.bookings(payment_status);
CREATE INDEX idx_bookings_refund_status  ON public.bookings(refund_status);


-- ============================================================
-- 7. BOOKING_SERVICES (multi-layanan per booking)
-- ============================================================
CREATE TABLE public.booking_services (
  id         uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  booking_id uuid NOT NULL REFERENCES public.bookings(id)  ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES public.services(id)  ON DELETE RESTRICT,
  price      numeric(10,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(booking_id, service_id)
);

ALTER TABLE public.booking_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own booking services" ON public.booking_services
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bookings
      WHERE id = booking_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage booking services" ON public.booking_services
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Anyone can insert booking services" ON public.booking_services
  FOR INSERT WITH CHECK (true);

CREATE INDEX idx_booking_services_booking ON public.booking_services(booking_id);
CREATE INDEX idx_booking_services_service ON public.booking_services(service_id);


-- ============================================================
-- 8. REVIEWS
-- ============================================================
CREATE TABLE public.reviews (
  id         uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  booking_id uuid REFERENCES public.bookings(id) ON DELETE CASCADE UNIQUE NOT NULL,
  user_id    uuid REFERENCES public.profiles(id)  ON DELETE SET NULL,
  service_id uuid REFERENCES public.services(id)  ON DELETE SET NULL,
  staff_id   uuid REFERENCES public.staff(id)     ON DELETE SET NULL,
  rating     int NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment    text,
  is_public  boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view public reviews" ON public.reviews
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can create review for own booking" ON public.reviews
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.bookings
      WHERE id = booking_id AND user_id = auth.uid() AND status = 'completed'
    )
  );

CREATE POLICY "Admins can manage reviews" ON public.reviews
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX idx_reviews_service ON public.reviews(service_id);


-- ============================================================
-- 9. BLOCKED DATES (tanggal libur)
-- ============================================================
CREATE TABLE public.blocked_dates (
  id           uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  blocked_date date NOT NULL UNIQUE,
  reason       text,
  created_at   timestamptz DEFAULT now()
);

ALTER TABLE public.blocked_dates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view blocked dates" ON public.blocked_dates
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage blocked dates" ON public.blocked_dates
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 10. NOTIFICATIONS
-- ============================================================
CREATE TABLE public.notifications (
  id         uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    uuid REFERENCES public.profiles(id)  ON DELETE CASCADE,
  booking_id uuid REFERENCES public.bookings(id)  ON DELETE CASCADE,
  type       text NOT NULL CHECK (type IN (
    'booking_confirmed', 'booking_reminder', 'booking_cancelled', 'booking_completed',
    'payment_rejected',
    'refund_requested', 'refund_approved', 'refund_rejected', 'refund_completed'
  )),
  title      text NOT NULL,
  message    text NOT NULL,
  is_read    boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can mark own notifications as read" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage notifications" ON public.notifications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX idx_notifications_user ON public.notifications(user_id, is_read);


-- ============================================================
-- 11. STORAGE BUCKET (bukti pembayaran)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Users can upload payment proof'
  ) THEN
    CREATE POLICY "Users can upload payment proof"
      ON storage.objects FOR INSERT
      WITH CHECK (bucket_id = 'payment-proofs');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Anyone can view payment proof'
  ) THEN
    CREATE POLICY "Anyone can view payment proof"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'payment-proofs');
  END IF;
END $$;


-- ============================================================
-- 12. VIEW: bookings_per_slot
-- ============================================================
CREATE OR REPLACE VIEW public.bookings_per_slot
WITH (security_invoker = false) AS
  SELECT
    booking_date,
    booking_time,
    count(*) AS booked_count
  FROM public.bookings
  WHERE status NOT IN ('cancelled', 'no_show')
  GROUP BY booking_date, booking_time;

GRANT SELECT ON public.bookings_per_slot TO anon, authenticated;


-- ============================================================
-- 13. FUNCTION: get_available_slots (v5 — FINAL)
--     ✅ Timezone WIB (Asia/Jakarta)
--     ✅ Memperhitungkan durasi layanan (jam mulai + durasi <= sekarang)
--     ✅ Support multi-layanan via p_total_duration
--     ✅ Overlap check per booking (bukan hanya cek jam persis sama)
--     ✅ Per-staff conflict check
--     ✅ Pakai total_duration dari kolom bookings jika ada
-- ============================================================
DROP FUNCTION IF EXISTS public.get_available_slots(date, uuid, uuid, int);
DROP FUNCTION IF EXISTS public.get_available_slots(date, uuid, uuid, int, int);
DROP FUNCTION IF EXISTS public.get_available_slots(date, uuid);
DROP FUNCTION IF EXISTS public.get_available_slots(date, uuid, int);

CREATE OR REPLACE FUNCTION public.get_available_slots(
  p_date           date,
  p_service_id     uuid,
  p_staff_id       uuid  DEFAULT NULL,
  p_max_per_slot   int   DEFAULT 20,
  p_total_duration int   DEFAULT NULL  -- total durasi semua layanan (multi-layanan)
)
RETURNS TABLE(
  slot_time       time,
  available_count int,
  is_available    boolean,
  reason          text
) AS $$
DECLARE
  v_day_of_week      int;
  v_open_time        time;
  v_close_time       time;
  v_slot_duration    int;
  v_service_duration int;
  v_effective_dur    int;
  v_current_slot     time;
  v_booked_count     int;
  v_staff_booked     int;
  v_now              time;
  v_today            date;
  v_buffer_min       int := 30;  -- buffer 30 menit dari sekarang
BEGIN
  -- Hari dalam minggu
  v_day_of_week := EXTRACT(DOW FROM p_date)::int;

  -- Jam operasional
  SELECT open_time, close_time, slot_duration_minutes
  INTO v_open_time, v_close_time, v_slot_duration
  FROM public.working_hours
  WHERE day_of_week = v_day_of_week AND is_open = true;

  IF NOT FOUND THEN RETURN; END IF;  -- hari tutup

  -- Tanggal libur
  IF EXISTS (SELECT 1 FROM public.blocked_dates WHERE blocked_date = p_date) THEN
    RETURN;
  END IF;

  -- Durasi layanan utama (fallback)
  SELECT duration_minutes INTO v_service_duration
  FROM public.services WHERE id = p_service_id;

  -- Efektif: pakai total_duration jika dikirim (multi-layanan)
  v_effective_dur := COALESCE(p_total_duration, v_service_duration);

  -- Waktu sekarang dalam WIB
  v_now   := (NOW() AT TIME ZONE 'Asia/Jakarta')::time;
  v_today := (NOW() AT TIME ZONE 'Asia/Jakarta')::date;

  v_current_slot := v_open_time;

  WHILE v_current_slot + (v_effective_dur || ' minutes')::interval <= v_close_time LOOP

    -- Hitung booking yang overlap dengan slot ini (semua staff)
    -- Overlap: booking_start < slot_end DAN booking_end > slot_start
    SELECT COALESCE(COUNT(*), 0) INTO v_booked_count
    FROM public.bookings b
    JOIN public.services s ON s.id = b.service_id
    WHERE b.booking_date = p_date
      AND b.status NOT IN ('cancelled', 'no_show')
      AND b.booking_time < (v_current_slot + (v_effective_dur || ' minutes')::interval)
      AND (b.booking_time + (COALESCE(b.total_duration, s.duration_minutes) || ' minutes')::interval)
          > v_current_slot;

    -- Hitung konflik staff tertentu
    v_staff_booked := 0;
    IF p_staff_id IS NOT NULL THEN
      SELECT COALESCE(COUNT(*), 0) INTO v_staff_booked
      FROM public.bookings b
      JOIN public.services s ON s.id = b.service_id
      WHERE b.booking_date = p_date
        AND b.staff_id = p_staff_id
        AND b.status NOT IN ('cancelled', 'no_show')
        AND b.booking_time < (v_current_slot + (v_effective_dur || ' minutes')::interval)
        AND (b.booking_time + (COALESCE(b.total_duration, s.duration_minutes) || ' minutes')::interval)
            > v_current_slot;
    END IF;

    slot_time       := v_current_slot;
    available_count := p_max_per_slot - v_booked_count;

    -- Tentukan ketersediaan slot
    IF p_date < v_today THEN
      -- Tanggal sudah lewat
      is_available := false;
      reason       := 'Tanggal sudah lewat';

    ELSIF p_date = v_today
      AND (v_current_slot + (v_effective_dur || ' minutes')::interval)
          <= (v_now + (v_buffer_min || ' minutes')::interval) THEN
      -- Jam + durasi sudah lewat batas (sekarang + buffer)
      is_available := false;
      reason       := 'Waktu sudah lewat';

    ELSIF v_booked_count >= p_max_per_slot THEN
      -- Slot penuh
      is_available := false;
      reason       := 'Penuh';

    ELSIF p_staff_id IS NOT NULL AND v_staff_booked > 0 THEN
      -- Stylist sudah ada booking yang overlap
      is_available := false;
      reason       := 'Stylist tidak tersedia';

    ELSE
      is_available := true;
      reason       := NULL;
    END IF;

    RETURN NEXT;

    v_current_slot := v_current_slot + (v_slot_duration || ' minutes')::interval;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- SELESAI ✅
-- Cara verifikasi — jalankan query ini setelah import:
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' ORDER BY table_name;
--
-- Harusnya ada: blocked_dates, booking_services, bookings,
-- notifications, profiles, reviews, services, staff,
-- vouchers, working_hours
--
-- Setelah import, ubah role akun admin:
-- UPDATE public.profiles SET role = 'admin'
-- WHERE id = (SELECT id FROM auth.users WHERE email = 'emailkamu@gmail.com');
-- ============================================================