-- ============================================================
-- MIGRATION: Fitur Pengembalian Dana (Refund)
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Tambah kolom refund ke tabel bookings
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS refund_status  text DEFAULT NULL
    CHECK (refund_status IN ('requested', 'approved', 'rejected', 'completed')),
  ADD COLUMN IF NOT EXISTS refund_amount  numeric(10,2) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_method  text DEFAULT NULL,  -- rekening/ewallet info
  ADD COLUMN IF NOT EXISTS refund_notes   text DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_at      timestamptz DEFAULT NULL;

-- 2. Tambah tipe notif baru untuk refund
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN (
    'booking_confirmed', 'booking_reminder', 'booking_cancelled',
    'booking_completed', 'payment_rejected',
    'refund_requested', 'refund_approved', 'refund_rejected', 'refund_completed'
  ));

-- 3. Index
CREATE INDEX IF NOT EXISTS idx_bookings_refund_status ON public.bookings(refund_status);