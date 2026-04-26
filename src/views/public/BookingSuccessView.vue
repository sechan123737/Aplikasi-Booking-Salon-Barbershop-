<!-- src/views/public/BookingSuccessView.vue -->
<template>
  <div class="px-4 py-6 max-w-lg mx-auto">

    <!-- Header -->
    <div class="text-center mb-6">
      <div class="w-20 h-20 bg-amber-100 rounded-full flex items-center justify-center text-4xl mb-4 mx-auto">🎉</div>
      <h1 class="text-2xl font-bold text-gray-900 mb-1">Booking Diterima!</h1>
      <p class="text-gray-500 text-sm">Pilih metode pembayaran untuk melanjutkan</p>
      <div class="inline-block bg-amber-50 border-2 border-amber-200 rounded-2xl px-6 py-3 mt-3">
        <p class="text-xs text-amber-600 font-medium mb-0.5">Kode Booking</p>
        <p class="text-xl font-bold text-amber-700 tracking-widest">{{ route.query.code }}</p>
      </div>
    </div>

    <!-- Ringkasan harga -->
    <div v-if="booking" class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-5">
      <p class="text-sm font-semibold text-gray-700 mb-3">Ringkasan Pesanan</p>
      <div class="space-y-1.5">
        <div v-for="bs in booking.booking_services" :key="bs.id" class="flex justify-between text-sm">
          <span class="text-gray-600">{{ bs.services?.name }}</span>
          <span class="font-medium">Rp {{ formatPrice(bs.price) }}</span>
        </div>
        <div v-if="!booking.booking_services?.length" class="flex justify-between text-sm">
          <span class="text-gray-600">{{ booking.services?.name }}</span>
          <span class="font-medium">Rp {{ formatPrice(booking.service_price) }}</span>
        </div>
        <div v-if="booking.discount_amount > 0" class="flex justify-between text-sm text-green-600">
          <span>Diskon ({{ booking.voucher_code }})</span>
          <span>- Rp {{ formatPrice(booking.discount_amount) }}</span>
        </div>
      </div>
      <div class="border-t border-gray-100 mt-3 pt-3 flex justify-between font-bold">
        <span>Total Bayar</span>
        <span class="text-amber-600">Rp {{ formatPrice(finalAmount) }}</span>
      </div>
    </div>

    <!-- STEP 1: Pilih metode -->
    <div v-if="step === 1">
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-5">
        <p class="text-sm font-semibold text-gray-700 mb-3">Pilih Metode Pembayaran</p>
        <div class="space-y-2">
          <button v-for="m in methods" :key="m.value"
            @click="selectedMethod = m.value"
            class="w-full flex items-center gap-3 p-3.5 rounded-xl border-2 transition-all text-left"
            :class="selectedMethod === m.value ? 'border-amber-500 bg-amber-50' : 'border-gray-100 hover:border-amber-200'">
            <span class="text-2xl flex-shrink-0">{{ m.icon }}</span>
            <div class="flex-1">
              <p class="font-semibold text-gray-800 text-sm">{{ m.label }}</p>
              <p class="text-xs text-gray-400">{{ m.desc }}</p>
            </div>
            <div class="w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0"
              :class="selectedMethod === m.value ? 'border-amber-500 bg-amber-500' : 'border-gray-300'">
              <div v-if="selectedMethod === m.value" class="w-2 h-2 bg-white rounded-full"></div>
            </div>
          </button>
        </div>
      </div>

      <button @click="goToStep2" :disabled="!selectedMethod"
        class="w-full py-4 rounded-2xl font-bold text-white transition-colors mb-3"
        :class="selectedMethod ? 'bg-amber-500 hover:bg-amber-600' : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
        Lanjut →
      </button>
      <button @click="$router.push('/history')"
        class="w-full py-3.5 border-2 border-gray-200 text-gray-600 rounded-2xl font-semibold text-sm">
        Bayar Nanti
      </button>
    </div>

    <!-- STEP 2: Info rekening + upload bukti -->
    <div v-else-if="step === 2">

      <!-- COD -->
      <div v-if="selectedMethod === 'cod'" class="bg-blue-50 border-2 border-blue-200 rounded-2xl p-5 mb-5 text-center">
        <p class="text-4xl mb-2">🤝</p>
        <p class="font-bold text-blue-800 text-lg mb-1">Bayar di Tempat</p>
        <p class="text-blue-600 text-sm">Siapkan uang tunai <span class="font-bold">Rp {{ formatPrice(finalAmount) }}</span> saat tiba di salon.</p>
        <p class="text-blue-500 text-xs mt-2">Booking Anda akan dikonfirmasi oleh admin.</p>
      </div>

      <!-- Transfer / QRIS / E-wallet -->
      <div v-else class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-5">
        <p class="text-sm font-semibold text-gray-700 mb-3">Info Pembayaran</p>

        <!-- Detail rekening sesuai metode -->
        <div class="bg-gray-50 rounded-xl p-4 mb-4">
          <template v-if="selectedMethod === 'bank_transfer'">
            <p class="text-xs text-gray-500 mb-2 font-medium">Transfer ke rekening berikut:</p>
            <div class="space-y-2">
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Bank</span>
                <span class="font-bold text-gray-800">BCA</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">No. Rekening</span>
                <button @click="copyText('1234567890')"
                  class="font-bold text-gray-800 flex items-center gap-1 hover:text-amber-600">
                  1234567890 <span class="text-xs">📋</span>
                </button>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Atas Nama</span>
                <span class="font-bold text-gray-800">ChaLon Salon</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Jumlah</span>
                <button @click="copyText(String(finalAmount))"
                  class="font-bold text-amber-600 flex items-center gap-1 hover:text-amber-700">
                  Rp {{ formatPrice(finalAmount) }} <span class="text-xs">📋</span>
                </button>
              </div>
            </div>
          </template>

          <template v-else-if="selectedMethod === 'qris'">
            <p class="text-xs text-gray-500 mb-3 font-medium">Scan QR Code berikut:</p>
            <div class="flex justify-center mb-3">
              <!-- Placeholder QRIS - ganti dengan gambar QRIS asli -->
              <div class="w-40 h-40 bg-gray-200 rounded-xl flex items-center justify-center text-gray-400 text-sm text-center p-3">
                <div>
                  <p class="text-3xl mb-1">📱</p>
                  <p class="text-xs">Taruh gambar QRIS salon di sini</p>
                </div>
              </div>
            </div>
            <p class="text-center text-xs text-gray-500">Jumlah: <span class="font-bold text-amber-600">Rp {{ formatPrice(finalAmount) }}</span></p>
          </template>

          <template v-else-if="selectedMethod === 'gopay'">
            <p class="text-xs text-gray-500 mb-2 font-medium">Transfer GoPay / OVO / Dana ke:</p>
            <div class="space-y-2">
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Nomor</span>
                <button @click="copyText('08123456789')"
                  class="font-bold text-gray-800 flex items-center gap-1 hover:text-amber-600">
                  0812-3456-789 <span class="text-xs">📋</span>
                </button>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Atas Nama</span>
                <span class="font-bold text-gray-800">ChaLon Salon</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Jumlah</span>
                <button @click="copyText(String(finalAmount))"
                  class="font-bold text-amber-600 flex items-center gap-1 hover:text-amber-700">
                  Rp {{ formatPrice(finalAmount) }} <span class="text-xs">📋</span>
                </button>
              </div>
            </div>
          </template>
        </div>

        <!-- Upload bukti -->
        <p class="text-sm font-semibold text-gray-700 mb-2">Upload Bukti Pembayaran</p>
        <div
          @click="$refs.fileInput.click()"
          @dragover.prevent
          @drop.prevent="onDrop"
          class="border-2 border-dashed rounded-xl p-5 text-center cursor-pointer transition-colors"
          :class="proofFile ? 'border-green-400 bg-green-50' : 'border-gray-200 hover:border-amber-400 hover:bg-amber-50'">
          <input ref="fileInput" type="file" accept="image/*" class="hidden" @change="onFileChange" />
          <div v-if="proofFile">
            <img :src="proofPreview" class="w-full max-h-40 object-contain rounded-lg mb-2" />
            <p class="text-xs text-green-600 font-medium">{{ proofFile.name }}</p>
          </div>
          <div v-else>
            <p class="text-3xl mb-2">📸</p>
            <p class="text-sm text-gray-500">Tap untuk pilih foto</p>
            <p class="text-xs text-gray-400 mt-1">JPG, PNG — maks 5MB</p>
          </div>
        </div>
      </div>

      <!-- Copied toast -->
      <div v-if="copied" class="fixed top-4 left-1/2 -translate-x-1/2 bg-gray-800 text-white text-sm px-4 py-2 rounded-full z-50 shadow-lg">
        ✅ Disalin!
      </div>

      <!-- Error -->
      <div v-if="error" class="bg-red-50 border border-red-200 rounded-xl p-3 mb-4 text-sm text-red-600">
        {{ error }}
      </div>

      <!-- Tombol -->
      <button @click="submitPayment" :disabled="paying || (selectedMethod !== 'cod' && !proofFile)"
        class="w-full py-4 rounded-2xl font-bold text-white transition-colors flex items-center justify-center gap-2 mb-3"
        :class="(selectedMethod === 'cod' || proofFile) && !paying
          ? 'bg-amber-500 hover:bg-amber-600'
          : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
        <span v-if="paying || paymentStore.uploading"
          class="inline-block w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
        {{ paying || paymentStore.uploading
          ? 'Mengupload...'
          : selectedMethod === 'cod' ? '✅ Konfirmasi' : '📤 Kirim Bukti Bayar' }}
      </button>

      <button @click="step = 1" class="w-full py-3.5 border-2 border-gray-200 text-gray-600 rounded-2xl font-semibold text-sm">
        ← Ganti Metode
      </button>
    </div>

    <!-- STEP 3: Sukses submit -->
    <div v-else-if="step === 3" class="text-center">
      <div class="w-20 h-20 rounded-full flex items-center justify-center text-4xl mb-4 mx-auto"
        :class="selectedMethod === 'cod' ? 'bg-blue-100' : 'bg-green-100'">
        {{ selectedMethod === 'cod' ? '🤝' : '⏳' }}
      </div>
      <h2 class="text-xl font-bold text-gray-900 mb-2">
        {{ selectedMethod === 'cod' ? 'Siap! Bayar di Tempat' : 'Bukti Dikirim!' }}
      </h2>
      <p class="text-gray-500 text-sm mb-6">
        {{ selectedMethod === 'cod'
          ? 'Booking Anda tercatat dan menunggu konfirmasi admin. Setelah dikonfirmasi, silakan datang ke salon dan bayar tunai.'
          : 'Kami akan memverifikasi pembayaran Anda. Notifikasi akan dikirim setelah dikonfirmasi.' }}
      </p>
      <div class="space-y-3">
        <router-link to="/history"
          class="block w-full py-3.5 bg-amber-500 text-white rounded-2xl font-semibold hover:bg-amber-600 transition-colors">
          Lihat Riwayat Booking
        </router-link>
        <router-link to="/"
          class="block w-full py-3.5 border-2 border-gray-200 text-gray-700 rounded-2xl font-semibold">
          Kembali ke Beranda
        </router-link>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePaymentStore } from '@/stores/payment'
import { supabase } from '@/lib/supabase'

const route        = useRoute()
const router       = useRouter()
const paymentStore = usePaymentStore()

const booking        = ref(null)
const step           = ref(1)
const selectedMethod = ref('')
const proofFile      = ref(null)
const proofPreview   = ref('')
const paying         = ref(false)
const error          = ref('')
const copied         = ref(false)
const fileInput      = ref(null)

const methods = [
  { value: 'bank_transfer', icon: '🏦', label: 'Transfer Bank',      desc: 'BCA — konfirmasi otomatis setelah upload bukti' },
  { value: 'qris',          icon: '📱', label: 'QRIS',               desc: 'Scan QR, langsung dari semua e-wallet' },
  { value: 'gopay',         icon: '💚', label: 'GoPay / OVO / Dana', desc: 'Transfer ke nomor e-wallet salon' },
  { value: 'cod',           icon: '🤝', label: 'Bayar di Tempat',    desc: 'Bayar tunai saat tiba di salon' },
]

const finalAmount = computed(() => {
  if (!booking.value) return 0
  const total = booking.value.booking_services?.length
    ? booking.value.booking_services.reduce((s, bs) => s + Number(bs.price || 0), 0)
    : Number(booking.value.service_price || 0)
  return Math.max(0, total - Number(booking.value.discount_amount || 0))
})

function goToStep2() {
  if (!selectedMethod.value) return
  step.value = 2
}

function onFileChange(e) {
  const file = e.target.files[0]
  if (!file) return
  if (file.size > 5 * 1024 * 1024) { error.value = 'Ukuran file maksimal 5MB.'; return }
  proofFile.value   = file
  proofPreview.value = URL.createObjectURL(file)
  error.value = ''
}

function onDrop(e) {
  const file = e.dataTransfer.files[0]
  if (file) onFileChange({ target: { files: [file] } })
}

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text)
    copied.value = true
    setTimeout(() => copied.value = false, 2000)
  } catch {}
}

async function submitPayment() {
  if (!booking.value) return
  paying.value = true
  error.value  = ''
  try {
    let proofUrl = null
    if (selectedMethod.value !== 'cod' && proofFile.value) {
      proofUrl = await paymentStore.uploadProof(booking.value.id, proofFile.value)
    }
    await paymentStore.submitPayment(booking.value.id, selectedMethod.value, proofUrl)
    step.value = 3
  } catch (e) {
    error.value = e.message || 'Gagal mengirim. Coba lagi.'
  } finally {
    paying.value = false
  }
}

function formatPrice(p) { return Number(p || 0).toLocaleString('id-ID') }

onMounted(async () => {
  const code = route.query.code
  if (!code) return
  const { data } = await supabase
    .from('bookings')
    .select('*, services(*), booking_services(*, services(*))')
    .eq('booking_code', code)
    .single()
  booking.value = data
})
</script>