<!-- src/views/public/BookingHistoryView.vue -->
<template>
  <div class="px-4 py-6">
    <h1 class="text-xl font-bold text-gray-900 mb-4">Riwayat Booking</h1>

    <!-- Filter -->
    <div class="flex gap-2 mb-4 pb-1" style="overflow-x: auto; scrollbar-width: none; -ms-overflow-style: none;">
      <button v-for="f in filters" :key="f.value"
        @click="activeFilter = f.value"
        style="flex-shrink: 0;"
        class="px-4 py-1.5 rounded-full text-sm font-medium transition-colors"
        :class="activeFilter === f.value ? 'bg-amber-500 text-white' : 'bg-gray-100 text-gray-600'">
        {{ f.label }}
      </button>
    </div>

    <div v-if="bookingStore.loading" class="space-y-3">
      <div v-for="i in 3" :key="i" class="h-28 bg-gray-100 rounded-2xl animate-pulse"></div>
    </div>

    <div v-else-if="filteredBookings.length === 0" class="text-center py-16">
      <span class="text-5xl block mb-3">📋</span>
      <p class="text-gray-500">Belum ada booking</p>
      <router-link to="/booking" class="inline-block mt-4 px-6 py-2.5 bg-amber-500 text-white rounded-2xl font-medium text-sm">
        Buat Booking Sekarang
      </router-link>
    </div>

    <div v-else class="space-y-3">
      <div v-for="b in filteredBookings" :key="b.id"
        class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="p-4">
          <div class="flex items-start justify-between mb-2">
            <div>
              <p class="text-xs text-gray-400 font-medium mb-0.5">{{ b.booking_code }}</p>
              <div v-if="b.booking_services && b.booking_services.length > 0">
                <p v-for="bs in b.booking_services" :key="bs.id"
                  class="font-semibold text-gray-800 text-sm leading-snug">
                  {{ bs.services?.name }}
                </p>
              </div>
              <p v-else class="font-bold text-gray-800">{{ b.services?.name }}</p>
              <p class="text-sm text-gray-500">{{ formatDate(b.booking_date) }} · {{ b.booking_time?.slice(0,5) }}</p>
              <p v-if="b.staff" class="text-sm text-gray-500">👤 {{ b.staff?.name }}</p>
            </div>
            <div class="flex flex-col items-end gap-1">
              <StatusBadge :status="b.status" />
              <span v-if="b.payment_status === 'paid'"
                class="text-xs px-2 py-0.5 bg-green-100 text-green-600 rounded-full font-medium">✅ Lunas</span>
              <span v-else-if="b.payment_status === 'waiting_verification'"
                class="text-xs px-2 py-0.5 bg-yellow-100 text-yellow-600 rounded-full font-medium">⏳ Menunggu Verifikasi</span>
              <span v-else-if="b.payment_status === 'failed'"
                class="text-xs px-2 py-0.5 bg-red-100 text-red-500 rounded-full font-medium">❌ Ditolak</span>
              <span v-else-if="b.payment_method === 'cod'"
                class="text-xs px-2 py-0.5 bg-blue-100 text-blue-600 rounded-full font-medium">🤝 Bayar di Tempat</span>
              <span v-else-if="b.status !== 'cancelled'"
                class="text-xs px-2 py-0.5 bg-red-50 text-red-400 rounded-full font-medium">❗ Belum Bayar</span>
            </div>
          </div>
          <div class="pt-3 border-t border-gray-50">
            <!-- Subtotal layanan -->
            <div v-if="b.booking_services && b.booking_services.length > 0"
              class="space-y-0.5 mb-1">
              <div v-for="bs in b.booking_services" :key="bs.id"
                class="flex justify-between text-xs text-gray-400">
                <span>{{ bs.services?.name }}</span>
                <span>Rp {{ formatPrice(bs.price) }}</span>
              </div>
            </div>
            <!-- Diskon voucher -->
            <div v-if="b.discount_amount > 0"
              class="flex justify-between text-xs text-green-600 mb-1">
              <span>Diskon ({{ b.voucher_code }})</span>
              <span>- Rp {{ formatPrice(b.discount_amount) }}</span>
            </div>
            <!-- Total akhir -->
            <div class="flex items-center justify-between">
              <p class="text-amber-600 font-bold">
                Rp {{ formatPrice(
                  b.final_price > 0
                    ? b.final_price
                    : b.booking_services && b.booking_services.length > 0
                      ? b.booking_services.reduce((sum, bs) => sum + Number(bs.price || 0), 0) - Number(b.discount_amount || 0)
                      : b.service_price || 0
                ) }}
              </p>
            </div>
            <div class="flex gap-2">
              <router-link
                v-if="['unpaid', 'failed'].includes(b.payment_status) && b.payment_method !== 'cod' && !['cancelled'].includes(b.status)"
                :to="{ name: 'booking-success', query: { code: b.booking_code } }"
                class="text-xs px-3 py-1.5 bg-amber-500 text-white rounded-full font-medium hover:bg-amber-600 transition-colors">
                💳 {{ b.payment_status === 'failed' ? 'Upload Ulang' : 'Bayar Sekarang' }}
              </router-link>
              <button v-if="b.status === 'completed' && !b.reviews?.length"
                @click="$router.push({ name: 'review', params: { bookingId: b.id } })"
                class="text-xs px-3 py-1.5 bg-amber-50 text-amber-600 rounded-full font-medium">
                ⭐ Beri Ulasan
              </button>
              <button v-if="['pending','confirmed'].includes(b.status)"
                @click="openCancelModal(b)"
                class="text-xs px-3 py-1.5 bg-red-50 text-red-500 rounded-full font-medium">
                Batalkan
              </button>
              <button v-if="b.status === 'cancelled' && b.payment_status === 'paid' && !b.refund_status"
                @click="openRefundModal(b)"
                class="text-xs px-3 py-1.5 bg-blue-50 text-blue-600 rounded-full font-medium hover:bg-blue-100 transition-colors">
                💸 Ajukan Refund
              </button>
              <span v-if="b.refund_status === 'requested'"
                class="text-xs px-3 py-1.5 bg-yellow-50 text-yellow-600 rounded-full font-medium">
                ⏳ Refund Diproses
              </span>
              <span v-if="b.refund_status === 'approved'"
                class="text-xs px-3 py-1.5 bg-blue-50 text-blue-600 rounded-full font-medium">
                ✅ Refund Disetujui
              </span>
              <span v-if="b.refund_status === 'completed'"
                class="text-xs px-3 py-1.5 bg-green-50 text-green-600 rounded-full font-medium">
                💚 Refund Selesai
              </span>
              <span v-if="b.refund_status === 'rejected'"
                class="text-xs px-3 py-1.5 bg-red-50 text-red-500 rounded-full font-medium">
                ❌ Refund Ditolak
              </span>
              <button v-if="b.status === 'cancelled'"
                @click="openDeleteModal(b)"
                class="text-xs px-3 py-1.5 bg-gray-100 text-gray-500 rounded-full font-medium hover:bg-red-50 hover:text-red-500 transition-colors">
                🗑️ Hapus
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <!-- Modal Batalkan -->
  <div v-if="cancelTarget" class="fixed inset-0 z-50 flex items-end sm:items-center pb-24 justify-center p-4 bg-black/40">
    <div class="bg-white rounded-3xl w-full max-w-sm shadow-xl p-6">
      <div class="text-center mb-4">
        <div class="text-4xl mb-2">⚠️</div>
        <p class="font-bold text-gray-900 text-lg">Batalkan Booking?</p>
        <p class="text-sm text-gray-500 mt-1">
          Booking <span class="font-mono font-bold text-gray-700">{{ cancelTarget.booking_code }}</span> akan dibatalkan.
          Tindakan ini tidak bisa diurungkan.
        </p>
      </div>
      <div class="flex gap-3 mt-5">
        <button @click="cancelTarget = null"
          class="flex-1 py-3 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600">
          Kembali
        </button>
        <button @click="doCancel" :disabled="processing"
          class="flex-1 py-3 rounded-2xl bg-red-500 hover:bg-red-600 font-semibold text-white transition-colors flex items-center justify-center gap-2">
          <span v-if="processing" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          {{ processing ? '...' : 'Ya, Batalkan' }}
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Refund -->
  <div v-if="refundTarget" class="fixed inset-0 z-50 flex items-end sm:items-center pb-24 justify-center p-4 bg-black/40">
    <div class="bg-white rounded-3xl w-full max-w-sm shadow-xl p-6">
      <div class="text-center mb-4">
        <div class="text-4xl mb-2">💸</div>
        <p class="font-bold text-gray-900 text-lg">Ajukan Pengembalian Dana</p>
        <p class="text-sm text-gray-500 mt-1">
          Booking <span class="font-mono font-bold text-gray-700">{{ refundTarget.booking_code }}</span>
        </p>
        <p class="text-2xl font-bold text-amber-600 mt-2">
          Rp {{ formatPrice(refundTarget.final_price ?? refundTarget.service_price ?? 0) }}
        </p>
      </div>
      <div class="space-y-3 mb-5">
        <div>
          <label class="text-xs font-semibold text-gray-600 block mb-1">Info Rekening / E-Wallet *</label>
          <input v-model="refundMethod" type="text"
            placeholder="cth: BCA 1234567890 a/n Nama"
            class="w-full border-2 border-gray-200 rounded-xl px-3 py-2.5 text-sm focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-xs font-semibold text-gray-600 block mb-1">Catatan (opsional)</label>
          <textarea v-model="refundNotes" rows="2" placeholder="Alasan atau keterangan tambahan..."
            class="w-full border-2 border-gray-200 rounded-xl px-3 py-2.5 text-sm focus:border-amber-500 outline-none resize-none"></textarea>
        </div>
      </div>
      <div class="flex gap-3">
        <button @click="refundTarget = null; refundMethod = ''; refundNotes = ''"
          class="flex-1 py-3 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600">
          Batal
        </button>
        <button @click="doRefund" :disabled="processing || !refundMethod"
          class="flex-1 py-3 rounded-2xl font-semibold text-white transition-colors flex items-center justify-center gap-2"
          :class="refundMethod && !processing ? 'bg-blue-500 hover:bg-blue-600' : 'bg-gray-300'">
          <span v-if="processing" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          {{ processing ? '...' : 'Ajukan Refund' }}
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Hapus -->
  <div v-if="deleteTarget" class="fixed inset-0 z-50 flex items-end sm:items-center pb-24 justify-center p-4 bg-black/40">
    <div class="bg-white rounded-3xl w-full max-w-sm shadow-xl p-6">
      <div class="text-center mb-4">
        <div class="text-4xl mb-2">🗑️</div>
        <p class="font-bold text-gray-900 text-lg">Hapus Riwayat?</p>
        <p class="text-sm text-gray-500 mt-1">
          Booking <span class="font-mono font-bold text-gray-700">{{ deleteTarget.booking_code }}</span>
          yang sudah dibatalkan akan dihapus permanen dari riwayat kamu.
        </p>
      </div>
      <div class="flex gap-3 mt-5">
        <button @click="deleteTarget = null"
          class="flex-1 py-3 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600">
          Kembali
        </button>
        <button @click="doDelete" :disabled="processing"
          class="flex-1 py-3 rounded-2xl bg-red-500 hover:bg-red-600 font-semibold text-white transition-colors flex items-center justify-center gap-2">
          <span v-if="processing" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          {{ processing ? '...' : 'Ya, Hapus' }}
        </button>
      </div>
    </div>
  </div>

</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useBookingStore } from '@/stores/booking'
import StatusBadge from '@/components/public/StatusBadge.vue'
import { supabase } from '@/lib/supabase'

const authStore = useAuthStore()
const bookingStore = useBookingStore()
const activeFilter = ref('all')

const filters = [
  { value: 'all', label: 'Semua' },
  { value: 'pending', label: 'Menunggu' },
  { value: 'confirmed', label: 'Dikonfirmasi' },
  { value: 'completed', label: 'Selesai' },
  { value: 'cancelled', label: 'Dibatalkan' },
]

const filteredBookings = computed(() => {
  if (activeFilter.value === 'all') return bookingStore.bookings
  return bookingStore.bookings.filter(b => b.status === activeFilter.value)
})

const cancelTarget  = ref(null)
const deleteTarget  = ref(null)
const refundTarget  = ref(null)
const refundMethod  = ref('')
const refundNotes   = ref('')

function openRefundModal(b) { refundTarget.value = b }
const processing    = ref(false)

function openCancelModal(b) { cancelTarget.value = b }
function openDeleteModal(b) { deleteTarget.value = b }

async function doCancel() {
  if (!cancelTarget.value) return
  processing.value = true
  try {
    await bookingStore.cancelBooking(cancelTarget.value.id)
    cancelTarget.value = null
  } catch (e) {
    alert(e.message || 'Gagal membatalkan booking.')
  } finally {
    processing.value = false
  }
}

async function doDelete() {
  if (!deleteTarget.value) return
  processing.value = true
  try {
    await bookingStore.deleteBooking(deleteTarget.value.id)
    deleteTarget.value = null
  } catch (e) {
    alert(e.message || 'Gagal menghapus booking.')
  } finally {
    processing.value = false
  }
}

async function doRefund() {
  if (!refundTarget.value || !refundMethod.value) return
  processing.value = true
  try {
    const { error } = await supabase
      .from('bookings')
      .update({
        refund_status: 'requested',
        refund_amount: refundTarget.value.final_price ?? refundTarget.value.service_price ?? 0,
        refund_method: refundMethod.value,
        refund_notes:  refundNotes.value || null,
        updated_at:    new Date().toISOString(),
      })
      .eq('id', refundTarget.value.id)
    if (error) throw error

    // Update local state
    const idx = bookingStore.bookings.findIndex(b => b.id === refundTarget.value.id)
    if (idx !== -1) {
      bookingStore.bookings[idx].refund_status = 'requested'
      bookingStore.bookings[idx].refund_method = refundMethod.value
    }
    refundTarget.value = null
    refundMethod.value = ''
    refundNotes.value  = ''
  } catch (e) {
    alert(e.message || 'Gagal mengajukan refund.')
  } finally {
    processing.value = false
  }
}

function formatPrice(p) { return Number(p||0).toLocaleString('id-ID') }
function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { weekday:'short', day:'numeric', month:'short', year:'numeric' })
}

onMounted(() => {
  if (authStore.user) bookingStore.fetchMyBookings(authStore.user.id)
})
</script>