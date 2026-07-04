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
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Nomor Hp</label>
          <input v-model="form.phone" type="tel" placeholder="Masukkan nomor telepon"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Email</label>
          <input v-model="form.email" type="email" placeholder="Buat alamat email"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="text-sm font-medium text-gray-700">Password</label>
              <span class="text-xs text-gray-400">Min 8 karakter</span>
            </div>
            <div class="relative">
              <input v-model="form.password" :type="showPass ? 'text' : 'password'" placeholder="Buat password"
                class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none pr-12" />
              <button @click="showPass = !showPass" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-lg">
                {{ showPass ? '🙈' : '👁️' }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="relative my-4">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full border-t border-gray-200"></div>
        </div>
        <div class="relative flex justify-center text-sm">
          <span class="px-3 bg-white text-gray-400">atau</span>
        </div>
      </div>

      <!-- Setelah divider "atau" -->
      <button @click="loginWithGoogle" :disabled="loadingGoogle"
      class="w-full py-3.5 rounded-2xl border-2 border-gray-200 hover:border-gray-300 hover:bg-gray-50 font-semibold text-gray-700 transition-colors flex items-center justify-center gap-3">
      <span v-if="loadingGoogle" class="w-4 h-4 border-2 border-gray-400 border-t-transparent rounded-full animate-spin"></span>
      <svg v-else width="18" height="18" viewBox="0 0 48 48">
        <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
        <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
        <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
        <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
        <path fill="none" d="M0 0h48v48H0z"/>
      </svg>
        {{ loadingGoogle ? 'Menghubungkan...' : 'Daftar dengan Google' }}
      </button>

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
const showPass      = ref(false)
const loading       = ref(false)
const loadingGoogle = ref(false)
const error         = ref('')
const success       = ref(false)

// ── Daftar dengan Google ───────────────────────────────────────
async function loginWithGoogle() {
  loadingGoogle.value = true
  error.value = ''
  try {
    await authStore.loginWithGoogle(`${window.location.origin}/`)
  } catch (e) {
    error.value = 'Gagal daftar dengan Google. Coba lagi.'
    loadingGoogle.value = false
  }
}

// ── Daftar dengan email ────────────────────────────────────────
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
  error.value   = ''
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
