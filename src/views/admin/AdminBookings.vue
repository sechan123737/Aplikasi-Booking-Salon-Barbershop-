<!-- src/views/admin/AdminBookings.vue -->
<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-white">Manajemen Booking</h1>
        <p class="text-gray-400 text-sm mt-0.5">{{ bookingStore.bookings.length }} total booking</p>
      </div>
    </div>

    <!-- Filters -->
    <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4 mb-6 flex flex-wrap gap-3">
      <select v-model="filters.status"
        class="bg-gray-800 border border-gray-700 text-gray-300 text-sm rounded-xl px-3 py-2 focus:border-amber-500 outline-none">
        <option value="">Semua Status</option>
        <option value="pending">Menunggu</option>
        <option value="confirmed">Dikonfirmasi</option>
        <option value="in_progress">Berlangsung</option>
        <option value="completed">Selesai</option>
        <option value="cancelled">Dibatalkan</option>
        <option value="no_show">Tidak Hadir</option>
      </select>
      <input v-model="filters.date" type="date"
        class="bg-gray-800 border border-gray-700 text-gray-300 text-sm rounded-xl px-3 py-2 focus:border-amber-500 outline-none" />
      <input v-model="searchQuery" type="text" placeholder="Cari nama / kode..."
        class="bg-gray-800 border border-gray-700 text-gray-300 text-sm rounded-xl px-3 py-2 focus:border-amber-500 outline-none flex-1 min-w-40" />
      <button @click="applyFilters"
        class="px-4 py-2 bg-amber-500 hover:bg-amber-600 text-white text-sm font-medium rounded-xl transition-colors">
        Cari
      </button>
      <button @click="resetFilters"
        class="px-4 py-2 bg-gray-800 hover:bg-gray-700 text-gray-300 text-sm font-medium rounded-xl transition-colors">
        Reset
      </button>
    </div>

    <!-- Loading -->
    <div v-if="bookingStore.loading" class="p-8 text-center text-gray-500 bg-gray-900 rounded-2xl border border-gray-800">
      <div class="w-8 h-8 border-2 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto mb-2"></div>
      Memuat data...
    </div>

    <div v-else-if="filteredBookings.length === 0" class="p-12 text-center text-gray-500 bg-gray-900 rounded-2xl border border-gray-800">
      <p class="text-4xl mb-2">📋</p>
      Tidak ada booking ditemukan
    </div>

    <div v-else>
      <!-- Mobile: Card List -->
      <div class="lg:hidden space-y-3">
        <div v-for="b in filteredBookings" :key="b.id"
          class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
          <!-- Header -->
          <div class="flex items-start justify-between mb-3">
            <span class="text-amber-400 font-mono text-sm font-bold">{{ b.booking_code }}</span>
            <AdminStatusBadge :status="b.status" />
          </div>
          <!-- Info -->
          <div class="space-y-1.5 mb-3">
            <div class="flex gap-2 text-sm">
              <span class="text-gray-500 w-20 flex-shrink-0">Pelanggan</span>
              <span class="text-white font-medium">{{ b.customer_name }}</span>
            </div>
            <div class="flex gap-2 text-sm">
              <span class="text-gray-500 w-20 flex-shrink-0">HP</span>
              <span class="text-gray-300">{{ b.customer_phone }}</span>
            </div>
            <div class="flex gap-2 text-sm">
              <span class="text-gray-500 w-20 flex-shrink-0">Layanan</span>
              <span class="text-gray-300">{{ b.booking_services?.length > 1 ? b.booking_services.map(bs => bs.services?.name).join(', ') : b.services?.name }}</span>
            </div>
            <div class="flex gap-2 text-sm">
              <span class="text-gray-500 w-20 flex-shrink-0">Stylist</span>
              <span class="text-gray-300">{{ b.staff?.name || 'Siapa saja' }}</span>
            </div>
            <div class="flex gap-2 text-sm">
              <span class="text-gray-500 w-20 flex-shrink-0">Jadwal</span>
              <span class="text-gray-300">{{ formatDate(b.booking_date) }} · {{ b.booking_time?.slice(0,5) }}</span>
            </div>
          </div>
          <!-- Actions -->
          <div class="flex flex-wrap gap-2 pt-3 border-t border-gray-800">
            <router-link :to="`/admin/bookings/${b.id}`"
              class="px-3 py-1.5 bg-blue-500/20 text-blue-400 text-xs font-medium rounded-lg hover:bg-blue-500/30 transition-colors">
              Detail
            </router-link>
            <select v-if="!['completed','cancelled'].includes(b.status)"
              @change="quickStatus(b.id, $event.target.value)"
              class="bg-gray-800 border border-gray-700 text-gray-300 text-xs rounded-lg px-2 py-1.5 focus:border-amber-500 outline-none">
              <option value="">Ubah Status</option>
              <option value="confirmed">Konfirmasi</option>
              <option value="in_progress">Mulai</option>
              <option value="completed">Selesai</option>
              <option value="cancelled">Batalkan</option>
              <option value="no_show">Tidak Hadir</option>
            </select>
            <button @click="deleteBooking(b.id)"
              class="px-3 py-1.5 bg-red-500/20 text-red-400 text-xs font-medium rounded-lg hover:bg-red-500/30 transition-colors">
              🗑️ Hapus
            </button>
          </div>
        </div>
      </div>

      <!-- Desktop: Table -->
      <div class="hidden lg:block bg-gray-900 rounded-2xl border border-gray-800 overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="border-b border-gray-800">
              <tr class="text-left">
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Kode</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Pelanggan</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Layanan</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Jadwal</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Status</th>
                <th class="px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wide">Aksi</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-800">
              <tr v-for="b in filteredBookings" :key="b.id"
                class="hover:bg-gray-800/50 transition-colors">
                <td class="px-5 py-4">
                  <span class="text-amber-400 font-mono text-sm font-semibold">{{ b.booking_code }}</span>
                </td>
                <td class="px-5 py-4">
                  <p class="text-white text-sm font-medium">{{ b.customer_name }}</p>
                  <p class="text-gray-400 text-xs">{{ b.customer_phone }}</p>
                </td>
                <td class="px-5 py-4">
                  <p class="text-gray-300 text-sm">{{ b.booking_services?.length > 1 ? b.booking_services.map(bs => bs.services?.name).join(', ') : b.services?.name }}</p>
                  <p class="text-gray-500 text-xs">{{ b.staff?.name || 'Siapa saja' }}</p>
                </td>
                <td class="px-5 py-4">
                  <p class="text-gray-300 text-sm">{{ formatDate(b.booking_date) }}</p>
                  <p class="text-gray-500 text-xs">{{ b.booking_time?.slice(0,5) }}</p>
                </td>
                <td class="px-5 py-4">
                  <AdminStatusBadge :status="b.status" />
                </td>
                <td class="px-5 py-4">
                  <div class="flex items-center gap-2">
                    <router-link :to="`/admin/bookings/${b.id}`"
                      class="px-3 py-1.5 bg-blue-500/20 text-blue-400 text-xs font-medium rounded-lg hover:bg-blue-500/30 transition-colors">
                      Detail
                    </router-link>
                    <select v-if="!['completed','cancelled'].includes(b.status)"
                      @change="quickStatus(b.id, $event.target.value)"
                      class="bg-gray-800 border border-gray-700 text-gray-300 text-xs rounded-lg px-2 py-1.5 focus:border-amber-500 outline-none">
                      <option value="">Ubah Status</option>
                      <option value="confirmed">Konfirmasi</option>
                      <option value="in_progress">Mulai</option>
                      <option value="completed">Selesai</option>
                      <option value="cancelled">Batalkan</option>
                      <option value="no_show">Tidak Hadir</option>
                    </select>
                    <button @click="deleteBooking(b.id)"
                      class="px-3 py-1.5 bg-red-500/20 text-red-400 text-xs font-medium rounded-lg hover:bg-red-500/30 transition-colors">
                      Hapus
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useBookingStore } from '@/stores/booking'
import { useNotificationsStore } from '@/stores/notifications'
import AdminStatusBadge from '@/components/admin/AdminStatusBadge.vue'

const bookingStore = useBookingStore()
const notifStore = useNotificationsStore()

const filters = ref({ status: '', date: '' })
const searchQuery = ref('')

const filteredBookings = computed(() => {
  let list = bookingStore.bookings
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(b =>
      b.customer_name?.toLowerCase().includes(q) ||
      b.booking_code?.toLowerCase().includes(q) ||
      b.customer_phone?.includes(q)
    )
  }
  return list
})

async function applyFilters() {
  await bookingStore.fetchAllBookings({
    status: filters.value.status || undefined,
    date: filters.value.date || undefined,
  })
}

async function resetFilters() {
  filters.value = { status: '', date: '' }
  searchQuery.value = ''
  await bookingStore.fetchAllBookings()
}

async function quickStatus(id, status) {
  if (!status) return
  const booking = bookingStore.bookings.find(b => b.id === id)
  await bookingStore.updateBookingStatus(id, status)
  // Send notification if user exists
  if (booking?.user_id) {
    await notifStore.sendBookingNotification(booking.user_id, id, `booking_${status}`, booking.booking_code)
  }
}

async function deleteBooking(id) {
  if (!confirm('Hapus booking ini? Tindakan ini tidak dapat dibatalkan.')) return
  await bookingStore.deleteBooking(id)
}

function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { day:'numeric', month:'short', year:'numeric' })
}

onMounted(() => bookingStore.fetchAllBookings())
</script>