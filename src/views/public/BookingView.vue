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

    <!-- Step 1: Pilih Layanan -->
    <div v-if="currentStep === 0">
      <h2 class="font-semibold text-gray-800 mb-3">Pilih Layanan</h2>
      <div v-if="servicesStore.loading" class="space-y-3">
        <div v-for="i in 4" :key="i" class="h-20 bg-gray-100 rounded-2xl animate-pulse"></div>
      </div>
      <div v-else class="space-y-3">
        <div v-for="svc in servicesStore.services" :key="svc.id"
          @click="selectService(svc)"
          class="flex items-center gap-4 p-4 rounded-2xl border-2 cursor-pointer transition-all"
          :class="form.service_id === svc.id ? 'border-amber-500 bg-amber-50' : 'border-gray-100 bg-white hover:border-amber-200'">
          <img :src="getCategoryIcon(svc.category)" class="w-8 h-8 object-contain" />
          <div class="flex-1">
            <p class="font-semibold text-gray-800">{{ svc.name }}</p>
            <p class="text-xs text-gray-500">{{ svc.duration_minutes }} menit</p>
            <p v-if="svc.description" class="text-xs text-gray-400 mt-0.5">{{ svc.description }}</p>
          </div>
          <p class="font-bold text-amber-600">Rp {{ formatPrice(svc.price) }}</p>
        </div>
      </div>
      <button @click="nextStep" :disabled="!form.service_id"
        class="w-full mt-6 py-3.5 rounded-2xl font-semibold text-white transition-colors"
        :class="form.service_id ? 'bg-amber-500 hover:bg-amber-600' : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
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
      <div v-else class="grid grid-cols-4 gap-2">
        <button v-for="slot in availableSlots" :key="slot.slot_time"
          :disabled="!slot.is_available"
          @click="form.booking_time = slot.slot_time"
          class="py-2.5 rounded-xl text-sm font-semibold transition-all"
          :class="form.booking_time === slot.slot_time
            ? 'bg-amber-500 text-white'
            : slot.is_available
              ? 'bg-white border-2 border-gray-200 text-gray-700 hover:border-amber-300'
              : 'bg-gray-100 text-gray-300 cursor-not-allowed'">
          {{ slot.slot_time.slice(0,5) }}
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
          <textarea v-model="form.notes" rows="3" placeholder="Ada catatan khusus? (opsional)"
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

    <!-- Step 4: Konfirmasi -->
    <div v-if="currentStep === 3">
      <h2 class="font-semibold text-gray-800 mb-4">Konfirmasi Booking</h2>
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-4">
        <div class="bg-amber-500 text-white p-4">
          <p class="text-sm text-amber-100">Layanan</p>
          <p class="font-bold text-lg">{{ selectedService?.name }}</p>
          <p class="text-amber-100 text-sm">{{ selectedService?.duration_minutes }} menit · Rp {{ formatPrice(selectedService?.price) }}</p>
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
        </div>
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
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useServicesStore } from '@/stores/services'
import { useStaffStore } from '@/stores/staff'
import { useBookingStore } from '@/stores/booking'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const servicesStore = useServicesStore()
const staffStore = useStaffStore()
const bookingStore = useBookingStore()

const steps = ['Layanan', 'Jadwal', 'Data', 'Konfirmasi']
const currentStep = ref(0)
const loadingSlots = ref(false)
const availableSlots = ref([])
const submitting = ref(false)
const error = ref('')

const today = new Date().toISOString().split('T')[0]
const maxDate = new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]

const form = ref({
  service_id: route.query.service || null,
  booking_date: '',
  booking_time: null,
  staff_id: null,
  customer_name: authStore.profile?.full_name || '',
  customer_phone: authStore.profile?.phone || '',
  customer_email: authStore.user?.email || '',
  notes: ''
})

const selectedService = computed(() => servicesStore.services.find(s => s.id === form.value.service_id))
const selectedStaff = computed(() => staffStore.staff.find(s => s.id === form.value.staff_id))

function selectService(svc) { form.value.service_id = svc.id }
function nextStep() { if (currentStep.value < 3) currentStep.value++ }
function prevStep() { if (currentStep.value > 0) currentStep.value-- }

async function loadSlots() {
  if (!form.value.booking_date || !form.value.service_id) return
  loadingSlots.value = true
  form.value.booking_time = null
  try {
    availableSlots.value = await bookingStore.getAvailableSlots(form.value.booking_date, form.value.service_id)
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
    const payload = {
      ...form.value,
      user_id: authStore.user?.id || null,
    }
    const booking = await bookingStore.createBooking(payload)
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
  await Promise.all([servicesStore.fetchServices(), staffStore.fetchStaff()])
  if (form.value.service_id) currentStep.value = 0
})
</script>
