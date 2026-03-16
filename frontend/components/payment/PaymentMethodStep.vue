<template>
  <div class="space-y-4">
    <!-- Amount summary -->
    <div class="text-center py-3 bg-blue-50 rounded-xl border border-blue-100">
      <p class="text-sm text-gray-500">ชำระให้ <span class="font-semibold text-gray-800">{{ driverName }}</span></p>
      <p class="text-3xl font-extrabold text-blue-600 mt-1">
        {{ amount.toLocaleString('th-TH') }}
        <span class="text-lg font-semibold text-blue-400">บาท</span>
      </p>
      <p class="text-xs text-gray-400 mt-0.5">{{ tripInfo }}</p>
    </div>

    <div class="space-y-3">
      <p class="text-sm font-semibold text-gray-700">เลือกวิธีชำระเงิน</p>
      <div class="flex gap-2">
        <button
          @click="$emit('update:method', 'transfer')"
          class="flex-1 flex flex-col items-center justify-center gap-2 py-4 rounded-xl border-2 transition-all"
          :class="method === 'transfer'
            ? 'border-blue-500 bg-blue-50 text-blue-700'
            : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'"
        >
          <div class="w-10 h-10 rounded-full flex items-center justify-center transition-colors"
               :class="method === 'transfer' ? 'bg-blue-100' : 'bg-gray-100'">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
            </svg>
          </div>
          <span class="text-sm font-bold">โอนเงิน</span>
        </button>
        <button
          @click="$emit('update:method', 'cash')"
          class="flex-1 flex flex-col items-center justify-center gap-2 py-4 rounded-xl border-2 transition-all"
          :class="method === 'cash'
            ? 'border-green-500 bg-green-50 text-green-700'
            : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'"
        >
          <div class="w-10 h-10 rounded-full flex items-center justify-center transition-colors"
               :class="method === 'cash' ? 'bg-green-100' : 'bg-gray-100'">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/>
            </svg>
          </div>
          <span class="text-sm font-bold">เงินสด</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  driverName: String,
  amount: Number,
  tripInfo: String,
  method: String
})
defineEmits(['update:method'])
</script>
