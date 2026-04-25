// src/stores/vouchers.js
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useVoucherStore = defineStore('vouchers', () => {
  const vouchers = ref([])       // dipakai admin (semua voucher)
  const activePromos = ref([])   // dipakai HomeView (hanya yang benar-benar aktif)
  const loading = ref(false)

  // ── ADMIN ──────────────────────────────────────────────────
  async function fetchAllVouchers() {
    loading.value = true
    const { data, error } = await supabase
      .from('vouchers')
      .select('*')
      .order('created_at', { ascending: false })
    loading.value = false
    if (error) throw error
    vouchers.value = data
    return data
  }

  async function createVoucher(payload) {
    const { data, error } = await supabase
      .from('vouchers')
      .insert(payload)
      .select()
      .single()
    if (error) throw error
    vouchers.value.unshift(data)
    return data
  }

  async function updateVoucher(id, payload) {
    const { data, error } = await supabase
      .from('vouchers')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    const idx = vouchers.value.findIndex(v => v.id === id)
    if (idx !== -1) vouchers.value[idx] = data
    return data
  }

  async function deleteVoucher(id) {
    const { error } = await supabase
      .from('vouchers')
      .delete()
      .eq('id', id)
    if (error) throw error
    vouchers.value = vouchers.value.filter(v => v.id !== id)
  }

  // ── PUBLIC ─────────────────────────────────────────────────
  // Khusus untuk banner promo di HomeView — aman untuk semua user
  async function fetchActiveVouchers() {
    const now = new Date().toISOString().split('T')[0]
    const { data } = await supabase
      .from('vouchers')
      .select('*')
      .eq('is_active', true)
      .or(`valid_until.is.null,valid_until.gte.${now}`)
      .or(`valid_from.is.null,valid_from.lte.${now}`)
      .order('created_at', { ascending: false })

    const raw = data || []

    // Filter ketat di sisi client: pastikan quota belum habis
    activePromos.value = raw.filter(v => {
      if (!v.is_active) return false
      const today = new Date()
      if (v.valid_from && new Date(v.valid_from) > today) return false
      if (v.valid_until && new Date(v.valid_until) < today) return false
      if (v.max_uses !== null && v.used_count >= v.max_uses) return false
      return true
    })

    return activePromos.value
  }


  async function validateVoucher(code, servicePrice) {
    const { data, error } = await supabase
      .from('vouchers')
      .select('*')
      .eq('code', code.toUpperCase().trim())
      .eq('is_active', true)
      .single()

    if (error || !data) throw new Error('Kode voucher tidak valid atau sudah tidak aktif.')

    const now = new Date()
    if (data.valid_from && new Date(data.valid_from) > now)
      throw new Error('Voucher belum berlaku.')
    if (data.valid_until && new Date(data.valid_until) < now)
      throw new Error('Voucher sudah kedaluwarsa.')
    if (data.max_uses !== null && data.used_count >= data.max_uses)
      throw new Error('Voucher sudah mencapai batas penggunaan.')
    if (data.min_purchase !== null && servicePrice < data.min_purchase)
      throw new Error(`Minimum pembelian Rp ${Number(data.min_purchase).toLocaleString('id-ID')} untuk voucher ini.`)

    // Hitung diskon
    let discountAmount = 0
    if (data.discount_type === 'percent') {
      discountAmount = Math.round(servicePrice * data.discount_value / 100)
      if (data.max_discount !== null) discountAmount = Math.min(discountAmount, data.max_discount)
    } else {
      discountAmount = Math.min(data.discount_value, servicePrice)
    }

    return { voucher: data, discountAmount }
  }

  async function incrementVoucherUsage(voucherId) {
    const { error } = await supabase.rpc('increment_voucher_usage', { v_id: voucherId })
    if (error) console.error('Gagal update usage voucher:', error)
  }

  return {
    vouchers, activePromos, loading,
    fetchAllVouchers, fetchActiveVouchers,
    createVoucher, updateVoucher, deleteVoucher,
    validateVoucher, incrementVoucherUsage
  }
})
