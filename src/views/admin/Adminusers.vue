<!-- src/views/admin/AdminUsers.vue -->
<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-white">Manajemen Pengguna</h1>
        <p class="text-gray-400 text-sm mt-0.5">Kelola role & akses pengguna</p>
      </div>
    </div>

    <!-- Search -->
    <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4 mb-6">
      <input v-model="search" type="text" placeholder="Cari nama atau email..."
        class="w-full bg-gray-800 border border-gray-700 text-gray-300 rounded-xl px-4 py-2.5 text-sm focus:border-amber-500 outline-none" />
    </div>

    <!-- Tabel -->
    <div class="bg-gray-900 rounded-2xl border border-gray-800 overflow-hidden">
      <div v-if="loading" class="p-8 text-center text-gray-500">
        <div class="w-8 h-8 border-2 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto mb-2"></div>
        Memuat data...
      </div>
      <div v-else-if="filteredUsers.length === 0" class="p-12 text-center text-gray-500">
        <p class="text-4xl mb-2">👥</p>
        Tidak ada pengguna ditemukan
      </div>
      <div v-else>
        <!-- Desktop table -->
        <div class="hidden lg:block overflow-x-auto">
          <table class="w-full">
            <thead class="border-b border-gray-800">
              <tr class="text-left">
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Pengguna</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Role</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Bergabung</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Aksi</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-800">
              <tr v-for="u in filteredUsers" :key="u.id" class="hover:bg-gray-800/50 transition-colors">
                <td class="px-5 py-4">
                  <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold text-sm flex-shrink-0">
                      {{ u.full_name?.[0]?.toUpperCase() || '?' }}
                    </div>
                    <div>
                      <p class="text-white font-medium text-sm">{{ u.full_name || 'Tanpa Nama' }}</p>
                      <p class="text-gray-400 text-xs">{{ u.phone || '-' }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-5 py-4">
                  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold"
                    :class="u.role === 'admin' ? 'bg-purple-500/20 text-purple-400' : 'bg-gray-700 text-gray-300'">
                    {{ u.role === 'admin' ? '👑 Admin' : '👤 User' }}
                  </span>
                </td>
                <td class="px-5 py-4 text-gray-400 text-sm">{{ formatDate(u.created_at) }}</td>
                <td class="px-5 py-4">
                  <!-- Tidak bisa ubah role diri sendiri -->
                  <button v-if="u.id !== currentUserId"
                    @click="confirmRoleChange(u)"
                    class="px-3 py-1.5 text-xs font-medium rounded-lg transition-colors"
                    :class="u.role === 'admin'
                      ? 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                      : 'bg-purple-500/20 text-purple-400 hover:bg-purple-500/30'">
                    {{ u.role === 'admin' ? 'Jadikan User' : '👑 Jadikan Admin' }}
                  </button>
                  <span v-else class="text-gray-600 text-xs">Akun kamu</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Mobile cards -->
        <div class="lg:hidden space-y-3 p-4">
          <div v-for="u in filteredUsers" :key="u.id"
            class="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold">
                  {{ u.full_name?.[0]?.toUpperCase() || '?' }}
                </div>
                <div>
                  <p class="text-white font-medium text-sm">{{ u.full_name || 'Tanpa Nama' }}</p>
                  <p class="text-gray-400 text-xs">{{ u.phone || '-' }}</p>
                </div>
              </div>
              <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold"
                :class="u.role === 'admin' ? 'bg-purple-500/20 text-purple-400' : 'bg-gray-700 text-gray-300'">
                {{ u.role === 'admin' ? '👑 Admin' : '👤 User' }}
              </span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-gray-500 text-xs">{{ formatDate(u.created_at) }}</span>
              <button v-if="u.id !== currentUserId"
                @click="confirmRoleChange(u)"
                class="px-3 py-1.5 text-xs font-medium rounded-lg transition-colors"
                :class="u.role === 'admin'
                  ? 'bg-gray-700 text-gray-300'
                  : 'bg-purple-500/20 text-purple-400'">
                {{ u.role === 'admin' ? 'Jadikan User' : '👑 Jadikan Admin' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Konfirmasi Ubah Role -->
    <div v-if="confirmTarget" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-black/70" @click="confirmTarget = null"></div>
      <div class="relative bg-gray-900 border border-gray-700 rounded-3xl p-6 w-full max-w-sm">
        <div class="w-16 h-16 rounded-2xl flex items-center justify-center text-4xl mx-auto mb-4"
          :class="confirmTarget.role === 'admin' ? 'bg-gray-700' : 'bg-purple-500/20'">
          {{ confirmTarget.role === 'admin' ? '👤' : '👑' }}
        </div>
        <h2 class="text-white font-bold text-lg text-center mb-2">
          {{ confirmTarget.role === 'admin' ? 'Turunkan ke User?' : 'Jadikan Admin?' }}
        </h2>
        <p class="text-gray-400 text-sm text-center mb-1">
          <span class="text-white font-semibold">{{ confirmTarget.full_name }}</span>
          akan dijadikan
          <span class="font-semibold" :class="confirmTarget.role === 'admin' ? 'text-gray-300' : 'text-purple-400'">
            {{ confirmTarget.role === 'admin' ? 'User biasa' : 'Admin' }}
          </span>
        </p>
        <p v-if="confirmTarget.role !== 'admin'" class="text-gray-500 text-xs text-center mb-6">
          Admin bisa mengakses semua data dan pengaturan salon.
        </p>
        <p v-else class="text-gray-500 text-xs text-center mb-6">
          Pengguna ini tidak bisa lagi mengakses panel admin.
        </p>
        <div class="flex gap-3">
          <button @click="confirmTarget = null"
            class="flex-1 py-3 rounded-2xl border-2 border-gray-700 font-semibold text-gray-400 hover:bg-gray-800 transition-colors">
            Batal
          </button>
          <button @click="doRoleChange" :disabled="saving"
            class="flex-1 py-3 rounded-2xl font-semibold text-white transition-colors flex items-center justify-center gap-2"
            :class="confirmTarget.role === 'admin' ? 'bg-gray-600 hover:bg-gray-500' : 'bg-purple-600 hover:bg-purple-500'">
            <span v-if="saving" class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            {{ saving ? 'Menyimpan...' : 'Ya, Ubah' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const authStore = useAuthStore()
const currentUserId = computed(() => authStore.user?.id)

const users = ref([])
const loading = ref(true)
const search = ref('')
const confirmTarget = ref(null)
const saving = ref(false)

const filteredUsers = computed(() => {
  if (!search.value) return users.value
  const q = search.value.toLowerCase()
  return users.value.filter(u =>
    u.full_name?.toLowerCase().includes(q) ||
    u.phone?.includes(q)
  )
})

async function loadUsers() {
  loading.value = true
  // Pakai RPC function agar bypass RLS (SECURITY DEFINER)
  const { data, error } = await supabase
    .rpc('get_all_profiles')
  loading.value = false
  if (error) {
    console.error('loadUsers error:', error)
    return
  }
  users.value = data || []
}

function confirmRoleChange(u) {
  confirmTarget.value = { ...u }
}

async function doRoleChange() {
  saving.value = true
  const newRole = confirmTarget.value.role === 'admin' ? 'user' : 'admin'
  try {
    // Pakai RPC agar bypass RLS
    const { error } = await supabase.rpc('update_user_role', {
      p_user_id: confirmTarget.value.id,
      p_role: newRole
    })
    if (error) throw error
    // Update tampilan lokal
    const idx = users.value.findIndex(u => u.id === confirmTarget.value.id)
    if (idx !== -1) users.value[idx].role = newRole
    confirmTarget.value = null
  } catch (e) {
    console.error('Gagal ubah role:', e)
    alert('Gagal mengubah role: ' + e.message)
  } finally {
    saving.value = false
  }
}

function formatDate(d) {
  return new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
}

onMounted(loadUsers)
</script>