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
      .select(`*, services(*), staff(*), reviews(*), booking_services(*, services(*))`)
      .eq('user_id', userId)
      .order('booking_date', { ascending: false })
      .order('booking_time', { ascending: false })
    loading.value = false
    if (error) throw error
    bookings.value = data
    return data
  }

  async function createBooking(payload) {
    // Pisahkan service_ids dari payload utama
    // Pisahkan field yang tidak ada di tabel bookings
    const { service_ids, services_price, service_price, ...bookingPayload } = payload

    // service_id (kolom lama) tetap diisi dengan yang pertama
    bookingPayload.service_id = service_ids?.[0] || null

    const { data, error } = await supabase
      .from('bookings')
      .insert(bookingPayload)
      .select(`*, services(*), staff(*)`)
      .single()
    if (error) throw error

    // Insert semua layanan ke booking_services
    if (service_ids && service_ids.length > 0) {
      const bsRows = service_ids.map(sid => ({
        booking_id: data.id,
        service_id: sid,
        price: services_price?.[sid] || 0,
      }))
      const { error: bsError } = await supabase
        .from('booking_services')
        .insert(bsRows)
      if (bsError) console.error('booking_services insert error:', bsError)
    }

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
        p_max_per_slot: 20
      })
    if (error) throw error
    return data
  }

  // ── ADMIN ──────────────────────────────────────────────────────
  async function fetchAllBookings(filters = {}) {
    loading.value = true
    let query = supabase
      .from('bookings')
      .select(`*, services(*), staff(*), profiles(*), booking_services(*, services(*))`)
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