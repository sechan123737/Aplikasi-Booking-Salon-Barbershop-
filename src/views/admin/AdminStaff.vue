<!-- src/views/admin/AdminStaff.vue -->
<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-white">Manajemen Karyawan</h1>
        <p class="text-gray-400 text-sm mt-0.5">{{ staffStore.staff.length }} karyawan</p>
      </div>
      <button @click="openModal()" class="px-4 py-2.5 bg-amber-500 hover:bg-amber-600 text-white text-sm font-semibold rounded-xl transition-colors">
        + Tambah Karyawan
      </button>
    </div>

    <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="st in staffStore.staff" :key="st.id"
        class="bg-gray-900 rounded-2xl border border-gray-800 p-5 hover:border-gray-700 transition-colors">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-14 h-14 rounded-2xl bg-amber-500/20 flex items-center justify-center text-2xl font-bold text-amber-400">
            {{ st.name[0] }}
          </div>
          <div>
            <p class="text-white font-semibold">{{ st.name }}</p>
            <p class="text-gray-400 text-xs">{{ st.phone || 'Tidak ada HP' }}</p>
          </div>
        </div>
        <div v-if="st.specialization?.length" class="flex flex-wrap gap-1.5 mb-3">
          <span v-for="spec in st.specialization" :key="spec"
            class="text-xs bg-gray-800 text-gray-300 rounded-full px-2.5 py-0.5">
            {{ spec }}
          </span>
        </div>
        <p v-if="st.bio" class="text-gray-400 text-xs mb-4">{{ st.bio }}</p>
        <div class="flex gap-2">
          <button @click="openModal(st)"
            class="flex-1 py-2 bg-blue-500/20 text-blue-400 text-xs font-medium rounded-xl hover:bg-blue-500/30 transition-colors">
            ✏️ Edit
          </button>
          <button @click="toggleActive(st)"
            class="flex-1 py-2 bg-gray-800 text-gray-400 text-xs font-medium rounded-xl hover:bg-gray-700 transition-colors">
            {{ st.is_active ? 'Nonaktifkan' : 'Aktifkan' }}
          </button>
          <button @click="deleteStaff(st.id)"
            class="py-2 px-3 bg-red-500/20 text-red-400 text-xs font-medium rounded-xl hover:bg-red-500/30 transition-colors">
            🗑️
          </button>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-black/70" @click="showModal = false"></div>
      <div class="relative bg-gray-900 border border-gray-700 rounded-3xl p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
        <h2 class="text-white font-bold text-lg mb-5">{{ editingId ? 'Edit Karyawan' : 'Tambah Karyawan' }}</h2>
        <div class="space-y-4">
          <div>
            <label class="text-gray-400 text-xs font-medium block mb-1.5">Nama *</label>
            <input v-model="form.name" type="text"
              class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm" />
          </div>
          <div>
            <label class="text-gray-400 text-xs font-medium block mb-1.5">Nomor HP</label>
            <input v-model="form.phone" type="tel"
              class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm" />
          </div>
          <div>
            <label class="text-gray-400 text-xs font-medium block mb-1.5">Spesialisasi</label>
            <div class="flex flex-wrap gap-2">
              <label v-for="spec in specOptions" :key="spec"
                class="flex items-center gap-1.5 cursor-pointer">
                <input type="checkbox" :value="spec" v-model="form.specialization" class="accent-amber-500" />
                <span class="text-gray-300 text-sm">{{ spec }}</span>
              </label>
            </div>
          </div>
          <div>
            <label class="text-gray-400 text-xs font-medium block mb-1.5">Bio</label>
            <textarea v-model="form.bio" rows="2"
              class="w-full bg-gray-800 border border-gray-700 text-white rounded-xl p-3 focus:border-amber-500 outline-none text-sm resize-none"></textarea>
          </div>
          <label class="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" v-model="form.is_active" class="accent-amber-500" />
            <span class="text-gray-300 text-sm">Karyawan aktif</span>
          </label>
        </div>
        <div v-if="formError" class="mt-3 text-red-400 text-sm">{{ formError }}</div>
        <div class="flex gap-3 mt-5">
          <button @click="showModal = false" class="flex-1 py-3 rounded-xl border border-gray-700 text-gray-400 font-medium">Batal</button>
          <button @click="saveStaff" :disabled="saving"
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
import { useStaffStore } from '@/stores/staff'

const staffStore = useStaffStore()
const showModal = ref(false)
const editingId = ref(null)
const saving = ref(false)
const formError = ref('')

const specOptions = ['rambut', 'wajah', 'kuku', 'barbershop', 'general']
const defaultForm = () => ({ name: '', phone: '', specialization: [], bio: '', is_active: true })
const form = ref(defaultForm())

function openModal(st = null) {
  formError.value = ''
  if (st) {
    editingId.value = st.id
    form.value = { name: st.name, phone: st.phone || '', specialization: [...(st.specialization || [])], bio: st.bio || '', is_active: st.is_active }
  } else {
    editingId.value = null
    form.value = defaultForm()
  }
  showModal.value = true
}

async function saveStaff() {
  if (!form.value.name) { formError.value = 'Nama wajib diisi.'; return }
  saving.value = true
  formError.value = ''
  try {
    if (editingId.value) {
      await staffStore.updateStaff(editingId.value, form.value)
    } else {
      await staffStore.createStaff(form.value)
    }
    showModal.value = false
  } catch (e) {
    formError.value = e.message
  } finally {
    saving.value = false
  }
}

async function toggleActive(st) {
  await staffStore.updateStaff(st.id, { is_active: !st.is_active })
}

async function deleteStaff(id) {
  if (!confirm('Hapus karyawan ini?')) return
  await staffStore.deleteStaff(id)
}

onMounted(() => staffStore.fetchStaff(false))
</script>
