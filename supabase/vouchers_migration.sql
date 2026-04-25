-- ============================================================
-- MIGRATION: Tambah Fitur Voucher Diskon
-- Jalankan query ini di Supabase SQL Editor
-- ============================================================

-- ── 1. TABEL VOUCHERS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vouchers (
  id             uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  code           text NOT NULL UNIQUE,               -- kode unik, huruf kapital
  name           text,                               -- nama/deskripsi voucher
  discount_type  text NOT NULL DEFAULT 'percent'
                   CHECK (discount_type IN ('percent', 'fixed')),
  discount_value numeric(10,2) NOT NULL,             -- nilai diskon (% atau Rp)
  max_discount   numeric(10,2),                      -- batas maks diskon (khusus persen)
  min_purchase   numeric(10,2),                      -- minimum harga layanan
  valid_from     date,                               -- mulai berlaku
  valid_until    date,                               -- sampai tanggal
  max_uses       int,                                -- batas total pemakaian (null = tak terbatas)
  used_count     int NOT NULL DEFAULT 0,             -- sudah dipakai berapa kali
  is_active      boolean NOT NULL DEFAULT true,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

-- Row-level security
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;

-- Admin bisa semua
CREATE POLICY "Admins can manage vouchers" ON public.vouchers
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Semua orang (termasuk guest/anon) bisa SELECT voucher aktif
-- Ini penting agar banner promo & validasi booking bisa berjalan tanpa login
CREATE POLICY "Anyone can view active vouchers" ON public.vouchers
  FOR SELECT USING (true);

-- ── 2. TAMBAH KOLOM KE TABEL BOOKINGS ────────────────────────
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS voucher_code    text,
  ADD COLUMN IF NOT EXISTS discount_amount numeric(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS final_price     numeric(10,2);

-- ── 3. FUNCTION: increment used_count ────────────────────────
CREATE OR REPLACE FUNCTION public.increment_voucher_usage(v_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.vouchers
  SET used_count = used_count + 1,
      updated_at = now()
  WHERE id = v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 4. SAMPLE VOUCHERS (opsional, bisa dihapus) ──────────────
INSERT INTO public.vouchers (code, name, discount_type, discount_value, max_discount, min_purchase, valid_until, max_uses)
VALUES
  ('WELCOME10',   'Diskon Pelanggan Baru 10%',      'percent', 10,    20000, 30000,  now() + interval '90 days', 100),
  ('DISKON20',    'Promo 20% Semua Layanan',          'percent', 20,    50000, 50000,  now() + interval '30 days', 50),
  ('HEMAT50K',    'Potongan Rp 50.000',               'fixed',   50000, null,  100000, now() + interval '30 days', 30),
  ('RAMBUT15',    'Diskon 15% Layanan Rambut',        'percent', 15,    30000, 25000,  now() + interval '60 days', null),
  ('FLASHSALE',   'Flash Sale Rp 25.000',             'fixed',   25000, null,  null,   now() + interval '7 days',  20)
ON CONFLICT (code) DO NOTHING;

-- ── 5. INDEX ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_vouchers_code ON public.vouchers(code);
CREATE INDEX IF NOT EXISTS idx_vouchers_active ON public.vouchers(is_active);
