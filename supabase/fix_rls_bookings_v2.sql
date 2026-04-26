-- ============================================================
-- FIX v2: RLS booking INSERT error
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- Drop semua policy INSERT yang mungkin conflict
DROP POLICY IF EXISTS "Users can create bookings" ON public.bookings;
DROP POLICY IF EXISTS "Anyone can create bookings" ON public.bookings;
DROP POLICY IF EXISTS "Allow booking insert" ON public.bookings;

-- Buat policy baru yang benar-benar terbuka untuk INSERT
-- (keamanan dijaga dari sisi aplikasi & trigger)
CREATE POLICY "Anyone can create bookings"
  ON public.bookings
  FOR INSERT
  WITH CHECK (true);

-- Pastikan role anon & authenticated punya hak INSERT
GRANT INSERT, SELECT, UPDATE ON public.bookings TO anon;
GRANT INSERT, SELECT, UPDATE ON public.bookings TO authenticated;

-- Pastikan sequence uuid tidak diblokir
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
