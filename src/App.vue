<!-- src/App.vue -->
<template>
  <div>
    <div v-if="!authReady" class="fixed inset-0 bg-white flex items-center justify-center">
      <div class="text-center">
        <!-- Animasi loading barbershop -->
        <div class="relative w-20 h-20 mx-auto mb-4">
          <div class="absolute inset-0 rounded-full border-4 border-amber-100"></div>
          <div class="absolute inset-0 rounded-full border-4 border-amber-500 border-t-transparent animate-spin"></div>
          <div class="absolute inset-0 flex items-center justify-center text-3xl">✂️</div>
        </div>
        <p class="text-gray-700 font-semibold text-sm">ChaaLon</p>
        <p class="text-gray-400 text-xs mt-1">Menyiapkan aplikasi...</p>
      </div>
    </div>
    <router-view v-else />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useNotificationsStore } from '@/stores/notifications'
import { useServicesStore } from '@/stores/services'
import { useStaffStore } from '@/stores/staff'

const authStore    = useAuthStore()
const notifStore   = useNotificationsStore()
const servicesStore = useServicesStore()
const staffStore   = useStaffStore()
const authReady    = ref(false)

onMounted(async () => {
  try {
    // Jalankan auth + prefetch data secara paralel
    await Promise.all([
      authStore.init(),
      servicesStore.fetchServices(),  // prefetch layanan
      staffStore.fetchStaff(),        // prefetch staff
    ])
  } catch (e) {
    console.error('App init error:', e)
  } finally {
    authReady.value = true
  }

  if (authStore.user) {
    notifStore.fetchNotifications(authStore.user.id)
    notifStore.subscribeToNotifications(authStore.user.id)
  }
})
</script>