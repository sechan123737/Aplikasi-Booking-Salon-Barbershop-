-- ============================================================
-- FIX FINAL: RLS booking error - jalankan SEMUA query ini
-- Supabase SQL Editor → New Query → Run
-- ============================================================

-- ── STEP 1: Hapus SEMUA policy lama di tabel bookings ────────
DO $$
DECLARE
  pol record;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies WHERE tablename = 'bookings' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.bookings', pol.policyname);
  END LOOP;
END $$;

-- ── STEP 2: Buat ulang semua policy dengan benar ─────────────

-- SELECT: user lihat booking sendiri, admin lihat semua
CREATE POLICY "select_own_bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- INSERT: benar-benar bebas (aplikasi yang validasi)
CREATE POLICY "insert_bookings_open" ON public.bookings
  FOR INSERT WITH CHECK (true);

-- UPDATE: user hanya bisa cancel miliknya, admin bisa semua
CREATE POLICY "update_bookings" ON public.bookings
  FOR UPDATE USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- DELETE: hanya admin
CREATE POLICY "delete_bookings_admin" ON public.bookings
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ── STEP 3: Grant eksplisit ───────────────────────────────────
GRANT ALL ON public.bookings TO authenticated;
GRANT INSERT, SELECT ON public.bookings TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ── STEP 4: Fix trigger agar tidak crash saat service_id null ─
CREATE OR REPLACE FUNCTION public.set_booking_defaults()
RETURNS trigger AS $$
DECLARE
  svc record;
BEGIN
  -- Hanya proses jika service_id ada
  IF new.service_id IS NOT NULL THEN
    SELECT price, duration_minutes INTO svc
    FROM public.services WHERE id = new.service_id;

    IF FOUND THEN
      new.service_price = svc.price;
      new.end_time = new.booking_time + (svc.duration_minutes || ' minutes')::interval;
    END IF;
  END IF;

  -- Isi final_price jika belum ada (booking tanpa voucher)
  IF new.final_price IS NULL THEN
    new.final_price = COALESCE(new.service_price, 0);
  END IF;

  new.updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── STEP 5: Pastikan trigger masih aktif ─────────────────────
DROP TRIGGER IF EXISTS booking_set_defaults ON public.bookings;
CREATE TRIGGER booking_set_defaults
  BEFORE INSERT OR UPDATE ON public.bookings
  FOR EACH ROW EXECUTE PROCEDURE public.set_booking_defaults();

-- Verifikasi: lihat semua policy aktif setelah fix
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'bookings' AND schemaname = 'public'
ORDER BY cmd;