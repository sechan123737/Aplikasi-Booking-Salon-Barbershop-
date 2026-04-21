// src/stores/notifications.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useNotificationsStore = defineStore('notifications', () => {
  const notifications = ref([])
  const loading = ref(false)

  const unreadCount = computed(() => notifications.value.filter(n => !n.is_read).length)

  async function fetchNotifications(userId) {
    loading.value = true
    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(50)
    loading.value = false
    if (error) throw error
    notifications.value = data
    return data
  }

  async function markAsRead(id) {
    const { error } = await supabase
      .from('notifications').update({ is_read: true }).eq('id', id)
    if (!error) {
      const idx = notifications.value.findIndex(n => n.id === id)
      if (idx !== -1) notifications.value[idx].is_read = true
    }
  }

  async function markAllAsRead(userId) {
    const { error } = await supabase
      .from('notifications').update({ is_read: true }).eq('user_id', userId).eq('is_read', false)
    if (!error) notifications.value.forEach(n => n.is_read = true)
  }

  // Push notification ke user setelah booking
  async function sendBookingNotification(userId, bookingId, type, bookingCode) {
    const messages = {
      booking_confirmed: {
        title: '✅ Booking Dikonfirmasi',
        message: `Booking #${bookingCode} Anda telah dikonfirmasi. Kami menunggu kedatangan Anda!`
      },
      booking_reminder: {
        title: '🔔 Reminder Booking',
        message: `Jangan lupa! Booking #${bookingCode} Anda adalah hari ini. Sampai jumpa!`
      },
      booking_cancelled: {
        title: '❌ Booking Dibatalkan',
        message: `Booking #${bookingCode} telah dibatalkan.`
      },
      booking_completed: {
        title: '⭐ Booking Selesai',
        message: `Terima kasih! Booking #${bookingCode} selesai. Mohon tinggalkan ulasan Anda.`
      }
    }
    const msg = messages[type]
    if (!msg) return

    const { error } = await supabase.from('notifications').insert({
      user_id: userId,
      booking_id: bookingId,
      type,
      title: msg.title,
      message: msg.message
    })
    if (error) console.error('Notification error:', error)
  }

  // Real-time subscription
  function subscribeToNotifications(userId) {
    return supabase
      .channel(`notifications:${userId}`)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: `user_id=eq.${userId}`
      }, (payload) => {
        notifications.value.unshift(payload.new)
      })
      .subscribe()
  }

  return {
    notifications, loading, unreadCount,
    fetchNotifications, markAsRead, markAllAsRead,
    sendBookingNotification, subscribeToNotifications
  }
})
