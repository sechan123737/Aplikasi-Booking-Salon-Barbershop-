<!-- src/views/public/LoginView.vue -->
<template>
  <div class="min-h-screen bg-gray-50 flex flex-col justify-center px-6 py-12">
    <!-- Header -->
    <div class="text-center mb-8">
      <span class="text-5xl block mb-3">✂️</span>
      <h1 class="text-2xl font-bold text-gray-900">Selamat Datang</h1>
      <p class="text-gray-500 text-sm mt-1">Masuk ke akun ChaaLon Anda</p>
    </div>

    <!-- Form -->
    <div class="bg-white rounded-3xl shadow-sm border border-gray-100 p-6 max-w-sm mx-auto w-full">
      <div class="space-y-4">
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Email</label>
          <input v-model="form.email" type="email" placeholder="email@contoh.com"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none text-gray-800"
            @keyup.enter="login" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Password</label>
          <div class="relative">
            <input v-model="form.password" :type="showPass ? 'text' : 'password'" placeholder="Masukkan password"
              class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none text-gray-800 pr-12"
              @keyup.enter="login" />
            <button @click="showPass = !showPass"
              class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-lg">
              {{ showPass ? '🙈' : '👁️' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Link Lupa Password -->
      <div class="flex justify-end mt-1">
        <button @click="showForgot = true"
          class="text-xs text-amber-600 hover:text-amber-700 font-medium">
          Lupa password?
        </button>
      </div>

      <div v-if="error" class="mt-4 bg-red-50 border border-red-200 rounded-xl p-3 text-sm text-red-600">
        {{ error }}
      </div>

      <button @click="login" :disabled="loading"
        class="w-full mt-6 py-3.5 rounded-2xl bg-amber-500 hover:bg-amber-600 text-white font-bold transition-colors flex items-center justify-center gap-2">
        <span v-if="loading" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
        {{ loading ? 'Masuk...' : 'Masuk' }}
      </button>

      <p class="text-center text-sm text-gray-500 mt-4">
        Belum punya akun?
        <router-link to="/register" class="text-amber-600 font-semibold">Daftar</router-link>
      </p>
    </div>

    <router-link to="/" class="text-center text-sm text-gray-400 mt-6 block">← Kembali ke Beranda</router-link>
  </div>

  <!-- Modal Lupa Password -->
  <div v-if="showForgot" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-black/60" @click="closeForgot"></div>
    <div class="relative bg-white rounded-3xl shadow-xl p-6 w-full max-w-sm">

      <!-- Icon -->
      <div class="text-center mb-5">
        <div class="w-14 h-14 bg-amber-100 rounded-2xl flex items-center justify-center text-3xl mx-auto mb-3">
          🔑
        </div>
        <h2 class="font-bold text-gray-900 text-lg">Lupa Password?</h2>
        <p class="text-gray-500 text-sm mt-1">
          Masukkan email kamu, kami akan kirim link untuk reset password.
        </p>
      </div>

      <!-- Input email -->
      <div v-if="!forgotSent">
        <input v-model="forgotEmail" type="email" placeholder="email@contoh.com"
          @keyup.enter="sendResetEmail"
          class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none text-gray-800 mb-3" />

        <div v-if="forgotError" class="bg-red-50 border border-red-200 rounded-xl p-3 text-sm text-red-600 mb-3">
          {{ forgotError }}
        </div>

        <div class="flex gap-3">
          <button @click="closeForgot"
            class="flex-1 py-3 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600 hover:bg-gray-50 transition-colors">
            Batal
          </button>
          <button @click="sendResetEmail" :disabled="forgotLoading"
            class="flex-1 py-3 rounded-2xl bg-amber-500 hover:bg-amber-600 text-white font-semibold transition-colors flex items-center justify-center gap-2">
            <span v-if="forgotLoading" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            {{ forgotLoading ? 'Mengirim...' : 'Kirim Link' }}
          </button>
        </div>
      </div>

      <!-- Sukses -->
      <div v-else class="text-center">
        <div class="text-4xl mb-3">📧</div>
        <p class="text-gray-700 font-medium mb-1">Email terkirim!</p>
        <p class="text-gray-500 text-sm mb-5">
          Cek inbox <strong>{{ forgotEmail }}</strong> dan klik link reset password yang kami kirim.
        </p>
        <p class="text-gray-400 text-xs mb-5">Tidak ada email? Cek folder spam/junk.</p>
        <button @click="closeForgot"
          class="w-full py-3 rounded-2xl bg-amber-500 text-white font-semibold hover:bg-amber-600 transition-colors">
          Oke, Mengerti
        </button>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const form = ref({ email: '', password: '' })
const showPass = ref(false)
const loading = ref(false)
const error = ref('')

async function login() {
  if (!form.value.email || !form.value.password) {
    error.value = 'Email dan password wajib diisi.'
    return
  }
  loading.value = true
  error.value = ''
  try {
    await authStore.login(form.value.email, form.value.password)
    const redirect = route.query.redirect || (authStore.isAdmin ? '/admin' : '/')
    router.push(redirect)
  } catch (e) {
    error.value = 'Email atau password salah.'
  } finally {
    loading.value = false
  }
}

// ── Lupa Password ──────────────────────────────────────────────
const showForgot   = ref(false)
const forgotEmail  = ref('')
const forgotError  = ref('')
const forgotLoading = ref(false)
const forgotSent   = ref(false)

function closeForgot() {
  showForgot.value  = false
  forgotEmail.value = ''
  forgotError.value = ''
  forgotSent.value  = false
}

async function sendResetEmail() {
  forgotError.value = ''
  if (!forgotEmail.value.trim()) {
    forgotError.value = 'Email wajib diisi.'
    return
  }

  forgotLoading.value = true
  try {
    const { error: err } = await supabase.auth.resetPasswordForEmail(
      forgotEmail.value.trim(),
      {
        redirectTo: import.meta.env.VITE_APP_URL
          ? `${import.meta.env.VITE_APP_URL}/reset-password`
          : `${window.location.origin}/reset-password`
      }
    )
      if (err) throw err
    forgotSent.value = true
  } catch (e) {
    forgotError.value = 'Gagal mengirim email. Pastikan email sudah benar.'
  } finally {
    forgotLoading.value = false
  }
}
</script>