<!-- src/components/admin/AdminStatusBadge.vue -->
<template>
  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold" :class="colorClass">
    {{ label }}
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({ status: { type: String, required: true } })

const statusMap = {
  pending:     { label: '⏳ Menunggu',    color: 'bg-yellow-500/20 text-yellow-400' },
  confirmed:   { label: '✅ Dikonfirmasi', color: 'bg-blue-500/20 text-blue-400' },
  in_progress: { label: '💈 Berlangsung', color: 'bg-purple-500/20 text-purple-400' },
  completed:   { label: '🎉 Selesai',      color: 'bg-green-500/20 text-green-400' },
  cancelled:   { label: '❌ Dibatalkan',   color: 'bg-red-500/20 text-red-400' },
  no_show:     { label: '👻 Tidak Hadir',  color: 'bg-gray-500/20 text-gray-400' },
}

const info = computed(() => statusMap[props.status] || { label: props.status, color: 'bg-gray-500/20 text-gray-400' })
const label = computed(() => info.value.label)
const colorClass = computed(() => info.value.color)
</script>
