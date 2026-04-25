-- ============================================================
-- HOTFIX (AMAN): Nama reviewer tampil "Anonim"
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- Solusi aman: buat view khusus yang HANYA expose
-- full_name dan avatar_url — phone/email/role TIDAK terekspos
CREATE OR REPLACE VIEW public.profiles_public AS
  SELECT id, full_name, avatar_url
  FROM public.profiles;

-- Izinkan semua orang baca view ini (bukan tabel aslinya)
GRANT SELECT ON public.profiles_public TO anon, authenticated;

-- Tabel profiles asli tidak diubah — tetap aman seperti semula
