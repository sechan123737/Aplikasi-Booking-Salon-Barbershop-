<!-- src/views/public/ReviewView.vue -->
<template>
  <div class="px-4 py-6">
    <h1 class="text-xl font-bold text-gray-900 mb-2">Beri Ulasan</h1>
    <p class="text-sm text-gray-500 mb-6">Bagaimana pengalaman Anda?</p>

    <!-- Star Rating -->
    <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 mb-4">
      <p class="text-center text-sm font-medium text-gray-600 mb-4">Pilih rating</p>
      <div class="flex justify-center gap-3 mb-2">
        <button v-for="i in 5" :key="i" @click="form.rating = i"
          class="text-4xl transition-transform hover:scale-110"
          :class="i <= form.rating ? 'text-amber-400' : 'text-gray-200'">
          ★
        </button>
      </div>
      <p class="text-center text-sm font-medium text-amber-600">{{ ratingLabel }}</p>
    </div>

    <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 mb-6">
      <label class="text-sm font-medium text-gray-700 block mb-2">Komentar (opsional)</label>
      <textarea v-model="form.comment" rows="4"
        placeholder="Ceritakan pengalaman Anda..."
        class="w-full border-2 border-gray-200 rounded-xl p-3 resize-none focus:border-amber-500 outline-none text-sm">
      </textarea>
    </div>

    <div v-if="error" class="bg-red-50 border border-red-200 rounded-xl p-3 mb-4 text-sm text-red-600">{{ error }}</div>

    <button @click="submitReview" :disabled="!form.rating || submitting"
      class="w-full py-3.5 rounded-2xl font-semibold text-white transition-colors"
      :class="form.rating ? 'bg-amber-500 hover:bg-amber-600' : 'bg-gray-200 text-gray-400 cursor-not-allowed'">
      {{ submitting ? 'Mengirim...' : '✅ Kirim Ulasan' }}
    </button>
  </div>
</template>
<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useReviewsStore } from '@/stores/reviews'
import { useBookingStore } from '@/stores/booking'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const reviewsStore = useReviewsStore()
const bookingStore = useBookingStore()

const form = ref({ rating: 0, comment: '' })
const submitting = ref(false)
const error = ref('')

const ratingLabel = computed(() => {
  const labels = ['','Buruk','Kurang','Cukup','Bagus','Sangat Bagus']
  return labels[form.value.rating] || 'Pilih rating'
})

const booking = computed(() => bookingStore.bookings.find(b => b.id === route.params.bookingId))

async function submitReview() {
  submitting.value = true
  error.value = ''
  try {
    await reviewsStore.createReview({
      booking_id: route.params.bookingId,
      user_id: authStore.user.id,
      service_id: booking.value?.service_id,
      staff_id: booking.value?.staff_id,
      rating: form.value.rating,
      comment: form.value.comment
    })
    router.push({ name: 'booking-history' })
  } catch (e) {
    error.value = e.message
  } finally {
    submitting.value = false
  }
}
</script>
