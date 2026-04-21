<!-- src/views/admin/AdminSchedule.vue -->
<template>
  <div class="max-w-2xl">
    <h1 class="text-2xl font-bold text-white mb-2">Jadwal & Jam Buka</h1>
    <p class="text-gray-400 text-sm mb-8">Kelola jam operasional dan hari libur</p>

    <!-- Working Hours -->
    <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5 mb-6">
      <h2 class="text-white font-semibold mb-4">Jam Operasional</h2>
      <div v-if="loadingHours" class="space-y-3">
        <div v-for="i in 7" :key="i" class="h-12 bg-gray-800 rounded-xl animate-pulse"></div>
      </div>
      <div v-else class="space-y-3">
        <div v-for="wh in workingHours" :key="wh.day_of_week"
          class="flex items-center gap-4 p-3 bg-gray-800/50 rounded-xl">
          <label class="flex items-center gap-2 w-28 cursor-pointer">
            <input type="checkbox" v-model="wh.is_open" @change="saveHour(wh)" class="accent-amber-500" />
            <span class="text-sm font-medium" :class="wh.is_open ? 'text-white' : 'text-gray-500'">
              {{ dayNames[wh.day_of_week] }}
            </span>
          </label>
          <template v-if="wh.is_open">
            <input type="time" v-model="wh.open_time" @change="saveHour(wh)"
              class="bg-gray-700 border border-gray-600 text-white rounded-lg px-2 py-1.5 text-sm focus:border-amber-500 outline-none" />
            <span class="text-gray-500 text-sm">–</span>
            <input type="time" v-model="wh.close_time" @change="saveHour(wh)"
              class="bg-gray-700 border border-gray-600 text-white rounded-lg px-2 py-1.5 text-sm focus:border-amber-500 outline-none" />
          </template>
          <span v-else class="text-gray-500 text-sm italic">Tutup</span>
        </div>
      </div>
    </div>

    <!-- Blocked Dates -->
    <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-white font-semibold">Tanggal Libur / Tutup</h2>
      </div>

      <!-- Add blocked date -->
      <div class="flex gap-3 mb-4">
        <input v-model="newBlock.date" type="date" :min="today"
          class="flex-1 bg-gray-800 border border-gray-700 text-white rounded-xl px-3 py-2 text-sm focus:border-amber-500 outline-none" />
        <input v-model="newBlock.reason" type="text" placeholder="Alasan (opsional)"
          class="flex-1 bg-gray-800 border border-gray-700 text-white rounded-xl px-3 py-2 text-sm focus:border-amber-500 outline-none" />
        <button @click="addBlockedDate"
          class="px-4 py-2 bg-amber-500 hover:bg-amber-600 text-white text-sm font-medium rounded-xl transition-colors">
          Tambah
        </button>
      </div>

      <div v-if="loadingBlocked" class="space-y-2">
        <div v-for="i in 3" :key="i" class="h-12 bg-gray-800 rounded-xl animate-pulse"></div>
      </div>
      <div v-else-if="blockedDates.length === 0" class="text-center py-6 text-gray-500 text-sm">
        Tidak ada tanggal libur
      </div>
      <div v-else class="space-y-2">
        <div v-for="bd in blockedDates" :key="bd.id"
          class="flex items-center justify-between p-3 bg-gray-800/50 rounded-xl">
          <div>
            <p class="text-white text-sm font-medium">{{ formatDate(bd.blocked_date) }}</p>
            <p v-if="bd.reason" class="text-gray-400 text-xs">{{ bd.reason }}</p>
          </div>
          <button @click="removeBlockedDate(bd.id)"
            class="px-3 py-1.5 bg-red-500/20 text-red-400 text-xs font-medium rounded-lg hover:bg-red-500/30 transition-colors">
            Hapus
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']
const today = new Date().toISOString().split('T')[0]

const workingHours = ref([])
const blockedDates = ref([])
const loadingHours = ref(true)
const loadingBlocked = ref(true)
const newBlock = ref({ date: '', reason: '' })

async function loadWorkingHours() {
  loadingHours.value = true
  const { data } = await supabase.from('working_hours').select('*').order('day_of_week')
  workingHours.value = data || []
  loadingHours.value = false
}

async function saveHour(wh) {
  await supabase.from('working_hours').update({
    is_open: wh.is_open, open_time: wh.open_time, close_time: wh.close_time
  }).eq('id', wh.id)
}

async function loadBlockedDates() {
  loadingBlocked.value = true
  const { data } = await supabase.from('blocked_dates').select('*').order('blocked_date')
  blockedDates.value = data || []
  loadingBlocked.value = false
}

async function addBlockedDate() {
  if (!newBlock.value.date) return
  const { data } = await supabase.from('blocked_dates')
    .insert({ blocked_date: newBlock.value.date, reason: newBlock.value.reason })
    .select().single()
  if (data) {
    blockedDates.value.push(data)
    newBlock.value = { date: '', reason: '' }
  }
}

async function removeBlockedDate(id) {
  await supabase.from('blocked_dates').delete().eq('id', id)
  blockedDates.value = blockedDates.value.filter(b => b.id !== id)
}

function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { weekday:'long', day:'numeric', month:'long', year:'numeric' })
}

onMounted(() => {
  loadWorkingHours()
  loadBlockedDates()
})
</script>
