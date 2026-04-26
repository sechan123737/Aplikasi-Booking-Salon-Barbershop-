// src/stores/payment.js
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const usePaymentStore = defineStore('payment', () => {
  const uploading = ref(false)

  // Upload bukti pembayaran ke Supabase Storage
  async function uploadProof(bookingId, file) {
    uploading.value = true
    try {
      const ext  = file.name.split('.').pop()
      const path = `${bookingId}/${Date.now()}.${ext}`

      const { error: uploadErr } = await supabase.storage
        .from('payment-proofs')
        .upload(path, file, { upsert: true })
      if (uploadErr) throw uploadErr

      const { data: urlData } = supabase.storage
        .from('payment-proofs')
        .getPublicUrl(path)

      return urlData.publicUrl
    } finally {
      uploading.value = false
    }
  }

  // Simpan metode + bukti bayar
  // COD → status booking langsung 'confirmed', payment_status 'unpaid' (bayar nanti di tempat)
  // Transfer/QRIS/GoPay → waiting_verification (tunggu admin konfirmasi bukti)
  async function submitPayment(bookingId, method, proofUrl = null) {
    const isCod = method === 'cod'
    const updates = {
      payment_method: method,
      payment_status: isCod ? 'unpaid' : 'waiting_verification',
      updated_at:     new Date().toISOString(),
      // status tetap 'pending' — admin konfirmasi manual via halaman admin
    }
    if (proofUrl) updates.payment_proof = proofUrl

    const { data, error } = await supabase
      .from('bookings')
      .update(updates)
      .eq('id', bookingId)
      .select()
      .single()
    if (error) throw error
    return data
  }

  // Admin: konfirmasi pembayaran → paid + confirmed
  async function confirmPayment(bookingId, userId, bookingCode) {
    const { error } = await supabase
      .from('bookings')
      .update({
        payment_status: 'paid',
        status:         'confirmed',
        paid_at:        new Date().toISOString(),
        updated_at:     new Date().toISOString(),
      })
      .eq('id', bookingId)
    if (error) throw error

    // Kirim notifikasi ke user
    if (userId) {
      await supabase.from('notifications').insert({
        user_id:    userId,
        booking_id: bookingId,
        type:       'booking_confirmed',
        title:      '✅ Pembayaran Dikonfirmasi!',
        message:    `Pembayaran booking #${bookingCode} telah dikonfirmasi. Kami menunggu kedatangan Anda!`,
      })
    }
  }

  // Admin: tolak pembayaran → failed
  async function rejectPayment(bookingId, userId, bookingCode) {
    const { error } = await supabase
      .from('bookings')
      .update({
        payment_status: 'failed',
        updated_at:     new Date().toISOString(),
      })
      .eq('id', bookingId)
    if (error) throw error

    if (userId) {
      await supabase.from('notifications').insert({
        user_id:    userId,
        booking_id: bookingId,
        type:       'payment_rejected',
        title:      '❌ Bukti Bayar Ditolak',
        message:    `Bukti pembayaran booking #${bookingCode} ditolak. Silakan upload ulang bukti yang valid.`,
      })
    }
  }

  return { uploading, uploadProof, submitPayment, confirmPayment, rejectPayment }
})