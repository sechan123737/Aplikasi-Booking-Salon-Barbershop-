<!-- src/App.vue -->
<template>
  <div>
    <div v-if="!authReady" class="fixed inset-0 bg-white flex items-center justify-center">
      <!-- loading spinner (sama seperti sebelumnya) -->
      ...
    </div>

    <router-view v-else />

    <!-- ✅ Modal Lengkapi Profil untuk user Google baru -->
    <div v-if="showCompleteProfile" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
      <div class="bg-white rounded-3xl shadow-xl p-6 w-full max-w-sm">

        <div class="text-center mb-5">
          <div class="text-4xl mb-2">👋</div>
          <h2 class="font-bold text-gray-900 text-lg">Selamat Datang!</h2>
          <p class="text-gray-500 text-sm mt-1">Lengkapi profil kamu untuk melanjutkan.</p>
        </div>

        <!-- Nama sudah auto-fill dari Google, bisa diedit -->
        <div class="space-y-3">
          <div>
            <label class="text-sm font-medium text-gray-700 block mb-1.5">Nama Lengkap</label>
            <input v-model="completeForm.full_name" type="text" placeholder="Nama lengkap kamu"
              class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
          </div>
          <div>
            <label class="text-sm font-medium text-gray-700 block mb-1.5">Nomor HP</label>
            <input v-model="completeForm.phone" type="tel" placeholder="08xxxxxxxxxx"
              class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
          </div>
        </div>

        <div v-if="completeError" class="mt-3 bg-red-50 border border-red-200 rounded-xl p-3 text-sm text-red-600">
          {{ completeError }}
        </div>

        <button @click="saveCompleteProfile" :disabled="completeSaving"
          class="w-full mt-5 py-3.5 rounded-2xl bg-amber-500 hover:bg-amber-600 text-white font-bold transition-colors flex items-center justify-center gap-2">
          <span v-if="completeSaving" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          {{ completeSaving ? 'Menyimpan...' : 'Simpan & Lanjutkan' }}
        </button>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useNotificationsStore } from '@/stores/notifications'
import { useServicesStore } from '@/stores/services'
import { useStaffStore } from '@/stores/staff'
import { App as CapApp } from '@capacitor/app'
import { useRouter } from 'vue-router'
import { Capacitor } from '@capacitor/core'

const authStore     = useAuthStore()
const notifStore    = useNotificationsStore()
const servicesStore = useServicesStore()
const staffStore    = useStaffStore()
const authReady     = ref(false)
const router        = useRouter()

// ── Lengkapi Profil Google ─────────────────────────────────────
const showCompleteProfile = ref(false)
const completeForm  = ref({ full_name: '', phone: '' })
const completeError = ref('')
const completeSaving = ref(false)

// Cek apakah profil perlu dilengkapi (user Google tanpa nomor HP)
function checkProfileComplete() {
  const profile = authStore.profile
  const user    = authStore.user

  if (!profile || !user) return

  // Cek apakah login via Google (provider = google)
  const isGoogle = user.app_metadata?.provider === 'google' ||
                   user.identities?.some(i => i.provider === 'google')

  // Tampilkan modal jika nomor HP kosong
  if (isGoogle && !profile.phone) {
    completeForm.value.full_name = profile.full_name || ''
    completeForm.value.phone     = ''
    showCompleteProfile.value    = true
  }
}

async function saveCompleteProfile() {
  completeError.value = ''
  if (!completeForm.value.full_name.trim()) {
    completeError.value = 'Nama lengkap wajib diisi.'
    return
  }
  if (!completeForm.value.phone.trim()) {
    completeError.value = 'Nomor HP wajib diisi.'
    return
  }

  completeSaving.value = true
  try {
    await authStore.updateProfile({
      full_name: completeForm.value.full_name.trim(),
      phone:     completeForm.value.phone.trim()
    })
    showCompleteProfile.value = false
  } catch (e) {
    completeError.value = 'Gagal menyimpan. Coba lagi.'
  } finally {
    completeSaving.value = false
  }
}

// Watch perubahan profil — tampilkan modal saat profil baru dimuat
watch(() => authStore.profile, (newProfile) => {
  if (newProfile) checkProfileComplete()
})

onMounted(async () => {
  // ── Deep link handler ──────────────────────────────────────
  if (Capacitor.isNativePlatform()) {
    CapApp.addListener('appUrlOpen', async (event) => {
      const url = event.url
      if (url.startsWith('chaalon://login')) {
        router.push('/login?reset=true')
        return
      }
      if (url.startsWith('chaalon://confirm')) {
        router.push('/login?confirmed=true')
        return
      }
    })
  }

  // ── Init app ───────────────────────────────────────────────
  try {
    await Promise.all([
      authStore.init(),
      servicesStore.fetchServices(),
      staffStore.fetchStaff(),
    ])
  } catch (e) {
    console.error('App init error:', e)
  } finally {
    authReady.value = true
  }

  if (authStore.user) {
    notifStore.fetchNotifications(authStore.user.id)
    notifStore.subscribeToNotifications(authStore.user.id)
    // Cek profil setelah init
    checkProfileComplete()
  }
})
</script>