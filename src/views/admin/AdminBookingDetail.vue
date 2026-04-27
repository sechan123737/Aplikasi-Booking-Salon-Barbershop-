<!-- src/views/admin/AdminBookingDetail.vue -->
<template>
  <div class="max-w-2xl">
    <div class="flex items-center gap-3 mb-6">
      <router-link to="/admin/bookings" class="text-gray-400 hover:text-white transition-colors">← Kembali</router-link>
      <span class="text-gray-600">/</span>
      <h1 class="text-white font-semibold">Detail Booking</h1>
    </div>

    <div v-if="loading" class="space-y-4">
      <div v-for="i in 3" :key="i" class="h-32 bg-gray-900 rounded-2xl border border-gray-800 animate-pulse"></div>
    </div>

    <div v-else-if="booking">
      <!-- Header Card -->
      <div class="bg-gradient-to-br from-amber-500 to-orange-600 rounded-2xl p-6 mb-5 text-white">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-amber-100 text-sm font-medium">Kode Booking</p>
            <p class="text-2xl font-bold font-mono">{{ booking.booking_code }}</p>
          </div>
          <AdminStatusBadge :status="booking.status" />
        </div>
        <p class="text-amber-100 text-sm mt-3">Dibuat: {{ formatDateTime(booking.created_at) }}</p>
      </div>

      <!-- Info Cards -->
      <div class="grid gap-4 mb-5">
        <!-- Layanan -->
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5">
          <h3 class="text-gray-400 text-xs font-semibold uppercase tracking-wide mb-3">Informasi Layanan</h3>
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">Layanan</span>
              <span class="text-white font-medium">{{ booking.booking_services?.length > 0 ? booking.booking_services.map(bs => bs.services?.name).join(', ') : booking.services?.name }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">Stylist</span>
              <span class="text-white">{{ booking.staff?.name || 'Siapa saja' }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">Tanggal</span>
              <span class="text-white">{{ formatDate(booking.booking_date) }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">Jam</span>
              <span class="text-white">{{ booking.booking_time?.slice(0,5) }} – {{ booking.end_time?.slice(0,5) }}</span>
            </div>
            <!-- Subtotal per layanan -->
            <div v-if="booking.booking_services && booking.booking_services.length > 0"
              class="space-y-1 mb-1">
              <div v-for="bs in booking.booking_services" :key="bs.id"
                class="flex justify-between text-sm">
                <span class="text-gray-400">{{ bs.services?.name }}</span>
                <span class="text-gray-300">Rp {{ formatPrice(bs.price) }}</span>
              </div>
            </div>
            <!-- Diskon -->
            <div v-if="booking.discount_amount > 0" class="flex justify-between text-sm">
              <span class="text-green-400">Diskon ({{ booking.voucher_code }})</span>
              <span class="text-green-400">- Rp {{ formatPrice(booking.discount_amount) }}</span>
            </div>
            <!-- Total -->
            <div class="flex justify-between text-sm border-t border-gray-700 pt-2 mt-1">
              <span class="text-gray-400">Total Bayar</span>
              <span class="text-amber-400 font-bold">Rp {{ formatPrice(
                booking.final_price > 0
                  ? booking.final_price
                  : booking.booking_services && booking.booking_services.length > 0
                    ? booking.booking_services.reduce((sum, bs) => sum + Number(bs.price || 0), 0) - Number(booking.discount_amount || 0)
                    : booking.service_price || 0
              ) }}</span>
            </div>
          </div>
        </div>

        <!-- Pelanggan -->
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5">
          <h3 class="text-gray-400 text-xs font-semibold uppercase tracking-wide mb-3">Data Pelanggan</h3>
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">Nama</span>
              <span class="text-white font-medium">{{ booking.customer_name }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">HP</span>
              <span class="text-white">{{ booking.customer_phone }}</span>
            </div>
            <div v-if="booking.customer_email" class="flex justify-between text-sm">
              <span class="text-gray-400">Email</span>
              <span class="text-white">{{ booking.customer_email }}</span>
            </div>
            <div v-if="booking.notes" class="text-sm">
              <p class="text-gray-400 mb-1">Catatan Pelanggan</p>
              <p class="text-gray-300 bg-gray-800 rounded-xl p-3 text-xs">{{ booking.notes }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Pembayaran -->
      <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5 mb-5">
        <h3 class="text-gray-400 text-xs font-semibold uppercase tracking-wide mb-3">Informasi Pembayaran</h3>
        <div class="space-y-2">
          <!-- Metode Pembayaran -->
          <div class="flex justify-between text-sm">
            <span class="text-gray-400">Metode Bayar</span>
            <span class="text-white font-medium">{{ methodLabel(booking.payment_method) }}</span>
          </div>
          <!-- Status Pembayaran -->
          <div class="flex justify-between text-sm">
            <span class="text-gray-400">Status Bayar</span>
            <span class="font-medium"
              :class="{
                'text-green-400':  booking.payment_status === 'paid',
                'text-yellow-400': booking.payment_status === 'waiting_verification',
                'text-red-400':    booking.payment_status === 'failed',
                'text-gray-400':   !booking.payment_status || booking.payment_status === 'unpaid',
              }">
              {{ paymentStatusLabel(booking.payment_status) }}
            </span>
          </div>
          <!-- Waktu Lunas -->
          <div v-if="booking.paid_at" class="flex justify-between text-sm">
            <span class="text-gray-400">Dibayar Pada</span>
            <span class="text-white">{{ formatDateTime(booking.paid_at) }}</span>
          </div>
          <!-- Bukti Transfer -->
          <div v-if="booking.payment_proof" class="mt-3">
            <p class="text-gray-400 text-xs mb-2">Bukti Pembayaran</p>
            <a :href="booking.payment_proof" target="_blank">
              <img :src="booking.payment_proof" alt="Bukti Pembayaran"
                class="w-full max-w-xs rounded-xl border border-gray-700 object-cover hover:opacity-80 transition-opacity cursor-pointer" />
            </a>
          </div>
        </div>

        <!-- Aksi Konfirmasi / Tolak (hanya jika waiting_verification) -->
        <div v-if="booking.payment_status === 'waiting_verification'" class="mt-4 pt-4 border-t border-gray-700 flex gap-3">
          <button @click="handleConfirmPayment" :disabled="verifying"
            class="flex-1 py-2.5 rounded-xl bg-green-600 hover:bg-green-700 text-white text-sm font-semibold transition-colors disabled:opacity-50">
            {{ verifying ? 'Memproses...' : '✅ Konfirmasi Pembayaran' }}
          </button>
          <button @click="handleRejectPayment" :disabled="verifying"
            class="flex-1 py-2.5 rounded-xl bg-red-600/30 hover:bg-red-600/50 text-red-400 text-sm font-semibold transition-colors disabled:opacity-50 border border-red-500/30">
            {{ verifying ? '...' : '❌ Tolak' }}
          </button>
        </div>

        <!-- COD: belum bayar, tunggu pelanggan datang -->
        <div v-else-if="booking.payment_method === 'cod' && booking.payment_status === 'unpaid'"
          class="mt-4 pt-4 border-t border-gray-700">
          <p class="text-yellow-400 text-sm text-center mb-3">🤝 Pelanggan akan bayar tunai saat datang</p>
          <button @click="handleMarkCodPaid" :disabled="verifying"
            class="w-full py-2.5 rounded-xl bg-green-600 hover:bg-green-700 text-white text-sm font-semibold transition-colors disabled:opacity-50">
            {{ verifying ? 'Memproses...' : '💵 Tandai Sudah Bayar (COD)' }}
          </button>
        </div>

        <!-- Sudah Lunas -->
        <div v-else-if="booking.payment_status === 'paid'"
          class="mt-4 pt-4 border-t border-gray-700 text-center text-green-400 text-sm font-medium">
          ✅ Pembayaran sudah dikonfirmasi
        </div>
      </div>

      <!-- Panel Refund (muncul jika ada permintaan refund) -->
      <div v-if="booking.refund_status" class="bg-gray-900 rounded-2xl border border-gray-800 p-5 mb-5">
        <h3 class="text-gray-400 text-xs font-semibold uppercase tracking-wide mb-4">Permintaan Pengembalian Dana</h3>

        <div class="space-y-2 mb-4">
          <div class="flex justify-between text-sm">
            <span class="text-gray-400">Status Refund</span>
            <span class="font-semibold" :class="{
              'text-yellow-400': booking.refund_status === 'requested',
              'text-blue-400':   booking.refund_status === 'approved',
              'text-green-400':  booking.refund_status === 'completed',
              'text-red-400':    booking.refund_status === 'rejected',
            }">
              {{ { requested: '⏳ Menunggu', approved: '✅ Disetujui', completed: '💚 Selesai', rejected: '❌ Ditolak' }[booking.refund_status] }}
            </span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-400">Jumlah Refund</span>
            <span class="text-white font-bold">Rp {{ formatPrice(booking.refund_amount) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-400">Tujuan Transfer</span>
            <span class="text-white text-right max-w-[60%]">{{ booking.refund_method }}</span>
          </div>
          <div v-if="booking.refund_notes" class="flex justify-between text-sm">
            <span class="text-gray-400">Catatan</span>
            <span class="text-gray-300 text-right max-w-[60%]">{{ booking.refund_notes }}</span>
          </div>
          <div v-if="booking.refund_at" class="flex justify-between text-sm">
            <span class="text-gray-400">Diproses</span>
            <span class="text-gray-300">{{ formatDateTime(booking.refund_at) }}</span>
          </div>
        </div>

        <!-- Aksi admin untuk refund yang masih requested -->
        <div v-if="booking.refund_status === 'requested'" class="flex gap-3 pt-4 border-t border-gray-700">
          <button @click="processRefund('rejected')" :disabled="processingRefund"
            class="flex-1 py-2.5 rounded-xl bg-red-500/20 text-red-400 text-sm font-semibold hover:bg-red-500/30 transition-colors">
            ❌ Tolak
          </button>
          <button @click="processRefund('approved')" :disabled="processingRefund"
            class="flex-1 py-2.5 rounded-xl bg-blue-500/20 text-blue-400 text-sm font-semibold hover:bg-blue-500/30 transition-colors">
            ✅ Setujui
          </button>
          <button @click="processRefund('completed')" :disabled="processingRefund"
            class="flex-1 py-2.5 rounded-xl bg-green-500/20 text-green-400 text-sm font-semibold hover:bg-green-500/30 transition-colors">
            💚 Selesai
          </button>
        </div>
        <!-- Aksi jika sudah approved, tandai selesai -->
        <div v-else-if="booking.refund_status === 'approved'" class="pt-4 border-t border-gray-700">
          <button @click="processRefund('completed')" :disabled="processingRefund"
            class="w-full py-2.5 rounded-xl bg-green-500 hover:bg-green-600 text-white text-sm font-semibold transition-colors">
            💚 Tandai Dana Sudah Dikembalikan
          </button>
        </div>
      </div>

      <!-- Update Status -->
      <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5 mb-5">
        <h3 class="text-gray-400 text-xs font-semibold uppercase tracking-wide mb-4">Ubah Status</h3>
        <div class="flex flex-wrap gap-2 mb-4">
          <button v-for="s in statusOptions" :key="s.value"
            @click="selectedStatus = s.value"
            class="px-4 py-2 rounded-xl text-sm font-medium transition-all border-2"
            :class="selectedStatus === s.value
              ? 'border-amber-500 bg-amber-500/20 text-amber-400'
              : 'border-gray-700 bg-gray-800 text-gray-400 hover:border-gray-600'">
            {{ s.label }}
          </button>
        </div>
        <textarea v-model="adminNotes" rows="2" placeholder="Catatan admin (opsional)"
          class="w-full bg-gray-800 border border-gray-700 text-gray-300 text-sm rounded-xl p-3 mb-3 resize-none focus:border-amber-500 outline-none"></textarea>
        <button @click="updateStatus" :disabled="!selectedStatus || updating"
          class="w-full py-3 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-semibold transition-colors disabled:opacity-50">
          {{ updating ? 'Menyimpan...' : 'Simpan Perubahan' }}
        </button>
      </div>

      <!-- Delete -->
      <button @click="deleteTarget = booking"
        class="w-full py-3 rounded-xl border-2 border-red-500/30 text-red-400 font-medium hover:bg-red-500/10 transition-colors">
        🗑️ Hapus Booking
      </button>
    </div>
  </div>

  <!-- Modal Hapus -->
  <div v-if="deleteTarget" class="fixed inset-0 z-50 flex items-end sm:items-center pb-24 sm:pb-0 justify-center p-4 bg-black/40">
    <div class="bg-white rounded-3xl w-full max-w-sm shadow-xl p-6">
      <div class="text-center mb-4">
        <div class="text-4xl mb-2">🗑️</div>
        <p class="font-bold text-gray-900 text-lg">Hapus Booking?</p>
        <p class="text-sm text-gray-500 mt-1">
          Booking <span class="font-mono font-bold text-gray-700">{{ deleteTarget.booking_code }}</span>
          atas nama <span class="font-semibold text-gray-700">{{ deleteTarget.customer_name }}</span> akan dihapus permanen.
        </p>
      </div>
      <div class="flex gap-3 mt-5">
        <button @click="deleteTarget = null" class="flex-1 py-3 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600">Kembali</button>
        <button @click="doDelete" :disabled="deleting"
          class="flex-1 py-3 rounded-2xl bg-red-500 hover:bg-red-600 font-semibold text-white transition-colors flex items-center justify-center gap-2">
          <span v-if="deleting" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          {{ deleting ? '...' : 'Ya, Hapus' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useBookingStore } from '@/stores/booking'
import { useNotificationsStore } from '@/stores/notifications'
import AdminStatusBadge from '@/components/admin/AdminStatusBadge.vue'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const router = useRouter()
const bookingStore = useBookingStore()
const notifStore = useNotificationsStore()

const booking = ref(null)
const loading = ref(true)
const updating = ref(false)
const selectedStatus = ref('')
const adminNotes = ref('')

const statusOptions = [
  { value: 'confirmed',   label: '✅ Konfirmasi' },
  { value: 'in_progress', label: '💈 Mulai' },
  { value: 'completed',   label: '🎉 Selesai' },
  { value: 'cancelled',   label: '❌ Batalkan' },
  { value: 'no_show',     label: '👻 Tidak Hadir' },
]

async function loadBooking() {
  loading.value = true
  const { data, error } = await supabase
    .from('bookings')
    .select(`*, services(*), staff(*), profiles(*), reviews(*), booking_services(*, services(*))`)
    .eq('id', route.params.id)
    .single()
  if (!error) {
    booking.value = data
    selectedStatus.value = data.status
  }
  loading.value = false
}

async function updateStatus() {
  updating.value = true
  await bookingStore.updateBookingStatus(route.params.id, selectedStatus.value, adminNotes.value)
  if (booking.value?.user_id && ['confirmed','cancelled','completed'].includes(selectedStatus.value)) {
    await notifStore.sendBookingNotification(
      booking.value.user_id, route.params.id,
      `booking_${selectedStatus.value}`, booking.value.booking_code
    )
  }
  booking.value.status = selectedStatus.value
  updating.value = false
}

const deleteTarget = ref(null)
const deleting     = ref(false)

async function doDelete() {
  deleting.value = true
  try {
    await bookingStore.deleteBooking(route.params.id)
    router.push('/admin/bookings')
  } finally { deleting.value = false; deleteTarget.value = null }
}

import { usePaymentStore } from '@/stores/payment'
const paymentStore = usePaymentStore()
const verifying    = ref(false)

function methodLabel(m) {
  const map = { bank_transfer: 'Transfer Bank', qris: 'QRIS', gopay: 'GoPay / OVO / Dana', cod: 'Bayar di Tempat' }
  return map[m] || m || '-'
}

function paymentStatusLabel(s) {
  if (s === 'unpaid' && booking.value?.payment_method === 'cod') return 'Bayar di Tempat 🤝'
  const map = { unpaid: 'Belum Bayar', waiting_verification: 'Menunggu Verifikasi', paid: 'Lunas ✅', failed: 'Ditolak ❌' }
  return map[s] || '-'
}

const processingRefund = ref(false)

async function processRefund(status) {
  processingRefund.value = true
  try {
    const updates = {
      refund_status: status,
      refund_at:     new Date().toISOString(),
      updated_at:    new Date().toISOString(),
    }
    const { error } = await supabase
      .from('bookings')
      .update(updates)
      .eq('id', booking.value.id)
    if (error) throw error

    booking.value.refund_status = status
    booking.value.refund_at     = updates.refund_at

    if (booking.value.user_id) {
      const notifMap = {
        approved:  { type: 'refund_approved',  title: '✅ Refund Disetujui',        message: `Permintaan refund booking #${booking.value.booking_code} disetujui. Dana akan segera ditransfer.` },
        rejected:  { type: 'refund_rejected',  title: '❌ Refund Ditolak',          message: `Permintaan refund booking #${booking.value.booking_code} tidak dapat diproses. Hubungi salon untuk info lebih lanjut.` },
        completed: { type: 'refund_completed', title: '💚 Dana Sudah Dikembalikan', message: `Dana refund booking #${booking.value.booking_code} telah berhasil ditransfer ke rekening kamu.` },
      }
      const notif = notifMap[status]
      if (notif) {
        await supabase.from('notifications').insert({
          user_id:    booking.value.user_id,
          booking_id: booking.value.id,
          type:       notif.type,
          title:      notif.title,
          message:    notif.message,
        })
      }
    }
  } catch (e) {
    alert(e.message || 'Gagal memproses refund.')
  } finally {
    processingRefund.value = false
  }
}

async function handleMarkCodPaid() {
  if (!confirm('Tandai booking ini sudah dibayar tunai (COD)?')) return
  verifying.value = true
  try {
    await paymentStore.confirmPayment(booking.value.id, booking.value.user_id, booking.value.booking_code)
    booking.value.payment_status = 'paid'
    booking.value.status         = 'confirmed'
    booking.value.paid_at        = new Date().toISOString()
  } catch (e) { alert(e.message) }
  finally { verifying.value = false }
}

async function handleConfirmPayment() {
  if (!confirm('Konfirmasi pembayaran ini?')) return
  verifying.value = true
  try {
    await paymentStore.confirmPayment(booking.value.id, booking.value.user_id, booking.value.booking_code)
    booking.value.payment_status = 'paid'
    booking.value.status         = 'confirmed'
    booking.value.paid_at        = new Date().toISOString()
  } catch (e) { alert(e.message) }
  finally { verifying.value = false }
}

async function handleRejectPayment() {
  if (!confirm('Tolak bukti pembayaran ini? User akan diminta upload ulang.')) return
  verifying.value = true
  try {
    await paymentStore.rejectPayment(booking.value.id, booking.value.user_id, booking.value.booking_code)
    booking.value.payment_status = 'failed'
  } catch (e) { alert(e.message) }
  finally { verifying.value = false }
}

function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { weekday:'long', day:'numeric', month:'long', year:'numeric' })
}
function formatDateTime(ts) {
  return new Date(ts).toLocaleDateString('id-ID', { day:'numeric', month:'short', year:'numeric', hour:'2-digit', minute:'2-digit' })
}
function formatPrice(p) { return Number(p||0).toLocaleString('id-ID') }

onMounted(loadBooking)
</script>