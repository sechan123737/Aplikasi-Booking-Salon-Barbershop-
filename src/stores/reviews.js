// src/stores/reviews.js
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useReviewsStore = defineStore('reviews', () => {
  const reviews = ref([])
  const loading = ref(false)

  async function fetchReviews(serviceId = null) {
    loading.value = true
    let query = supabase
      .from('reviews')
      .select(`*, profiles(full_name, avatar_url), services(name), staff(name)`)
      .eq('is_public', true)
      .order('created_at', { ascending: false })
    if (serviceId) query = query.eq('service_id', serviceId)
    const { data, error } = await query
    loading.value = false
    if (error) throw error
    reviews.value = data
    return data
  }

  async function fetchAllReviews() {
    loading.value = true
    const { data, error } = await supabase
      .from('reviews')
      .select(`*, profiles(full_name), services(name), staff(name), bookings(booking_code)`)
      .order('created_at', { ascending: false })
    loading.value = false
    if (error) throw error
    reviews.value = data
    return data
  }

  async function createReview(payload) {
    const { data, error } = await supabase
      .from('reviews').insert(payload).select().single()
    if (error) throw error
    reviews.value.unshift(data)
    return data
  }

  async function deleteReview(id) {
    const { error } = await supabase.from('reviews').delete().eq('id', id)
    if (error) throw error
    reviews.value = reviews.value.filter(r => r.id !== id)
  }

  async function toggleReviewVisibility(id, isPublic) {
    const { data, error } = await supabase
      .from('reviews').update({ is_public: isPublic }).eq('id', id).select().single()
    if (error) throw error
    const idx = reviews.value.findIndex(r => r.id === id)
    if (idx !== -1) reviews.value[idx] = data
    return data
  }

  return { reviews, loading, fetchReviews, fetchAllReviews, createReview, deleteReview, toggleReviewVisibility }
})
