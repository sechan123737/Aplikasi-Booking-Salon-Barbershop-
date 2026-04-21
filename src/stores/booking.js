// src/stores/booking.js
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useBookingStore = defineStore('booking', () => {
  const bookings = ref([])
  const loading = ref(false)

  // ── USER ───────────────────────────────────────────────────────
  async function fetchMyBookings(userId) {
    loading.value = true
    const { data, error } = await supabase
      .from('bookings')
      .select(`*, services(*), staff(*), reviews(*)`)
      .eq('user_id', userId)
      .order('booking_date', { ascending: false })
      .order('booking_time', { ascending: false })
    loading.value = false
    if (error) throw error
    bookings.value = data
    return data
  }

  async function createBooking(payload) {
    const { data, error } = await supabase
      .from('bookings')
      .insert(payload)
      .select(`*, services(*), staff(*)`)
      .single()
    if (error) throw error
    return data
  }

  async function cancelBooking(bookingId) {
    const { data, error } = await supabase
      .from('bookings')
      .update({ status: 'cancelled', updated_at: new Date().toISOString() })
      .eq('id', bookingId)
      .select()
      .single()
    if (error) throw error
    const idx = bookings.value.findIndex(b => b.id === bookingId)
    if (idx !== -1) bookings.value[idx] = { ...bookings.value[idx], ...data }
    return data
  }

  async function getAvailableSlots(date, serviceId) {
    const { data, error } = await supabase
      .rpc('get_available_slots', {
        p_date: date,
        p_service_id: serviceId,
        p_max_per_slot: 2
      })
    if (error) throw error
    return data
  }

  // ── ADMIN ──────────────────────────────────────────────────────
  async function fetchAllBookings(filters = {}) {
    loading.value = true
    let query = supabase
      .from('bookings')
      .select(`*, services(*), staff(*), profiles(*)`)
      .order('booking_date', { ascending: false })
      .order('booking_time', { ascending: false })

    if (filters.status) query = query.eq('status', filters.status)
    if (filters.date) query = query.eq('booking_date', filters.date)
    if (filters.staffId) query = query.eq('staff_id', filters.staffId)

    const { data, error } = await query
    loading.value = false
    if (error) throw error
    bookings.value = data
    return data
  }

  async function updateBookingStatus(bookingId, status, adminNotes = '') {
    const updates = { status, updated_at: new Date().toISOString() }
    if (adminNotes) updates.admin_notes = adminNotes
    const { data, error } = await supabase
      .from('bookings')
      .update(updates)
      .eq('id', bookingId)
      .select()
      .single()
    if (error) throw error
    const idx = bookings.value.findIndex(b => b.id === bookingId)
    if (idx !== -1) bookings.value[idx] = { ...bookings.value[idx], ...data }
    return data
  }

  async function adminUpdateBooking(bookingId, payload) {
    const { data, error } = await supabase
      .from('bookings')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', bookingId)
      .select(`*, services(*), staff(*)`)
      .single()
    if (error) throw error
    return data
  }

  async function deleteBooking(bookingId) {
    const { error } = await supabase
      .from('bookings')
      .delete()
      .eq('id', bookingId)
    if (error) throw error
    bookings.value = bookings.value.filter(b => b.id !== bookingId)
  }

  return {
    bookings, loading,
    fetchMyBookings, createBooking, cancelBooking, getAvailableSlots,
    fetchAllBookings, updateBookingStatus, adminUpdateBooking, deleteBooking
  }
})
