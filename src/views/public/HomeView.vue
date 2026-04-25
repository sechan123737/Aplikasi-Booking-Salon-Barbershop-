<!-- src/views/public/HomeView.vue -->
<template>
  <div class="pb-4">
    <!-- Hero -->
    <div class="bg-gradient-to-br rounded-2xl from-amber-500 to-orange-600 text-white px-6 pt-6 pb-6 relative">
      <div class="absolute inset-0 opacity-10 rounded-2xl" style="background-image:radial-gradient(circle at 70% 50%, white 1px, transparent 1px); background-size:24px 24px; overflow:hidden;"></div>
      <p class="text-amber-100 text-sm mb-1">Selamat datang 👋</p>
      <h1 class="text-2xl font-bold mb-1">{{ authStore.profile?.full_name || 'Pelanggan' }}</h1>

      <!-- Location hover card -->
      <div class="location-wrapper" ref="locationTrigger" @mouseenter="openCard" @mouseleave="closeCard" @click.stop="toggleCard">
        <p class="text-amber-100 text-sm mt-1 flex items-center gap-1.5 cursor-pointer select-none">
          <span>📍</span>
          <span class="text-white font-semibold underline decoration-dotted underline-offset-2">ChaLon Salon & Barbershop</span>
        </p>

        <!-- Card popup — teleport ke body agar tidak terpotong apapun -->
        <Teleport to="body">
        <Transition name="loc-card">
          <div v-if="showCard" class="loc-card-fixed" :style="cardStyle" @mouseenter="openCard" @mouseleave="closeCard" @click.stop>
            <!-- Clouds -->
            <div class="cloud cloud-1"></div>
            <div class="cloud cloud-2"></div>
            <div class="cloud cloud-3"></div>

            <div class="loc-inner">
              <!-- Google Maps Embed -->
              <div class="loc-map">
                <iframe
                  src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3966.0286337300754!2d107.00039701048442!3d-6.259958593702469!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x2e698dd6e28035a3%3A0xeb68af412b8007e5!2sUniversitas%20Bina%20Sarana%20Informatika%20Kampus%20Cut%20Mutia%20Bekasi%20(BSI%20Cut%20Mutia%20Bekasi)!5e0!3m2!1sid!2sid!4v1777085204974!5m2!1sid!2sid"
                  style="border:0;width:100%;height:100%;display:block;"
                  allowfullscreen loading="lazy"
                  referrerpolicy="no-referrer-when-downgrade">
                </iframe>
              </div>

              <!-- Info -->
              <div class="loc-info">
                <div class="loc-info-blur"></div>
                <p class="loc-name">ChaLon</p>
                <p class="loc-sub">Salon & Barbershop</p>
                <p class="loc-addr">Jl. Contoh No. 12, Kota</p>
                <a href="https://maps.google.com" target="_blank" class="loc-btn" @click.stop>
                  Buka Maps →
                </a>
              </div>
            </div>
          </div>
        </Transition>
        </Teleport>
      </div>
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

    <!-- Promo Banner Voucher Aktif -->
    <div v-if="activePromos.length > 0" class="mx-4 mt-4">
      <h2 class="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wide">🔥 Promo Berlangsung</h2>

      <!-- Carousel wrapper -->
      <div class="relative overflow-hidden">
        <div
          class="flex transition-transform duration-500 ease-in-out gap-3"
          :style="{ transform: `translateX(calc(-${promoIndex * 100}% - ${promoIndex * 12}px))` }">
          <div
            v-for="(promo, i) in activePromos" :key="promo.id"
            class="min-w-full rounded-2xl p-4 relative overflow-hidden"
            :style="{ background: promoGradients[i % promoGradients.length] }">

            <!-- deco dots -->
            <div class="absolute inset-0 opacity-10" style="background-image:radial-gradient(circle, white 1.5px, transparent 1.5px); background-size:20px 20px;"></div>

            <div class="relative flex items-start justify-between gap-3">
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-1">
                  <span class="text-2xl">🎟️</span>
                  <span class="text-xs font-bold bg-white/25 text-white rounded-full px-2 py-0.5 uppercase tracking-wider">
                    {{ promo.code }}
                  </span>
                </div>
                <p class="text-white font-bold text-base leading-snug">{{ promo.name || promo.code }}</p>
                <p class="text-white/80 text-sm mt-0.5">
                  Hemat
                  <span class="font-bold text-white">
                    {{ promo.discount_type === "percent"
                        ? promo.discount_value + "%"
                        : "Rp " + formatPrice(promo.discount_value) }}
                  </span>
                  <span v-if="promo.discount_type === 'percent' && promo.max_discount">
                    (maks Rp {{ formatPrice(promo.max_discount) }})
                  </span>
                </p>
                <div class="flex flex-wrap gap-x-3 gap-y-0.5 mt-1.5 text-white/70 text-xs">
                  <span v-if="promo.min_purchase">Min. Rp {{ formatPrice(promo.min_purchase) }}</span>
                  <span v-if="promo.valid_until">s/d {{ formatDateShort(promo.valid_until) }}</span>
                  <span v-if="promo.max_uses">Sisa {{ Math.max(0, promo.max_uses - promo.used_count) }}x</span>
                </div>
              </div>

              <!-- CTA -->
              <router-link to="/booking"
                class="flex-shrink-0 bg-white/20 hover:bg-white/30 border border-white/30 text-white text-xs font-bold px-3 py-2 rounded-xl transition-colors text-center">
                Pakai<br>Sekarang
              </router-link>
            </div>
          </div>
        </div>

        <!-- Dots navigator -->
        <div v-if="activePromos.length > 1" class="flex justify-center gap-1.5 mt-3">
          <button
            v-for="(_, i) in activePromos" :key="i"
            @click="promoIndex = i"
            class="h-1.5 rounded-full transition-all duration-300"
            :class="promoIndex === i ? 'bg-amber-500 w-5' : 'bg-gray-300 w-1.5'">
          </button>
        </div>
      </div>
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
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useServicesStore } from '@/stores/services'
import { useBookingStore } from '@/stores/booking'
import { useReviewsStore } from '@/stores/reviews'
import StatusBadge from '@/components/public/StatusBadge.vue'
import { useVoucherStore } from '@/stores/vouchers'

const authStore = useAuthStore()
const servicesStore = useServicesStore()
const bookingStore = useBookingStore()
const reviewsStore = useReviewsStore()
const voucherStore = useVoucherStore()

const loadingServices = ref(true)

// ── Promo banner ───────────────────────────────────────────────
const showCard       = ref(false)
const locationTrigger = ref(null)
const cardPos         = ref({ top: 0, left: 0 })
const promoIndex      = ref(0)

const cardStyle = computed(() => ({
  position: 'fixed',
  top:  cardPos.value.top  + 'px',
  left: cardPos.value.left + 'px',
  zIndex: 99999,
}))

function calcCardPos() {
  if (!locationTrigger.value) return
  const rect = locationTrigger.value.getBoundingClientRect()
  const cardW = window.innerWidth < 480 ? 240 : 220
  let left = rect.left
  // Jangan sampai keluar kanan layar
  if (left + cardW > window.innerWidth - 12) {
    left = window.innerWidth - cardW - 12
  }
  cardPos.value = {
    top:  rect.bottom + 8,
    left: Math.max(8, left),
  }
}

function openCard() {
  calcCardPos()
  showCard.value = true
}
function closeCard() {
  showCard.value = false
}
function toggleCard() {
  if (showCard.value) { closeCard() } else { openCard() }
}
const promoGradients = [
  'linear-gradient(135deg, #f59e0b, #ea580c)',
  'linear-gradient(135deg, #8b5cf6, #ec4899)',
  'linear-gradient(135deg, #10b981, #0891b2)',
  'linear-gradient(135deg, #ef4444, #f97316)',
  'linear-gradient(135deg, #3b82f6, #8b5cf6)',
]

// Pakai activePromos langsung dari store (sudah difilter ketat)
const activePromos = computed(() => voucherStore.activePromos)

let promoTimer = null
function startPromoTimer() {
  if (promoTimer) clearInterval(promoTimer)
  promoTimer = setInterval(() => {
    if (activePromos.value.length > 1) {
      promoIndex.value = (promoIndex.value + 1) % activePromos.value.length
    }
  }, 4000)
}

const popularServices = computed(() => servicesStore.services.slice(0, 4))
const upcomingBooking = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return bookingStore.bookings.find(b =>
    b.booking_date >= today && ['pending','confirmed'].includes(b.status)
  )
})
const recentReviews = computed(() => reviewsStore.reviews.slice(0, 3))

function formatPrice(p) { return Number(p || 0).toLocaleString('id-ID') }
function formatDateShort(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('id-ID', { day:'numeric', month:'short', year:'numeric' })
}
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

onUnmounted(() => { if (promoTimer) clearInterval(promoTimer) })

onMounted(async () => {
  // Load services dulu — tidak boleh terganggu oleh voucher
  await servicesStore.fetchServices()
  // Load voucher aktif secara terpisah (tidak throw kalau gagal)
  voucherStore.fetchActiveVouchers().then(() => startPromoTimer()).catch(() => {})
  loadingServices.value = false
  reviewsStore.fetchReviews()
  if (authStore.isLoggedIn) {
    bookingStore.fetchMyBookings(authStore.user.id)
  }
})
</script>
<style scoped>
/* ── Location wrapper ── */
.location-wrapper {
  position: relative;
  display: inline-block;
  overflow: visible;
}

/* ── Card ── */
.loc-card-fixed {
  width: 220px;
  height: 130px;
  background: white;
  border-radius: 18px;
  box-shadow: 0 0 0 2px #b0dbbf, 2px 6px 16px rgba(0,0,0,0.22);
  padding: 3px;
  overflow: hidden;
  cursor: default;
}

@media (max-width: 480px) {
  .loc-card-fixed {
    width: 240px;
  }
}

/* ── Transition ── */
.loc-card-fixed-enter-active { animation: locFadeIn 0.28s cubic-bezier(0.34,1.3,0.64,1) both; }
.loc-card-fixed-leave-active { animation: locFadeIn 0.18s cubic-bezier(0.4,0,1,1) reverse both; }

@keyframes locFadeIn {
  from { opacity: 0; transform: scale(0.85) translateY(-6px); filter: blur(6px); }
  to   { opacity: 1; transform: scale(1)    translateY(0);    filter: blur(0);   }
}

/* ── Inner card ── */
.loc-inner {
  position: relative;
  border-radius: calc(18px - 3px);
  height: 100%;
  width: 100%;
  border: 1.5px solid rgba(45,45,45,0.18);
  background: #daecdd;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* ── Map area ── */
.loc-map {
  position: relative;
  flex: 1 1 0;
  background: #e8f4ea;
  overflow: hidden;
}





/* ── Info strip ── */
.loc-info {
  position: relative;
  padding: 6px 10px 7px;
  background: #daecdd;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.loc-info-blur {
  position: absolute;
  inset: -10px 0 0 0;
  background: #daecdd;
  filter: blur(5px);
  z-index: -1;
}

.loc-name  { font-size: 12px; font-weight: 700; color: #4e8e5b; white-space: nowrap; }
.loc-sub   { font-size: 9px;  color: #5e836b; white-space: nowrap; flex: 1; margin-top: -1px; }
.loc-addr  { display: none; }

.loc-btn {
  font-size: 9px;
  font-weight: 600;
  color: white;
  background: #226630;
  border-radius: 8px;
  padding: 3px 7px;
  text-decoration: none;
  white-space: nowrap;
  flex-shrink: 0;
  transition: background 0.2s;
}
.loc-btn:hover { background: #1a4d24; }

/* ── Clouds ── */
.cloud {
  position: absolute;
  border-radius: 50%;
  z-index: 2;
  pointer-events: none;
  animation-timing-function: ease-in-out;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}

@keyframes driftCloud { from { transform: translateX(-8px); } to { transform: translateX(8px); } }

.cloud-1 {
  width: 28px; height: 12px;
  top: 6px; left: 40%;
  background: rgba(255,255,255,0.7);
  filter: blur(3px);
  animation-name: driftCloud;
  animation-duration: 8s;
}
.cloud-2 {
  width: 18px; height: 8px;
  top: 2px; right: 20%;
  background: rgba(255,255,255,0.55);
  filter: blur(2px);
  animation-name: driftCloud;
  animation-duration: 12s;
  animation-delay: -4s;
}
.cloud-3 {
  width: 12px; height: 6px;
  top: 14px; left: 20%;
  background: rgba(255,255,255,0.5);
  filter: blur(2px);
  animation-name: driftCloud;
  animation-duration: 10s;
  animation-delay: -2s;
}
</style>
