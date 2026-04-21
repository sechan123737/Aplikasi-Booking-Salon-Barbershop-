<!-- src/views/admin/AdminServices.vue -->
<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-white">Manajemen Layanan</h1>
        <p class="text-gray-400 text-sm mt-0.5">{{ servicesStore.services.length }} layanan</p>
      </div>
      <button @click="openModal()" class="px-4 py-2.5 bg-amber-500 hover:bg-amber-600 text-white text-sm font-semibold rounded-xl transition-colors">
        + Tambah Layanan
      </button>
    </div>

    <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="svc in servicesStore.services" :key="svc.id"
        class="bg-gray-900 rounded-2xl border border-gray-800 p-5 hover:border-gray-700 transition-colors">
        <div class="flex items-start justify-between mb-3">
          <div class="w-12 h-12 bg-amber-500/20 rounded-xl flex items-center justify-center text-2xl">
            {{ getCategoryEmoji(svc.category) }}
          </div>
          <div class="flex items-center gap-1">
            <span class="text-xs px-2 py-0.5 rounded-full" :class="svc.is_active ? 'bg-green-500/20 text-green-400' : 'bg-gray-700 text-gray-400'">
              {{ svc.is_active ? 'Aktif' : 'Nonaktif' }}
            </span>
          </div>
        </div>
        <p class="text-white font-semibold mb-1">{{ svc.name }}</p>
        <p class="text-gray-400 text-xs mb-3">{{ svc.description || 'Tidak ada deskripsi' }}</p>
        <div class="flex items-center justify-between text-sm mb-4">
          <span class="text-amber-400 font-bold">Rp {{ formatPrice(svc.price) }}</span>
          <span class="text-gray-400">⏱ {{ svc.duration_minutes }} menit</span>
        </div>
        <div class="flex gap-2">
          <button @click="openModal(svc)"
            class="flex-1 py-2 bg-blue-500/20 text-blue-400 text-xs font-medium rounded-xl hover:bg-blue-500/30 transition-colors">
            ✏️ Edit
          </button>
          <button @click="toggleActive(svc)"
            class="flex-1 py-2 bg-gray-800 text-gray-400 text-xs font-medium rounded-xl hover:bg-gray-700 transition-colors">
            {{ svc.is_active ? 'Nonaktifkan' : 'Aktifkan' }}
          </button>
          <button @click="deleteService(svc.id)"
            class="py-2 px-3 bg-red-500/20 text-red-400 text-xs font-medium rounded-xl hover:bg-red-500/30 transition-colors">
            🗑️
          </button>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-black/70" @click="showModal = false"></div>
      <div class="relative bg-gray-900 border border-gray-700 rounded-3xl p-6 w-full max-w-md">
        <h2 class="text-white font-bold text-lg mb-5">{{ editingId ? 'Edit Layanan' : 'Tambah Layanan' }}</h2>
        <div class="space-y-4">
          <div>
            <label class="text-gray-400 text-xs font-medium block mb-1.5">Nama Layanan *</label>
            <input v-model="form.name" type="text"
              class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm" />
          </div>
          <div>
            <label class="text-gray-400 text-xs font-medium block mb-1.5">Kategori</label>
            <select v-model="form.category"
              class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm">
              <option value="rambut">Rambut</option>
              <option value="wajah">Wajah</option>
              <option value="kuku">Kuku</option>
              <option value="barbershop">Barbershop</option>
              <option value="general">Umum</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-gray-400 text-xs font-medium block mb-1.5">Harga (Rp) *</label>
              <input v-model="form.price" type="number" min="0"
                class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm" />
            </div>
            <div>
              <label class="text-gray-400 text-xs font-medium block mb-1.5">Durasi (menit) *</label>
              <input v-model="form.duration_minutes" type="number" min="15" step="15"
                class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm" />
            </div>
          </div>
          <div>
            <label class="text-gray-400 text-xs font-medium block mb-1.5">Deskripsi</label>
            <textarea v-model="form.description" rows="2"
              class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm resize-none"></textarea>
          </div>
          <label class="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" v-model="form.is_active" class="accent-amber-500" />
            <span class="text-gray-300 text-sm">Layanan aktif</span>
          </label>
        </div>
        <div v-if="formError" class="mt-3 text-red-400 text-sm">{{ formError }}</div>
        <div class="flex gap-3 mt-5">
          <button @click="showModal = false" class="flex-1 py-3 rounded-xl border border-gray-700 text-gray-400 font-medium hover:bg-gray-800">Batal</button>
          <button @click="saveService" :disabled="saving"
            class="flex-1 py-3 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-semibold transition-colors">
            {{ saving ? 'Menyimpan...' : 'Simpan' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useServicesStore } from '@/stores/services'

const servicesStore = useServicesStore()
const showModal = ref(false)
const editingId = ref(null)
const saving = ref(false)
const formError = ref('')

const defaultForm = () => ({
  name: '', category: 'rambut', price: 0, duration_minutes: 30, description: '', is_active: true
})
const form = ref(defaultForm())

function openModal(svc = null) {
  formError.value = ''
  if (svc) {
    editingId.value = svc.id
    form.value = { name: svc.name, category: svc.category, price: svc.price, duration_minutes: svc.duration_minutes, description: svc.description || '', is_active: svc.is_active }
  } else {
    editingId.value = null
    form.value = defaultForm()
  }
  showModal.value = true
}

async function saveService() {
  if (!form.value.name || !form.value.price) { formError.value = 'Nama dan harga wajib diisi.'; return }
  saving.value = true
  formError.value = ''
  try {
    if (editingId.value) {
      await servicesStore.updateService(editingId.value, form.value)
    } else {
      await servicesStore.createService(form.value)
    }
    showModal.value = false
  } catch (e) {
    formError.value = e.message
  } finally {
    saving.value = false
  }
}

async function toggleActive(svc) {
  await servicesStore.updateService(svc.id, { is_active: !svc.is_active })
}

async function deleteService(id) {
  if (!confirm('Hapus layanan ini?')) return
  await servicesStore.deleteService(id)
}

function formatPrice(p) { return Number(p).toLocaleString('id-ID') }
function getCategoryEmoji(cat) {
  const map = { rambut:'💇', wajah:'🧖', kuku:'💅', barbershop:'🪒', general:'✂️' }
  return map[cat] || '✂️'
}

onMounted(() => servicesStore.fetchServices(false))
</script>
