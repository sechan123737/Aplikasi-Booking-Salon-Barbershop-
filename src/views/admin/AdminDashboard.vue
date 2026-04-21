<!-- src/views/admin/AdminDashboard.vue -->
<template>
  <div>
    <h1 class="text-2xl font-bold text-white mb-1">Dashboard</h1>
    <p class="text-gray-400 text-sm mb-8">{{ todayLabel }}</p>

    <!-- Stat Cards -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <div v-for="stat in stats" :key="stat.label"
        class="bg-gray-900 rounded-2xl p-5 border border-gray-800">
        <p class="text-gray-400 text-xs font-medium mb-3">{{ stat.label }}</p>
        <p class="text-3xl font-bold text-white">{{ stat.value }}</p>
        <p class="text-xs mt-1" :class="stat.color">{{ stat.sub }}</p>
      </div>
    </div>

    <div class="grid lg:grid-cols-2 gap-6">
      <!-- Booking Hari Ini -->
      <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-white font-semibold">Booking Hari Ini</h2>
          <router-link to="/admin/bookings" class="text-amber-400 text-xs hover:underline">Lihat semua</router-link>
        </div>
        <div v-if="loadingBookings" class="space-y-2">
          <div v-for="i in 3" :key="i" class="h-14 bg-gray-800 rounded-xl animate-pulse"></div>
        </div>
        <div v-else-if="todayBookings.length === 0" class="text-center py-8 text-gray-500 text-sm">
          Tidak ada booking hari ini
        </div>
        <div v-else class="space-y-2">
          <div v-for="b in todayBookings" :key="b.id"
            class="flex items-center gap-3 p-3 bg-gray-800/50 rounded-xl">
            <div class="w-10 h-10 bg-amber-500/20 rounded-xl flex items-center justify-center text-lg flex-shrink-0">✂️</div>
            <div class="flex-1 min-w-0">
              <p class="text-white text-sm font-medium truncate">{{ b.customer_name }}</p>
              <p class="text-gray-400 text-xs">{{ b.services?.name }} · {{ b.booking_time?.slice(0,5) }}</p>
            </div>
            <AdminStatusBadge :status="b.status" />
          </div>
        </div>
      </div>

      <!-- Ulasan Terbaru -->
      <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-white font-semibold">Ulasan Terbaru</h2>
          <router-link to="/admin/reviews" class="text-amber-400 text-xs hover:underline">Lihat semua</router-link>
        </div>
        <div v-if="reviewsStore.loading" class="space-y-2">
          <div v-for="i in 3" :key="i" class="h-14 bg-gray-800 rounded-xl animate-pulse"></div>
        </div>
        <div v-else-if="recentReviews.length === 0" class="text-center py-8 text-gray-500 text-sm">
          Belum ada ulasan
        </div>
        <div v-else class="space-y-3">
          <div v-for="r in recentReviews" :key="r.id" class="p-3 bg-gray-800/50 rounded-xl">
            <div class="flex items-center justify-between mb-1">
              <p class="text-white text-sm font-medium">{{ r.profiles?.full_name || 'Anonim' }}</p>
              <div class="flex gap-0.5">
                <span v-for="i in 5" :key="i" class="text-xs" :class="i <= r.rating ? 'text-amber-400' : 'text-gray-600'">★</span>
              </div>
            </div>
            <p class="text-gray-400 text-xs">{{ r.services?.name }}</p>
            <p v-if="r.comment" class="text-gray-300 text-xs mt-1 line-clamp-2">{{ r.comment }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useBookingStore } from '@/stores/booking'
import { useReviewsStore } from '@/stores/reviews'
import AdminStatusBadge from '@/components/admin/AdminStatusBadge.vue'

const bookingStore = useBookingStore()
const reviewsStore = useReviewsStore()
const loadingBookings = ref(true)

const todayStr = new Date().toISOString().split('T')[0]
const todayLabel = new Date().toLocaleDateString('id-ID', { weekday:'long', day:'numeric', month:'long', year:'numeric' })

const todayBookings = computed(() =>
  bookingStore.bookings.filter(b => b.booking_date === todayStr)
)
const recentReviews = computed(() => reviewsStore.reviews.slice(0, 4))

const stats = computed(() => {
  const all = bookingStore.bookings
  const today = todayBookings.value
  const pending = all.filter(b => b.status === 'pending').length
  const revenue = all.filter(b => b.status === 'completed')
    .reduce((s, b) => s + Number(b.service_price || 0), 0)
  const avgRating = reviewsStore.reviews.length
    ? (reviewsStore.reviews.reduce((s,r) => s + r.rating, 0) / reviewsStore.reviews.length).toFixed(1)
    : '-'

  return [
    { label: 'Booking Hari Ini', value: today.length, sub: `${today.filter(b=>b.status==='completed').length} selesai`, color: 'text-amber-400' },
    { label: 'Menunggu Konfirmasi', value: pending, sub: 'perlu diproses', color: 'text-yellow-400' },
    { label: 'Total Pendapatan', value: 'Rp ' + revenue.toLocaleString('id-ID'), sub: 'booking selesai', color: 'text-green-400' },
    { label: 'Rating Rata-rata', value: avgRating + ' ⭐', sub: `dari ${reviewsStore.reviews.length} ulasan`, color: 'text-blue-400' },
  ]
})

onMounted(async () => {
  await Promise.all([
    bookingStore.fetchAllBookings({ date: todayStr }),
    reviewsStore.fetchAllReviews(),
  ])
  loadingBookings.value = false
  // Load all for stats
  bookingStore.fetchAllBookings()
})
</script>
