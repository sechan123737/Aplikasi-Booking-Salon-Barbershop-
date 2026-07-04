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

      <!-- Pesan sukses setelah reset password dari web -->
      <div v-if="route.query.reset === 'true'" 
        class="mb-4 bg-green-50 border border-green-200 rounded-xl p-3 text-sm text-green-700 text-center">
        ✅ Password berhasil diubah! Silakan login.
      </div>

      <!-- Pesan sukses konfirmasi email -->
      <div v-if="route.query.confirmed === 'true'"
        class="mb-4 bg-green-50 border border-green-200 rounded-xl p-3 text-sm text-green-700 text-center">
        ✅ Email berhasil dikonfirmasi! Silakan login.
      </div>

      <div class="space-y-4">
        <div>
          <label class="text-sm font-medium text-gray-700 block mb-1.5">Email</label>
          <input v-model="form.email" type="email" placeholder="Masukkan alamat email"
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

      <!-- Tambah sebelum tombol Masuk, setelah input password -->
    <div class="relative my-4">
      <div class="absolute inset-0 flex items-center">
        <div class="w-full border-t border-gray-200"></div>
      </div>
      <div class="relative flex justify-center text-sm">
        <span class="px-3 bg-white text-gray-400">atau</span>
      </div>
    </div>

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
      {{ loadingGoogle ? 'Menghubungkan...' : 'Masuk dengan Google' }}
    </button>

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
        <input v-model="forgotEmail" type="email" placeholder="Masukkan alamat email"
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
import { Capacitor } from '@capacitor/core'

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

const loadingGoogle = ref(false)

async function loginWithGoogle() {
  loadingGoogle.value = true
  try {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/`
      }
    })
    if (error) throw error
  } catch (e) {
    error.value = 'Gagal masuk dengan Google. Coba lagi.'
    loadingGoogle.value = false
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
    // Di Android app → link email tetap ke web untuk isi password baru
    // Setelah simpan di web → web redirect ke chaalon://login → buka app
    const { error: err } = await supabase.auth.resetPasswordForEmail(
      forgotEmail.value.trim(),
      { redirectTo: 'https://chaalon-booking.vercel.app/reset-password' }
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