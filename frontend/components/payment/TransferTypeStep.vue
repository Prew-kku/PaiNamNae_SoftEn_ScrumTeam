<template>
  <div class="space-y-4">
    <p class="text-sm font-semibold text-gray-700">เลือกช่องทางการโอนเงิน</p>
    <div class="grid grid-cols-1 gap-3">
      <!-- PromptPay Option -->
      <button
        v-if="promptPayId"
        @click="$emit('update:type', 'promptpay')"
        class="flex items-center gap-4 p-4 rounded-xl border-2 text-left transition-all"
        :class="type === 'promptpay'
          ? 'border-blue-500 bg-blue-50 text-blue-700'
          : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'"
      >
        <div class="w-12 h-12 rounded-lg bg-blue-600 flex items-center justify-center shrink-0">
          <span class="text-white font-bold text-xs uppercase">Prompt<br>Pay</span>
        </div>
        <div class="flex-1">
          <p class="font-bold">พร้อมเพย์ (PromptPay)</p>
          <p class="text-xs opacity-70">สแกน QR Code เพื่อชำระเงิน</p>
        </div>
        <div v-if="type === 'promptpay'" class="w-5 h-5 rounded-full bg-blue-500 flex items-center justify-center">
          <svg class="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/>
          </svg>
        </div>
      </button>

      <!-- Bank Account Options -->
      <button
        v-for="acc in bankAccounts"
        :key="acc.id"
        @click="$emit('update:type', 'bank_' + acc.id)"
        class="flex items-center gap-4 p-4 rounded-xl border-2 text-left transition-all"
        :class="type === 'bank_' + acc.id
          ? 'border-blue-500 bg-blue-50 text-blue-700'
          : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'"
        :style="type === 'bank_' + acc.id ? { borderColor: getBankInfo(acc.bankCode).color, backgroundColor: getBankInfo(acc.bankCode).bg } : {}"
      >
        <div class="w-12 h-12 rounded-lg flex items-center justify-center shrink-0 overflow-hidden"
             :style="{ backgroundColor: getBankInfo(acc.bankCode).color || '#f3f4f6' }">
          <img v-if="getBankInfo(acc.bankCode).logo" :src="getBankInfo(acc.bankCode).logo" :alt="acc.bankCode" class="w-full h-full object-cover" />
          <span v-else class="text-white font-bold text-xs uppercase">{{ acc.bankCode }}</span>
        </div>
        <div class="flex-1">
          <p class="font-bold">{{ getBankInfo(acc.bankCode).nameTh }}</p>
          <p class="text-xs opacity-70">โอนผ่านเลขบัญชีธนาคาร</p>
        </div>
        <div v-if="type === 'bank_' + acc.id" class="w-5 h-5 rounded-full flex items-center justify-center"
             :style="{ backgroundColor: getBankInfo(acc.bankCode).color || '#3b82f6' }">
          <svg class="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/>
          </svg>
        </div>
      </button>

      <!-- Fallback if nothing available -->
      <div v-if="!promptPayId && bankAccounts.length === 0" class="text-center py-8 bg-gray-50 rounded-xl border-2 border-dashed border-gray-200">
        <p class="text-sm text-gray-500">ไม่พบช่องทางการรับเงินของคนขับ</p>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  type: String,
  promptPayId: String,
  bankAccounts: Array
})
defineEmits(['update:type'])

const BANK_MAP = {
  KBANK:  { nameTh: 'ธนาคารกสิกรไทย',          logo: '/banks/kbank.png', color: '#06a94d', bg: '#e8f5ec' },
  SCB:    { nameTh: 'ธนาคารไทยพาณิชย์',         logo: '/banks/scb.png', color: '#4b154b', bg: '#f3e8f7' },
  BBL:    { nameTh: 'ธนาคารกรุงเทพ',            logo: '/banks/bangkok.png', color: '#1e3d73', bg: '#e8edfa' },
  KTB:    { nameTh: 'ธนาคารกรุงไทย',            logo: '/banks/krungthai.png', color: '#00aae4', bg: '#e0f5fd' },
  BAY:    { nameTh: 'ธนาคารกรุงศรีอยุธยา',      logo: '/banks/krungsri.png', color: '#fec43b', bg: '#fffbe6' },
  OTHER:  { nameTh: 'ธนาคารอื่น',               logo: null, color: '#6b7280', bg: '#f3f4f6' }
}

const getBankInfo = (code) => BANK_MAP[code] || BANK_MAP['OTHER']
</script>
