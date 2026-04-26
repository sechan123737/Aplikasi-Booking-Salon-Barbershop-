-- ============================================================
-- FIX: Izinkan user hapus booking milik sendiri yang sudah cancelled
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- Tambah policy DELETE untuk user
DROP POLICY IF EXISTS "Users can delete own cancelled bookings" ON public.bookings;

CREATE POLICY "Users can delete own cancelled bookings"
  ON public.bookings
  FOR DELETE
  USING (
    auth.uid() = user_id
    AND status = 'cancelled'
  );

-- Pastikan authenticated punya hak DELETE
GRANT DELETE ON public.bookings TO authenticated;