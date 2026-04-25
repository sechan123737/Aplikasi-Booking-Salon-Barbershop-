-- ============================================================
-- MIGRATION: Multi-Layanan per Booking
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Tabel junction booking_services
CREATE TABLE IF NOT EXISTS public.booking_services (
  id         uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  booking_id uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  price      numeric(10,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(booking_id, service_id)
);

ALTER TABLE public.booking_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own booking services" ON public.booking_services
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bookings
      WHERE id = booking_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage booking services" ON public.booking_services
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Anyone can insert booking services" ON public.booking_services
  FOR INSERT WITH CHECK (true);

-- 2. Migrate data lama: salin service_id lama ke tabel baru
INSERT INTO public.booking_services (booking_id, service_id, price)
SELECT b.id, b.service_id, COALESCE(s.price, 0)
FROM public.bookings b
JOIN public.services s ON s.id = b.service_id
WHERE b.service_id IS NOT NULL
ON CONFLICT (booking_id, service_id) DO NOTHING;

-- 3. Index
CREATE INDEX IF NOT EXISTS idx_booking_services_booking ON public.booking_services(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_services_service ON public.booking_services(service_id);
