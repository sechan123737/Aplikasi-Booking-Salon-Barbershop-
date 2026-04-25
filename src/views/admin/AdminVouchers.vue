<!-- src/views/admin/AdminVouchers.vue -->
<template>
  <div class="p-6 max-w-5xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Kelola Voucher</h1>
        <p class="text-sm text-gray-500 mt-0.5">Buat & atur kode diskon untuk pelanggan</p>
      </div>
      <button @click="openModal()"
        class="flex items-center gap-2 bg-amber-500 hover:bg-amber-600 text-white px-4 py-2.5 rounded-xl font-semibold transition-colors">
        <span>➕</span> Buat Voucher
      </button>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-3 gap-4 mb-6">
      <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
        <p class="text-xs text-gray-500 mb-1">Total Voucher</p>
        <p class="text-2xl font-bold text-gray-900">{{ voucherStore.vouchers.length }}</p>
      </div>
      <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
        <p class="text-xs text-gray-500 mb-1">Aktif</p>
        <p class="text-2xl font-bold text-green-600">{{ activeCount }}</p>
      </div>
      <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
        <p class="text-xs text-gray-500 mb-1">Total Dipakai</p>
        <p class="text-2xl font-bold text-amber-600">{{ totalUsed }}</p>
      </div>
    </div>

    <!-- List -->
    <div v-if="voucherStore.loading" class="space-y-3">
      <div v-for="i in 4" :key="i" class="h-24 bg-gray-100 rounded-2xl animate-pulse"></div>
    </div>

    <div v-else-if="voucherStore.vouchers.length === 0"
      class="text-center py-16 text-gray-400">
      <p class="text-4xl mb-3">🎟️</p>
      <p class="font-medium">Belum ada voucher. Buat voucher pertama!</p>
    </div>

    <div v-else class="space-y-3">
      <div v-for="v in voucherStore.vouchers" :key="v.id"
        class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 flex flex-col sm:flex-row sm:items-center gap-4">

        <!-- Kode + badge -->
        <div class="flex items-center gap-3 flex-1">
          <div class="bg-amber-50 rounded-xl p-3 text-2xl">🎟️</div>
          <div>
            <div class="flex items-center gap-2 flex-wrap">
              <span class="font-mono font-bold text-gray-900 text-lg tracking-widest">{{ v.code }}</span>
              <span class="text-xs px-2 py-0.5 rounded-full font-semibold"
                :class="getStatusClass(v)">{{ getStatusLabel(v) }}</span>
            </div>
            <p class="text-sm text-gray-600 mt-0.5">{{ v.name }}</p>
            <div class="flex flex-wrap gap-3 mt-1.5 text-xs text-gray-500">
              <span class="font-semibold text-amber-600">
                {{ v.discount_type === 'percent' ? v.discount_value + '%' : 'Rp ' + formatPrice(v.discount_value) }} diskon
                <span v-if="v.discount_type === 'percent' && v.max_discount"> (maks Rp {{ formatPrice(v.max_discount) }})</span>
              </span>
              <span v-if="v.min_purchase">Min. Rp {{ formatPrice(v.min_purchase) }}</span>
              <span v-if="v.valid_until">Berlaku s/d {{ formatDate(v.valid_until) }}</span>
              <span>Pakai: {{ v.used_count }}{{ v.max_uses ? '/' + v.max_uses : '' }}x</span>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex gap-2 sm:flex-col">
          <button @click="openModal(v)"
            class="flex-1 sm:flex-none text-sm px-4 py-2 rounded-xl border-2 border-gray-200 hover:border-amber-400 text-gray-600 hover:text-amber-600 font-medium transition-colors">
            ✏️ Edit
          </button>
          <button @click="toggleActive(v)"
            class="flex-1 sm:flex-none text-sm px-4 py-2 rounded-xl font-medium transition-colors"
            :class="v.is_active ? 'bg-red-50 text-red-500 hover:bg-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100'">
            {{ v.is_active ? '🔴 Nonaktifkan' : '🟢 Aktifkan' }}
          </button>
          <button @click="confirmDelete(v)"
            class="flex-1 sm:flex-none text-sm px-4 py-2 rounded-xl bg-gray-50 text-gray-400 hover:bg-red-50 hover:text-red-500 font-medium transition-colors">
            🗑️
          </button>
        </div>
      </div>
    </div>

    <!-- ── MODAL CREATE/EDIT ── -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 bg-black/40">
      <div class="bg-white rounded-3xl w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
        <div class="p-6">
          <div class="flex items-center justify-between mb-5">
            <h2 class="text-xl font-bold">{{ editingVoucher ? 'Edit Voucher' : 'Buat Voucher Baru' }}</h2>
            <button @click="closeModal" class="text-gray-400 hover:text-gray-600 text-2xl leading-none">×</button>
          </div>

          <div class="space-y-4">
            <!-- Kode -->
            <div>
              <label class="text-sm font-medium text-gray-700 mb-1.5 block">Kode Voucher *</label>
              <div class="flex gap-2">
                <input v-model="form.code" type="text" placeholder="cth: DISKON50"
                  class="flex-1 border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none font-mono uppercase tracking-widest"
                  @input="form.code = form.code.toUpperCase().replace(/\s/g,'')" />
                <button @click="generateCode"
                  class="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-xl text-sm font-medium text-gray-600 transition-colors">
                  🎲 Acak
                </button>
              </div>
            </div>

            <!-- Nama/Deskripsi -->
            <div>
              <label class="text-sm font-medium text-gray-700 mb-1.5 block">Nama / Keterangan</label>
              <input v-model="form.name" type="text" placeholder="cth: Promo Hari Jadi Salon"
                class="w-full border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none" />
            </div>

            <!-- Tipe Diskon -->
            <div>
              <label class="text-sm font-medium text-gray-700 mb-2 block">Tipe Diskon *</label>
              <div class="grid grid-cols-2 gap-3">
                <button @click="form.discount_type = 'percent'"
                  class="py-3 rounded-xl border-2 font-semibold text-sm transition-all"
                  :class="form.discount_type === 'percent' ? 'border-amber-500 bg-amber-50 text-amber-700' : 'border-gray-200 text-gray-600'">
                  % Persen
                </button>
                <button @click="form.discount_type = 'fixed'"
                  class="py-3 rounded-xl border-2 font-semibold text-sm transition-all"
                  :class="form.discount_type === 'fixed' ? 'border-amber-500 bg-amber-50 text-amber-700' : 'border-gray-200 text-gray-600'">
                  Rp Nominal
                </button>
              </div>
            </div>

            <!-- Nilai Diskon -->
            <div>
              <label class="text-sm font-medium text-gray-700 mb-1.5 block">
                Nilai Diskon * <span class="text-gray-400 font-normal">({{ form.discount_type === 'percent' ? '% dari harga' : 'Rupiah' }})</span>
              </label>
              <div class="relative">
                <span v-if="form.discount_type === 'fixed'" class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-medium">Rp</span>
                <input v-model.number="form.discount_value" type="number" min="0"
                  :max="form.discount_type === 'percent' ? 100 : undefined"
                  :placeholder="form.discount_type === 'percent' ? '0 - 100' : 'contoh: 50000'"
                  class="w-full border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none"
                  :class="form.discount_type === 'fixed' ? 'pl-10' : ''" />
                <span v-if="form.discount_type === 'percent'" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500">%</span>
              </div>
            </div>

            <!-- Max diskon (hanya untuk persen) -->
            <div v-if="form.discount_type === 'percent'">
              <label class="text-sm font-medium text-gray-700 mb-1.5 block">
                Maks. Diskon <span class="text-gray-400 font-normal">(opsional)</span>
              </label>
              <div class="relative">
                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-medium">Rp</span>
                <input v-model.number="form.max_discount" type="number" min="0" placeholder="tidak terbatas"
                  class="w-full border-2 border-gray-200 rounded-xl p-3 pl-10 focus:border-amber-500 outline-none" />
              </div>
            </div>

            <!-- Min Purchase -->
            <div>
              <label class="text-sm font-medium text-gray-700 mb-1.5 block">
                Minimum Pembelian <span class="text-gray-400 font-normal">(opsional)</span>
              </label>
              <div class="relative">
                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-medium">Rp</span>
                <input v-model.number="form.min_purchase" type="number" min="0" placeholder="tidak ada minimum"
                  class="w-full border-2 border-gray-200 rounded-xl p-3 pl-10 focus:border-amber-500 outline-none" />
              </div>
            </div>

            <!-- Masa berlaku -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-sm font-medium text-gray-700 mb-1.5 block">Berlaku Dari</label>
                <input v-model="form.valid_from" type="date"
                  class="w-full border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none" />
              </div>
              <div>
                <label class="text-sm font-medium text-gray-700 mb-1.5 block">Berlaku Sampai</label>
                <input v-model="form.valid_until" type="date"
                  class="w-full border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none" />
              </div>
            </div>

            <!-- Max penggunaan -->
            <div>
              <label class="text-sm font-medium text-gray-700 mb-1.5 block">
                Maks. Penggunaan <span class="text-gray-400 font-normal">(opsional)</span>
              </label>
              <input v-model.number="form.max_uses" type="number" min="1" placeholder="tidak terbatas"
                class="w-full border-2 border-gray-200 rounded-xl p-3 focus:border-amber-500 outline-none" />
            </div>

            <!-- Status aktif -->
            <div class="flex items-center justify-between p-3.5 bg-gray-50 rounded-xl">
              <span class="text-sm font-medium text-gray-700">Voucher Aktif</span>
              <button @click="form.is_active = !form.is_active"
                class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors"
                :class="form.is_active ? 'bg-amber-500' : 'bg-gray-300'">
                <span class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow"
                  :class="form.is_active ? 'translate-x-6' : 'translate-x-1'"></span>
              </button>
            </div>
          </div>

          <!-- Error -->
          <div v-if="formError" class="mt-4 bg-red-50 border border-red-200 rounded-xl p-3 text-sm text-red-600">
            {{ formError }}
          </div>

          <!-- Actions -->
          <div class="flex gap-3 mt-6">
            <button @click="closeModal" class="flex-1 py-3 rounded-xl border-2 border-gray-200 font-semibold text-gray-600">Batal</button>
            <button @click="saveVoucher" :disabled="saving"
              class="flex-1 py-3 rounded-xl bg-amber-500 hover:bg-amber-600 font-semibold text-white transition-colors flex items-center justify-center gap-2">
              <span v-if="saving" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
              {{ saving ? 'Menyimpan...' : (editingVoucher ? 'Simpan Perubahan' : 'Buat Voucher') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- ── MODAL DELETE CONFIRM ── -->
    <div v-if="deletingVoucher" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40">
      <div class="bg-white rounded-2xl p-6 w-full max-w-sm shadow-xl">
        <p class="text-lg font-bold text-gray-900 mb-2">Hapus Voucher?</p>
        <p class="text-sm text-gray-500 mb-5">Voucher <span class="font-mono font-bold">{{ deletingVoucher.code }}</span> akan dihapus permanen.</p>
        <div class="flex gap-3">
          <button @click="deletingVoucher = null" class="flex-1 py-2.5 rounded-xl border-2 border-gray-200 font-semibold text-gray-600">Batal</button>
          <button @click="doDelete" :disabled="saving"
            class="flex-1 py-2.5 rounded-xl bg-red-500 hover:bg-red-600 text-white font-semibold transition-colors">
            {{ saving ? '...' : 'Hapus' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useVoucherStore } from '@/stores/vouchers'

const voucherStore = useVoucherStore()

const showModal   = ref(false)
const editingVoucher = ref(null)
const deletingVoucher = ref(null)
const saving      = ref(false)
const formError   = ref('')

const defaultForm = () => ({
  code: '',
  name: '',
  discount_type: 'percent',
  discount_value: '',
  max_discount: null,
  min_purchase: null,
  valid_from: '',
  valid_until: '',
  max_uses: null,
  is_active: true,
})
const form = ref(defaultForm())

const activeCount = computed(() => voucherStore.vouchers.filter(v => v.is_active).length)
const totalUsed   = computed(() => voucherStore.vouchers.reduce((s, v) => s + (v.used_count || 0), 0))

function getStatusClass(v) {
  if (!v.is_active) return 'bg-gray-100 text-gray-500'
  const now = new Date()
  if (v.valid_until && new Date(v.valid_until) < now) return 'bg-red-100 text-red-600'
  if (v.max_uses !== null && v.used_count >= v.max_uses) return 'bg-orange-100 text-orange-600'
  return 'bg-green-100 text-green-600'
}

function getStatusLabel(v) {
  if (!v.is_active) return 'Nonaktif'
  const now = new Date()
  if (v.valid_until && new Date(v.valid_until) < now) return 'Kedaluwarsa'
  if (v.max_uses !== null && v.used_count >= v.max_uses) return 'Habis'
  return 'Aktif'
}

function openModal(voucher = null) {
  formError.value = ''
  if (voucher) {
    editingVoucher.value = voucher
    form.value = {
      code:           voucher.code,
      name:           voucher.name || '',
      discount_type:  voucher.discount_type,
      discount_value: voucher.discount_value,
      max_discount:   voucher.max_discount,
      min_purchase:   voucher.min_purchase,
      valid_from:     voucher.valid_from?.slice(0,10) || '',
      valid_until:    voucher.valid_until?.slice(0,10) || '',
      max_uses:       voucher.max_uses,
      is_active:      voucher.is_active,
    }
  } else {
    editingVoucher.value = null
    form.value = defaultForm()
  }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingVoucher.value = null
  formError.value = ''
}

function generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  form.value.code = Array.from({ length: 8 }, () => chars[Math.floor(Math.random() * chars.length)]).join('')
}

async function saveVoucher() {
  formError.value = ''
  if (!form.value.code) return (formError.value = 'Kode voucher wajib diisi.')
  if (!form.value.discount_value || form.value.discount_value <= 0) return (formError.value = 'Nilai diskon harus lebih dari 0.')
  if (form.value.discount_type === 'percent' && form.value.discount_value > 100) return (formError.value = 'Diskon persen maksimal 100%.')

  saving.value = true
  try {
    const payload = {
      code:           form.value.code,
      name:           form.value.name || null,
      discount_type:  form.value.discount_type,
      discount_value: form.value.discount_value,
      max_discount:   form.value.discount_type === 'percent' ? (form.value.max_discount || null) : null,
      min_purchase:   form.value.min_purchase || null,
      valid_from:     form.value.valid_from || null,
      valid_until:    form.value.valid_until || null,
      max_uses:       form.value.max_uses || null,
      is_active:      form.value.is_active,
    }
    if (editingVoucher.value) {
      await voucherStore.updateVoucher(editingVoucher.value.id, payload)
    } else {
      await voucherStore.createVoucher(payload)
    }
    closeModal()
  } catch (e) {
    formError.value = e.message || 'Gagal menyimpan voucher.'
  } finally {
    saving.value = false
  }
}

async function toggleActive(v) {
  try {
    await voucherStore.updateVoucher(v.id, { is_active: !v.is_active })
  } catch (e) {
    alert(e.message)
  }
}

function confirmDelete(v) {
  deletingVoucher.value = v
}

async function doDelete() {
  saving.value = true
  try {
    await voucherStore.deleteVoucher(deletingVoucher.value.id)
    deletingVoucher.value = null
  } catch (e) {
    alert(e.message)
  } finally {
    saving.value = false
  }
}

function formatPrice(p) { return Number(p || 0).toLocaleString('id-ID') }
function formatDate(d)   { return d ? new Date(d).toLocaleDateString('id-ID', { day:'numeric', month:'short', year:'numeric' }) : '-' }

onMounted(() => voucherStore.fetchAllVouchers())
</script>
