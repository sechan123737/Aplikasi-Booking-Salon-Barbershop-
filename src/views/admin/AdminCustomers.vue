<!-- src/views/admin/AdminCustomers.vue -->
<template>
  <div>
    <h1 class="text-2xl font-bold text-white mb-6">Data Pelanggan</h1>

    <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4 mb-6">
      <input v-model="search" type="text" placeholder="Cari nama atau nomor HP..."
        class="w-full bg-gray-800 border border-gray-700 text-gray-300 rounded-xl px-4 py-2.5 text-sm focus:border-amber-500 outline-none" />
    </div>

    <div v-if="loading" class="space-y-3">
      <div v-for="i in 5" :key="i" class="h-20 bg-gray-900 rounded-2xl border border-gray-800 animate-pulse"></div>
    </div>

    <template v-else>
      <!-- Mobile: card layout -->
      <div class="block sm:hidden space-y-3">
        <div v-if="filteredCustomers.length === 0"
          class="py-12 text-center text-gray-500 text-sm bg-gray-900 rounded-2xl border border-gray-800">
          Tidak ada pelanggan ditemukan
        </div>
        <div v-for="c in filteredCustomers" :key="c.phone"
          class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
          <div class="flex items-start justify-between mb-3">
            <div class="flex-1 min-w-0 pr-2">
              <p class="text-white font-semibold text-sm">{{ c.name }}</p>
              <p class="text-gray-400 text-xs mt-0.5">{{ c.phone }}</p>
              <p v-if="c.email" class="text-gray-500 text-xs truncate">{{ c.email }}</p>
            </div>
            <span class="shrink-0 text-xs bg-amber-500/20 text-amber-400 font-semibold px-2 py-1 rounded-lg">
              {{ c.totalBookings }} booking
            </span>
          </div>
          <div class="flex items-center justify-between pt-3 border-t border-gray-800">
            <div>
              <p class="text-[10px] text-gray-500 mb-0.5">Total Bayar</p>
              <p class="text-amber-400 font-bold text-sm">Rp {{ formatPrice(c.totalSpent) }}</p>
            </div>
            <div class="text-right">
              <p class="text-[10px] text-gray-500 mb-0.5">Terakhir Booking</p>
              <p class="text-gray-300 text-xs">{{ formatDate(c.lastBooking) }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Desktop: table layout -->
      <div class="hidden sm:block bg-gray-900 rounded-2xl border border-gray-800 overflow-hidden">
        <table class="w-full">
          <thead class="border-b border-gray-800">
            <tr>
              <th class="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Pelanggan</th>
              <th class="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Total Booking</th>
              <th class="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Total Bayar</th>
              <th class="px-5 py-3.5 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide">Terakhir Booking</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-800">
            <tr v-for="c in filteredCustomers" :key="c.phone" class="hover:bg-gray-800/50 transition-colors">
              <td class="px-5 py-4">
                <p class="text-white font-medium text-sm">{{ c.name }}</p>
                <p class="text-gray-400 text-xs">{{ c.phone }}</p>
                <p v-if="c.email" class="text-gray-500 text-xs">{{ c.email }}</p>
              </td>
              <td class="px-5 py-4">
                <span class="text-white font-medium">{{ c.totalBookings }}</span>
                <span class="text-gray-400 text-xs ml-1">booking</span>
              </td>
              <td class="px-5 py-4">
                <span class="text-amber-400 font-semibold text-sm">Rp {{ formatPrice(c.totalSpent) }}</span>
              </td>
              <td class="px-5 py-4">
                <span class="text-gray-400 text-sm">{{ formatDate(c.lastBooking) }}</span>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-if="filteredCustomers.length === 0" class="py-12 text-center text-gray-500 text-sm">
          Tidak ada pelanggan ditemukan
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const customers = ref([])
const loading = ref(true)
const search = ref('')

const filteredCustomers = computed(() => {
  if (!search.value) return customers.value
  const q = search.value.toLowerCase()
  return customers.value.filter(c =>
    c.name?.toLowerCase().includes(q) || c.phone?.includes(q)
  )
})

async function loadCustomers() {
  loading.value = true
  const { data } = await supabase
    .from('bookings')
    .select('customer_name, customer_phone, customer_email, final_price, service_price, booking_date, payment_status')
    .order('booking_date', { ascending: false })

  // Aggregate by customer_phone
  const map = {}
  for (const b of data || []) {
    const key = b.customer_phone
    if (!map[key]) {
      map[key] = { name: b.customer_name, phone: b.customer_phone, email: b.customer_email, totalBookings: 0, totalSpent: 0, lastBooking: b.booking_date }
    }
    map[key].totalBookings++
    if (b.payment_status === 'paid') map[key].totalSpent += Number(b.final_price ?? b.service_price ?? 0)
    if (b.booking_date > map[key].lastBooking) map[key].lastBooking = b.booking_date
  }
  customers.value = Object.values(map).sort((a,b) => b.totalBookings - a.totalBookings)
  loading.value = false
}

function formatPrice(p) { return Number(p).toLocaleString('id-ID') }
function formatDate(d) {
  if (!d) return '-'
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { day:'numeric', month:'short', year:'numeric' })
}

onMounted(loadCustomers)
</script>