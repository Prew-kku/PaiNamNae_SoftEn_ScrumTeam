<template>
  <transition name="ps-fade">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm flex flex-col overflow-hidden">
        <!-- ── Header ── -->
        <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div>
            <p class="text-xs font-medium text-gray-400 uppercase tracking-wide">ชำระค่าโดยสาร</p>
            <h3 class="text-base font-bold text-gray-800 leading-tight">
              {{ currentStepLabel }}
            </h3>
          </div>
          <!-- Step dots -->
          <div class="flex items-center gap-3">
            <div class="flex items-center gap-1">
              <div
                v-for="s in totalStepDots"
                :key="s"
                class="rounded-full transition-all duration-300"
                :class="s < activeDot
                  ? 'w-2 h-2 bg-green-500'
                  : s === activeDot
                    ? 'w-3 h-3 bg-blue-600 ring-2 ring-blue-200'
                    : 'w-2 h-2 bg-gray-200'"
              />
            </div>
            <button
              @click="handleClose"
              class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- ── Body ── -->
        <div class="flex-1 overflow-y-auto px-5 py-4 max-h-[65vh]">
          <!-- STEP 1: Select Method -->
          <div v-if="flowStep === 1">
            <PaymentMethodStep
              :driverName="booking?.driver?.name"
              :amount="totalAmount"
              :tripInfo="tripInfoText"
              v-model:method="paymentMethod"
            />
            
            <!-- จ่ายแทนผู้ร่วมเดินทาง (จากโค้ดเดิม) -->
            <div v-if="fellowPassengers.length > 0" class="mt-4">
              <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">จ่ายแทนผู้ร่วมเดินทาง</p>
              <div class="space-y-1.5">
                <label
                  v-for="f in fellowPassengers"
                  :key="f.bookingId"
                  class="flex items-center gap-3 p-2.5 rounded-xl border cursor-pointer transition-all"
                  :class="selectedFriendIds.has(f.bookingId)
                    ? 'border-blue-400 bg-blue-50'
                    : 'border-gray-200 bg-gray-50 hover:border-blue-200 hover:bg-blue-50/50'"
                >
                  <input
                    type="checkbox"
                    class="w-4 h-4 accent-blue-600 rounded shrink-0"
                    :checked="selectedFriendIds.has(f.bookingId)"
                    @change="toggleFriend(f.bookingId)"
                  />
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-gray-800 leading-tight">{{ f.name }}</p>
                    <p class="text-xs text-gray-500">{{ f.seats }} ที่นั่ง</p>
                  </div>
                  <span class="text-sm font-bold text-blue-700 shrink-0">+{{ f.price.toLocaleString('th-TH') }}</span>
                </label>
              </div>
            </div>
          </div>

          <!-- STEP 2: Select Transfer Type (PromptPay / Specific Bank) -->
          <TransferTypeStep
            v-else-if="flowStep === 2 && paymentMethod === 'transfer'"
            v-model:type="transferType"
            :promptPayId="promptPayId"
            :bankAccounts="bankAccounts"
          />

          <!-- STEP 3: Payment Details (QR / Bank Info) -->
          <div v-else-if="flowStep === 3">
            <!-- Amount summary -->
            <div class="text-center mb-4 py-3 bg-blue-50 rounded-xl border border-blue-100">
              <p class="text-sm text-gray-500">ชำระให้ <span class="font-semibold text-gray-800">{{ booking?.driver?.name }}</span></p>
              <p class="text-3xl font-extrabold text-blue-600 mt-1">
                {{ totalAmount.toLocaleString('th-TH') }}
                <span class="text-lg font-semibold text-blue-400">บาท</span>
              </p>
              <p class="text-xs text-gray-400 mt-0.5">{{ tripInfoText }}</p>
            </div>

            <!-- PromptPay QR -->
            <div v-if="transferType === 'promptpay' && paymentMethod === 'transfer'">
              <div v-if="promptPayId">
                <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">พร้อมเพย์</p>
                <div class="flex flex-col items-center p-4 bg-gray-50 border border-gray-200 rounded-xl mb-4">
                  <div class="relative w-48 h-48 rounded-xl overflow-hidden bg-white border border-gray-100 shadow-sm">
                    <img
                      v-if="!qrError"
                      :src="promptPayQrUrl"
                      alt="QR Code พร้อมเพย์"
                      class="w-full h-full object-contain p-1"
                      @error="qrError = true"
                    />
                    <div v-else class="flex flex-col items-center justify-center w-full h-full text-center p-4">
                      <svg class="w-10 h-10 text-gray-300 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                      </svg>
                      <p class="text-xs text-gray-400">ไม่สามารถสร้าง QR ได้<br>กรุณาใช้เลขพร้อมเพย์ด้านล่าง</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-2 mt-3 px-3 py-2 bg-white border border-gray-100 rounded-xl shadow-sm w-full max-w-xs">
                    <svg class="w-4 h-4 text-blue-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                    </svg>
                    <span class="flex-1 text-sm text-gray-700 font-mono tracking-wide text-center">{{ promptPayId }}</span>
                    <button @click="copyPromptPayId" class="p-1 text-gray-400 hover:text-blue-600 transition-colors">
                      <svg v-if="!copied" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                      </svg>
                      <svg v-else class="w-4 h-4 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
              <div v-else class="flex items-center gap-3 p-3 bg-amber-50 border border-amber-200 rounded-xl mb-4">
                <svg class="w-5 h-5 text-amber-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                </svg>
                <p class="text-sm text-amber-700">คนขับไม่ได้ตั้งค่าพร้อมเพย์ กรุณาโอนผ่านบัญชีธนาคาร</p>
              </div>
            </div>

            <!-- Specific Bank Account -->
            <div v-else-if="transferType.startsWith('bank_') || paymentMethod === 'cash'">
               <div v-if="paymentMethod === 'cash'" class="space-y-3">
                  <div class="flex items-start gap-3 p-4 bg-green-50 border border-green-200 rounded-2xl">
                    <svg class="w-8 h-8 text-green-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/>
                    </svg>
                    <div>
                      <p class="text-sm font-bold text-green-800">ชำระด้วยเงินสดกับคนขับโดยตรง</p>
                      <p class="text-xs text-green-700 mt-1">เตรียมเงิน <span class="font-extrabold">{{ totalAmount.toLocaleString('th-TH') }} บาท</span></p>
                    </div>
                  </div>
               </div>
               <div v-else-if="selectedAccount">
                 <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">บัญชีธนาคาร</p>
                 <div class="p-4 bg-gray-50 border border-gray-100 rounded-2xl">
                    <div class="flex items-center gap-4 mb-4">
                      <div class="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 overflow-hidden" 
                           :style="bankInfo(selectedAccount.bankCode).bg ? { background: bankInfo(selectedAccount.bankCode).bg } : {}">
                        <img v-if="bankInfo(selectedAccount.bankCode).logo" :src="bankInfo(selectedAccount.bankCode).logo" class="w-full h-full object-cover" />
                        <span v-else class="text-xs font-bold">{{ selectedAccount.bankCode }}</span>
                      </div>
                      <div>
                        <p class="text-base font-bold text-gray-800">{{ bankInfo(selectedAccount.bankCode).nameTh }}</p>
                      </div>
                    </div>
                    <div class="space-y-3">
                      <div class="flex items-center justify-between p-3 bg-white border border-gray-100 rounded-xl">
                        <div>
                          <p class="text-[10px] text-gray-400 uppercase font-semibold">เลขที่บัญชี</p>
                          <p class="text-lg font-mono font-bold text-gray-700">{{ selectedAccount.accountNumber }}</p>
                        </div>
                        <button @click="copyText(selectedAccount.accountNumber)" class="p-2 text-gray-400 hover:text-blue-600 transition-colors">
                          <svg v-if="!copiedAcc" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                          </svg>
                          <svg v-else class="w-5 h-5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
                          </svg>
                        </button>
                      </div>
                      <div class="px-1">
                        <p class="text-[10px] text-gray-400 uppercase font-semibold">ชื่อบัญชี</p>
                        <p class="text-sm font-semibold text-gray-700">{{ selectedAccount.accountName }}</p>
                      </div>
                    </div>
                 </div>
               </div>
            </div>
          </div>

          <!-- STEP 4: Upload Slip -->
          <div v-else-if="flowStep === 4">
            <p class="text-sm text-gray-500 mb-4">อัปโหลดสลิปการโอน <span class="font-bold text-gray-800">{{ totalAmount.toLocaleString('th-TH') }} บาท</span></p>
            <div
              class="relative border-2 border-dashed rounded-2xl p-6 text-center cursor-pointer transition-all"
              :class="slipFile ? 'border-green-300 bg-green-50' : 'border-gray-300 hover:border-blue-400 hover:bg-gray-50'"
              @click="triggerFileInput"
            >
              <div v-if="slipPreviewUrl">
                 <img :src="slipPreviewUrl" class="w-full max-h-48 object-contain rounded-lg" />
                 <p class="mt-2 text-xs text-green-700 font-medium">{{ slipFile?.name }}</p>
              </div>
              <div v-else>
                 <svg class="w-10 h-10 text-gray-300 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/>
                 </svg>
                 <p class="text-sm font-semibold text-gray-700">คลิกเพื่อแนบสลิป</p>
              </div>
            </div>
            <input ref="fileInputRef" type="file" accept="image/*" class="hidden" @change="onFileSelected" />
          </div>

          <!-- STEP 5: Final Confirmation -->
          <div v-else-if="flowStep === 5">
            <div class="p-4 bg-blue-50 border border-blue-100 rounded-2xl space-y-2">
               <p class="text-sm font-bold text-gray-800">สรุปรายการ</p>
               <p class="text-xs text-gray-600">ชำระให้: <span class="font-semibold">{{ booking?.driver?.name }}</span></p>
               <p class="text-xs text-gray-600">จำนวน: <span class="font-bold text-blue-700 text-sm">{{ totalAmount.toLocaleString('th-TH') }} บาท</span></p>
               <p class="text-xs text-gray-600">วิธีชำระ: <span class="font-semibold">{{ paymentMethod === 'cash' ? 'เงินสด' : 'เงินโอน' }}</span></p>
            </div>
            <p class="text-[10px] text-amber-700 mt-4 leading-tight">กรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนกดยืนยัน</p>
          </div>
        </div>

        <!-- ── Footer ── -->
        <div class="flex gap-2 px-5 py-4 border-t border-gray-100">
          <button
            v-if="flowStep > 1"
            @click="prevStep"
            class="px-4 py-2.5 text-sm font-medium text-gray-600 bg-gray-100 rounded-xl hover:bg-gray-200"
          >
            ย้อนกลับ
          </button>
          <button
            @click="handleNext"
            :disabled="isSubmitting || (flowStep === 1 && !paymentMethod) || (flowStep === 2 && !transferType)"
            class="flex-1 px-4 py-2.5 text-sm font-semibold text-white bg-blue-600 rounded-xl hover:bg-blue-700 disabled:opacity-50"
          >
            <span v-if="isSubmitting">กำลังดำเนินการ...</span>
            <span v-else-if="isLastStep">ยืนยันการชำระเงิน</span>
            <span v-else>ต่อไป</span>
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useToast } from '~/composables/useToast'
import { useAuth } from '~/composables/useAuth'
import PaymentMethodStep from './payment/PaymentMethodStep.vue'
import TransferTypeStep from './payment/TransferTypeStep.vue'

const props = defineProps({
  show: Boolean,
  booking: Object
})
const emit = defineEmits(['close', 'submitted'])

const { $api }   = useNuxtApp()
const { toast } = useToast()
const { user }  = useAuth()

const flowStep = ref(1)
const paymentMethod = ref('') // 'transfer' | 'cash'
const transferType  = ref('') // 'promptpay' | 'scb'

// Step data
const qrError = ref(false)
const copied  = ref(false)
const copiedAcc = ref(false)
const isSubmitting = ref(false)
const slipFile = ref(null)
const slipPreviewUrl = ref(null)
const fileInputRef = ref(null)

// Friend payment state
const fellowPassengers = ref([])
const selectedFriendIds = ref(new Set())

const BANK_MAP = {
  KBANK:  { nameTh: 'ธนาคารกสิกรไทย',          logo: '/banks/kbank.png', bg: '#e8f5ec' },
  SCB:    { nameTh: 'ธนาคารไทยพาณิชย์',         logo: '/banks/scb.png', bg: '#f3e8f7' },
  BBL:    { nameTh: 'ธนาคารกรุงเทพ',            logo: '/banks/bangkok.png', bg: '#e8edfa' },
  KTB:    { nameTh: 'ธนาคารกรุงไทย',            logo: '/banks/krungthai.png', bg: '#e0f5fd' },
  BAY:    { nameTh: 'ธนาคารกรุงศรีอยุธยา',      logo: '/banks/krungsri.png', bg: '#fffbe6' },
  OTHER:  { nameTh: 'ธนาคารอื่น',               logo: null, bg: '#f3f4f6' }
}
const bankInfo = (code) => BANK_MAP[code] || BANK_MAP['OTHER']

const totalAmount = computed(() => {
  let total = props.booking?.price || 0
  for (const f of fellowPassengers.value) {
    if (selectedFriendIds.value.has(f.bookingId)) total += f.price
  }
  return total
})

const tripInfoText = computed(() => `${props.booking?.seats || 1} ที่นั่ง ${props.booking?.origin || ''} → ${props.booking?.destination || ''}`)

const promptPayId = computed(() => props.booking?.driverPayment?.promptPayId)
const bankAccounts = computed(() => props.booking?.driverPayment?.bankAccounts || [])

const selectedAccount = computed(() => {
  if (!transferType.value.startsWith('bank_')) return null
  const id = parseInt(transferType.value.split('_')[1])
  return bankAccounts.value.find(acc => acc.id === id)
})

const isLastStep = computed(() => flowStep.value === 5)
const totalStepDots = computed(() => paymentMethod.value === 'cash' ? 3 : 5)
const activeDot = computed(() => {
  if (paymentMethod.value === 'cash' && flowStep.value === 3) return 2
  if (paymentMethod.value === 'cash' && flowStep.value === 5) return 3
  return flowStep.value
})

const labels = ['เลือกวิธีชำระเงิน', 'เลือกธนาคาร', 'ข้อมูลการชำระเงิน', 'แนบสลิป', 'ยืนยันรายการ']
const currentStepLabel = computed(() => labels[flowStep.value - 1])

const toggleFriend = (bookingId) => {
  const s = new Set(selectedFriendIds.value)
  if (s.has(bookingId)) s.delete(bookingId)
  else s.add(bookingId)
  selectedFriendIds.value = s
}

function handleNext() {
  if (flowStep.value === 1) {
    if (!paymentMethod.value) return
    paymentMethod.value === 'cash' ? flowStep.value = 3 : flowStep.value = 2
    return
  }
  if (flowStep.value === 2) {
    if (!transferType.value) return
    flowStep.value = 3
    return
  }
  if (flowStep.value === 3) {
    paymentMethod.value === 'cash' ? flowStep.value = 5 : flowStep.value = 4
    return
  }
  if (flowStep.value === 4) {
    if (!slipFile.value) return toast.error('กรุณาแนบสลิป')
    flowStep.value = 5
    return
  }
  if (flowStep.value === 5) {
    executeSubmit()
  }
}

function prevStep() {
   if (flowStep.value === 3 && paymentMethod.value === 'cash') flowStep.value = 1
   else if (flowStep.value === 5 && paymentMethod.value === 'cash') flowStep.value = 3
   else flowStep.value--
}

async function executeSubmit() {
  isSubmitting.value = true
  try {
    const friendIds = [...selectedFriendIds.value]
    if (paymentMethod.value === 'cash') {
      await $api(`/bookings/${props.booking.id}/payment/cash`, { method: 'PATCH' })
      for (const id of friendIds) await $api(`/bookings/${id}/payment/cash`, { method: 'PATCH' })
      toast.success('แจ้งพนักงานแล้ว')
    } else {
      const formData = new FormData()
      formData.append('slip', slipFile.value)
      formData.append('method', transferType.value === 'promptpay' ? 'PROMPTPAY' : 'BANK_TRANSFER')
      await $api(`/bookings/${props.booking.id}/payment/slip`, { method: 'POST', body: formData })
      for (const id of friendIds) {
        const fd = new FormData()
        fd.append('slip', slipFile.value)
        fd.append('method', transferType.value === 'promptpay' ? 'PROMPTPAY' : 'BANK_TRANSFER')
        await $api(`/bookings/${id}/payment/slip`, { method: 'POST', body: fd })
      }
      toast.success('ส่งสลิปเรียบร้อย')
    }
    emit('submitted')
    handleClose()
  } catch (e) {
    toast.error('ล้มเหลว', e?.data?.message || 'เกิดข้อผิดพลาด')
  } finally {
    isSubmitting.value = false
  }
}

function handleClose() {
  emit('close')
}

// Reset and Fetch
watch(() => props.show, async (newVal) => {
  if (newVal) {
    flowStep.value = 1
    paymentMethod.value = ''
    transferType.value = ''
    slipFile.value = null
    slipPreviewUrl.value = null
    qrError.value = false
    copied.value = false
    selectedFriendIds.value = new Set()
    fellowPassengers.value = []

    if (props.booking?.routeId) {
      try {
        const route = await $api(`/routes/${props.booking.routeId}`)
        if (route?.bookings && route.pricePerSeat) {
          fellowPassengers.value = route.bookings
            .filter(b => b.status === 'COMPLETED' && b.passengerId !== user.value?.id)
            .map(b => ({
              bookingId: b.id,
              name: `${b.passenger?.firstName || ''} ${b.passenger?.lastName || ''}`.trim() || 'ผู้โดยสาร',
              seats: b.numberOfSeats || 1,
              price: (b.numberOfSeats || 1) * route.pricePerSeat,
            }))
        }
      } catch (e) {}
    }
  }
})

// PromptPay Utils
function buildPromptPayEMV(target, amount) {
  function crc16(str) {
    let crc = 0xFFFF
    for (let i = 0; i < str.length; i++) {
      crc ^= str.charCodeAt(i) << 8
      for (let j = 0; j < 8; j++) crc = (crc & 0x8000) ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF
    }
    return crc.toString(16).toUpperCase().padStart(4, '0')
  }
  const tlv = (id, value) => `${id}${String(value.length).padStart(2, '0')}${value}`
  const isPhone = /^\d{10}$/.test(target)
  const isNid   = /^\d{13}$/.test(target)
  const accType = isPhone ? '01' : isNid ? '02' : '03'
  const accVal  = isPhone ? '0066' + target.substring(1) : target
  const merchantInfo = tlv('00', 'A000000677010111') + tlv(accType, accVal)
  const amtStr = amount && amount > 0 ? Number(amount).toFixed(2) : null
  const amtTlv = amtStr ? tlv('54', amtStr) : ''
  let payload = tlv('00', '01') + tlv('01', '12') + tlv('29', merchantInfo) + tlv('53', '764') + amtTlv + tlv('58', 'TH') + '6304'
  return payload + crc16(payload)
}

const promptPayQrUrl = computed(() => {
  if (!promptPayId.value) return null
  const payload = buildPromptPayEMV(promptPayId.value, totalAmount.value)
  return `https://api.qrserver.com/v1/create-qr-code/?size=220x220&ecc=M&data=${encodeURIComponent(payload)}`
})

function copyPromptPayId() {
  navigator.clipboard.writeText(promptPayId.value)
  copied.value = true
  setTimeout(() => copied.value = false, 2000)
}

function copyText(text) {
  navigator.clipboard.writeText(text)
  copiedAcc.value = true
  setTimeout(() => copiedAcc.value = false, 2000)
}

function triggerFileInput() { fileInputRef.value?.click() }
function onFileSelected(e) {
  const file = e.target.files?.[0]
  if (file) {
    slipFile.value = file
    const reader = new FileReader()
    reader.onload = (ev) => slipPreviewUrl.value = ev.target.result
    reader.readAsDataURL(file)
  }
}
</script>

<style scoped>
.ps-fade-enter-active, .ps-fade-leave-active { transition: opacity 0.3s ease; }
.ps-fade-enter-from, .ps-fade-leave-to { opacity: 0; }
</style>
