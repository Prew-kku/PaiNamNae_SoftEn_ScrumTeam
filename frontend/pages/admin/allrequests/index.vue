<template>
    <div class="">
        <AdminHeader />
        <AdminSidebar />

        <!-- Main Content -->
        <main id="main-content" class="main-content ml-0 lg:ml-[280px] p-6">
            <div class="mx-auto max-w-8xl">
                <!-- Title + Controls -->
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">All Requests</h1>
                    </div>

                    <!-- Right: Quick Search -->
                    <div class="flex items-center gap-2">
                        <input v-model.trim="filters.q" @keyup.enter="applyFilters" type="text"
                            placeholder="ค้นหา : Email / User / Name"
                            class="max-w-full px-3 py-2 border border-gray-300 rounded-md w-72 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                        <button @click="applyFilters"
                            class="px-4 py-2 text-white bg-blue-600 rounded-md cursor-pointer hover:bg-blue-700">
                            ค้นหา
                        </button>
                    </div>
                </div>

                <!-- Filters -->
                <div class="mb-4 bg-white border border-gray-300 rounded-lg shadow-sm">
                    <div class="grid grid-cols-1 gap-3 px-4 py-4 sm:px-6 sm:grid-cols-3">
                        <!-- Filter: ประเภทคำร้อง -->
                        <div>
                            <label class="block mb-1 text-xs font-medium text-gray-600">ประเภทคำร้อง</label>
                            <select v-model="filters.type" @change="applyFilters"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500">
                                <option value="">ทั้งหมด</option>
                                <option value="deletion">ขอลบบัญชี</option>
                                <option value="incident">แจ้งเหตุการณ์</option>
                                <option value="behavior">รายงานพฤติกรรม</option>
                            </select>
                        </div>

                        <!-- Filter: สถานะ -->
                        <div>
                            <label class="block mb-1 text-xs font-medium text-gray-600">สถานะ</label>
                            <select v-model="filters.status" @change="applyFilters"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500">
                                <option value="">ทั้งหมด</option>
                                <option value="pending">รอดำเนินการ</option>
                                <option value="approved">อนุมัติแล้ว</option>
                                <option value="rejected">ปฏิเสธแล้ว</option>
                                <option value="open">เปิด</option>
                                <option value="in_progress">กำลังดำเนินการ</option>
                                <option value="resolved">แก้ไขแล้ว</option>
                                <option value="closed">ปิดแล้ว</option>
                            </select>
                        </div>

                        <!-- Filter: บทบาท -->
                        <div>
                            <label class="block mb-1 text-xs font-medium text-gray-600">บทบาท</label>
                            <select v-model="filters.role" @change="applyFilters"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500">
                                <option value="">ทั้งหมด</option>
                                <option value="PASSENGER">ผู้โดยสาร</option>
                                <option value="DRIVER">คนขับ</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- Card -->
                <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
                    <div class="flex items-center justify-between px-4 py-4 border-b border-gray-200 sm:px-6">
                        <div class="text-sm text-gray-600">
                            หน้าที่ {{ pagination.page }} / {{ totalPages }} • ทั้งหมด {{ pagination.total }} คำร้อง
                        </div>
                    </div>

                    <!-- Loading / Error -->
                    <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
                    <div v-else-if="loadError" class="p-8 text-center text-red-600">
                        {{ loadError }}
                    </div>

                    <!-- Table -->
                    <div v-else class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        ผู้ใช้
                                    </th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        อีเมล
                                    </th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        ชื่อผู้ใช้
                                    </th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        บทบาท
                                    </th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        ประเภท
                                    </th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        สถานะ
                                    </th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        สร้างเมื่อ
                                    </th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        การกระทำ
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                <tr v-for="r in filteredRequests" :key="r.id"
                                    class="transition-opacity hover:bg-gray-50">
                                    <td class="px-4 py-3">
                                        <div class="flex items-center gap-3">
                                            <img :src="r.user.profilePicture || `https://ui-avatars.com/api/?name=${encodeURIComponent(r.user.firstName || 'U')}&background=random&size=64`"
                                                class="object-cover rounded-full w-9 h-9" alt="avatar" />
                                            <div>
                                                <div class="font-medium text-gray-900">
                                                    {{ r.user.firstName }} {{ r.user.lastName }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-4 py-3 text-gray-700">{{ r.user.email }}</td>
                                    <td class="px-4 py-3 text-gray-700">{{ r.user.username }}</td>
                                    <td class="px-4 py-3">
                                        <span
                                            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full"
                                            :class="roleBadge(r.user.role)">
                                            {{ r.user.role }}
                                        </span>
                                    </td>
                                    <td class="px-4 py-3">
                                        <span
                                            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full"
                                            :class="typeBadge(r.type)">
                                            {{ typeLabel(r.type) }}
                                        </span>
                                    </td>
                                    <td class="px-4 py-3">
                                        <span
                                            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full"
                                            :class="statusBadge(r.status)">
                                            {{ statusLabel(r.status) }}
                                        </span>
                                    </td>
                                    <td class="px-4 py-3 text-gray-700">
                                        <div class="text-sm">{{ formatDate(r.createdAt) }}</div>
                                    </td>
                                    <td class="px-4 py-3">
                                        <div class="flex items-center gap-1">
                                            <button @click="onViewRequest(r)"
                                                class="p-2 text-gray-500 transition-colors cursor-pointer hover:text-blue-600"
                                                title="ดูรายละเอียด" aria-label="ดูรายละเอียด">
                                                <i class="text-lg fa-regular fa-eye"></i>
                                            </button>
                                            <button v-if="r.type === 'deletion' && r.status === 'pending'"
                                                @click="onApprove(r)"
                                                class="p-2 text-gray-500 transition-colors cursor-pointer hover:text-emerald-600"
                                                title="อนุมัติ" aria-label="อนุมัติ">
                                                <i class="text-lg fa-solid fa-check"></i>
                                            </button>
                                            <button v-if="r.type === 'deletion' && r.status === 'pending'"
                                                @click="onReject(r)"
                                                class="p-2 text-gray-500 transition-colors cursor-pointer hover:text-red-600"
                                                title="ปฏิเสธ" aria-label="ปฏิเสธ">
                                                <i class="text-lg fa-solid fa-xmark"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>

                                <tr v-if="!filteredRequests.length">
                                    <td colspan="8" class="px-4 py-10 text-center text-gray-500">ไม่มีคำร้อง</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination -->
                    <div
                        class="flex flex-col gap-3 px-4 py-4 border-t border-gray-200 sm:px-6 sm:flex-row sm:items-center sm:justify-between">
                        <div class="flex flex-wrap items-center gap-3 text-sm">
                            <div class="flex items-center gap-2">
                                <span class="text-xs text-gray-500">Limit:</span>
                                <select v-model.number="pagination.limit" @change="applyFilters"
                                    class="px-2 py-1 text-sm border border-gray-300 rounded-md focus:ring-blue-500">
                                    <option :value="10">10</option>
                                    <option :value="20">20</option>
                                    <option :value="50">50</option>
                                </select>
                            </div>
                        </div>

                        <nav class="flex items-center gap-1">
                            <button class="px-3 py-2 text-sm border rounded-md disabled:opacity-50"
                                :disabled="pagination.page <= 1 || isLoading"
                                @click="changePage(pagination.page - 1)">
                                Previous
                            </button>

                            <template v-for="(p, idx) in pageButtons" :key="`p-${idx}-${p}`">
                                <span v-if="p === '…'" class="px-2 text-sm text-gray-500">…</span>
                                <button v-else class="px-3 py-2 text-sm border rounded-md"
                                    :class="p === pagination.page ? 'bg-blue-50 text-blue-600 border-blue-200' : 'hover:bg-gray-50'"
                                    :disabled="isLoading" @click="changePage(p)">
                                    {{ p }}
                                </button>
                            </template>

                            <button class="px-3 py-2 text-sm border rounded-md disabled:opacity-50"
                                :disabled="pagination.page >= totalPages || isLoading"
                                @click="changePage(pagination.page + 1)">
                                Next
                            </button>
                        </nav>
                    </div>
                </div>
            </div>
        </main>

        <!-- Admin Note Modal -->
        <div v-if="modal.show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @click.self="closeModal">
            <div class="w-full max-w-md p-6 mx-4 bg-white rounded-lg shadow-xl">
                <h3 class="mb-1 text-lg font-semibold text-gray-800">
                    {{ modal.action === 'approve' ? 'อนุมัติคำร้อง' : 'ปฏิเสธคำร้อง' }}
                </h3>
                <p class="mb-4 text-sm text-gray-500">
                    คำร้องของ {{ modal.request?.user.firstName }} {{ modal.request?.user.lastName }}
                </p>

                <label class="block mb-1 text-sm font-medium text-gray-700">หมายเหตุแอดมิน</label>
                <textarea v-model="modal.adminNote" rows="3"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="ระบุหมายเหตุ (ไม่บังคับ)"></textarea>

                <div class="flex justify-end gap-3 mt-4">
                    <button @click="closeModal"
                        class="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md cursor-pointer hover:bg-gray-50">
                        ยกเลิก
                    </button>
                    <button @click="confirmModal"
                        class="px-4 py-2 text-sm text-white rounded-md cursor-pointer"
                        :class="modal.action === 'approve' ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-red-600 hover:bg-red-700'">
                        {{ modal.action === 'approve' ? 'อนุมัติ' : 'ปฏิเสธ' }}
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'

useHead({
    title: 'All Requests • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const isLoading = ref(false)
const loadError = ref('')

// ─── Filters ───
const filters = reactive({
    q: '',
    type: '',
    status: '',
    role: ''
})

// ─── Mock Data (จะเปลี่ยนเป็น API เมื่อ backend พร้อม) ───
const requests = ref([
    // ── Deletion requests ──
    {
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
    {
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
    {
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
    // ── Ticket requests ──
    {
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
            description: 'จองรถเวลา 08:00 แต่คนขับมาถึง 09:30'
        }
    },
    {
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
            description: 'คนขับใช้คำพูดไม่เหมาะสมระหว่างเดินทาง'
        }
    }
])

// ─── Filtered list (client-side filter สำหรับ mock data) ───
const filteredRequests = computed(() => {
    let list = requests.value

    if (filters.q) {
        const q = filters.q.toLowerCase()
        list = list.filter(r =>
            r.user.firstName.toLowerCase().includes(q) ||
            r.user.lastName.toLowerCase().includes(q) ||
            r.user.email.toLowerCase().includes(q) ||
            r.user.username.toLowerCase().includes(q)
        )
    }

    if (filters.status) {
        list = list.filter(r => r.status === filters.status)
    }

    if (filters.role) {
        list = list.filter(r => r.user.role === filters.role)
    }

    if (filters.type) {
        list = list.filter(r => r.type === filters.type)
    }

    return list
})

// ─── Pagination ───
const pagination = reactive({
    page: 1,
    limit: 20,
    total: computed(() => filteredRequests.value.length),
    totalPages: 1
})

const totalPages = computed(() =>
    Math.max(1, Math.ceil(filteredRequests.value.length / pagination.limit))
)

const pageButtons = computed(() => {
    const total = totalPages.value
    const current = pagination.page
    if (!total || total < 1) return []
    if (total <= 5) return Array.from({ length: total }, (_, i) => i + 1)
    const set = new Set([1, total, current])
    if (current - 1 > 1) set.add(current - 1)
    if (current + 1 < total) set.add(current + 1)
    const pages = Array.from(set).sort((a, b) => a - b)
    const out = []
    for (let i = 0; i < pages.length; i++) {
        if (i > 0 && pages[i] - pages[i - 1] > 1) out.push('…')
        out.push(pages[i])
    }
    return out
})

function changePage(next) {
    if (next < 1 || next > totalPages.value) return
    pagination.page = next
}

function applyFilters() {
    pagination.page = 1
    // TODO: เมื่อ backend พร้อม ให้เรียก fetchRequests() ที่นี่
}

// ─── Helpers: badges & labels ───
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

// ─── Admin Note Modal ───
const modal = reactive({
    show: false,
    action: '',       // 'approve' | 'reject'
    request: null,
    adminNote: ''
})

function openModal(action, r) {
    modal.show = true
    modal.action = action
    modal.request = r
    modal.adminNote = ''
}

function closeModal() {
    modal.show = false
    modal.request = null
    modal.adminNote = ''
}

function confirmModal() {
    if (!modal.request) return
    const r = modal.request
    // TODO: เรียก API พร้อมส่ง adminNote 
    if (modal.action === 'approve') {
        r.status = 'approved'
    } else {
        r.status = 'rejected'
    }
    if (r.deletion) {
        r.deletion.adminNote = modal.adminNote || undefined
        r.deletion.reviewedAt = new Date().toISOString()
    }
    closeModal()
}

// ─── Actions ───
function onViewRequest(r) {
    navigateTo(`/admin/allrequests/${r.id}`)
}

function onApprove(r) {
    openModal('approve', r)
}

function onReject(r) {
    openModal('reject', r)
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
