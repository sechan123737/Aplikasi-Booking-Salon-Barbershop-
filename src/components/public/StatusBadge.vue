<!-- src/components/public/StatusBadge.vue -->
<template>
  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold"
    :class="[colorClass, dark ? 'bg-white/20 text-white' : '']">
    {{ label }}
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  status: { type: String, required: true },
  dark: { type: Boolean, default: false }
})

const statusMap = {
  pending:     { label: '⏳ Menunggu',    color: 'bg-yellow-100 text-yellow-700' },
  confirmed:   { label: '✅ Dikonfirmasi', color: 'bg-blue-100 text-blue-700' },
  in_progress: { label: '💈 Berlangsung', color: 'bg-purple-100 text-purple-700' },
  completed:   { label: '🎉 Selesai',      color: 'bg-green-100 text-green-700' },
  cancelled:   { label: '❌ Dibatalkan',   color: 'bg-red-100 text-red-500' },
  no_show:     { label: '👻 Tidak Hadir',  color: 'bg-gray-100 text-gray-500' },
}

const info = computed(() => statusMap[props.status] || { label: props.status, color: 'bg-gray-100 text-gray-500' })
const label = computed(() => info.value.label)
const colorClass = computed(() => props.dark ? '' : info.value.color)
</script>
