<!-- Thongchai595-6 -->
<template>
    <transition name="modal-fade">
        <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40">
            <form
                @submit.prevent="handleSubmit"
                class="w-full max-w-lg max-h-[90vh] overflow-y-auto p-6 bg-white rounded-lg shadow-xl"
            >
                <!-- Header -->
                <div class="mb-4">
                    <h3 class="text-xl font-semibold text-gray-900">ขอลบข้อมูลส่วนบุคคล</h3>
                    <p class="mt-1 text-sm text-gray-600">
                        กรุณาระบุเหตุผลและยืนยันตัวตนเพื่อดำเนินการลบข้อมูลตาม พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล
                    </p>
                </div>

                <!-- เหตุผล -->
                <div class="mb-6">
                    <label class="block mb-2 text-sm font-medium text-gray-700">
                        เหตุผลในการขอลบข้อมูล <span class="text-red-500">*</span>
                    </label>
                    <select v-model="selectedReason"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                        :class="{ 'border-red-500': showError && !selectedReason }"
                    >
                        <option value="" disabled>-- เลือกเหตุผล --</option>
                        <option v-for="reason in reasons" :key="reason.value" :value="reason.label">
                            {{ reason.label }}
                        </option>
                    </select>
                    <p v-if="showError && !selectedReason" class="mt-1 text-xs text-red-500">
                        กรุณาเลือกเหตุผล
                    </p>
                </div>

                <!-- รายละเอียดเพิ่มเติม -->
                <div class="mb-6">
                    <label class="block mb-2 text-sm font-medium text-gray-700">
                        รายละเอียดเพิ่มเติม (ถ้าต้องการ)
                    </label>
                    <textarea v-model="additionalDetails" rows="2" placeholder="ระบุรายละเอียดเพิ่มเติม..."
                        class="w-full px-3 py-2 border border-gray-300 rounded-md resize-none focus:ring-blue-500 focus:border-blue-500"></textarea>
                </div>

                <!-- คำเตือน -->
                <div class="p-4 mb-6 border-l-4 border-red-500 rounded-r-lg bg-red-50">
                    <div class="flex items-start">
                        <svg class="w-5 h-5 mt-0.5 mr-3 text-red-500 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd"
                                d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                                clip-rule="evenodd" />
                        </svg>
                        <div>
                            <h4 class="font-semibold text-red-800">คำเตือนสำคัญ</h4>
                            <ul class="mt-2 space-y-1 text-sm text-red-700">
                                <li>• การลบข้อมูลนี้เป็นการลบถาวรและไม่สามารถกู้คืนได้</li>
                                <li>• บัญชีของคุณจะถูกปิดการใช้งานทันที</li>
                                <li>• ข้อมูลที่เป็นข้อมูลส่วนบุคคลจะถูกลบ/ทำให้ระบุตัวตนไม่ได้ภายใน 7–30 วัน</li>
                            </ul>
                        </div>
                    </div>
                </div>

                <!-- Password Confirmation -->
                <div class="mb-6">
                    <label class="block mb-2 text-sm font-medium text-gray-700">
                        รหัสผ่านเพื่อยืนยันตัวตน <span class="text-red-500">*</span>
                    </label>
                    <input type="password" v-model="password" placeholder="กรอกรหัสผ่านของคุณ"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-red-500 focus:border-red-500"
                        :class="{ 'border-red-500': showError && !password }" />
                    <p v-if="showError && !password" class="mt-1 text-xs text-red-500">
                        กรุณากรอกรหัสผ่านเพื่อยืนยัน
                    </p>
                </div>

                <!-- Checkbox -->
                <div class="mb-6">
                    <label class="flex items-start cursor-pointer">
                        <input type="checkbox" v-model="confirmed"
                            class="w-4 h-4 mt-1 mr-3 text-red-600 border-gray-300 rounded focus:ring-red-500">
                        <span class="text-sm text-gray-700">ข้าพเจ้ายินยอมรับ
                            <NuxtLink to="/terms-of-service" target="_blank" rel="noopener noreferrer"
                            class="text-blue-600 hover:underline">ข้อตกลงและเงื่อนไขฯ</NuxtLink> และได้อ่าน <NuxtLink
                            to="/privacy" target="_blank" rel="noopener noreferrer" class="text-blue-600 hover:underline">
                            นโยบายความเป็นส่วนตัว</NuxtLink> แล้ว
                        </span>
                    </label>
                </div>

                <!-- Buttons -->
                <div class="flex flex-col gap-3 sm:flex-row sm:space-x-4">
                    <button 
                        type="button"
                        @click="handleCancel"
                        class="flex-1 px-4 py-3 font-semibold text-gray-800 transition duration-200 bg-gray-200 rounded-md hover:bg-gray-300">
                        ยกเลิก
                    </button>
                    <button 
                        type="submit"
                        @click="handleSubmit" :disabled="!canSubmit || isSubmitting"
                        class="flex-1 px-4 py-3 font-semibold text-white transition duration-200 rounded-md"
                        :class="canSubmit && !isSubmitting ? 'bg-red-600 hover:bg-red-700 cursor-pointer' : 'bg-gray-400 cursor-not-allowed'">
                        {{ isSubmitting ? 'กำลังส่งคำขอ...' : 'ยืนยันการลบข้อมูล' }}
                    </button>
                </div>
            </form>
        </div>
    </transition>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
    show: {
        type: Boolean,
        required: true
    }
})

const emit = defineEmits(['close', 'confirm'])

const reasons = [
    { value: 'NO_LONGER_NEEDED', label: 'ไม่ต้องการใช้บริการอีกต่อไป' },
    { value: 'PRIVACY_CONCERNS', label: 'กังวลเรื่องความเป็นส่วนตัว' },
    { value: 'INCORRECT_DATA', label: 'ข้อมูลไม่ถูกต้อง/ไม่เป็นปัจจุบัน' },
    { value: 'SERVICE_DISSATISFACTION', label: 'ไม่พึงพอใจกับบริการ' },
    { value: 'SECURITY_BREACH', label: 'ข้อมูลรั่วไหลหรือมีปัญหาด้านความปลอดภัย' },
    { value: 'OTHER', label: 'อื่นๆ' }
]

const selectedReason = ref('')
const additionalDetails = ref('')
const password = ref('')
const confirmed = ref(false)
const showError = ref(false)
const isSubmitting = ref(false)

const canSubmit = computed(() => {
    return selectedReason.value && confirmed.value && password.value.length > 0
})

const handleCancel = () => {
    if (!isSubmitting.value) {
        resetForm()
        emit('close')
    }
}

const handleSubmit = () => {
    showError.value = true

    if (!selectedReason.value || !confirmed.value || !password.value) {
        return
    }

    isSubmitting.value = true

    // รวมเหตุผลกับรายละเอียด
    const fullReason = selectedReason.value && additionalDetails.value
        ? `${selectedReason.value} - ${additionalDetails.value}`
        : selectedReason.value || additionalDetails.value || null

    const requestData = {
        password: password.value,
        reason: fullReason
    }

    emit('confirm', requestData)

    setTimeout(() => {
        isSubmitting.value = false
    }, 1000)
}

const resetForm = () => {
    selectedReason.value = ''
    additionalDetails.value = ''
    password.value = ''
    confirmed.value = false
    showError.value = false
    isSubmitting.value = false
}
</script>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
    transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
    opacity: 0;
}
</style>
