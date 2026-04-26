-- ============================================================
-- MIGRATION: Fitur Pembayaran Manual
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- Tambah kolom pembayaran ke tabel bookings
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS payment_status  text DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'waiting_verification', 'paid', 'failed')),
  ADD COLUMN IF NOT EXISTS payment_method  text,
  ADD COLUMN IF NOT EXISTS payment_proof   text,   -- URL bukti transfer
  ADD COLUMN IF NOT EXISTS paid_at         timestamptz;

-- Buat bucket storage untuk bukti pembayaran
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', true)
ON CONFLICT (id) DO NOTHING;

-- Policy storage: siapa saja bisa upload
CREATE POLICY "Users can upload payment proof" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'payment-proofs');

-- Policy storage: siapa saja bisa lihat
CREATE POLICY "Anyone can view payment proof" ON storage.objects
  FOR SELECT USING (bucket_id = 'payment-proofs');

-- Index
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON public.bookings(payment_status);
