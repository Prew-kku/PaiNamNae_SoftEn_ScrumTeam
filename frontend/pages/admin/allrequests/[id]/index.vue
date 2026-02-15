<template>
    <div>
        <AdminHeader />
        <AdminSidebar />

        <main id="main-content" class="main-content ml-0 lg:ml-[280px] p-6">
            <!-- Back -->
            <div class="mb-8">
                <NuxtLink to="/admin/allrequests"
                    class="inline-flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
                    <i class="fa-solid fa-arrow-left"></i>
                    <span>ย้อนกลับ</span>
                </NuxtLink>
            </div>

            <div class="mx-auto max-w-8xl">
                <!-- Title -->
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">รายละเอียดคำร้อง</h1>
                        <span v-if="request"
                            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full"
                            :class="statusBadge(request.status)">
                            {{ statusLabel(request.status) }}
                        </span>
                    </div>
                </div>

                <!-- Loading / Error -->
                <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
                <div v-else-if="loadError" class="p-8 text-center text-red-600">{{ loadError }}</div>

                <!-- Content -->
                <div v-else-if="request" class="space-y-6">
                    <!-- ข้อมูลผู้ใช้ -->
                    <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
                        <div class="px-4 py-4 border-b border-gray-200 sm:px-6">
                            <h2 class="font-medium text-gray-800">ข้อมูลผู้ใช้</h2>
                        </div>
                        <div class="grid grid-cols-1 gap-6 p-4 sm:p-6 sm:grid-cols-2">
                            <div class="flex items-center gap-4 sm:col-span-2">
                                <img :src="request.user.profilePicture || `https://ui-avatars.com/api/?name=${encodeURIComponent(request.user.firstName || 'U')}&background=random&size=80`"
                                    class="object-cover w-16 h-16 rounded-full" alt="avatar" />
                                <div>
                                    <div class="text-lg font-medium text-gray-900">
                                        {{ request.user.firstName }} {{ request.user.lastName }}
                                    </div>
                                    <div class="text-sm text-gray-500">@{{ request.user.username }}</div>
                                </div>
                            </div>
                            <div>
                                <label class="block text-xs font-medium text-gray-500 uppercase">อีเมล</label>
                                <p class="mt-1 text-gray-900">{{ request.user.email }}</p>
                            </div>
                            <div>
                                <label class="block text-xs font-medium text-gray-500 uppercase">บทบาท</label>
                                <span class="inline-flex items-center px-2 py-1 mt-1 text-xs font-medium rounded-full"
                                    :class="roleBadge(request.user.role)">
                                    {{ request.user.role }}
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- รายละเอียดคำร้อง -->
                    <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
                        <div class="px-4 py-4 border-b border-gray-200 sm:px-6">
                            <h2 class="font-medium text-gray-800">รายละเอียดคำร้อง</h2>
                        </div>
                        <div class="grid grid-cols-1 gap-6 p-4 sm:p-6 sm:grid-cols-2">
                            <!-- ประเภท (ทุก type) -->
                            <div>
                                <label class="block text-xs font-medium text-gray-500 uppercase">ประเภทคำร้อง</label>
                                <span class="inline-flex items-center px-2 py-1 mt-1 text-xs font-medium rounded-full"
                                    :class="typeBadge(request.type)">
                                    {{ typeLabel(request.type) }}
                                </span>
                            </div>

                            <!-- สร้างเมื่อ (ทุก type) -->
                            <div>
                                <label class="block text-xs font-medium text-gray-500 uppercase">สร้างเมื่อ</label>
                                <p class="mt-1 text-gray-900">{{ formatDate(request.createdAt) }}</p>
                            </div>

                            <!-- ── Deletion-specific fields ── -->
                            <template v-if="request.type === 'deletion' && request.deletion">
                                <div>
                                    <label class="block text-xs font-medium text-gray-500 uppercase">เหตุผล</label>
                                    <span class="inline-flex items-center px-2 py-1 mt-1 text-xs font-medium rounded-full"
                                        :class="reasonBadge(request.deletion.reason)">
                                        {{ reasonLabel(request.deletion.reason) }}
                                    </span>
                                </div>
                                <div v-if="request.deletion.description" class="sm:col-span-2">
                                    <label class="block text-xs font-medium text-gray-500 uppercase">รายละเอียดเพิ่มเติม</label>
                                    <p class="mt-1 text-gray-900">{{ request.deletion.description }}</p>
                                </div>
                                <div v-if="request.deletion.reviewedAt">
                                    <label class="block text-xs font-medium text-gray-500 uppercase">ตรวจสอบเมื่อ</label>
                                    <p class="mt-1 text-gray-900">{{ formatDate(request.deletion.reviewedAt) }}</p>
                                </div>
                                <div v-if="request.deletion.adminNote" class="sm:col-span-2">
                                    <label class="block text-xs font-medium text-gray-500 uppercase">หมายเหตุแอดมิน</label>
                                    <p class="mt-1 text-gray-900">{{ request.deletion.adminNote }}</p>
                                </div>
                            </template>

                            <!-- ── Ticket-specific fields (incident / behavior) ── -->
                            <template v-if="(request.type === 'incident' || request.type === 'behavior') && request.ticket">
                                <div class="sm:col-span-2">
                                    <label class="block text-xs font-medium text-gray-500 uppercase">หัวข้อ</label>
                                    <p class="mt-1 text-gray-900">{{ request.ticket.title }}</p>
                                </div>
                                <div class="sm:col-span-2">
                                    <label class="block text-xs font-medium text-gray-500 uppercase">รายละเอียด</label>
                                    <p class="mt-1 text-gray-900 whitespace-pre-line">{{ request.ticket.description }}</p>
                                </div>
                            </template>
                        </div>
                    </div>

                    <!-- Ticket Replies (เฉพาะ incident / behavior) -->
                    <div v-if="request.ticket && request.ticket.replies && request.ticket.replies.length"
                        class="bg-white border border-gray-300 rounded-lg shadow-sm">
                        <div class="px-4 py-4 border-b border-gray-200 sm:px-6">
                            <h2 class="font-medium text-gray-800">การตอบกลับ ({{ request.ticket.replies.length }})</h2>
                        </div>
                        <div class="p-4 space-y-4 sm:p-6">
                            <div v-for="reply in request.ticket.replies" :key="reply.id"
                                class="p-3 border border-gray-200 rounded-lg">
                                <div class="flex items-center justify-between mb-2">
                                    <span class="text-sm font-medium text-gray-900">{{ reply.sender?.firstName }} {{ reply.sender?.lastName }}</span>
                                    <span class="text-xs text-gray-500">{{ formatDate(reply.createdAt) }}</span>
                                </div>
                                <p class="text-sm text-gray-700 whitespace-pre-line">{{ reply.message }}</p>
                            </div>
                        </div>
                    </div>

                    <!-- Ticket Attachments (เฉพาะ incident / behavior) -->
                    <div v-if="request.ticket && request.ticket.attachments && request.ticket.attachments.length"
                        class="bg-white border border-gray-300 rounded-lg shadow-sm">
                        <div class="px-4 py-4 border-b border-gray-200 sm:px-6">
                            <h2 class="font-medium text-gray-800">ไฟล์แนบ ({{ request.ticket.attachments.length }})</h2>
                        </div>
                        <div class="grid grid-cols-2 gap-4 p-4 sm:p-6 sm:grid-cols-3 md:grid-cols-4">
                            <div v-for="att in request.ticket.attachments" :key="att.id">
                                <a v-if="att.type === 'image'" :href="att.url" target="_blank">
                                    <img :src="att.url" class="object-cover w-full rounded-lg h-36" alt="attachment" />
                                </a>
                                <a v-else :href="att.url" target="_blank"
                                    class="flex items-center justify-center w-full gap-2 p-4 text-sm text-blue-600 border border-gray-200 rounded-lg h-36 hover:bg-gray-50">
                                    <i class="fa-solid fa-play"></i>
                                    ดูวิดีโอ
                                </a>
                            </div>
                        </div>
                    </div>

                    <!-- Actions -->
                    <!-- Deletion: approve / reject (เฉพาะ pending) -->
                    <div v-if="request.type === 'deletion' && request.status === 'pending'"
                        class="flex items-center gap-3 p-4 bg-white border border-gray-300 rounded-lg shadow-sm sm:p-6">
                        <button @click="openModal('approve')"
                            class="inline-flex items-center gap-2 px-4 py-2 text-white rounded-md cursor-pointer bg-emerald-600 hover:bg-emerald-700">
                            <i class="fa-solid fa-check"></i>
                            อนุมัติคำร้อง
                        </button>
                        <button @click="openModal('reject')"
                            class="inline-flex items-center gap-2 px-4 py-2 text-white bg-red-600 rounded-md cursor-pointer hover:bg-red-700">
                            <i class="fa-solid fa-xmark"></i>
                            ปฏิเสธคำร้อง
                        </button>
                    </div>

                    <!-- Ticket: resolve / close (เฉพาะ open / in_progress) -->
                    <div v-if="(request.type === 'incident' || request.type === 'behavior') && (request.status === 'open' || request.status === 'in_progress')"
                        class="flex items-center gap-3 p-4 bg-white border border-gray-300 rounded-lg shadow-sm sm:p-6">
                        <button @click="openModal('resolve')"
                            class="inline-flex items-center gap-2 px-4 py-2 text-white rounded-md cursor-pointer bg-emerald-600 hover:bg-emerald-700">
                            <i class="fa-solid fa-check"></i>
                            แก้ไขแล้ว
                        </button>
                        <button @click="openModal('close')"
                            class="inline-flex items-center gap-2 px-4 py-2 text-white bg-gray-600 rounded-md cursor-pointer hover:bg-gray-700">
                            <i class="fa-solid fa-xmark"></i>
                            ปิดคำร้อง
                        </button>
                    </div>
                </div>
            </div>
        </main>

        <!-- Confirm Modal -->
        <div v-if="modal.show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @click.self="closeModal">
            <div class="w-full max-w-md p-6 mx-4 bg-white rounded-lg shadow-xl">
                <h3 class="mb-1 text-lg font-semibold text-gray-800">{{ modalTitle }}</h3>
                <p class="mb-4 text-sm text-gray-500">
                    คำร้องของ {{ request.user.firstName }} {{ request.user.lastName }}
                </p>

                <!-- Admin Note (เฉพาะ deletion) -->
                <div v-if="request.type === 'deletion'" class="mb-4">
                    <label class="block mb-1 text-sm font-medium text-gray-700">หมายเหตุแอดมิน</label>
                    <textarea v-model="modal.adminNote" rows="3"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="ระบุหมายเหตุ (ไม่บังคับ)"></textarea>
                </div>

                <div class="flex justify-end gap-3">
                    <button @click="closeModal"
                        class="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md cursor-pointer hover:bg-gray-50">
                        ยกเลิก
                    </button>
                    <button @click="confirmModal"
                        class="px-4 py-2 text-sm text-white rounded-md cursor-pointer"
                        :class="modalConfirmClass">
                        {{ modalConfirmText }}
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'

const route = useRoute()
const requestId = route.params.id

useHead({
    title: 'Request Detail • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const isLoading = ref(false)
const loadError = ref('')

// ─── Mock Data (จะเปลี่ยนเป็น API เมื่อ backend พร้อม) ───
const mockData = {
    'req_1': {
        id: 'req_1',
        type: 'deletion',
        status: 'pending',
        createdAt: '2026-02-15T02:30:00Z',
        updatedAt: '2026-02-15T02:30:00Z',
        user: {
            id: 'u1',
            firstName: 'Somchai',
            lastName: 'Jaidee',
            email: 'somchai@example.com',
            username: 'somchai_j',
            role: 'PASSENGER'
        },
        deletion: {
            reason: 'privacy_concern',
            description: 'I am concerned about my personal data.'
        }
    },
    'req_2': {
        id: 'req_2',
        type: 'deletion',
        status: 'approved',
        createdAt: '2026-02-14T10:00:00Z',
        updatedAt: '2026-02-14T11:00:00Z',
        user: {
            id: 'u2',
            firstName: 'Anong',
            lastName: 'Dee',
            email: 'anong@example.com',
            username: 'anong_d',
            role: 'PASSENGER'
        },
        deletion: {
            reason: 'not_use_anymore',
            description: 'I no longer use this service.',
            adminNote: 'Account deleted successfully.',
            reviewedAt: '2026-02-14T11:00:00Z'
        }
    },
    'req_3': {
        id: 'req_3',
        type: 'deletion',
        status: 'rejected',
        createdAt: '2026-02-13T09:00:00Z',
        updatedAt: '2026-02-13T12:00:00Z',
        user: {
            id: 'u3',
            firstName: 'Preecha',
            lastName: 'Sukjai',
            email: 'preecha@example.com',
            username: 'preecha_s',
            role: 'DRIVER'
        },
        deletion: {
            reason: 'other',
            description: 'Please remove my account.',
            adminNote: 'User has ongoing legal investigation.',
            reviewedAt: '2026-02-13T12:00:00Z'
        }
    },
    'req_4': {
        id: 'req_4',
        type: 'incident',
        status: 'open',
        createdAt: '2026-02-14T15:00:00Z',
        updatedAt: '2026-02-14T15:00:00Z',
        user: {
            id: 'u4',
            firstName: 'Suda',
            lastName: 'Meesuk',
            email: 'suda@example.com',
            username: 'suda_m',
            role: 'PASSENGER'
        },
        ticket: {
            type: 'incident',
            title: 'คนขับไม่มารับตามเวลา',
            description: 'จองรถเวลา 08:00 แต่คนขับมาถึง 09:30',
            replies: [
                {
                    id: 'reply_1',
                    sender: { firstName: 'Admin', lastName: '' },
                    message: 'ขอบคุณที่แจ้งครับ กำลังตรวจสอบ',
                    createdAt: '2026-02-14T16:00:00Z'
                }
            ],
            attachments: []
        }
    },
    'req_5': {
        id: 'req_5',
        type: 'behavior',
        status: 'in_progress',
        createdAt: '2026-02-12T11:00:00Z',
        updatedAt: '2026-02-13T08:00:00Z',
        user: {
            id: 'u5',
            firstName: 'Wichai',
            lastName: 'Tongdee',
            email: 'wichai@example.com',
            username: 'wichai_t',
            role: 'PASSENGER'
        },
        ticket: {
            type: 'behavior',
            title: 'คนขับพูดจาไม่สุภาพ',
            description: 'คนขับใช้คำพูดไม่เหมาะสมระหว่างเดินทาง',
            replies: [],
            attachments: []
        }
    }
}

const request = ref(mockData[requestId] || null)

if (!request.value) {
    loadError.value = 'ไม่พบคำร้องนี้'
}

// ─── Helpers ───
function roleBadge(role) {
    if (role === 'DRIVER') return 'bg-blue-100 text-blue-700'
    return 'bg-gray-100 text-gray-700'
}

// RequestType: deletion | incident | behavior
function typeBadge(type) {
    const map = {
        'deletion': 'bg-red-100 text-red-700',
        'incident': 'bg-orange-100 text-orange-700',
        'behavior': 'bg-yellow-100 text-yellow-700'
    }
    return map[type] || 'bg-gray-100 text-gray-700'
}

function typeLabel(type) {
    const map = {
        'deletion': 'ขอลบบัญชี',
        'incident': 'แจ้งเหตุการณ์',
        'behavior': 'รายงานพฤติกรรม'
    }
    return map[type] || type
}

// DeletionReason: privacy_concern | not_use_anymore | found_better_service | too_expensive | other
function reasonBadge(reason) {
    const map = {
        'privacy_concern': 'bg-yellow-100 text-yellow-700',
        'not_use_anymore': 'bg-gray-100 text-gray-700',
        'found_better_service': 'bg-blue-100 text-blue-700',
        'too_expensive': 'bg-orange-100 text-orange-700',
        'other': 'bg-gray-100 text-gray-600'
    }
    return map[reason] || map['other']
}

function reasonLabel(reason) {
    const map = {
        'privacy_concern': 'ความเป็นส่วนตัว',
        'not_use_anymore': 'ไม่ใช้บริการแล้ว',
        'found_better_service': 'พบบริการที่ดีกว่า',
        'too_expensive': 'ราคาแพงเกินไป',
        'other': 'อื่น ๆ'
    }
    return map[reason] || map['other']
}

// RequestStatus: pending | approved | rejected | open | in_progress | resolved | closed
function statusBadge(status) {
    const map = {
        'pending': 'bg-yellow-100 text-yellow-700',
        'approved': 'bg-green-100 text-green-700',
        'rejected': 'bg-red-100 text-red-700',
        'open': 'bg-blue-100 text-blue-700',
        'in_progress': 'bg-indigo-100 text-indigo-700',
        'resolved': 'bg-green-100 text-green-700',
        'closed': 'bg-gray-100 text-gray-600'
    }
    return map[status] || 'bg-gray-100 text-gray-700'
}

function statusLabel(status) {
    const map = {
        'pending': 'รอดำเนินการ',
        'approved': 'อนุมัติแล้ว',
        'rejected': 'ปฏิเสธแล้ว',
        'open': 'เปิด',
        'in_progress': 'กำลังดำเนินการ',
        'resolved': 'แก้ไขแล้ว',
        'closed': 'ปิดแล้ว'
    }
    return map[status] || status
}

function formatDate(iso) {
    if (!iso) return '-'
    return new Date(iso).toLocaleDateString('th-TH', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    })
}

// ─── Confirm Modal ───
const modal = reactive({
    show: false,
    action: '',  // 'approve' | 'reject' | 'resolve' | 'close'
    adminNote: ''
})

const modalTitle = computed(() => {
    const map = {
        'approve': 'ยืนยันอนุมัติคำร้อง',
        'reject': 'ยืนยันปฏิเสธคำร้อง',
        'resolve': 'ยืนยันแก้ไขคำร้องแล้ว',
        'close': 'ยืนยันปิดคำร้อง'
    }
    return map[modal.action] || ''
})

const modalConfirmText = computed(() => {
    const map = {
        'approve': 'อนุมัติ',
        'reject': 'ปฏิเสธ',
        'resolve': 'แก้ไขแล้ว',
        'close': 'ปิดคำร้อง'
    }
    return map[modal.action] || 'ยืนยัน'
})

const modalConfirmClass = computed(() => {
    const map = {
        'approve': 'bg-emerald-600 hover:bg-emerald-700',
        'reject': 'bg-red-600 hover:bg-red-700',
        'resolve': 'bg-emerald-600 hover:bg-emerald-700',
        'close': 'bg-gray-600 hover:bg-gray-700'
    }
    return map[modal.action] || 'bg-blue-600 hover:bg-blue-700'
})

function openModal(action) {
    modal.show = true
    modal.action = action
    modal.adminNote = ''
}

function closeModal() {
    modal.show = false
    modal.adminNote = ''
}

function confirmModal() {
    // TODO: เรียก API ตาม action เมื่อ backend พร้อม
    const statusMap = {
        'approve': 'approved',
        'reject': 'rejected',
        'resolve': 'resolved',
        'close': 'closed'
    }
    request.value.status = statusMap[modal.action]

    if (request.value.deletion && (modal.action === 'approve' || modal.action === 'reject')) {
        request.value.deletion.adminNote = modal.adminNote || undefined
        request.value.deletion.reviewedAt = new Date().toISOString()
    }

    closeModal()
}
</script>

<style>
.sidebar {
    transition: width 0.3s ease;
}

.sidebar.collapsed {
    width: 80px;
}

.sidebar:not(.collapsed) {
    width: 280px;
}

.sidebar-item {
    transition: all 0.3s ease;
}

.sidebar-item:hover {
    background-color: rgba(59, 130, 246, 0.05);
}

.sidebar.collapsed .sidebar-text {
    display: none;
}

.sidebar.collapsed .sidebar-item {
    justify-content: center;
}

.main-content {
    transition: margin-left 0.3s ease;
}

@media (max-width: 768px) {
    .sidebar {
        position: fixed;
        z-index: 1000;
        transform: translateX(-100%);
    }

    .sidebar.mobile-open {
        transform: translateX(0);
    }

    .main-content {
        margin-left: 0 !important;
    }
}
</style>
