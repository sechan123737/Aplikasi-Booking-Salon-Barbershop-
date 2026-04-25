<!-- src/views/public/ServicesView.vue -->
<template>
  <div class="px-4 py-6">
    <h1 class="text-xl font-bold text-gray-900 mb-4">Layanan Kami</h1>

    <!-- Category Filter -->
    <div class="flex gap-2 overflow-x-auto pb-2 mb-5 no-scrollbar">
      <button v-for="cat in categories" :key="cat.value"
        @click="activeCategory = cat.value"
        class="flex-shrink-0 flex items-center px-4 py-1.5 rounded-full text-sm font-medium transition-colors"
        :class="activeCategory === cat.value ? 'bg-amber-500 text-white' : 'bg-gray-100 text-gray-600'">
        <img :src="cat.icon" class="w-5 h-5 object-contain" />
        <span>{{ cat.label }}</span>
      </button>
    </div>

    <div v-if="servicesStore.loading" class="space-y-3">
      <div v-for="i in 5" :key="i" class="h-24 bg-gray-100 rounded-2xl animate-pulse"></div>
    </div>

    <div v-else class="space-y-3">
      <div v-for="svc in filteredServices" :key="svc.id"
        class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex items-center gap-4">
        <img :src="getCategoryIcon(svc.category)" class="w-8 h-8 object-contain" />
        <div class="flex-1">
          <p class="font-semibold text-gray-800">{{ svc.name }}</p>
          <p v-if="svc.description" class="text-xs text-gray-500 mt-0.5">{{ svc.description }}</p>
          <div class="flex items-center gap-3 mt-1">
            <span class="text-amber-600 font-bold text-sm">Rp {{ formatPrice(svc.price) }}</span>
            <span class="text-gray-400 text-xs">⏱ {{ svc.duration_minutes }} menit</span>
          </div>
        </div>
        <router-link :to="{ name: 'booking', query: { service: svc.id } }"
          class="px-3 py-2 bg-amber-500 text-white text-xs font-semibold rounded-xl hover:bg-amber-600 transition-colors">
          Booking
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useServicesStore } from '@/stores/services'

const servicesStore = useServicesStore()
const activeCategory = ref('all')

const categories = [
  { value: 'all', label: 'Semua', icon: '/icons/Semua.png' },
  { value: 'rambut', label: 'Rambut', icon: '/icons/Rambut.png' },
  { value: 'barbershop', label: 'Barbershop', icon: '/icons/Barbershop.png' },
  { value: 'wajah', label: 'Wajah', icon: '/icons/Wajah.png' },
  { value: 'kuku', label: 'Kuku', icon: '/icons/Kuku.png' },
]

const filteredServices = computed(() => {
  if (activeCategory.value === 'all') return servicesStore.services
  return servicesStore.services.filter(s => s.category === activeCategory.value)
})

function formatPrice(p) { return Number(p).toLocaleString('id-ID') }
function getCategoryIcon(cat) {
  const map = {
    rambut:     '/icons/Rambut.png',
    wajah:      '/icons/Wajah.png',
    kuku:       '/icons/Kuku.png',
    barbershop: '/icons/Barbershop.png',
    general:    '/Layanan.png',
  }
  return map[cat] || '/Layanan.png'
}

onMounted(() => servicesStore.fetchServices())
</script>
