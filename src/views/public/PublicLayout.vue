<!-- src/views/public/PublicLayout.vue -->
<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
    <!-- Top Nav -->
    <header class="bg-white shadow-sm sticky top-0 z-50">
      <div class="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
        <router-link to="/" class="flex items-center gap-2">
          <span class="text-2xl">✂️</span>
          <span class="font-bold text-gray-900 text-lg">ChaLon</span>
        </router-link>

        <div class="flex items-center gap-3">
          <router-link v-if="authStore.isLoggedIn" to="/notifications" class="relative p-1">
            <span class="text-xl">🔔</span>
            <span v-if="notifStore.unreadCount" class="absolute -top-0.5 -right-0.5 bg-rose-500 text-white text-[10px] rounded-full w-4 h-4 flex items-center justify-center">
              {{ notifStore.unreadCount > 9 ? '9+' : notifStore.unreadCount }}
            </span>
          </router-link>

          <router-link v-if="authStore.isLoggedIn" to="/profile" class="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center text-sm font-semibold text-amber-700">
            {{ authStore.profile?.full_name?.[0]?.toUpperCase() || 'U' }}
          </router-link>

          <router-link v-else to="/login" class="text-sm font-medium text-amber-600 border border-amber-300 rounded-full px-3 py-1">
            Masuk
          </router-link>
        </div>
      </div>
    </header>

    <!-- Page Content -->
    <main class="flex-1 max-w-lg mx-auto w-full">
      <router-view />
    </main>

    <!-- Bottom Navigation -->
    <nav class="bg-white border-t border-gray-200 sticky bottom-0 z-50">
      <div class="max-w-lg mx-auto px-4 h-16 flex items-center justify-around">
        <router-link v-for="item in navItems" :key="item.to" :to="item.to"
          class="flex flex-col items-center gap-0.5 text-xs transition-colors"
          :class="$route.path === item.to || $route.path.startsWith(item.prefix || item.to + '/') ? 'text-amber-600' : 'text-gray-400'">
          <img :src="item.icon" class="w-6 h-6 object-contain"/>
          <span>{{ item.label }}</span>
        </router-link>
      </div>
    </nav>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useNotificationsStore } from '@/stores/notifications'

const authStore = useAuthStore()
const notifStore = useNotificationsStore()

const navItems = computed(() => {
  const base = [
    { to: '/', icon: '/Beranda.png', label: 'Beranda' },
    { to: '/services', icon: '/Layanan.png', label: 'Layanan' },
    { to: '/booking', icon: '/Booking.png', label: 'Booking' },
  ]
  if (authStore.isLoggedIn) {
    base.push({ to: '/history', icon: '/Riwayat.png', label: 'Riwayat' })
    base.push({ to: '/profile', icon: '/Profil.png', label: 'Profil' })
  } else {
    base.push({ to: '/login', icon: '/Profil.png', label: 'Masuk' })
  }
  return base
})
</script>
