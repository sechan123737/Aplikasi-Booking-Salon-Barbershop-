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

    <!-- ─── STEP 1: Pilih Layanan (multi-select) ──────────────── -->
    <div v-if="currentStep === 0">
      <div class="flex items-center justify-between mb-3">
        <h2 class="font-semibold text-gray-800">Pilih Layanan</h2>
        <span v-if="selectedServices.length" class="text-xs bg-amber-500 text-white rounded-full px-2.5 py-1 font-semibold">
          {{ selectedServices.length }} dipilih
        </span>
      </div>
      <p class="text-xs text-gray-400 mb-4">Kamu bisa memilih lebih dari satu layanan sekaligus ✨</p>

      <div v-if="servicesStore.loading" class="space-y-3">
        <div v-for="i in 4" :key="i" class="h-20 bg-gray-100 rounded-2xl animate-pulse"></div>
      </div>
      <div v-else class="space-y-3">
        <div v-for="svc in servicesStore.services" :key="svc.id"
          @click="toggleService(svc)"
          class="flex items-center gap-4 p-4 rounded-2xl border-2 cursor-pointer transition-all"
          :class="isSelected(svc.id) ? 'border-amber-500 bg-amber-50' : 'border-gray-100 bg-white hover:border-amber-200'">
          <!-- Checkbox visual -->
          <div class="w-5 h-5 rounded-md border-2 flex-shrink-0 flex items-center justify-center transition-colors"
            :class="isSelected(svc.id) ? 'bg-amber-500 border-amber-500' : 'border-gray-300'">
            <span v-if="isSelected(svc.id)" class="text-white text-xs font-bold">✓</span>
          </div>
          <img :src="getCategoryIcon(svc.category)" class="w-8 h-8 object-contain flex-shrink-0" />
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-gray-800">{{ svc.name }}</p>
            <p class="text-xs text-gray-500">{{ svc.duration_minutes }} menit</p>
            <p v-if="svc.description" class="text-xs text-gray-400 mt-0.5 truncate">{{ svc.description }}</p>
          </div>
          <p class="font-bold text-amber-600 flex-shrink-0">Rp {{ formatPrice(svc.price) }}</p>
        </div>
      </div>

      <!-- Ringkasan layanan terpilih -->
      <div v-if="selectedServices.length" class="mt-4 bg-amber-50 border border-amber-200 rounded-2xl p-4">
        <p class="text-xs font-semibold text-amber-700 mb-2">Ringkasan Pilihan:</p>
        <div class="space-y-1 mb-3">
          <div v-for="svc in selectedServices" :key="svc.id" class="flex justify-between text-sm">
            <span class="text-gray-700">{{ svc.name }}</span>
            <span class="text-amber-700 font-medium">Rp {{ formatPrice(svc.price) }}</span>
          </div>
        </div>
        <div class="border-t border-amber-200 pt-2 flex justify-between text-sm font-bold">
          <span class="text-gray-700">Total ({{ totalDuration }} menit)</span>
          <span class="text-amber-600">Rp {{ formatPrice(totalPrice) }}</span>
        </div>
      </div>

      <button @click="nextStep" :disabled="!selectedServices.length"
        class="w-full mt-5 py-3.5 rounded-2xl font-semibold text-white transition-colors"
        :class="selectedServices.length ? 'bg-amber-500 hover:bg-amber-600' : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
        Lanjut → ({{ selectedServices.length }} layanan)
      </button>
    </div>

    <!-- ─── STEP 2: Jadwal & Stylist ──────────────────────────── -->
    <div v-if="currentStep === 1">
      <h2 class="font-semibold text-gray-800 mb-3">Pilih Tanggal</h2>
      <input type="date" v-model="form.booking_date" :min="today" :max="maxDate"
        @change="loadSlots"
        class="w-full border-2 border-gray-200 rounded-2xl p-3.5 mb-5 focus:border-amber-500 outline-none text-gray-800" />

      <h2 class="font-semibold text-gray-800 mb-3">Pilih Jam Mulai</h2>
      <div v-if="loadingSlots" class="grid grid-cols-4 gap-2">
        <div v-for="i in 8" :key="i" class="h-12 bg-gray-100 rounded-xl animate-pulse"></div>
      </div>
      <div v-else-if="!form.booking_date" class="text-center text-gray-400 py-6 text-sm">Pilih tanggal terlebih dahulu</div>
      <div v-else-if="availableSlots.length === 0" class="text-center text-gray-400 py-6 text-sm">Tidak ada slot tersedia</div>
      <div v-else class="grid grid-cols-4 gap-2">
        <button v-for="slot in availableSlots" :key="slot.slot_time"
          :disabled="!slot.is_available"
          @click="form.booking_time = slot.slot_time"
          class="py-2.5 rounded-xl text-sm font-semibold transition-all"
          :class="form.booking_time === slot.slot_time ? 'bg-amber-500 text-white' : slot.is_available ? 'bg-white border-2 border-gray-200 text-gray-700 hover:border-amber-300' : 'bg-gray-100 text-gray-300 cursor-not-allowed'">
          {{ slot.slot_time.slice(0,5) }}
        </button>
      </div>

      <!-- Info total durasi -->
      <div v-if="form.booking_time" class="mt-3 bg-blue-50 border border-blue-200 rounded-xl p-3 flex items-center gap-2">
        <span class="text-blue-500">⏱</span>
        <p class="text-xs text-blue-700">
          Selesai sekitar pukul <strong>{{ estimatedEndTime }}</strong> ({{ totalDuration }} menit total)
        </p>
      </div>

      <!-- Pilih Stylist -->
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
            <div class="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-base font-bold text-amber-700 mb-1">{{ st.name[0] }}</div>
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

    <!-- ─── STEP 3: Data Pelanggan ────────────────────────────── -->
    <div v-if="currentStep === 2">
      <h2 class="font-semibold text-gray-800 mb-3">Data Pelanggan</h2>
      <div class="space-y-4">
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
        <div>
          <label class="text-sm font-medium text-gray-700 mb-1.5 block">Catatan</label>
          <textarea v-model="form.notes" rows="2" placeholder="Catatan khusus (opsional)"
            class="w-full border-2 border-gray-200 rounded-2xl p-3.5 focus:border-amber-500 outline-none resize-none"></textarea>
        </div>
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

    <!-- ─── STEP 4: Konfirmasi ────────────────────────────────── -->
    <div v-if="currentStep === 3">
      <h2 class="font-semibold text-gray-800 mb-4">Konfirmasi Booking</h2>

      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-4">
        <!-- Header -->
        <div class="bg-amber-500 text-white p-4">
          <p class="text-amber-100 text-xs mb-1">{{ selectedServices.length }} layanan dipilih</p>
          <div class="space-y-0.5">
            <p v-for="svc in selectedServices" :key="svc.id" class="font-semibold">{{ svc.name }}</p>
          </div>
          <p class="text-amber-100 text-sm mt-1">Total {{ totalDuration }} menit</p>
        </div>

        <!-- Detail -->
        <div class="p-4 space-y-3">
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Tanggal</span>
            <span class="font-medium text-right max-w-[60%]">{{ formatDate(form.booking_date) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Jam</span>
            <span class="font-medium">{{ form.booking_time?.slice(0,5) }} – {{ estimatedEndTime }}</span>
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
          <hr class="border-gray-100" />

          <!-- Rincian harga per layanan -->
          <div class="space-y-1.5">
            <div v-for="svc in selectedServices" :key="svc.id" class="flex justify-between text-sm">
              <span class="text-gray-500">{{ svc.name }}</span>
              <span>Rp {{ formatPrice(svc.price) }}</span>
            </div>
          </div>

          <!-- Voucher -->
          <div v-if="!appliedVoucher" class="flex gap-2 pt-1">
            <input v-model="voucherCode" type="text" placeholder="Kode voucher"
              @keyup.enter="applyVoucher"
              class="flex-1 border-2 border-gray-200 rounded-xl px-3 py-2 text-sm focus:border-amber-500 outline-none uppercase" />
            <button @click="applyVoucher" :disabled="checkingVoucher"
              class="px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-sm font-semibold transition-colors flex items-center gap-1">
              <span v-if="checkingVoucher" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
              <span v-else>Pakai</span>
            </button>
          </div>
          <div v-if="appliedVoucher" class="flex items-center justify-between bg-green-50 border border-green-200 rounded-xl px-3 py-2">
            <div class="flex items-center gap-2 text-sm text-green-700">
              <span>🎟️</span>
              <span class="font-medium">{{ appliedVoucher.code }} — hemat Rp {{ formatPrice(discountAmount) }}</span>
            </div>
            <button @click="removeVoucher" class="text-red-400 text-xs hover:text-red-600">✕</button>
          </div>
          <p v-if="voucherError" class="text-sm text-red-500">{{ voucherError }}</p>

          <!-- Total -->
          <div class="border-t border-gray-100 pt-2 space-y-1">
            <div class="flex justify-between text-sm">
              <span class="text-gray-500">Subtotal</span>
              <span>Rp {{ formatPrice(totalPrice) }}</span>
            </div>
            <div v-if="discountAmount" class="flex justify-between text-sm text-green-600">
              <span>Diskon</span>
              <span>- Rp {{ formatPrice(discountAmount) }}</span>
            </div>
            <div class="flex justify-between font-bold text-sm pt-1">
              <span>Total Bayar</span>
              <span class="text-amber-600 text-base">Rp {{ formatPrice(finalPrice) }}</span>
            </div>
          </div>
        </div>
      </div>

      <div v-if="error" class="bg-red-50 border border-red-200 rounded-xl p-3 mb-4 text-sm text-red-600">{{ error }}</div>

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
import { ref, computed, onMounted } from 'vue'
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

// ── Multi-select layanan ───────────────────────────────────────
const selectedServiceIds = ref(route.query.service ? [route.query.service] : [])

const selectedServices = computed(() =>
  servicesStore.services.filter(s => selectedServiceIds.value.includes(s.id))
)

const totalPrice = computed(() =>
  selectedServices.value.reduce((sum, s) => sum + Number(s.price), 0)
)

const totalDuration = computed(() =>
  selectedServices.value.reduce((sum, s) => sum + Number(s.duration_minutes), 0)
)

function isSelected(id) {
  return selectedServiceIds.value.includes(id)
}

function toggleService(svc) {
  const idx = selectedServiceIds.value.indexOf(svc.id)
  if (idx === -1) {
    selectedServiceIds.value.push(svc.id)
  } else {
    selectedServiceIds.value.splice(idx, 1)
  }
  removeVoucher()
}

// ── Perkiraan jam selesai ──────────────────────────────────────
const estimatedEndTime = computed(() => {
  if (!form.value.booking_time) return ''
  const [h, m] = form.value.booking_time.slice(0,5).split(':').map(Number)
  const totalMin = h * 60 + m + totalDuration.value
  const endH = Math.floor(totalMin / 60) % 24
  const endM = totalMin % 60
  return `${String(endH).padStart(2,'0')}:${String(endM).padStart(2,'0')}`
})

// ── Voucher ────────────────────────────────────────────────────
const voucherCode    = ref('')
const voucherError   = ref('')
const checkingVoucher = ref(false)
const appliedVoucher = ref(null)
const discountAmount = ref(0)

const finalPrice = computed(() => Math.max(0, totalPrice.value - discountAmount.value))

async function applyVoucher() {
  if (!voucherCode.value) return
  voucherError.value = ''
  checkingVoucher.value = true
  try {
    const result = await voucherStore.validateVoucher(voucherCode.value, totalPrice.value)
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

// ── Form & Booking ─────────────────────────────────────────────
const today = new Date().toISOString().split('T')[0]
const maxDate = new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]

const form = ref({
  booking_date: '',
  booking_time: null,
  staff_id: null,
  customer_name: authStore.profile?.full_name || '',
  customer_phone: authStore.profile?.phone || '',
  customer_email: authStore.user?.email || '',
  notes: ''
})

const selectedStaff = computed(() => staffStore.staff.find(s => s.id === form.value.staff_id))

function nextStep() { if (currentStep.value < 3) currentStep.value++ }
function prevStep() { if (currentStep.value > 0) currentStep.value-- }

async function loadSlots() {
  if (!form.value.booking_date || !selectedServiceIds.value.length) return
  loadingSlots.value = true
  form.value.booking_time = null
  try {
    // Gunakan layanan pertama untuk cek slot (durasi terpanjang sebagai acuan)
    const longestSvc = [...selectedServices.value].sort((a,b) => b.duration_minutes - a.duration_minutes)[0]
    availableSlots.value = await bookingStore.getAvailableSlots(form.value.booking_date, longestSvc.id)
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
    // Kirim booking pertama dengan layanan pertama, sisanya sebagai notes
    const primaryService = selectedServices.value[0]
    const additionalNames = selectedServices.value.slice(1).map(s => s.name).join(', ')
    const notesWithServices = additionalNames
      ? `[Layanan tambahan: ${additionalNames}]${form.value.notes ? ' | ' + form.value.notes : ''}`
      : form.value.notes

    const payload = {
      ...form.value,
      service_id: primaryService.id,
      user_id: authStore.user?.id || null,
      notes: notesWithServices,
      voucher_code: appliedVoucher.value?.code || null,
      discount_amount: discountAmount.value || 0,
      final_price: finalPrice.value,
    }
    const booking = await bookingStore.createBooking(payload)
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
    general:    '/Layanan.png',
  }
  return map[cat] || '/Layanan.png'
}

onMounted(async () => {
  await Promise.all([servicesStore.fetchServices(), staffStore.fetchStaff()])
})
</script>