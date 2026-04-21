// supabase/functions/send-reminders/index.ts
// Edge Function ini berjalan via Supabase Cron (setiap hari jam 18:00)
// Setup: supabase functions deploy send-reminders
// Aktifkan cron di Supabase Dashboard > Edge Functions > Schedules

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async () => {
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate() + 1)
  const tomorrowStr = tomorrow.toISOString().split('T')[0]

  const { data: bookings } = await supabase
    .from('bookings')
    .select('id, booking_code, user_id, booking_time, customer_name')
    .eq('booking_date', tomorrowStr)
    .in('status', ['pending', 'confirmed'])
    .eq('reminder_sent', false)
    .not('user_id', 'is', null)

  let sent = 0
  for (const b of bookings ?? []) {
    const { error } = await supabase.from('notifications').insert({
      user_id: b.user_id,
      booking_id: b.id,
      type: 'booking_reminder',
      title: '🔔 Reminder Booking Besok',
      message: `Halo ${b.customer_name}! Booking #${b.booking_code} Anda besok pukul ${b.booking_time?.slice(0,5)}. Kami menunggu kedatangan Anda!`
    })
    if (!error) {
      await supabase.from('bookings').update({ reminder_sent: true }).eq('id', b.id)
      sent++
    }
  }

  return new Response(JSON.stringify({ sent }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
