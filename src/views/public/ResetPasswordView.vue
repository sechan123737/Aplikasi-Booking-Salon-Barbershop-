<!-- src/views/public/ResetPasswordView.vue -->
<template>
  <div class="min-h-screen bg-gray-50 flex flex-col justify-center px-6 py-12">
    <div class="text-center mb-8">
      <div class="w-16 h-16 bg-amber-100 rounded-2xl flex items-center justify-center text-4xl mx-auto mb-4">
        🔐
      </div>
      <h1 class="text-2xl font-bold text-gray-900">Reset Password</h1>
      <p class="text-gray-500 text-sm mt-1">Masukkan password baru kamu</p>
    </div>

    <div class="bg-white rounded-3xl shadow-sm border border-gray-100 p-6 max-w-sm mx-auto w-full">

      <!-- ✅ Sukses + Animasi Ceklis -->
      <div v-if="success" class="text-center py-6">
        <div class="flex justify-center mb-5">
          <svg class="checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52">
            <circle class="checkmark__circle" cx="26" cy="26" r="25" fill="none"/>
            <path class="checkmark__check" fill="none" d="M14.1 27.2l7.1 7.2 16.7-16.8"/>
          </svg>
        </div>
        <p class="font-bold text-gray-900 text-lg mb-2">Password Berhasil Diubah!</p>
        <p class="text-gray-500 text-sm mb-1">Kamu akan diarahkan ke halaman login...</p>
        <p class="text-amber-500 font-bold text-2xl mt-3">{{ countdown }}</p>
      </div>

      <div v-else>
        <!-- Spinner -->
        <div v-if="waitingSession" class="text-center py-8">
          <span class="w-8 h-8 border-2 border-amber-400 border-t-transparent rounded-full animate-spin inline-block mb-3"></span>
          <p class="text-gray-400 text-sm">Memverifikasi link...</p>
        </div>

        <!-- Token benar-benar invalid (bukan lock error) -->
        <div v-else-if="tokenError" class="bg-red-50 border border-red-200 rounded-xl p-4 text-center">
          <p class="text-red-600 font-medium text-sm mb-2">⚠️ Link sudah expired atau tidak valid</p>
          <p class="text-red-400 text-xs mb-3">Silakan minta link reset password baru.</p>
          <router-link to="/login" class="text-amber-600 font-semibold text-sm hover:underline">
            Kembali ke halaman login
          </router-link>
        </div>

        <!-- Form -->
        <div v-else class="space-y-4">
          <div>
            <label class="text-sm font-medium text-gray-700 block mb-1.5">Password Baru *</label>
            <div class="relative">
              <input v-model="form.password" :type="showPass ? 'text' : 'password'"
                placeholder="Minimal 8 karakter"
                class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none pr-12" />
              <button @click="showPass = !showPass"
                class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-lg">
                {{ showPass ? '🙈' : '👁️' }}
              </button>
            </div>
          </div>

          <div>
            <label class="text-sm font-medium text-gray-700 block mb-1.5">Konfirmasi Password *</label>
            <div class="relative">
              <input v-model="form.confirmPassword" :type="showConfirm ? 'text' : 'password'"
                placeholder="Ulangi password baru"
                @keyup.enter="doReset"
                class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none pr-12" />
              <button @click="showConfirm = !showConfirm"
                class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-lg">
                {{ showConfirm ? '🙈' : '👁️' }}
              </button>
            </div>
          </div>

          <div v-if="error" class="bg-red-50 border border-red-200 rounded-xl p-3 text-sm text-red-600">
            {{ error }}
          </div>

          <button @click="doReset" :disabled="loading"
            class="w-full py-3.5 rounded-2xl bg-amber-500 hover:bg-amber-600 text-white font-bold transition-colors flex items-center justify-center gap-2 disabled:opacity-60">
            <span v-if="loading" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            {{ loading ? 'Menyimpan...' : 'Simpan Password Baru' }}
          </button>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

const form           = ref({ password: '', confirmPassword: '' })
const showPass       = ref(false)
const showConfirm    = ref(false)
const loading        = ref(false)
const error          = ref('')
const success        = ref(false)
const tokenError     = ref(false)
const waitingSession = ref(true)
const countdown      = ref(3)

let authListener = null
let timeoutId    = null

// Semua kata kunci yang berarti "error tapi password sudah tersimpan / session OK"
function isIgnorableError(msg = '') {
  return /lock|stole|released|future|skew/i.test(msg)
}

onMounted(async () => {
  const hash   = window.location.hash.substring(1)
  const params = new URLSearchParams(hash)

  const accessToken  = params.get('access_token')
  const refreshToken = params.get('refresh_token')
  const type         = params.get('type')

  if (accessToken && type === 'recovery') {
    // Bersihkan token dari URL bar
    window.history.replaceState(null, '', window.location.pathname)

    const { error: sessionErr } = await supabase.auth.setSession({
      access_token:  accessToken,
      refresh_token: refreshToken ?? ''
    })

    // Abaikan lock/clock-skew error — session tetap aktif meski ada warning
    if (sessionErr && !isIgnorableError(sessionErr.message)) {
      waitingSession.value = false
      tokenError.value     = true
      return
    }

    // Lanjut tampilkan form
    waitingSession.value = false
    return
  }

  // Tidak ada token di hash — cek session aktif
  const { data: { session } } = await supabase.auth.getSession()
  if (session) {
    waitingSession.value = false
    return
  }

  // Fallback: tunggu event Supabase
  const { data } = supabase.auth.onAuthStateChange((event) => {
    if (event === 'PASSWORD_RECOVERY' || event === 'SIGNED_IN') {
      clearTimeout(timeoutId)
      waitingSession.value = false
      tokenError.value     = false
    }
  })
  authListener = data.subscription

  timeoutId = setTimeout(() => {
    if (waitingSession.value) {
      waitingSession.value = false
      tokenError.value     = true
    }
  }, 5000)
})

onUnmounted(() => {
  authListener?.unsubscribe()
  clearTimeout(timeoutId)
})

function startCountdown() {
  const timer = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0) {
      clearInterval(timer)
      router.push('/login')
    }
  }, 1000)
}

async function doReset() {
  error.value = ''
  if (!form.value.password)           { error.value = 'Password baru wajib diisi.'; return }
  if (form.value.password.length < 8) { error.value = 'Password minimal 8 karakter.'; return }
  if (form.value.password !== form.value.confirmPassword) {
    error.value = 'Konfirmasi password tidak cocok.'
    return
  }

  loading.value = true

  try {
    // Race antara updateUser dan timeout 6 detik
    const result = await Promise.race([
      supabase.auth.updateUser({ password: form.value.password }),
      new Promise(resolve => setTimeout(() => resolve({ timedOut: true }), 6000))
    ])

    // Kalau timeout → password sudah tersimpan (email notif sudah keluar), anggap sukses
    if (result.timedOut) {
      loading.value = false
      success.value = true
      supabase.auth.signOut().catch(() => {})
      startCountdown()
      return
    }

    const { error: err } = result

    // Cek error — lock/navigator error → abaikan, anggap sukses
    if (err) {
      const isLock =
        err?.name?.includes('Lock') ||
        err?.name?.includes('Navigator') ||
        (err?.message || '').toLowerCase().match(/lock|stole|released/)

      if (!isLock) {
        loading.value = false
        error.value = err.message || 'Gagal mengubah password.'
        return
      }
    }

    // Sukses
    loading.value = false
    success.value = true
    supabase.auth.signOut().catch(() => {})
    startCountdown()

  } catch (e) {
    loading.value = false

    const isLock =
      e?.name?.includes('Lock') ||
      e?.name?.includes('Navigator') ||
      (e?.message || '').toLowerCase().match(/lock|stole|released/)

    if (isLock) {
      success.value = true
      supabase.auth.signOut().catch(() => {})
      startCountdown()
      return
    }

    error.value = e?.message || 'Gagal mengubah password.'
  }
}
</script>

<style scoped>
.checkmark {
  width: 80px; height: 80px;
  display: block;
  stroke-width: 3;
  stroke-miterlimit: 10;
  animation: scale 0.3s ease-in-out 0.9s both;
}
.checkmark__circle {
  stroke-dasharray: 166; stroke-dashoffset: 166;
  stroke-width: 3; stroke: #f59e0b; fill: none;
  animation: stroke 0.6s cubic-bezier(0.65, 0, 0.45, 1) forwards;
}
.checkmark__check {
  transform-origin: 50% 50%;
  stroke-dasharray: 48; stroke-dashoffset: 48;
  stroke: #f59e0b; stroke-width: 3;
  animation: stroke 0.3s cubic-bezier(0.65, 0, 0.45, 1) 0.8s forwards;
}
@keyframes stroke { 100% { stroke-dashoffset: 0; } }
@keyframes scale {
  0%, 100% { transform: none; }
  50% { transform: scale3d(1.1, 1.1, 1); }
}
</style>