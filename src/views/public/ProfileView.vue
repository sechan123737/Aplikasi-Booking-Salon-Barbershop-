<!-- src/views/public/ProfileView.vue -->
<template>
  <div class="px-4 py-6">
    <h1 class="text-xl font-bold text-gray-900 mb-6">Profil Saya</h1>

    <!-- Avatar -->
    <div class="flex flex-col items-center mb-8">
      <div class="relative mb-3">
        <!-- Foto profil — klik untuk perbesar -->
        <div 
          class="w-24 h-24 rounded-full overflow-hidden bg-amber-100 flex items-center justify-center cursor-pointer"
          @click="authStore.profile?.avatar_url && (showLightbox = true)">
          <img v-if="authStore.profile?.avatar_url"
            :src="authStore.profile.avatar_url"
            class="w-full h-full object-cover"
            alt="Foto profil" />
          <span v-else class="text-3xl font-bold text-amber-700">
            {{ authStore.profile?.full_name?.[0]?.toUpperCase() || 'U' }}
          </span>
        </div>

        <!-- Tombol ganti foto -->
        <button @click="triggerUpload"
          class="absolute bottom-0 right-0 w-8 h-8 bg-amber-500 hover:bg-amber-600 rounded-full flex items-center justify-center shadow-md transition-colors">
          <span class="text-white text-sm">📷</span>
        </button>
        <input ref="fileInput" type="file" accept="image/*" class="hidden" @change="handlePhotoUpload" />
      </div>

      <!-- Loading upload -->
      <div v-if="uploadingPhoto" class="flex items-center gap-2 text-sm text-amber-600 mb-1">
        <span class="w-3 h-3 border-2 border-amber-500 border-t-transparent rounded-full animate-spin"></span>
        Mengunggah foto...
      </div>

      <p class="font-bold text-gray-800 text-lg">{{ authStore.profile?.full_name }}</p>
      <p class="text-gray-400 text-sm">{{ authStore.user?.email }}</p>
      <span v-if="authStore.isAdmin" class="mt-2 px-3 py-1 bg-purple-100 text-purple-700 text-xs font-medium rounded-full">Admin</span>
    </div>

    <!-- Lightbox foto profil -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showLightbox"
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/90"
          @click="showLightbox = false">

          <!-- Foto besar -->
          <div class="relative flex items-center justify-center p-4" @click.stop>
            <img
              :src="authStore.profile.avatar_url"
              class="max-w-[90vw] max-h-[80vh] rounded-2xl object-contain shadow-2xl"
              alt="Foto profil" />

            <!-- Tombol tutup -->
            <button
              @click="showLightbox = false"
              class="absolute top-2 right-2 w-9 h-9 bg-black/50 hover:bg-black/70 rounded-full flex items-center justify-center text-white text-lg transition-colors">
              ✕
            </button>
          </div>

          <!-- Tap area luar untuk tutup -->
          <div class="absolute inset-0 -z-10" @click="showLightbox = false"></div>
        </div>
      </Transition>
    </Teleport>

    <!-- Edit Form -->
    <div v-if="editMode" class="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 mb-4">
      <div class="space-y-4">
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Nama Lengkap</label>
          <input v-model="form.full_name" type="text" class="w-full border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Nomor HP</label>
          <input v-model="form.phone" type="tel" class="w-full border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none" />
        </div>
      </div>
      <div class="flex gap-3 mt-5">
        <button @click="editMode = false" class="flex-1 py-3 rounded-xl border-2 border-gray-200 font-medium text-gray-600">Batal</button>
        <button @click="saveProfile" :disabled="saving"
          class="flex-1 py-3 rounded-xl bg-amber-500 text-white font-medium hover:bg-amber-600 transition-colors">
          {{ saving ? 'Menyimpan...' : 'Simpan' }}
        </button>
      </div>
    </div>

    <div v-else class="bg-white rounded-2xl shadow-sm border border-gray-100 divide-y divide-gray-50 mb-4">
      <div class="flex items-center justify-between p-4">
        <div>
          <p class="text-xs text-gray-400">Nama Lengkap</p>
          <p class="font-medium text-gray-800">{{ authStore.profile?.full_name || '-' }}</p>
        </div>
      </div>
      <div class="flex items-center justify-between p-4">
        <div>
          <p class="text-xs text-gray-400">Nomor HP</p>
          <p class="font-medium text-gray-800">{{ authStore.profile?.phone || '-' }}</p>
        </div>
      </div>
      <div class="p-4">
        <button @click="startEdit" class="text-amber-600 text-sm font-medium">✏️ Edit Profil</button>
      </div>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 divide-y divide-gray-50 mb-4">
      <router-link to="/history" class="flex items-center justify-between p-4">
        <div class="flex items-center gap-3">
          <span class="text-xl">📋</span>
          <span class="text-sm font-medium text-gray-700">Riwayat Booking</span>
        </div>
        <span class="text-gray-300">›</span>
      </router-link>
      <router-link to="/notifications" class="flex items-center justify-between p-4">
        <div class="flex items-center gap-3">
          <span class="text-xl">🔔</span>
          <span class="text-sm font-medium text-gray-700">Notifikasi</span>
        </div>
        <span class="text-gray-300">›</span>
      </router-link>
      <router-link v-if="authStore.isAdmin" to="/admin" class="flex items-center justify-between p-4">
        <div class="flex items-center gap-3">
          <span class="text-xl">⚙️</span>
          <span class="text-sm font-medium text-purple-700">Panel Admin</span>
        </div>
        <span class="text-gray-300">›</span>
      </router-link>
    </div>

    <button @click="logout" class="w-full py-3.5 rounded-2xl border-2 border-red-200 text-red-500 font-semibold hover:bg-red-50 transition-colors">
      Keluar
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const authStore      = useAuthStore()
const router         = useRouter()
const editMode       = ref(false)
const saving         = ref(false)
const form           = ref({ full_name: '', phone: '' })
const fileInput      = ref(null)
const uploadingPhoto = ref(false)
const showLightbox = ref(false)

function triggerUpload() {
  fileInput.value?.click()
}

async function handlePhotoUpload(event) {
  const file = event.target.files?.[0]
  if (!file) return
  if (file.size > 2 * 1024 * 1024) { alert('Ukuran foto maksimal 2MB.'); return }
  if (!file.type.startsWith('image/')) { alert('File harus berupa gambar.'); return }

  uploadingPhoto.value = true
  try {
    const userId = authStore.user.id
    const ext    = file.name.split('.').pop()
    const path   = `avatars/${userId}.${ext}`

    const { error: uploadErr } = await supabase.storage
      .from('avatars')
      .upload(path, file, { upsert: true })
    if (uploadErr) throw uploadErr

    const { data } = supabase.storage.from('avatars').getPublicUrl(path)
    const publicUrl = data.publicUrl + '?t=' + Date.now()

    await authStore.updateProfile({ avatar_url: publicUrl })
  } catch (e) {
    console.error('Upload error:', e)
    alert('Gagal mengunggah foto. Coba lagi.')
  } finally {
    uploadingPhoto.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

function startEdit() {
  form.value.full_name = authStore.profile?.full_name || ''
  form.value.phone     = authStore.profile?.phone || ''
  editMode.value       = true
}

async function saveProfile() {
  saving.value = true
  await authStore.updateProfile(form.value)
  saving.value  = false
  editMode.value = false
}

async function logout() {
  await authStore.logout()
  router.push('/')
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>