<!-- src/views/admin/AdminReviews.vue -->
<template>
  <div>
    <h1 class="text-2xl font-bold text-white mb-2">Manajemen Ulasan</h1>
    <p class="text-gray-400 text-sm mb-6">{{ reviewsStore.reviews.length }} ulasan total</p>

    <!-- Rating Summary -->
    <div class="bg-gray-900 rounded-2xl border border-gray-800 p-5 mb-6 flex items-center gap-8">
      <div class="text-center">
        <p class="text-5xl font-bold text-amber-400">{{ avgRating }}</p>
        <div class="flex justify-center gap-0.5 mt-1">
          <span v-for="i in 5" :key="i" class="text-lg" :class="i <= Math.round(avgRating) ? 'text-amber-400' : 'text-gray-600'">★</span>
        </div>
        <p class="text-gray-400 text-xs mt-1">Rating rata-rata</p>
      </div>
      <div class="flex-1 space-y-1.5">
        <div v-for="star in [5,4,3,2,1]" :key="star" class="flex items-center gap-2">
          <span class="text-gray-400 text-xs w-3">{{ star }}</span>
          <span class="text-amber-400 text-xs">★</span>
          <div class="flex-1 h-2 bg-gray-800 rounded-full overflow-hidden">
            <div class="h-full bg-amber-400 rounded-full transition-all"
              :style="{ width: getStarPercent(star) + '%' }"></div>
          </div>
          <span class="text-gray-400 text-xs w-6">{{ getStarCount(star) }}</span>
        </div>
      </div>
    </div>

    <div v-if="reviewsStore.loading" class="space-y-3">
      <div v-for="i in 4" :key="i" class="h-28 bg-gray-900 rounded-2xl border border-gray-800 animate-pulse"></div>
    </div>

    <div v-else class="space-y-3">
      <div v-for="r in reviewsStore.reviews" :key="r.id"
        class="bg-gray-900 rounded-2xl border border-gray-800 p-5">
        <div class="flex items-start justify-between mb-2">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold">
              {{ r.profiles?.full_name?.[0]?.toUpperCase() || '?' }}
            </div>
            <div>
              <p class="text-white font-medium text-sm">{{ r.profiles?.full_name || 'Anonim' }}</p>
              <p class="text-gray-400 text-xs">{{ r.services?.name }} · {{ r.staff?.name || '-' }}</p>
            </div>
          </div>
          <div class="flex gap-0.5">
            <span v-for="i in 5" :key="i" class="text-sm" :class="i <= r.rating ? 'text-amber-400' : 'text-gray-600'">★</span>
          </div>
        </div>
        <p v-if="r.comment" class="text-gray-300 text-sm mb-3">{{ r.comment }}</p>
        <p class="text-gray-500 text-xs mb-3">{{ formatDate(r.created_at) }}</p>
        <div class="flex gap-2">
          <button @click="toggleVisibility(r)"
            class="px-3 py-1.5 text-xs font-medium rounded-lg transition-colors"
            :class="r.is_public ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'">
            {{ r.is_public ? '👁️ Publik' : '🙈 Tersembunyi' }}
          </button>
          <button @click="deleteReview(r.id)"
            class="px-3 py-1.5 bg-red-500/20 text-red-400 text-xs font-medium rounded-lg hover:bg-red-500/30 transition-colors">
            🗑️ Hapus
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useReviewsStore } from '@/stores/reviews'

const reviewsStore = useReviewsStore()

const avgRating = computed(() => {
  if (!reviewsStore.reviews.length) return '0.0'
  return (reviewsStore.reviews.reduce((s,r) => s + r.rating, 0) / reviewsStore.reviews.length).toFixed(1)
})

function getStarCount(star) {
  return reviewsStore.reviews.filter(r => r.rating === star).length
}
function getStarPercent(star) {
  if (!reviewsStore.reviews.length) return 0
  return (getStarCount(star) / reviewsStore.reviews.length * 100).toFixed(0)
}

async function toggleVisibility(r) {
  await reviewsStore.toggleReviewVisibility(r.id, !r.is_public)
}

async function deleteReview(id) {
  if (!confirm('Hapus ulasan ini?')) return
  await reviewsStore.deleteReview(id)
}

function formatDate(ts) {
  return new Date(ts).toLocaleDateString('id-ID', { day:'numeric', month:'short', year:'numeric' })
}

onMounted(() => reviewsStore.fetchAllReviews())
</script>
