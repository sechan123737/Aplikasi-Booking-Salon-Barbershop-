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
              <p class="font-bold text-gray-800">{{ b.services?.name }}</p>
              <p class="text-sm text-gray-500">{{ formatDate(b.booking_date) }} · {{ b.booking_time?.slice(0,5) }}</p>
              <p v-if="b.staff" class="text-sm text-gray-500">👤 {{ b.staff?.name }}</p>
            </div>
            <StatusBadge :status="b.status" />
          </div>
          <div class="flex items-center justify-between pt-3 border-t border-gray-50">
            <p class="text-amber-600 font-bold">Rp {{ formatPrice(b.service_price) }}</p>
            <div class="flex gap-2">
              <button v-if="b.status === 'completed' && !b.reviews?.length"
                @click="$router.push({ name: 'review', params: { bookingId: b.id } })"
                class="text-xs px-3 py-1.5 bg-amber-50 text-amber-600 rounded-full font-medium">
                ⭐ Beri Ulasan
              </button>
              <button v-if="['pending','confirmed'].includes(b.status)"
                @click="cancelBooking(b.id)"
                class="text-xs px-3 py-1.5 bg-red-50 text-red-500 rounded-full font-medium">
                Batalkan
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useBookingStore } from '@/stores/booking'
import StatusBadge from '@/components/public/StatusBadge.vue'

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

async function cancelBooking(id) {
  if (!confirm('Batalkan booking ini?')) return
  await bookingStore.cancelBooking(id)
}

function formatPrice(p) { return Number(p||0).toLocaleString('id-ID') }
function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { weekday:'short', day:'numeric', month:'short', year:'numeric' })
}

onMounted(() => {
  if (authStore.user) bookingStore.fetchMyBookings(authStore.user.id)
})
</script>