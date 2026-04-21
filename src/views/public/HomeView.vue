<!-- src/views/public/HomeView.vue -->
<template>
  <div class="pb-4">
    <!-- Hero -->
    <div class="bg-gradient-to-br rounded-2xl from-amber-500 to-orange-600 text-white px-6 pt-6 pb-6 relative overflow-hidden">
      <div class="absolute inset-0 opacity-10" style="background-image:radial-gradient(circle at 70% 50%, white 1px, transparent 1px); background-size:24px 24px;"></div>
      <p class="text-amber-100 text-sm mb-1">Selamat datang 👋</p>
      <h1 class="text-2xl font-bold mb-1">{{ authStore.profile?.full_name || 'Pelanggan' }}</h1>
      <p class="text-amber-100 text-sm">Mau tampil keren hari ini?</p>
    </div>

    <!-- Quick Actions -->
    <div class="mx-4 mt-4 bg-white rounded-2xl shadow-lg p-4 grid grid-cols-3 gap-3">
      <router-link to="/booking" class="flex flex-col items-center gap-1.5 p-3 bg-amber-50 rounded-xl hover:bg-amber-100 transition-colors">
        <img src="/Booking.png" class="w-8 h-8" />
        <span class="text-xs font-medium text-gray-700 text-center">Booking</span>
      </router-link>
      <router-link to="/history" class="flex flex-col items-center gap-1.5 p-3 bg-blue-50 rounded-xl hover:bg-blue-100 transition-colors">
        <img src="/Riwayat.png" class="w-8 h-8" />
        <span class="text-xs font-medium text-gray-700 text-center">Riwayat</span>
      </router-link>
      <router-link to="/services" class="flex flex-col items-center gap-1.5 p-3 bg-green-50 rounded-xl hover:bg-green-100 transition-colors">
        <img src="/Layanan.png" class="w-8 h-8" />
        <span class="text-xs font-medium text-gray-700 text-center">Layanan</span>
      </router-link>
    </div>

    <!-- Upcoming Booking -->
    <div v-if="upcomingBooking" class="mx-4 mt-5">
      <h2 class="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wide">Booking Terdekat</h2>
      <div class="bg-gradient-to-r from-amber-500 to-orange-500 rounded-2xl p-4 text-white">
        <div class="flex items-center justify-between mb-2">
          <span class="text-xs bg-white/20 rounded-full px-2 py-0.5">{{ upcomingBooking.booking_code }}</span>
          <StatusBadge :status="upcomingBooking.status" dark />
        </div>
        <p class="font-bold text-lg">{{ upcomingBooking.services?.name }}</p>
        <p class="text-amber-100 text-sm">{{ formatDate(upcomingBooking.booking_date) }} · {{ upcomingBooking.booking_time?.slice(0,5) }}</p>
        <p v-if="upcomingBooking.staff" class="text-amber-100 text-sm">👤 {{ upcomingBooking.staff?.name }}</p>
      </div>
    </div>

    <!-- Popular Services -->
    <div class="mt-5 px-4">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide">Layanan Populer</h2>
        <router-link to="/services" class="text-amber-600 text-xs font-medium">Lihat semua →</router-link>
      </div>
      <div v-if="loadingServices" class="grid grid-cols-2 gap-3">
        <div v-for="i in 4" :key="i" class="h-28 bg-gray-100 rounded-2xl animate-pulse"></div>
      </div>
      <div v-else class="grid grid-cols-2 gap-3">
        <router-link
          v-for="svc in popularServices" :key="svc.id"
          :to="{ name: 'booking', query: { service: svc.id } }"
          class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
          <img :src="getCategoryIcon(svc.category)" class="w-8 h-8 object-contain" />
          <p class="font-semibold text-gray-800 text-sm leading-tight">{{ svc.name }}</p>
          <p class="text-amber-600 text-sm font-bold mt-1">Rp {{ formatPrice(svc.price) }}</p>
          <p class="text-gray-400 text-xs">{{ svc.duration_minutes }} menit</p>
        </router-link>
      </div>
    </div>

    <!-- Reviews -->
    <div class="mt-6 px-4">
      <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">Ulasan Terbaru</h2>
      <div v-if="recentReviews.length === 0" class="text-center text-gray-400 text-sm py-4">Belum ada ulasan</div>
      <div class="space-y-3">
        <div v-for="review in recentReviews" :key="review.id" class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center text-sm font-bold text-amber-700">
                {{ review.profiles?.full_name?.[0]?.toUpperCase() || '?' }}
              </div>
              <div>
                <p class="text-sm font-medium text-gray-800">{{ review.profiles?.full_name || 'Anonim' }}</p>
                <p class="text-xs text-gray-400">{{ review.services?.name }}</p>
              </div>
            </div>
            <div class="flex gap-0.5">
              <span v-for="i in 5" :key="i" class="text-sm" :class="i <= review.rating ? 'text-amber-400' : 'text-gray-200'">★</span>
            </div>
          </div>
          <p v-if="review.comment" class="text-sm text-gray-600">{{ review.comment }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useServicesStore } from '@/stores/services'
import { useBookingStore } from '@/stores/booking'
import { useReviewsStore } from '@/stores/reviews'
import StatusBadge from '@/components/public/StatusBadge.vue'

const authStore = useAuthStore()
const servicesStore = useServicesStore()
const bookingStore = useBookingStore()
const reviewsStore = useReviewsStore()

const loadingServices = ref(true)

const popularServices = computed(() => servicesStore.services.slice(0, 4))
const upcomingBooking = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return bookingStore.bookings.find(b =>
    b.booking_date >= today && ['pending','confirmed'].includes(b.status)
  )
})
const recentReviews = computed(() => reviewsStore.reviews.slice(0, 3))

function formatPrice(p) { return Number(p).toLocaleString('id-ID') }
function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { weekday:'short', day:'numeric', month:'short' })
}

function getCategoryIcon(cat) {
  const map = {
    rambut:     '/icons/Rambut.png',
    wajah:      '/icons/Wajah.png',
    kuku:       '/icons/Kuku.png',
    barbershop: '/icons/Barbershop.png',
    general:    '/Layanan.png.png',
  }
  return map[cat] || '/Layanan.png.png'
}

onMounted(async () => {
  await servicesStore.fetchServices()
  loadingServices.value = false
  reviewsStore.fetchReviews()
  if (authStore.isLoggedIn) {
    bookingStore.fetchMyBookings(authStore.user.id)
  }
})
</script>