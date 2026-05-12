// src/stores/services.js
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useServicesStore = defineStore('services', () => {
  const services = ref([])
  const loading  = ref(false)
  const lastFetched = ref(null)
  const CACHE_TTL = 5 * 60 * 1000 // 5 menit

  async function fetchServices(onlyActive = true, force = false) {
    // Gunakan cache jika data sudah ada dan belum expired
    const now = Date.now()
    if (
      !force &&
      services.value.length > 0 &&
      lastFetched.value &&
      (now - lastFetched.value) < CACHE_TTL
    ) {
      return services.value
    }

    loading.value = true
    let query = supabase.from('services').select('*').order('category').order('name')
    if (onlyActive) query = query.eq('is_active', true)
    const { data, error } = await query
    loading.value = false
    if (error) throw error
    services.value = data
    lastFetched.value = Date.now()
    return data
  }

  async function createService(payload) {
    const { data, error } = await supabase
      .from('services').insert(payload).select().single()
    if (error) throw error
    services.value.push(data)
    return data
  }

  async function updateService(id, payload) {
    const { data, error } = await supabase
      .from('services')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id).select().single()
    if (error) throw error
    const idx = services.value.findIndex(s => s.id === id)
    if (idx !== -1) services.value[idx] = data
    return data
  }

  async function deleteService(id) {
    const { error } = await supabase.from('services').delete().eq('id', id)
    if (error) throw error
    services.value = services.value.filter(s => s.id !== id)
    lastFetched.value = null // reset cache setelah delete
  }

  return { services, loading, lastFetched, fetchServices, createService, updateService, deleteService }
})