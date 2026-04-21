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
              <span class="text-white font-medium">{{ booking.services?.name }}</span>
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
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">Harga</span>
              <span class="text-amber-400 font-bold">Rp {{ formatPrice(booking.service_price) }}</span>
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
      <button @click="deleteBooking"
        class="w-full py-3 rounded-xl border-2 border-red-500/30 text-red-400 font-medium hover:bg-red-500/10 transition-colors">
        🗑️ Hapus Booking
      </button>
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
    .select(`*, services(*), staff(*), profiles(*), reviews(*)`)
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

async function deleteBooking() {
  if (!confirm('Hapus booking ini?')) return
  await bookingStore.deleteBooking(route.params.id)
  router.push('/admin/bookings')
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
