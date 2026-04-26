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
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

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
</script>
