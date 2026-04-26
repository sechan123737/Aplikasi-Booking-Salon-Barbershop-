-- ============================================================
-- FIX: Trigger booking_set_defaults tidak boleh overwrite final_price
-- Jalankan query ini di Supabase SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_booking_defaults()
RETURNS trigger AS $$
DECLARE
  svc record;
BEGIN
  -- Ambil data layanan pertama (untuk end_time & fallback service_price)
  SELECT price, duration_minutes INTO svc
  FROM public.services
  WHERE id = new.service_id;

  -- Set service_price dari layanan pertama (harga sebelum diskon)
  new.service_price = svc.price;

  -- Set end_time berdasarkan durasi layanan pertama
  new.end_time = new.booking_time + (svc.duration_minutes || ' minutes')::interval;

  -- Jika final_price belum diset (booking tanpa voucher), isi dengan service_price
  -- JANGAN overwrite final_price kalau sudah diisi dari frontend (sudah ada diskon)
  IF new.final_price IS NULL THEN
    new.final_price = new.service_price;
  END IF;

  new.updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
