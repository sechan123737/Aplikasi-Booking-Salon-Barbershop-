<!-- src/views/public/NotificationsView.vue -->
<template>
  <div class="px-4 py-6">
    <div class="flex items-center justify-between mb-4">
      <h1 class="text-xl font-bold text-gray-900">Notifikasi</h1>
      <button v-if="notifStore.unreadCount" @click="notifStore.markAllAsRead(authStore.user.id)"
        class="text-xs text-amber-600 font-medium">Tandai semua dibaca</button>
    </div>
    <div v-if="notifStore.loading" class="space-y-3">
      <div v-for="i in 4" :key="i" class="h-20 bg-gray-100 rounded-2xl animate-pulse"></div>
    </div>
    <div v-else-if="notifStore.notifications.length === 0" class="text-center py-16">
      <span class="text-5xl block mb-3">🔔</span>
      <p class="text-gray-500">Belum ada notifikasi</p>
    </div>
    <div v-else class="space-y-2">
      <div v-for="n in notifStore.notifications" :key="n.id"
        @click="notifStore.markAsRead(n.id)"
        class="bg-white rounded-2xl p-4 shadow-sm border cursor-pointer transition-colors"
        :class="n.is_read ? 'border-gray-100' : 'border-amber-200 bg-amber-50'">
        <div class="flex items-start gap-3">
          <div class="w-2 h-2 rounded-full mt-2 flex-shrink-0" :class="n.is_read ? 'bg-gray-200' : 'bg-amber-500'"></div>
          <div>
            <p class="font-semibold text-gray-800 text-sm">{{ n.title }}</p>
            <p class="text-gray-600 text-sm mt-0.5">{{ n.message }}</p>
            <p class="text-xs text-gray-400 mt-1">{{ formatTime(n.created_at) }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useNotificationsStore } from '@/stores/notifications'

const authStore = useAuthStore()
const notifStore = useNotificationsStore()

function formatTime(ts) {
  return new Date(ts).toLocaleDateString('id-ID', { day:'numeric', month:'short', hour:'2-digit', minute:'2-digit' })
}

onMounted(() => {
  if (authStore.user) notifStore.fetchNotifications(authStore.user.id)
})
</script>
