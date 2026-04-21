<!-- src/App.vue -->
<template>
  <div>
    <div v-if="!authReady" class="fixed inset-0 bg-white flex items-center justify-center">
      <div class="text-center">
        <span class="text-5xl block mb-3 animate-pulse">✂️</span>
        <p class="text-gray-400 text-sm">Memuat...</p>
      </div>
    </div>
    <router-view v-else />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useNotificationsStore } from '@/stores/notifications'

const authStore = useAuthStore()
const notifStore = useNotificationsStore()
const authReady = ref(false)

onMounted(async () => {
  try {
    await authStore.init()
  } catch (e) {
    console.error('Auth init error:', e)
  } finally {
    authReady.value = true
  }

  if (authStore.user) {
    notifStore.fetchNotifications(authStore.user.id)
    notifStore.subscribeToNotifications(authStore.user.id)
  }
})
</script>