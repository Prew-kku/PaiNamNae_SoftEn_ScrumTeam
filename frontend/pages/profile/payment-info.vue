<template>
    <div>
        <div class="flex items-center justify-center min-h-screen py-8">
            <div class="flex w-full max-w-6xl mx-4 overflow-hidden bg-white border border-gray-300 rounded-lg shadow-lg">

                <ProfileSidebar />

                <main class="flex-1 p-8">
                    <!-- Header -->
                    <div class="mb-8 text-center">
                        <div class="inline-flex items-center justify-center w-16 h-16 mb-4 bg-blue-600 rounded-full">
                            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                            </svg>
                        </div>
                        <h1 class="mb-2 text-3xl font-bold text-gray-800">ข้อมูลการรับเงิน</h1>
                        <p class="max-w-md mx-auto text-gray-600">จัดการช่องทางรับเงินจากผู้โดยสาร</p>
                    </div>

                    <div class="space-y-8">

                        <!-- PromptPay Section -->
                        <div class="pb-8 border-b border-gray-200">
                            <h2 class="mb-1 text-lg font-semibold text-gray-800">PromptPay</h2>
                            <p class="mb-4 text-sm text-gray-500">ระบบจะสร้าง QR Code จากหมายเลขนี้ให้ผู้โดยสารสแกนจ่าย</p>
                            <div class="flex gap-3">
                                <input
                                    v-model="promptPayId"
                                    type="text"
                                    placeholder="เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน"
                                    maxlength="13"
                                    class="flex-1 px-4 py-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                                <button
                                    @click="savePromptPay"
                                    :disabled="isSavingPromptPay"
                                    class="px-5 py-3 font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap"
                                >
                                    {{ isSavingPromptPay ? 'กำลังบันทึก...' : 'บันทึก' }}
                                </button>
                            </div>
                            <p class="mt-1.5 text-xs text-gray-400">รองรับเบอร์โทรศัพท์ (10 หลัก) หรือเลขบัตรประชาชน (13 หลัก)</p>
                        </div>

                        <!-- Bank Accounts Section -->
                        <div>
                            <div class="flex items-center justify-between mb-4">
                                <div>
                                    <h2 class="text-lg font-semibold text-gray-800">บัญชีธนาคาร</h2>
                                    <p class="text-sm text-gray-500">สามารถเพิ่มได้หลายบัญชี</p>
                                </div>
                                <button
                                    v-if="bankAccounts.length > 0"
                                    @click="openModal()"
                                    class="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                    </svg>
                                    เพิ่มบัญชี
                                </button>
                            </div>

                            <!-- Empty State -->
                            <div v-if="bankAccounts.length === 0"
                                class="flex flex-col items-center justify-center py-14 border-2 border-gray-200 border-dashed rounded-xl">
                                <div class="flex items-center justify-center w-16 h-16 mb-4 bg-gray-100 rounded-full">
                                    <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                                            d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                                    </svg>
                                </div>
                                <p class="mb-1 font-medium text-gray-700">ยังไม่มีบัญชีธนาคาร</p>
                                <p class="mb-5 text-sm text-gray-400">เพิ่มบัญชีเพื่อให้ผู้โดยสารโอนเงินได้</p>
                                <button
                                    @click="openModal()"
                                    class="flex items-center gap-2 px-5 py-2.5 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                    </svg>
                                    เพิ่มบัญชีธนาคาร
                                </button>
                            </div>

                            <!-- รายการบัญชี -->
                            <div v-else class="space-y-3">
                                <div
                                    v-for="account in bankAccounts"
                                    :key="account.id"
                                    class="flex items-center justify-between p-4 border border-gray-200 rounded-xl hover:bg-gray-50 transition-colors"
                                >
                                    <div class="flex items-center gap-4">
                                        <div class="flex items-center justify-center w-12 h-12 rounded-xl shrink-0 overflow-hidden border border-gray-100"
                                            :class="getBankLogo(account.bankCode) ? 'bg-white' : getBankColor(account.bankCode)">
                                            <img v-if="getBankLogo(account.bankCode)"
                                                :src="getBankLogo(account.bankCode)"
                                                :alt="account.bankCode"
                                                class="w-full h-full object-cover" />
                                            <span v-else class="text-xs font-bold text-white">{{ account.bankCode.slice(0,2) }}</span>
                                        </div>
                                        <div>
                                            <p class="font-semibold text-gray-800">{{ getBankName(account.bankCode, account.customBankName) }}</p>
                                            <p class="text-sm text-gray-500">{{ account.accountNumber }}</p>
                                            <p class="text-xs text-gray-400">{{ account.accountName }}</p>
                                        </div>
                                    </div>
                                    <div class="flex items-center gap-2">
                                        <button
                                            @click="openModal(account)"
                                            class="p-2 text-gray-500 rounded-lg hover:text-blue-600 transition-colors"
                                            title="แก้ไข"
                                        >
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                            </svg>
                                        </button>
                                        <button
                                            @click="deleteAccount(account)"
                                            class="p-2 text-gray-500 rounded-lg hover:text-red-600 transition-colors"
                                            title="ลบ"
                                        >
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>
                </main>
            </div>
        </div>

        <!-- Modal ยืนยันการลบ -->
        <!-- Modal ยืนยันการลบ -->
        <ConfirmModal
            :show="showDeleteModal"
            title="ลบบัญชีธนาคาร"
            message="คุณต้องการลบบัญชีนี้ใช่หรือไม่?"
            confirm-text="ลบบัญชี"
            variant="danger"
            @confirm="confirmDelete"
            @cancel="showDeleteModal = false"
        >
            <div class="flex items-center gap-3 p-3 bg-gray-50 border border-gray-200 rounded-lg">
                <div class="flex items-center justify-center w-10 h-10 rounded-lg shrink-0 overflow-hidden border border-gray-100"
                    :class="getBankLogo(accountToDelete?.bankCode) ? 'bg-white' : getBankColor(accountToDelete?.bankCode)">
                    <img v-if="getBankLogo(accountToDelete?.bankCode)"
                        :src="getBankLogo(accountToDelete?.bankCode)"
                        class="w-full h-full object-cover" />
                    <span v-else class="text-xs font-bold text-white">{{ accountToDelete?.bankCode?.slice(0,2) }}</span>
                </div>
                <div>
                    <p class="text-sm font-semibold text-gray-800">
                        {{ getBankName(accountToDelete?.bankCode, accountToDelete?.customBankName) }}
                    </p>
                    <p class="text-sm text-gray-500">{{ accountToDelete?.accountNumber }}</p>
                    <p class="text-xs text-gray-400">{{ accountToDelete?.accountName }}</p>
                </div>
            </div>
        </ConfirmModal>

        <!-- Modal เพิ่ม/แก้ไขบัญชีธนาคาร -->
        <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
                <div class="w-full max-w-md mx-4 bg-white rounded-2xl shadow-xl overflow-hidden">

                    <!-- Modal Header -->
                    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
                        <h3 class="text-lg font-semibold text-gray-800">
                            {{ editingId ? 'แก้ไขบัญชีธนาคาร' : 'เพิ่มบัญชีธนาคาร' }}
                        </h3>
                        <button @click="closeModal" class="p-1 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </div>

                    <!-- Modal Body -->
                    <div class="px-6 py-5 space-y-4">
                        <div>
                            <label class="block mb-1.5 text-sm font-medium text-gray-700">ธนาคาร</label>
                            <!-- Custom Bank Dropdown -->
                            <div class="relative" ref="bankDropdownRef">
                                <button
                                    type="button"
                                    @click="showBankDropdown = !showBankDropdown"
                                    class="w-full flex items-center justify-between px-4 py-3 border border-gray-300 rounded-lg bg-white hover:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors"
                                    :class="showBankDropdown ? 'border-blue-500 ring-2 ring-blue-500' : ''"
                                >
                                    <div class="flex items-center gap-3">
                                        <div v-if="form.bankCode"
                                            class="flex items-center justify-center w-7 h-7 rounded-xl shrink-0 overflow-hidden border border-gray-100"
                                            :class="getBankLogo(form.bankCode) ? 'bg-white' : getBankColor(form.bankCode)">
                                            <img v-if="getBankLogo(form.bankCode)"
                                                :src="getBankLogo(form.bankCode)"
                                                class="w-full h-full object-cover" />
                                            <span v-else class="text-xs font-bold text-white">{{ form.bankCode.slice(0,2) }}</span>
                                        </div>
                                        <span :class="form.bankCode ? 'text-gray-800' : 'text-gray-400'">
                                            {{ form.bankCode ? getBankName(form.bankCode, form.customBankName) : 'เลือกธนาคาร' }}
                                        </span>
                                    </div>
                                    <svg class="w-4 h-4 text-gray-400 transition-transform"
                                        :class="showBankDropdown ? 'rotate-180' : ''"
                                        fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                                    </svg>
                                </button>

                                <!-- Dropdown List -->
                                <div v-if="showBankDropdown"
                                    class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-xl shadow-lg overflow-hidden">
                                    <ul class="py-1 max-h-60 overflow-y-auto">
                                        <li v-for="bank in BANKS" :key="bank.code">
                                            <button
                                                type="button"
                                                @click="selectBank(bank.code)"
                                                class="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-gray-50 transition-colors"
                                                :class="form.bankCode === bank.code ? 'bg-blue-50' : ''"
                                            >
                                                <div class="flex items-center justify-center w-8 h-8 rounded-xl shrink-0 overflow-hidden border border-gray-100"
                                                    :class="bank.logo ? 'bg-white' : bank.color">
                                                    <img v-if="bank.logo" :src="bank.logo" class="w-full h-full object-cover" />
                                                    <span v-else class="text-xs font-bold text-white">{{ bank.code.slice(0,2) }}</span>
                                                </div>
                                                <span class="text-sm text-gray-800">{{ bank.name }}</span>
                                                <svg v-if="form.bankCode === bank.code"
                                                    class="w-4 h-4 text-blue-600 ml-auto"
                                                    fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                                </svg>
                                            </button>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                        <div v-if="form.bankCode === 'OTHER'">
                            <label class="block mb-1.5 text-sm font-medium text-gray-700">ชื่อธนาคาร</label>
                            <input
                                v-model="form.customBankName"
                                type="text"
                                placeholder="กรอกชื่อธนาคาร"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>
                        <div>
                            <label class="block mb-1.5 text-sm font-medium text-gray-700">เลขที่บัญชี</label>
                            <input
                                v-model="form.accountNumber"
                                type="text"
                                placeholder="เช่น 123-4-56789-0"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>
                        <div>
                            <label class="block mb-1.5 text-sm font-medium text-gray-700">ชื่อบัญชี</label>
                            <input
                                v-model="form.accountName"
                                type="text"
                                placeholder="ชื่อ-นามสกุล ตามบัญชีธนาคาร"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>
                    </div>

                    <!-- Modal Footer -->
                    <div class="flex border-t border-gray-200">
                        <button
                            @click="closeModal"
                            class="flex-1 px-4 py-3 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
                        >
                            ยกเลิก
                        </button>
                        <div class="w-px bg-gray-200"></div>
                        <button
                            @click="saveAccount"
                            :disabled="isSavingAccount"
                            class="flex-1 px-4 py-3 text-sm font-medium text-blue-600 hover:bg-blue-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {{ isSavingAccount ? 'กำลังบันทึก...' : (editingId ? 'บันทึกการแก้ไข' : 'เพิ่มบัญชี') }}
                        </button>
                    </div>

                </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useToast } from '~/composables/useToast'
import ProfileSidebar from '~/components/ProfileSidebar.vue'
import ConfirmModal from '~/components/ConfirmModal.vue'

definePageMeta({
    middleware: 'auth'
})

const { $api } = useNuxtApp()
const { toast } = useToast()

const BANKS = [
    { code: 'KBANK', name: 'ธนาคารกสิกรไทย',                  color: 'bg-green-600',  logo: '/banks/kbank.png' },
    { code: 'SCB',   name: 'ธนาคารไทยพาณิชย์',                color: 'bg-purple-600', logo: '/banks/scb.png' },
    { code: 'BBL',   name: 'ธนาคารกรุงเทพ',                    color: 'bg-blue-800',   logo: '/banks/bangkok.png' },
    { code: 'KTB',   name: 'ธนาคารกรุงไทย',                    color: 'bg-blue-500',   logo: '/banks/krungthai.png' },
    { code: 'BAY',   name: 'ธนาคารกรุงศรีอยุธยา',              color: 'bg-yellow-500', logo: '/banks/krungsri.png' },
    { code: 'TTB',   name: 'ธนาคารทหารไทยธนชาต',              color: 'bg-cyan-500',   logo: '/banks/ttb.png' },
    { code: 'BAAC',  name: 'ธนาคารเพื่อการเกษตรและสหกรณ์',   color: 'bg-green-800',  logo: '/banks/baac.png' },
    { code: 'GSB',   name: 'ธนาคารออมสิน',                       color: 'bg-purple-800', logo: '/banks/gsb.png' },
    { code: 'OTHER', name: 'ธนาคารอื่น ๆ',                     color: 'bg-gray-400',   logo: null },
]

const getBankName  = (code, customName) => code === 'OTHER' ? (customName || 'ธนาคารอื่น ๆ') : (BANKS.find(b => b.code === code)?.name ?? code)
const getBankColor = (code) => BANKS.find(b => b.code === code)?.color ?? 'bg-gray-400'
const getBankLogo  = (code) => BANKS.find(b => b.code === code)?.logo ?? null

// PromptPay
const promptPayId = ref('')
const isSavingPromptPay = ref(false)

// Bank accounts
const bankAccounts = ref([])
const showModal = ref(false)
const editingId = ref(null)
const isSavingAccount = ref(false)
const showDeleteModal = ref(false)
const accountToDelete = ref(null)

const form = ref({ bankCode: '', customBankName: '', accountNumber: '', accountName: '' })
const showBankDropdown = ref(false)
const bankDropdownRef = ref(null)

const selectBank = (code) => {
    form.value.bankCode = code
    showBankDropdown.value = false
}

const handleClickOutside = (e) => {
    if (bankDropdownRef.value && !bankDropdownRef.value.contains(e.target)) {
        showBankDropdown.value = false
    }
}

const fetchPaymentInfo = async () => {
    // TODO: replace with real API call
    // try {
    //     const data = await $api('/users/me/payment-info')
    //     promptPayId.value = data.promptPayId ?? ''
    //     bankAccounts.value = data.bankAccounts ?? []
    // } catch {
    //     toast.error('เกิดข้อผิดพลาด', 'ไม่สามารถดึงข้อมูลการรับเงินได้')
    // }

    // TEST DATA
    promptPayId.value = '0812345678'
    bankAccounts.value = [
        { id: '1', bankCode: 'KBANK', accountNumber: '012-3-45678-9', accountName: 'สมชาย ใจดี' },
        { id: '2', bankCode: 'SCB', accountNumber: '123-456789-0', accountName: 'สมชาย ใจดี' },
    ]
}

const savePromptPay = async () => {
    isSavingPromptPay.value = true
    try {
        await $api('/users/me/payment-info/promptpay', {
            method: 'PUT',
            body: { promptPayId: promptPayId.value }
        })
        toast.success('บันทึกสำเร็จ', 'อัปเดตหมายเลข PromptPay แล้ว')
    } catch (error) {
        toast.error('เกิดข้อผิดพลาด', error?.data?.message || 'ไม่สามารถบันทึกได้')
    } finally {
        isSavingPromptPay.value = false
    }
}

const openModal = (account = null) => {
    if (account) {
        editingId.value = account.id
        form.value = { bankCode: account.bankCode, customBankName: account.customBankName || '', accountNumber: account.accountNumber, accountName: account.accountName }
    } else {
        editingId.value = null
        form.value = { bankCode: '', customBankName: '', accountNumber: '', accountName: '' }
    }
    showModal.value = true
}

const closeModal = () => {
    showModal.value = false
    editingId.value = null
    showBankDropdown.value = false
}

const saveAccount = async () => {
    if (!form.value.bankCode || !form.value.accountNumber || !form.value.accountName) {
        toast.error('ข้อมูลไม่ครบ', 'กรุณากรอกข้อมูลบัญชีให้ครบทุกช่อง')
        return
    }
    if (form.value.bankCode === 'OTHER' && !form.value.customBankName.trim()) {
        toast.error('ข้อมูลไม่ครบ', 'กรุณากรอกชื่อธนาคาร')
        return
    }
    isSavingAccount.value = true
    try {
        if (editingId.value) {
            const updated = await $api(`/users/me/bank-accounts/${editingId.value}`, {
                method: 'PUT',
                body: form.value
            })
            const idx = bankAccounts.value.findIndex(a => a.id === editingId.value)
            if (idx !== -1) bankAccounts.value[idx] = updated
            toast.success('บันทึกสำเร็จ', 'แก้ไขบัญชีธนาคารแล้ว')
        } else {
            const created = await $api('/users/me/bank-accounts', {
                method: 'POST',
                body: form.value
            })
            bankAccounts.value.push(created)
            toast.success('เพิ่มสำเร็จ', 'เพิ่มบัญชีธนาคารแล้ว')
        }
        closeModal()
    } catch (error) {
        toast.error('เกิดข้อผิดพลาด', error?.data?.message || 'ไม่สามารถบันทึกได้')
    } finally {
        isSavingAccount.value = false
    }
}

const deleteAccount = (account) => {
    accountToDelete.value = account
    showDeleteModal.value = true
}

const confirmDelete = async () => {
    const id = accountToDelete.value?.id
    showDeleteModal.value = false
    try {
        await $api(`/users/me/bank-accounts/${id}`, { method: 'DELETE' })
        bankAccounts.value = bankAccounts.value.filter(a => a.id !== id)
        toast.success('ลบสำเร็จ', 'ลบบัญชีธนาคารแล้ว')
    } catch (error) {
        toast.error('เกิดข้อผิดพลาด', error?.data?.message || 'ไม่สามารถลบได้')
    } finally {
        accountToDelete.value = null
    }
}

onMounted(() => {
    fetchPaymentInfo()
    document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
    document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.modal-overlay {
    position: fixed;
    z-index: 50;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
}
</style>
