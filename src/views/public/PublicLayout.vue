<!-- src/views/public/PublicLayout.vue -->
<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">

    <!-- ===== DESKTOP SIDEBAR (lg+) ===== -->
    <div class="hidden lg:flex fixed inset-y-0 left-0 w-64 bg-white border-r border-gray-100 flex-col z-50 shadow-sm">
      <!-- Logo -->
      <div class="px-6 py-5 border-b border-gray-100">
        <router-link to="/" class="flex items-center gap-3">
          <span class="text-3xl">✂️</span>
          <div>
            <span class="font-extrabold text-gray-900 text-xl tracking-tight block leading-none">ChaLon</span>
            <span class="text-xs text-amber-500 font-medium">Salon & Barbershop</span>
          </div>
        </router-link>
      </div>

      <!-- Desktop Nav Links -->
      <nav class="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
        <router-link
          v-for="item in navItems" :key="item.to" :to="item.to"
          class="flex items-center gap-3 px-4 py-3 rounded-2xl text-sm font-medium transition-all group"
          :class="isActive(item) ? 'bg-amber-500 text-white shadow-md shadow-amber-200' : 'text-gray-600 hover:bg-amber-50 hover:text-amber-700'">
          <img :src="item.icon" class="w-6 h-6 object-contain" :class="isActive(item) ? 'brightness-200' : ''" />
          <span>{{ item.label }}</span>
          <span v-if="item.to === '/notifications' && notifStore.unreadCount"
            class="ml-auto bg-rose-500 text-white text-[10px] rounded-full w-5 h-5 flex items-center justify-center font-bold">
            {{ notifStore.unreadCount > 9 ? '9+' : notifStore.unreadCount }}
          </span>
        </router-link>
      </nav>

      <!-- Desktop User Info -->
      <div class="px-4 py-4 border-t border-gray-100">
        <div v-if="authStore.isLoggedIn" class="flex items-center gap-3 px-3 py-3 rounded-2xl bg-amber-50">
          <div class="w-9 h-9 rounded-full bg-amber-400 flex items-center justify-center text-sm font-bold text-white flex-shrink-0">
            {{ authStore.profile?.full_name?.[0]?.toUpperCase() || 'U' }}
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-semibold text-gray-800 truncate">{{ authStore.profile?.full_name || 'Pengguna' }}</p>
            <p class="text-xs text-gray-400 truncate">{{ authStore.user?.email }}</p>
          </div>
          <router-link to="/profile" class="text-gray-400 hover:text-amber-600 transition-colors flex-shrink-0">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </router-link>
        </div>
        <router-link v-else to="/login"
          class="block w-full text-center py-3 bg-amber-500 text-white rounded-2xl font-semibold text-sm hover:bg-amber-600 transition-colors">
          Masuk / Daftar
        </router-link>
      </div>
    </div>

    <!-- ===== MOBILE TOP NAV (< lg) ===== -->
    <header class="lg:hidden bg-white shadow-sm sticky top-0 z-50">
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

    <!-- ===== MAIN CONTENT AREA ===== -->
    <div class="flex flex-1 lg:pl-64">
      <main class="flex-1 w-full lg:max-w-none max-w-lg mx-auto">
        <!-- Desktop content wrapper with centered max-width -->
        <div class="lg:max-w-4xl lg:mx-auto lg:px-6 lg:py-6">
          <router-view />
        </div>
      </main>
    </div>

    <!-- ===== MOBILE BOTTOM NAV (< lg) ===== -->
    <nav class="lg:hidden bg-white border-t border-gray-200 sticky bottom-0 z-50">
      <div class="max-w-lg mx-auto px-4 h-16 flex items-center justify-around">
        <router-link
          v-for="item in navItems" :key="item.to" :to="item.to"
          class="flex flex-col items-center gap-0.5 text-xs transition-colors"
          :class="isActive(item) ? 'text-amber-600' : 'text-gray-400'">
          <img :src="item.icon" class="w-6 h-6 object-contain"/>
          <span>{{ item.label }}</span>
        </router-link>
      </div>
    </nav>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useNotificationsStore } from '@/stores/notifications'

const authStore = useAuthStore()
const notifStore = useNotificationsStore()
const route = useRoute()

const navItems = computed(() => {
  const base = [
    { to: '/', icon: '/Beranda.png', label: 'Beranda' },
    { to: '/services', icon: '/Layanan.png', label: 'Layanan' },
    { to: '/booking', icon: '/Booking.png', label: 'Booking' },
  ]
  if (authStore.isLoggedIn) {
    base.push({ to: '/history', icon: '/Riwayat.png', label: 'Riwayat' })
    base.push({ to: '/notifications', icon: '/Beranda.png', label: 'Notifikasi', hideOnMobile: true })
    base.push({ to: '/profile', icon: '/Profil.png', label: 'Profil' })
  } else {
    base.push({ to: '/login', icon: '/Profil.png', label: 'Masuk' })
  }
  return base.filter(item => !item.hideOnMobile)
})

function isActive(item) {
  if (item.to === '/') return route.path === '/'
  return route.path === item.to || route.path.startsWith(item.to + '/')
}
</script>