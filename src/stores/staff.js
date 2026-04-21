// src/stores/staff.js
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useStaffStore = defineStore('staff', () => {
  const staff = ref([])
  const loading = ref(false)

  async function fetchStaff(onlyActive = true) {
    loading.value = true
    let query = supabase.from('staff').select('*').order('name')
    if (onlyActive) query = query.eq('is_active', true)
    const { data, error } = await query
    loading.value = false
    if (error) throw error
    staff.value = data
    return data
  }

  async function createStaff(payload) {
    const { data, error } = await supabase
      .from('staff').insert(payload).select().single()
    if (error) throw error
    staff.value.push(data)
    return data
  }

  async function updateStaff(id, payload) {
    const { data, error } = await supabase
      .from('staff')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id).select().single()
    if (error) throw error
    const idx = staff.value.findIndex(s => s.id === id)
    if (idx !== -1) staff.value[idx] = data
    return data
  }

  async function deleteStaff(id) {
    const { error } = await supabase.from('staff').delete().eq('id', id)
    if (error) throw error
    staff.value = staff.value.filter(s => s.id !== id)
  }

  return { staff, loading, fetchStaff, createStaff, updateStaff, deleteStaff }
})
