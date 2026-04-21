// src/composables/useBookingReminder.js
// Composable untuk mengirim reminder booking H-1 via notifikasi
// Dijalankan via Supabase Edge Function / cron, tapi bisa juga dipanggil manual dari admin

import { supabase } from '@/lib/supabase'

export function useBookingReminder() {
  /**
   * Ambil semua booking besok yang belum di-remind,
   * lalu insert notifikasi reminder untuk masing-masing.
   * Panggil fungsi ini dari AdminDashboard atau Supabase Edge Function.
   */
  async function sendTomorrowReminders() {
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const tomorrowStr = tomorrow.toISOString().split('T')[0]

    // Ambil booking besok yang status confirmed / pending dan belum di-remind
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select('id, booking_code, user_id, booking_time, customer_name')
      .eq('booking_date', tomorrowStr)
      .in('status', ['pending', 'confirmed'])
      .eq('reminder_sent', false)
      .not('user_id', 'is', null)

    if (error) {
      console.error('Reminder fetch error:', error)
      return { sent: 0, error }
    }

    let sent = 0
    for (const booking of bookings || []) {
      // Insert notifikasi reminder
      const { error: notifError } = await supabase
        .from('notifications')
        .insert({
          user_id: booking.user_id,
          booking_id: booking.id,
          type: 'booking_reminder',
          title: '🔔 Reminder Booking Besok',
          message: `Halo ${booking.customer_name}! Jangan lupa booking #${booking.booking_code} Anda besok pukul ${booking.booking_time?.slice(0,5)}. Kami menunggu kedatangan Anda!`
        })

      if (!notifError) {
        // Tandai sudah di-remind
        await supabase
          .from('bookings')
          .update({ reminder_sent: true })
          .eq('id', booking.id)
        sent++
      }
    }

    console.log(`✅ ${sent} reminder berhasil dikirim`)
    return { sent, error: null }
  }

  /**
   * Trigger browser Notification API untuk reminder real-time
   * (hanya berfungsi jika user mengizinkan notifikasi browser)
   */
  async function requestBrowserPermission() {
    if (!('Notification' in window)) return false
    if (Notification.permission === 'granted') return true
    const permission = await Notification.requestPermission()
    return permission === 'granted'
  }

  function showBrowserNotif(title, body, icon = '/favicon.svg') {
    if (Notification.permission !== 'granted') return
    new Notification(title, { body, icon })
  }

  return { sendTomorrowReminders, requestBrowserPermission, showBrowserNotif }
}
