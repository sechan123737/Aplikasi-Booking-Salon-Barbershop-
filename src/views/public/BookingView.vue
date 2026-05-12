<!-- src/views/public/BookingView.vue -->
<template>
  <div class="px-4 py-6">
    <h1 class="text-xl font-bold text-gray-900 mb-1">Buat Booking</h1>
    <p class="text-sm text-gray-500 mb-6">Ikuti langkah-langkah berikut</p>

    <!-- Step Indicator -->
    <div class="flex items-center mb-8">
      <div v-for="(step, i) in steps" :key="i" class="flex items-center" :class="i < steps.length-1 ? 'flex-1' : ''">
        <div class="flex flex-col items-center">
          <div class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-colors"
            :class="currentStep > i ? 'bg-amber-500 text-white' : currentStep === i ? 'bg-amber-500 text-white ring-4 ring-amber-100' : 'bg-gray-200 text-gray-400'">
            {{ currentStep > i ? '✓' : i+1 }}
          </div>
          <span class="text-[10px] mt-1 text-gray-500 font-medium">{{ step }}</span>
        </div>
        <div v-if="i < steps.length-1" class="flex-1 h-0.5 mx-2 mb-4 transition-colors" :class="currentStep > i ? 'bg-amber-500' : 'bg-gray-200'"></div>
      </div>
    </div>

    <!-- Step 1: Pilih Layanan (multi-select) -->
    <div v-if="currentStep === 0">
      <div class="flex items-center justify-between mb-3">
        <h2 class="font-semibold text-gray-800">Pilih Layanan</h2>
        <span v-if="selectedServices.length > 0"
          class="text-xs bg-amber-100 text-amber-700 font-semibold px-2.5 py-1 rounded-full">
          {{ selectedServices.length }} dipilih
        </span>
      </div>
      <p class="text-xs text-gray-400 mb-3">Bisa pilih lebih dari satu layanan</p>
      <div v-if="servicesStore.loading" class="space-y-3">
        <div v-for="i in 4" :key="i" class="h-20 bg-gray-100 rounded-2xl animate-pulse"></div>
      </div>
      <div v-else class="space-y-3">
        <div v-for="svc in servicesStore.services" :key="svc.id"
          @click="toggleService(svc)"
          class="flex items-center gap-4 p-4 rounded-2xl border-2 cursor-pointer transition-all"
          :class="isServiceSelected(svc.id) ? 'border-amber-500 bg-amber-50' : 'border-gray-100 bg-white hover:border-amber-200'">
          <img :src="getCategoryIcon(svc.category)" class="w-8 h-8 object-contain" />
          <div class="flex-1">
            <p class="font-semibold text-gray-800">{{ svc.name }}</p>
            <p class="text-xs text-gray-500">{{ svc.duration_minutes }} menit</p>
            <p v-if="svc.description" class="text-xs text-gray-400 mt-0.5">{{ svc.description }}</p>
          </div>
          <div class="flex items-center gap-3">
            <p class="font-bold text-amber-600">Rp {{ formatPrice(svc.price) }}</p>
            <div class="w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all flex-shrink-0"
              :class="isServiceSelected(svc.id) ? 'bg-amber-500 border-amber-500 text-white' : 'border-gray-300'">
              <span v-if="isServiceSelected(svc.id)" class="text-xs font-bold">✓</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Ringkasan layanan terpilih -->
      <div v-if="selectedServices.length > 0" class="mt-4 bg-amber-50 rounded-2xl p-4 border border-amber-200">
        <p class="text-xs font-semibold text-amber-700 mb-2">Layanan dipilih:</p>
        <div class="space-y-1">
          <div v-for="svc in selectedServices" :key="svc.id" class="flex justify-between text-sm">
            <span class="text-gray-700">{{ svc.name }}</span>
            <span class="font-medium text-amber-600">Rp {{ formatPrice(svc.price) }}</span>
          </div>
        </div>
        <div class="border-t border-amber-200 mt-2 pt-2 flex justify-between font-bold text-sm">
          <span>Total</span>
          <span class="text-amber-600">Rp {{ formatPrice(totalServicesPrice) }}</span>
        </div>
        <div class="text-xs text-gray-400 mt-1">
          Total durasi: {{ totalDuration }} menit
        </div>
      </div>

      <button @click="nextStep" :disabled="selectedServices.length === 0"
        class="w-full mt-6 py-3.5 rounded-2xl font-semibold text-white transition-colors"
        :class="selectedServices.length > 0 ? 'bg-amber-500 hover:bg-amber-600' : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
        Lanjut →
      </button>
    </div>

    <!-- Step 2: Pilih Tanggal & Jam -->
    <div v-if="currentStep === 1">
      <h2 class="font-semibold text-gray-800 mb-3">Pilih Tanggal</h2>
      <input type="date" v-model="form.booking_date" :min="today" :max="maxDate"
        @change="loadSlots"
        class="w-full border-2 border-gray-200 rounded-2xl p-3.5 mb-5 focus:border-amber-500 outline-none text-gray-800" />

      <h2 class="font-semibold text-gray-800 mb-3">Pilih Jam</h2>
      <div v-if="loadingSlots" class="grid grid-cols-4 gap-2">
        <div v-for="i in 8" :key="i" class="h-12 bg-gray-100 rounded-xl animate-pulse"></div>
      </div>
      <div v-else-if="!form.booking_date" class="text-center text-gray-400 py-6 text-sm">
        Pilih tanggal terlebih dahulu
      </div>
      <div v-else-if="availableSlots.length === 0" class="text-center text-gray-400 py-6 text-sm">
        Tidak ada slot tersedia untuk tanggal ini
      </div>
      <!-- Announce slot penuh -->
      <div v-if="availableSlots.length > 0 && availableSlots.every(s => !s.is_available)"
        class="flex items-center gap-3 bg-red-50 border border-red-200 rounded-2xl px-4 py-3 mb-4">
        <span class="text-xl">🚫</span>
        <div>
          <p class="text-sm font-semibold text-red-600">Semua slot sudah penuh</p>
          <p class="text-xs text-red-400 mt-0.5">Coba pilih tanggal lain untuk booking</p>
        </div>
      </div>

      <div v-else class="grid grid-cols-4 gap-2">
        <button v-for="slot in availableSlots" :key="slot.slot_time"
          :disabled="!slot.is_available"
          @click="form.booking_time = slot.slot_time"
          class="h-12 rounded-xl text-xs font-semibold transition-all flex flex-col items-center justify-center gap-0.5 relative overflow-hidden"
          :class="form.booking_time === slot.slot_time
            ? 'bg-amber-500 text-white'
            : slot.is_available
              ? 'bg-white border-2 border-gray-200 text-gray-700 hover:border-amber-300'
              : slot.reason === 'Waktu sudah lewat' || slot.reason === 'Tanggal sudah lewat'
                ? 'bg-gray-50 text-gray-200 cursor-not-allowed border border-gray-100'
                : 'bg-gray-100 text-gray-300 cursor-not-allowed'">
          <span class="font-semibold">{{ slot.slot_time.slice(0,5) }}</span>
          <span v-if="!slot.is_available && slot.reason !== 'Waktu sudah lewat' && slot.reason !== 'Tanggal sudah lewat'"
            class="text-[9px] font-bold text-red-400 leading-none">
            {{ slot.reason === 'Stylist tidak tersedia' ? 'Stylist penuh' : 'Penuh' }}
          </span>
          <span v-else-if="slot.is_available && slot.available_count <= 3"
            class="text-[9px] leading-none"
            :class="form.booking_time === slot.slot_time ? 'text-amber-100' : 'text-orange-400'">
            sisa {{ slot.available_count }}
          </span>
        </button>
      </div>

      <!-- Pilih Staff (opsional) -->
      <div class="mt-6">
        <h2 class="font-semibold text-gray-800 mb-3">Pilih Stylist <span class="text-gray-400 font-normal text-sm">(opsional)</span></h2>
        <div class="grid grid-cols-2 gap-3">
          <div @click="form.staff_id = null"
            class="flex flex-col items-center p-3 rounded-2xl border-2 cursor-pointer transition-all"
            :class="!form.staff_id ? 'border-amber-500 bg-amber-50' : 'border-gray-100 bg-white'">
            <span class="text-2xl mb-1">🎲</span>
            <span class="text-sm font-medium text-gray-700">Siapa saja</span>
          </div>
          <div v-for="st in staffStore.staff" :key="st.id"
            @click="form.staff_id = st.id"
            class="flex flex-col items-center p-3 rounded-2xl border-2 cursor-pointer transition-all"
            :class="form.staff_id === st.id ? 'border-amber-500 bg-amber-50' : 'border-gray-100 bg-white'">
            <div class="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-base font-bold text-amber-700 mb-1">
              {{ st.name[0] }}
            </div>
            <span class="text-sm font-medium text-gray-700">{{ st.name }}</span>
          </div>
        </div>
      </div>

      <div class="flex gap-3 mt-6">
        <button @click="prevStep" class="flex-1 py-3.5 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600">← Kembali</button>
        <button @click="nextStep" :disabled="!form.booking_date || !form.booking_time"
          class="flex-1 py-3.5 rounded-2xl font-semibold text-white transition-colors"
          :class="form.booking_date && form.booking_time ? 'bg-amber-500 hover:bg-amber-600' : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
          Lanjut →
        </button>
      </div>
    </div>

    <!-- Step 3: Data Pelanggan -->
    <div v-if="currentStep === 2">
      <h2 class="font-semibold text-gray-800 mb-1">Data Pelanggan</h2>

      <!-- Sudah login: tampilkan data profil, readonly -->
      <div v-if="authStore.isLoggedIn" class="mb-4">
        <p class="text-xs text-gray-400 mb-3">Data diambil otomatis dari akun kamu</p>
        <div class="bg-amber-50 border border-amber-200 rounded-2xl p-4 space-y-3">
          <div class="flex justify-between text-sm">
            <span class="text-gray-500 font-medium">Nama</span>
            <span class="font-semibold text-gray-800">{{ form.customer_name || '-' }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500 font-medium">No. HP</span>
            <span class="font-semibold text-gray-800">{{ form.customer_phone || '-' }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500 font-medium">Email</span>
            <span class="font-semibold text-gray-800">{{ form.customer_email || '-' }}</span>
          </div>
        </div>
        <p class="text-xs text-gray-400 mt-2">
          Data salah?
          <router-link to="/profile" class="text-amber-600 font-semibold underline">Edit di Profil</router-link>
        </p>
      </div>

      <!-- Belum login: isi manual -->
      <div v-else class="space-y-4 mb-4">
        <p class="text-xs text-gray-400">Isi data diri kamu untuk melanjutkan booking</p>
        <div>
          <label class="text-sm font-medium text-gray-700 mb-1.5 block">Nama Lengkap *</label>
          <input v-model="form.customer_name" type="text" placeholder="Nama Anda"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 mb-1.5 block">Nomor HP *</label>
          <input v-model="form.customer_phone" type="tel" placeholder="08xxxxxxxxxx"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
        <div>
          <label class="text-sm font-medium text-gray-700 mb-1.5 block">Email</label>
          <input v-model="form.customer_email" type="email" placeholder="email@contoh.com"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none" />
        </div>
      </div>

      <!-- Catatan: selalu bisa diedit -->
      <div>
        <label class="text-sm font-medium text-gray-700 mb-1.5 block">Catatan <span class="text-gray-400 font-normal">(opsional)</span></label>
        <textarea v-model="form.notes" rows="3" placeholder="Ada catatan khusus? (opsional)"
          class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none resize-none"></textarea>
      </div>

      <div class="flex gap-3 mt-6">
        <button @click="prevStep" class="flex-1 py-3.5 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600">← Kembali</button>
        <button @click="nextStep" :disabled="!form.customer_name || !form.customer_phone"
          class="flex-1 py-3.5 rounded-2xl font-semibold text-white transition-colors"
          :class="form.customer_name && form.customer_phone ? 'bg-amber-500 hover:bg-amber-600' : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
          Lanjut →
        </button>
      </div>
    </div>

    <!-- Step 4: Konfirmasi -->
    <div v-if="currentStep === 3">
      <h2 class="font-semibold text-gray-800 mb-4">Konfirmasi Booking</h2>
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-4">
        <div class="bg-amber-500 text-white p-4">
          <p class="text-sm text-amber-100 mb-1">Layanan dipilih</p>
          <div class="space-y-1">
            <div v-for="svc in selectedServices" :key="svc.id" class="flex justify-between items-center">
              <p class="font-semibold">{{ svc.name }}</p>
              <p class="text-amber-100 text-sm">Rp {{ formatPrice(svc.price) }}</p>
            </div>
          </div>
          <p class="text-amber-100 text-xs mt-2">Total durasi: {{ totalDuration }} menit</p>
        </div>
        <div class="p-4 space-y-3">
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Tanggal</span>
            <span class="font-medium">{{ formatDate(form.booking_date) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Jam</span>
            <span class="font-medium">{{ form.booking_time?.slice(0,5) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Stylist</span>
            <span class="font-medium">{{ selectedStaff?.name || 'Siapa saja' }}</span>
          </div>
          <hr class="border-gray-100" />
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Nama</span>
            <span class="font-medium">{{ form.customer_name }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">HP</span>
            <span class="font-medium">{{ form.customer_phone }}</span>
          </div>
          <div v-if="form.notes" class="flex justify-between text-sm">
            <span class="text-gray-500">Catatan</span>
            <span class="font-medium text-right max-w-[60%]">{{ form.notes }}</span>
          </div>

          <!-- Ringkasan Harga -->
          <hr class="border-gray-100" />
          <div v-for="svc in selectedServices" :key="svc.id" class="flex justify-between text-sm">
            <span class="text-gray-500">{{ svc.name }}</span>
            <span class="font-medium">Rp {{ formatPrice(svc.price) }}</span>
          </div>
          <div v-if="appliedVoucher" class="flex justify-between text-sm text-green-600">
            <span>Diskon ({{ appliedVoucher.code }})</span>
            <span class="font-semibold">- Rp {{ formatPrice(discountAmount) }}</span>
          </div>
          <div class="flex justify-between font-bold text-gray-900 pt-1">
            <span>Total Bayar</span>
            <span class="text-amber-600">Rp {{ formatPrice(finalPrice) }}</span>
          </div>
        </div>
      </div>

      <!-- Input Voucher -->
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-4">
        <p class="text-sm font-semibold text-gray-700 mb-2">🎟️ Punya Kode Voucher?</p>
        <div class="flex gap-2">
          <input v-model="voucherCode" type="text" placeholder="Masukkan kode voucher"
            :disabled="!!appliedVoucher || checkingVoucher"
            class="flex-1 border-2 rounded-xl p-3 text-sm font-mono uppercase tracking-widest outline-none transition-colors"
            :class="appliedVoucher ? 'border-green-400 bg-green-50 text-green-700' : 'border-gray-200 focus:border-amber-500'"
            @input="voucherCode = voucherCode.toUpperCase().replace(/\s/g,'')"
            @keyup.enter="applyVoucher" />
          <button v-if="!appliedVoucher" @click="applyVoucher" :disabled="!voucherCode || checkingVoucher"
            class="px-4 py-2.5 rounded-xl font-semibold text-sm transition-colors"
            :class="voucherCode && !checkingVoucher ? 'bg-amber-500 hover:bg-amber-600 text-white' : 'bg-gray-100 text-gray-400 cursor-not-allowed'">
            <span v-if="checkingVoucher" class="inline-block w-4 h-4 border-2 border-amber-500 border-t-transparent rounded-full animate-spin"></span>
            <span v-else>Pakai</span>
          </button>
          <button v-else @click="removeVoucher"
            class="px-4 py-2.5 rounded-xl font-semibold text-sm bg-red-50 text-red-500 hover:bg-red-100 transition-colors">
            Hapus
          </button>
        </div>
        <div v-if="appliedVoucher" class="mt-2 flex items-center gap-2 text-sm text-green-600 font-medium">
          <span>✅</span>
          <span>{{ appliedVoucher.name || appliedVoucher.code }} — hemat Rp {{ formatPrice(discountAmount) }}</span>
        </div>
        <div v-if="voucherError" class="mt-2 text-sm text-red-500">{{ voucherError }}</div>
      </div>

      <div v-if="error" class="bg-red-50 border border-red-200 rounded-xl p-3 mb-4 text-sm text-red-600">
        {{ error }}
      </div>

      <div class="flex gap-3">
        <button @click="prevStep" :disabled="submitting" class="flex-1 py-3.5 rounded-2xl border-2 border-gray-200 font-semibold text-gray-600">← Kembali</button>
        <button @click="submitBooking" :disabled="submitting"
          class="flex-1 py-3.5 rounded-2xl bg-amber-500 hover:bg-amber-600 font-semibold text-white transition-colors flex items-center justify-center gap-2">
          <span v-if="submitting" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          {{ submitting ? 'Memproses...' : '✅ Konfirmasi' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useServicesStore } from '@/stores/services'
import { useStaffStore } from '@/stores/staff'
import { useBookingStore } from '@/stores/booking'
import { useVoucherStore } from '@/stores/vouchers'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const servicesStore = useServicesStore()
const staffStore = useStaffStore()
const bookingStore = useBookingStore()
const voucherStore = useVoucherStore()

const steps = ['Layanan', 'Jadwal', 'Data', 'Konfirmasi']
const currentStep = ref(0)
const loadingSlots = ref(false)
const availableSlots = ref([])
const submitting = ref(false)
const error = ref('')

// ── Voucher state ──────────────────────────────────────────────
const voucherCode     = ref('')
const voucherError    = ref('')
const checkingVoucher = ref(false)
const appliedVoucher  = ref(null)
const discountAmount  = ref(0)

const finalPrice = computed(() => {
  return Math.max(0, totalServicesPrice.value - discountAmount.value)
})

async function applyVoucher() {
  if (!voucherCode.value) return
  voucherError.value = ''
  checkingVoucher.value = true
  try {
    const servicePrice = totalServicesPrice.value
    const result = await voucherStore.validateVoucher(voucherCode.value, servicePrice)
    appliedVoucher.value = result.voucher
    discountAmount.value = result.discountAmount
  } catch (e) {
    voucherError.value = e.message
    appliedVoucher.value = null
    discountAmount.value = 0
  } finally {
    checkingVoucher.value = false
  }
}

function removeVoucher() {
  appliedVoucher.value = null
  discountAmount.value = 0
  voucherCode.value = ''
  voucherError.value = ''
}
// ──────────────────────────────────────────────────────────────

const today = new Date().toISOString().split('T')[0]
const maxDate = new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]

const form = ref({
  service_ids: route.query.service ? [route.query.service] : [],
  booking_date: '',
  booking_time: null,
  staff_id: null,
  customer_name: authStore.profile?.full_name || '',
  customer_phone: authStore.profile?.phone || '',
  customer_email: authStore.user?.email || '',
  notes: ''
})

const selectedServices = computed(() =>
  servicesStore.services.filter(s => form.value.service_ids.includes(s.id))
)
const selectedStaff = computed(() => staffStore.staff.find(s => s.id === form.value.staff_id))
const totalServicesPrice = computed(() => selectedServices.value.reduce((sum, s) => sum + Number(s.price || 0), 0))
const totalDuration = computed(() => selectedServices.value.reduce((sum, s) => sum + Number(s.duration_minutes || 0), 0))

function isServiceSelected(id) {
  return form.value.service_ids.includes(id)
}

function toggleService(svc) {
  const idx = form.value.service_ids.indexOf(svc.id)
  if (idx === -1) {
    form.value.service_ids.push(svc.id)
  } else {
    form.value.service_ids.splice(idx, 1)
  }
  // Reset voucher kalau ubah layanan
  removeVoucher()
}
function nextStep() {
  if (currentStep.value === 0 && form.value.service_ids.length === 0) return
  if (currentStep.value < 3) currentStep.value++
}
function prevStep() { if (currentStep.value > 0) currentStep.value-- }

async function loadSlots() {
  if (!form.value.booking_date || form.value.service_ids.length === 0) return
  loadingSlots.value = true
  form.value.booking_time = null
  try {
    // Gunakan layanan pertama untuk kalkulasi slot (durasi terpanjang)
    const primaryId = form.value.service_ids[0]
    // Kirim total durasi semua layanan agar slot yang tidak cukup waktu ikut diblokir
    const total = totalDuration.value || null
    availableSlots.value = await bookingStore.getAvailableSlots(
      form.value.booking_date,
      primaryId,
      form.value.staff_id,
      total
    )
  } catch (e) {
    console.error(e)
  } finally {
    loadingSlots.value = false
  }
}

async function submitBooking() {
  submitting.value = true
  error.value = ''
  try {
    // Re-validasi voucher sesaat sebelum submit, supaya tidak bisa lolos
    // jika voucher sudah expired/habis setelah di-apply tapi sebelum submit
    if (appliedVoucher.value) {
      try {
        const recheck = await voucherStore.validateVoucher(appliedVoucher.value.code, totalServicesPrice.value)
        discountAmount.value = recheck.discountAmount
      } catch (e) {
        // Voucher sudah tidak valid (expired, habis, dll) — batalkan diskon
        appliedVoucher.value = null
        discountAmount.value = 0
        error.value = `Voucher tidak dapat digunakan: ${e.message}`
        submitting.value = false
        return
      }
    }

    // Buat map harga per service
    const servicesPriceMap = {}
    selectedServices.value.forEach(s => { servicesPriceMap[s.id] = Number(s.price || 0) })

    const payload = {
      ...form.value,
      service_id:      form.value.service_ids[0] || null,  // kolom lama, isi dengan yg pertama
      service_ids:     form.value.service_ids,
      services_price:  servicesPriceMap,
      service_price:   totalServicesPrice.value,
      total_duration:  totalDuration.value,  // total durasi semua layanan
      user_id:         authStore.user?.id || null,
      voucher_code:    appliedVoucher.value?.code || null,
      discount_amount: discountAmount.value || 0,
      final_price:     finalPrice.value,
    }
    const booking = await bookingStore.createBooking(payload)
    // Increment usage counter voucher jika dipakai
    if (appliedVoucher.value) {
      await voucherStore.incrementVoucherUsage(appliedVoucher.value.id)
    }
    router.push({ name: 'booking-success', query: { code: booking.booking_code } })
  } catch (e) {
    error.value = e.message || 'Terjadi kesalahan. Coba lagi.'
  } finally {
    submitting.value = false
  }
}

function formatPrice(p) { return Number(p || 0).toLocaleString('id-ID') }
function formatDate(d) {
  if (!d) return '-'
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { weekday:'long', day:'numeric', month:'long', year:'numeric' })
}
function getCategoryIcon(cat) {
  const map = {
    rambut:     '/icons/Rambut.png',
    wajah:      '/icons/Wajah.png',
    kuku:       '/icons/Kuku.png',
    barbershop: '/icons/Barbershop.png',
    general:    '/Layanan.png.png',
  }
  return map[cat] || '/Layanan.png.png'
}

onMounted(async () => {
  // Wajib login untuk booking
  if (!authStore.isLoggedIn) {
    router.replace({ name: 'login', query: { redirect: route.fullPath } })
    return
  }
  await Promise.all([servicesStore.fetchServices(), staffStore.fetchStaff()])
  if (form.value.service_ids.length > 0) currentStep.value = 0
})

// Reload slot saat staff berubah (real-time per-staff check)
watch(() => form.value.staff_id, () => {
  if (form.value.booking_date && form.value.service_ids.length > 0) {
    loadSlots()
  }
})

//ea
watch(() => authStore.profile, (profile) => {
  if (!profile) return
  if (!form.value.customer_name)  form.value.customer_name  = profile.full_name || ''
  if (!form.value.customer_phone) form.value.customer_phone = profile.phone || ''
  if (!form.value.customer_email) form.value.customer_email = authStore.user?.email || ''
}, { immediate: true })
</script>