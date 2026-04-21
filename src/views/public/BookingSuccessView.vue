<!-- src/views/public/BookingSuccessView.vue -->
<template>
  <div class="flex flex-col items-center justify-center min-h-[70vh] px-6 text-center">
    <div class="w-24 h-24 bg-amber-100 rounded-full flex items-center justify-center text-5xl mb-6 animate-bounce">🎉</div>
    <h1 class="text-2xl font-bold text-gray-900 mb-2">Booking Berhasil!</h1>
    <p class="text-gray-500 mb-4">Booking Anda telah diterima dan menunggu konfirmasi.</p>
    <div class="bg-amber-50 border-2 border-amber-200 rounded-2xl px-8 py-4 mb-8">
      <p class="text-xs text-amber-600 font-medium mb-1">Kode Booking</p>
      <p class="text-2xl font-bold text-amber-700 tracking-widest">{{ route.query.code }}</p>
    </div>
    <div class="space-y-3 w-full">
      <router-link to="/history" class="block w-full py-3.5 bg-amber-500 text-white rounded-2xl font-semibold hover:bg-amber-600 transition-colors">
        Lihat Riwayat Booking
      </router-link>
      <router-link to="/" class="block w-full py-3.5 border-2 border-gray-200 text-gray-700 rounded-2xl font-semibold hover:bg-gray-50 transition-colors">
        Kembali ke Beranda
      </router-link>
    </div>
  </div>
</template>
<script setup>
import { useRoute } from 'vue-router'
const route = useRoute()
</script>
