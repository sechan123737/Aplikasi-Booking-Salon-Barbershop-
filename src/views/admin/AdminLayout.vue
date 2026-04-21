<!-- src/views/admin/AdminLayout.vue -->
<template>
  <div class="min-h-screen bg-gray-950 flex">
    <!-- Sidebar Desktop -->
    <aside class="hidden lg:flex w-64 flex-col bg-gray-900 border-r border-gray-800 fixed inset-y-0">
      <!-- Logo -->
      <div class="h-16 flex items-center gap-3 px-6 border-b border-gray-800">
        <span class="text-2xl">✂️</span>
        <div>
          <p class="font-bold text-white text-sm">SalonQ</p>
          <p class="text-gray-500 text-xs">Admin Panel</p>
        </div>
      </div>

      <!-- Nav -->
      <nav class="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
        <router-link v-for="item in navItems" :key="item.to" :to="item.to"
          class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors"
          :class="isActive(item.to) ? 'bg-amber-500 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-white'">
          <span class="text-lg">{{ item.icon }}</span>
          {{ item.label }}
        </router-link>
      </nav>

      <!-- User -->
      <div class="p-4 border-t border-gray-800">
        <div class="flex items-center gap-3 mb-3">
          <div class="w-8 h-8 rounded-full bg-amber-500 flex items-center justify-center text-white font-bold text-sm">
            {{ authStore.profile?.full_name?.[0]?.toUpperCase() || 'A' }}
          </div>
          <div class="min-w-0">
            <p class="text-white text-sm font-medium truncate">{{ authStore.profile?.full_name }}</p>
            <p class="text-gray-500 text-xs">Administrator</p>
          </div>
        </div>
        <router-link to="/" class="block text-center text-xs text-gray-500 hover:text-gray-300 mb-1">← Lihat Toko</router-link>
        <button @click="logout" class="w-full text-center text-xs text-red-400 hover:text-red-300">Keluar</button>
      </div>
    </aside>

    <!-- Mobile Header -->
    <div class="lg:hidden fixed top-0 inset-x-0 z-50 h-14 bg-gray-900 border-b border-gray-800 flex items-center justify-between px-4">
      <div class="flex items-center gap-2">
        <span class="text-xl">✂️</span>
        <p class="font-bold text-white">SalonQ Admin</p>
      </div>
      <button @click="mobileMenuOpen = !mobileMenuOpen" class="text-gray-400 text-2xl">☰</button>
    </div>

    <!-- Mobile Drawer -->
    <div v-if="mobileMenuOpen" class="lg:hidden fixed inset-0 z-50 flex">
      <div class="fixed inset-0 bg-black/60" @click="mobileMenuOpen = false"></div>
      <aside class="relative w-64 bg-gray-900 flex flex-col">
        <div class="h-14 flex items-center gap-2 px-4 border-b border-gray-800">
          <span class="text-xl">✂️</span>
          <p class="font-bold text-white">SalonQ Admin</p>
        </div>
        <nav class="flex-1 px-3 py-3 space-y-1 overflow-y-auto">
          <router-link v-for="item in navItems" :key="item.to" :to="item.to"
            @click="mobileMenuOpen = false"
            class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors"
            :class="isActive(item.to) ? 'bg-amber-500 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-white'">
            <span>{{ item.icon }}</span>{{ item.label }}
          </router-link>
        </nav>
        <div class="p-4 border-t border-gray-800">
          <button @click="logout" class="w-full text-center text-sm text-red-400">Keluar</button>
        </div>
      </aside>
    </div>

    <!-- Main Content -->
    <div class="flex-1 lg:ml-64 flex flex-col min-h-screen">
      <div class="lg:hidden h-14"></div>
      <main class="flex-1 p-4 lg:p-8">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()
const mobileMenuOpen = ref(false)

const navItems = [
  { to: '/admin/dashboard', icon: '📊', label: 'Dashboard' },
  { to: '/admin/bookings',  icon: '📅', label: 'Booking' },
  { to: '/admin/services',  icon: '✂️', label: 'Layanan' },
  { to: '/admin/staff',     icon: '👤', label: 'Karyawan' },
  { to: '/admin/customers', icon: '👥', label: 'Pelanggan' },
  { to: '/admin/reviews',   icon: '⭐', label: 'Ulasan' },
  { to: '/admin/schedule',  icon: '🕐', label: 'Jadwal Buka' },
]

function isActive(to) {
  return route.path === to || route.path.startsWith(to + '/')
}

async function logout() {
  await authStore.logout()
  router.push('/login')
}
</script>
