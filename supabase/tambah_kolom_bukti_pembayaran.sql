-- ================================================================
-- JALANKAN FILE INI DI: Supabase Dashboard → SQL Editor → Run
-- ================================================================
-- Cek dulu apakah kolom sudah ada atau belum
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
  AND column_name IN ('payment_status', 'payment_method', 'payment_proof', 'paid_at');

-- ================================================================
-- MIGRATION: Tambah kolom pembayaran ke tabel bookings
-- (IF NOT EXISTS = aman dijalankan berkali-kali)
-- ================================================================
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'waiting_verification', 'paid', 'failed')),
  ADD COLUMN IF NOT EXISTS payment_method text,
  ADD COLUMN IF NOT EXISTS payment_proof  text,
  ADD COLUMN IF NOT EXISTS paid_at        timestamptz;

-- Index biar query payment_status cepat
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status
  ON public.bookings(payment_status);

-- ================================================================
-- Storage bucket untuk bukti transfer
-- ================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', true)
ON CONFLICT (id) DO NOTHING;

-- Policy storage (skip jika sudah ada)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can upload payment proof'
  ) THEN
    CREATE POLICY "Users can upload payment proof"
      ON storage.objects FOR INSERT
      WITH CHECK (bucket_id = 'payment-proofs');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Anyone can view payment proof'
  ) THEN
    CREATE POLICY "Anyone can view payment proof"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'payment-proofs');
  END IF;
END $$;

-- ================================================================
-- VERIFIKASI: jalankan ini setelah migration untuk memastikan berhasil
-- ================================================================
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
  AND column_name IN ('payment_status', 'payment_method', 'payment_proof', 'paid_at')
ORDER BY column_name;
-- Harusnya muncul 4 baris. Kalau muncul 4 baris → BERHASIL ✅