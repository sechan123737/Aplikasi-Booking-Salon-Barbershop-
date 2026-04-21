<!-- src/views/public/RegisterView.vue -->
<template>
  <div class="min-h-screen bg-gray-50 flex flex-col justify-center px-6 py-12">
    <div class="text-center mb-8">
      <span class="text-5xl block mb-3">✂️</span>
      <h1 class="text-2xl font-bold text-gray-900">Buat Akun</h1>
      <p class="text-gray-500 text-sm mt-1">Daftar dan nikmati kemudahan booking</p>
    </div>

    <div class="bg-white rounded-3xl shadow-sm border border-gray-100 p-6 max-w-sm mx-auto w-full">
      <div class="space-y-4">
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Nama Lengkap</label>
          <input v-model="form.full_name" type="text" placeholder="Nama Anda"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Nomor HP</label>
          <input v-model="form.phone" type="tel" placeholder="08xxxxxxxxxx"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Email</label>
          <input v-model="form.email" type="email" placeholder="email@contoh.com"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Password</label>
          <div class="relative">
            <input v-model="form.password" :type="showPass ? 'text' : 'password'" placeholder="Min. 8 karakter"
              class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none pr-12" />
            <button @click="showPass = !showPass" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-lg">
              {{ showPass ? '🙈' : '👁️' }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="error" class="mt-4 bg-red-50 border border-red-200 rounded-xl p-3 text-sm text-red-600">{{ error }}</div>
      <div v-if="success" class="mt-4 bg-green-50 border border-green-200 rounded-xl p-3 text-sm text-green-700">
        ✅ Pendaftaran berhasil! Silakan cek email untuk verifikasi.
      </div>

      <button @click="register" :disabled="loading"
        class="w-full mt-6 py-3.5 rounded-2xl bg-amber-500 hover:bg-amber-600 text-white font-bold transition-colors flex items-center justify-center gap-2">
        <span v-if="loading" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
        {{ loading ? 'Mendaftar...' : 'Daftar Sekarang' }}
      </button>

      <p class="text-center text-sm text-gray-500 mt-4">
        Sudah punya akun?
        <router-link to="/login" class="text-amber-600 font-semibold">Masuk</router-link>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const form = ref({ full_name: '', phone: '', email: '', password: '' })
const showPass = ref(false)
const loading = ref(false)
const error = ref('')
const success = ref(false)

async function register() {
  if (!form.value.full_name || !form.value.email || !form.value.password) {
    error.value = 'Semua field wajib diisi.'
    return
  }
  if (form.value.password.length < 8) {
    error.value = 'Password minimal 8 karakter.'
    return
  }
  loading.value = true
  error.value = ''
  try {
    await authStore.register(form.value.email, form.value.password, form.value.full_name, form.value.phone)
    success.value = true
  } catch (e) {
    error.value = e.message || 'Pendaftaran gagal. Coba lagi.'
  } finally {
    loading.value = false
  }
}
</script>
