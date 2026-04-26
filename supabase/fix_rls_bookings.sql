-- ============================================================
-- FIX: RLS Policy "new row violates row-level security policy"
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Hapus policy INSERT lama yang mungkin conflict
DROP POLICY IF EXISTS "Users can create bookings" ON public.bookings;

-- 2. Buat ulang policy INSERT yang benar
-- Izinkan user yang sudah login MAUPUN guest (anon) untuk buat booking
CREATE POLICY "Users can create bookings" ON public.bookings
  FOR INSERT
  WITH CHECK (
    -- User login: user_id harus milik sendiri
    (auth.uid() IS NOT NULL AND auth.uid() = user_id)
    OR
    -- Guest booking: user_id boleh null
    (user_id IS NULL)
  );

-- 3. Pastikan anon role punya akses INSERT ke tabel bookings
GRANT INSERT ON public.bookings TO anon, authenticated;

-- 4. Pastikan sequence/id bisa diakses
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
