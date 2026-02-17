<template>
    <div class="">
        <AdminHeader />
        <AdminSidebar />

        <!-- Mobile Overlay -->
        <div id="overlay" class="fixed inset-0 z-40 hidden bg-black bg-opacity-50 lg:hidden"
            @click="closeMobileSidebar"></div>

        <!-- Main Content -->
        <main id="main-content" class="main-content ml-0 lg:ml-[280px] p-6">
            <div class="mx-auto max-w-8xl">
                <!-- Title + Controls -->
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">Audit Log</h1>
                    </div>

                    <!-- Right: Quick Search -->
                    <div class="flex items-center gap-2">
                        <div class="relative">
                            <i class="absolute text-gray-400 transform -translate-y-1/2 fa-solid fa-magnifying-glass left-3 top-1/2"></i>
                            <input v-model.trim="filters.q" @keyup.enter="applyFilters" type="text"
                                placeholder="Admin / คำร้อง / ผู้ใช้"
                                class="py-2 pl-10 pr-4 border border-gray-300 rounded-lg w-72 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                        </div>
                        <button @click="applyFilters"
                            class="px-4 py-2 text-white transition-colors bg-blue-600 rounded-lg cursor-pointer hover:bg-blue-700">
                            ค้นหา
                        </button>
                    </div>
                </div>

                <!-- Filters -->
                <div class="mb-4 bg-white border border-gray-200 rounded-xl shadow-sm">
                    <div class="grid grid-cols-1 gap-4 px-5 py-4 sm:grid-cols-[1fr_1fr_1fr_2fr]">
                        <!-- Filter: ประเภท Action -->
                        <div>
                            <label class="block mb-1 text-xs font-medium text-gray-600">ประเภท
                                Action</label>
                            <select v-model="filters.action" @change="applyFilters"
                                class="w-full px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                                <option value="">ทั้งหมด</option>
                                <option value="APPROVED">อนุมัติ</option>
                                <option value="REJECTED">ปฏิเสธ</option>
                                <option value="REPLY">ตอบกลับ</option>
                                <option value="CREATED">สร้างคำร้อง</option>
                                <option value="CLOSED">ปิดคำร้อง</option>
                            </select>
                        </div>

                        <!-- Filter: ประเภทคำร้อง -->
                        <div>
                            <label
                                class="block mb-1 text-xs font-medium text-gray-600">ประเภทคำร้อง</label>
                            <select v-model="filters.requestType" @change="applyFilters"
                                class="w-full px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                                <option value="">ทั้งหมด</option>
                                <option value="deletion">ขอลบบัญชี</option>
                                <option value="incident">แจ้งเหตุการณ์</option>
                                <option value="behavior">รายงานพฤติกรรม</option>
                            </select>
                        </div>

                        <!-- Filter: Admin -->
                        <div>
                            <label
                                class="block mb-1 text-xs font-medium text-gray-600">ดำเนินการโดย</label>
                            <select v-model="filters.adminId" @change="applyFilters"
                                class="w-full px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                                <option value="">ทั้งหมด</option>
                                <option v-for="admin in adminList" :key="admin.id" :value="admin.id">
                                    {{ admin.firstName }} {{ admin.lastName }}
                                </option>
                            </select>
                        </div>

                        <!-- Filter: ช่วงวันที่ -->
                        <div class="min-w-0">
                            <label
                                class="block mb-1 text-xs font-medium text-gray-600">ช่วงวันที่</label>
                            <div class="flex items-center gap-1.5">
                                <input v-model="filters.dateFrom" @change="applyFilters" type="date"
                                    class="min-w-0 flex-1 px-2 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                                <span class="text-xs text-gray-400 shrink-0">ถึง</span>
                                <input v-model="filters.dateTo" @change="applyFilters" type="date"
                                    class="min-w-0 flex-1 px-2 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Card -->
                <div class="overflow-hidden bg-white border border-gray-200 rounded-xl shadow-sm">
                    <div class="flex items-center justify-between px-5 py-3.5 border-b border-gray-100 bg-gray-50/50">
                        <div class="flex items-center gap-2 text-sm text-gray-600">
                            <i class="text-gray-400 fa-solid fa-list-ul"></i>
                            หน้าที่ {{ pagination.page }} / {{ totalPages }}
                            <span class="text-gray-300">|</span>
                            ทั้งหมด <span class="font-semibold text-gray-800">{{ pagination.total }}</span> รายการ
                        </div>
                    </div>

                    <!-- Loading / Error -->
                    <div v-if="isLoading" class="flex flex-col items-center gap-3 p-12 text-gray-400">
                        <i class="text-3xl fa-solid fa-spinner fa-spin"></i>
                        <span class="text-sm">กำลังโหลดข้อมูล...</span>
                    </div>
                    <div v-else-if="loadError" class="p-8 text-center text-red-600">
                        <i class="mb-2 text-2xl fa-solid fa-circle-exclamation"></i>
                        <p>{{ loadError }}</p>
                    </div>

                    <!-- Table -->
                    <div v-else class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-gray-100">
                                    <th
                                        class="px-5 py-3 text-xs font-semibold tracking-wider text-left text-gray-500 uppercase bg-gray-50/30">
                                        สร้างเมื่อ
                                    </th>
                                    <th
                                        class="px-5 py-3 text-xs font-semibold tracking-wider text-left text-gray-500 uppercase bg-gray-50/30">
                                        เจ้าของคำร้อง
                                    </th>
                                    <th
                                        class="px-5 py-3 text-xs font-semibold tracking-wider text-left text-gray-500 uppercase bg-gray-50/30">
                                        คำร้อง
                                    </th>
                                    <th
                                        class="px-5 py-3 text-xs font-semibold tracking-wider text-left text-gray-500 uppercase bg-gray-50/30">
                                        การดำเนินการ
                                    </th>
                                    <th
                                        class="px-5 py-3 text-xs font-semibold tracking-wider text-left text-gray-500 uppercase bg-gray-50/30">
                                        ดำเนินการโดย
                                    </th>
                                    <th
                                        class="px-5 py-3 text-xs font-semibold tracking-wider text-left text-gray-500 uppercase bg-gray-50/30">
                                        รายละเอียด
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="log in paginatedLogs" :key="log.id"
                                    class="transition-colors border-b border-gray-50 hover:bg-blue-50/30">
                                    <!-- สร้างเมื่อ -->
                                    <td class="px-5 py-3.5 whitespace-nowrap">
                                        <div class="text-sm text-gray-700">
                                            {{ formatDate(log.timestamp) }}
                                        </div>
                                    </td>

                                    <!-- เจ้าของคำร้อง -->
                                    <td class="px-5 py-3.5">
                                        <div class="text-sm font-medium text-gray-800">
                                            {{ log.request.user.firstName }} {{ log.request.user.lastName }}
                                        </div>
                                        <div class="text-xs text-gray-400">{{ log.request.user.email }}</div>
                                    </td>

                                    <!-- คำร้อง -->
                                    <td class="px-5 py-3.5">
                                        <div class="flex flex-col gap-1">
                                            <span class="text-sm text-gray-700">
                                                {{ requestTypeLabel(log.request.type) }}
                                            </span>
                                        </div>
                                    </td>

                                    <!-- การดำเนินการ -->
                                    <td class="px-5 py-3.5">
                                        <span class="text-sm text-gray-700">
                                            {{ actionLabel(log.action) }}
                                        </span>
                                    </td>

                                    <!-- ดำเนินการโดย -->
                                    <td class="px-5 py-3.5">
                                        <div class="text-sm font-medium text-gray-800">
                                            {{ log.performedBy.firstName }} {{ log.performedBy.lastName }}
                                        </div>
                                        <div class="text-xs text-gray-400">
                                            {{ roleLabel(log.performedBy.role) }}
                                        </div>
                                    </td>

                                    <!-- รายละเอียด -->
                                    <td class="px-5 py-3.5">
                                        <div class="flex items-center gap-2 max-w-[12rem]">
                                            <p class="text-sm text-gray-600 truncate">{{ log.detail }}</p>
                                            <button @click="goToRequest(log.request.id)"
                                                class="flex-shrink-0 flex items-center justify-center w-7 h-7 text-gray-400 transition-colors rounded-md cursor-pointer hover:text-blue-600 hover:bg-blue-50"
                                                title="ดูรายละเอียดคำร้อง">
                                                <i class="fa-solid fa-eye text-xs"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>

                                <tr v-if="!paginatedLogs.length">
                                    <td colspan="6" class="px-5 py-16 text-center">
                                        <div class="flex flex-col items-center gap-2 text-gray-400">
                                            <i class="text-4xl fa-regular fa-folder-open"></i>
                                            <p class="text-sm">ไม่พบรายการ Audit Log</p>
                                        </div>
                                    </td>
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

        
    </div>
</template>

<script setup>
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'

function closeMobileSidebar() {
    const sidebar = document.getElementById('sidebar')
    const overlay = document.getElementById('overlay')
    if (!sidebar || !overlay) return
    sidebar.classList.remove('mobile-open')
    overlay.classList.add('hidden')
}

useHead({
    title: 'Audit Log • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const isLoading = ref(false)
const loadError = ref('')

// ─── Filters ───
const filters = reactive({
    q: '',
    action: '',
    requestType: '',
    adminId: '',
    dateFrom: '',
    dateTo: ''
})

// test
const auditLogs = ref([
    {
        id: 'log_1',
        timestamp: '2026-02-15T14:30:00Z',
        action: 'CREATED',
        request: {
            id: 'req_1',
            type: 'deletion',
            status: 'pending',
            user: {
                id: 'u1', firstName: 'Somchai', lastName: 'Jaidee',
                email: 'somchai@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u1', firstName: 'Somchai', lastName: 'Jaidee', role: 'PASSENGER'
        },
        detail: 'สร้างคำร้องขอลบบัญชี เหตุผล: PRIVACY_CONCERNS - กังวลเรื่องความเป็นส่วนตัวของข้อมูลส่วนบุคคล',
        changes: null
    },
    {
        id: 'log_3',
        timestamp: '2026-02-15T16:45:00Z',
        action: 'APPROVED',
        request: {
            id: 'req_2',
            type: 'deletion',
            status: 'approved',
            user: {
                id: 'u2', firstName: 'Anong', lastName: 'Dee',
                email: 'anong@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u_admin1', firstName: 'Somsak', lastName: 'Thongdee', role: 'ADMIN'
        },
        detail: 'อนุมัติคำร้องขอลบบัญชี adminNote: ตรวจสอบแล้วไม่มีปัญหาค้างอยู่ ดำเนินการลบบัญชีได้',
        changes: { from: 'pending', to: 'approved' }
    },
    {
        id: 'log_4',
        timestamp: '2026-02-14T10:20:00Z',
        action: 'REJECTED',
        request: {
            id: 'req_3',
            type: 'deletion',
            status: 'rejected',
            user: {
                id: 'u3', firstName: 'Preecha', lastName: 'Sukjai',
                email: 'preecha@example.com', profilePicture: null, role: 'DRIVER'
            }
        },
        performedBy: {
            id: 'u_admin2', firstName: 'Pranee', lastName: 'Suksri', role: 'ADMIN'
        },
        detail: 'ปฏิเสธคำร้องขอลบบัญชี adminNote: ผู้ใช้มีการสอบสวนทางกฎหมายอยู่ ไม่สามารถลบบัญชีได้ในขณะนี้',
        changes: { from: 'pending', to: 'rejected' }
    },
    {
        id: 'log_5',
        timestamp: '2026-02-14T15:05:00Z',
        action: 'CREATED',
        request: {
            id: 'req_4',
            type: 'incident',
            status: 'open',
            user: {
                id: 'u4', firstName: 'Suda', lastName: 'Meesuk',
                email: 'suda@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u4', firstName: 'Suda', lastName: 'Meesuk', role: 'PASSENGER'
        },
        detail: 'สร้างคำร้องแจ้งเหตุการณ์ (Ticket: incident) หัวข้อ: คนขับไม่มารับตามเวลา - จองรถเวลา 08:00 แต่คนขับมาถึง 09:30',
        changes: null
    },
    {
        id: 'log_6',
        timestamp: '2026-02-14T16:30:00Z',
        action: 'REPLY',
        request: {
            id: 'req_4',
            type: 'incident',
            status: 'open',
            user: {
                id: 'u4', firstName: 'Suda', lastName: 'Meesuk',
                email: 'suda@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u_admin2', firstName: 'Pranee', lastName: 'Suksri', role: 'ADMIN'
        },
        detail: 'ตอบกลับคำร้อง (TicketReply): กำลังตรวจสอบข้อมูลการจองและติดต่อคนขับเพื่อหาสาเหตุ',
        changes: null
    },
    {
        id: 'log_7',
        timestamp: '2026-02-13T09:00:00Z',
        action: 'CREATED',
        request: {
            id: 'req_5',
            type: 'behavior',
            status: 'open',
            user: {
                id: 'u5', firstName: 'Wichai', lastName: 'Tongdee',
                email: 'wichai@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u5', firstName: 'Wichai', lastName: 'Tongdee', role: 'PASSENGER'
        },
        detail: 'สร้างคำร้องรายงานพฤติกรรม (Ticket: behavior) หัวข้อ: คนขับพูดจาไม่สุภาพระหว่างเดินทาง',
        changes: null
    },
    {
        id: 'log_8',
        timestamp: '2026-02-13T14:00:00Z',
        action: 'REPLY',
        request: {
            id: 'req_5',
            type: 'behavior',
            status: 'in_progress',
            user: {
                id: 'u5', firstName: 'Wichai', lastName: 'Tongdee',
                email: 'wichai@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u_admin1', firstName: 'Somsak', lastName: 'Thongdee', role: 'ADMIN'
        },
        detail: 'ตอบกลับ (TicketReply): ได้ตักเตือนคนขับแล้ว และจะติดตามพฤติกรรมต่อไป หากเกิดซ้ำจะพิจารณาระงับสิทธิ์',
        changes: null
    },
    {
        id: 'log_10',
        timestamp: '2026-02-12T17:00:00Z',
        action: 'CLOSED',
        request: {
            id: 'req_6',
            type: 'incident',
            status: 'closed',
            user: {
                id: 'u6', firstName: 'Nattaya', lastName: 'Srisuk',
                email: 'nattaya@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u_admin2', firstName: 'Pranee', lastName: 'Suksri', role: 'ADMIN'
        },
        detail: 'ปิดคำร้อง - แก้ไขปัญหาเรียบร้อยแล้ว ผู้ใช้พอใจกับผลลัพธ์การแก้ไข',
        changes: { from: 'resolved', to: 'closed' }
    },
    {
        id: 'log_11',
        timestamp: '2026-02-11T08:30:00Z',
        action: 'APPROVED',
        request: {
            id: 'req_7',
            type: 'deletion',
            status: 'approved',
            user: {
                id: 'u7', firstName: 'Kittisak', lastName: 'Boonmee',
                email: 'kittisak@example.com', profilePicture: null, role: 'PASSENGER'
            }
        },
        performedBy: {
            id: 'u_admin1', firstName: 'Somsak', lastName: 'Thongdee', role: 'ADMIN'
        },
        detail: 'อนุมัติคำร้องขอลบบัญชี adminNote: ผู้ใช้ยืนยันแล้ว ดำเนินการ soft delete และตั้ง deletedAt',
        changes: { from: 'pending', to: 'approved' }
    }
])

// ─── Filtered list ───
const filteredLogs = computed(() => {
    let list = auditLogs.value

    if (filters.q) {
        const q = filters.q.toLowerCase()
        list = list.filter(log => {
            const performedByName = `${log.performedBy.firstName} ${log.performedBy.lastName}`.toLowerCase()
            const ownerName = `${log.request.user.firstName} ${log.request.user.lastName}`.toLowerCase()
            return performedByName.includes(q) ||
                ownerName.includes(q) ||
                log.request.user.email.toLowerCase().includes(q) ||
                log.request.id.toLowerCase().includes(q) ||
                log.detail.toLowerCase().includes(q)
        })
    }

    if (filters.action) {
        list = list.filter(log => log.action === filters.action)
    }

    if (filters.requestType) {
        list = list.filter(log => log.request.type === filters.requestType)
    }

    if (filters.adminId) {
        list = list.filter(log => log.performedBy.id === filters.adminId)
    }

    if (filters.dateFrom) {
        const from = new Date(filters.dateFrom)
        list = list.filter(log => new Date(log.timestamp) >= from)
    }

    if (filters.dateTo) {
        const to = new Date(filters.dateTo)
        to.setHours(23, 59, 59, 999)
        list = list.filter(log => new Date(log.timestamp) <= to)
    }

    // เรียงตามเวลาล่าสุดก่อน
    list = [...list].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))

    return list
})

// ─── Pagination ───
const pagination = reactive({
    page: 1,
    limit: 20,
    total: computed(() => filteredLogs.value.length)
})

const totalPages = computed(() =>
    Math.max(1, Math.ceil(filteredLogs.value.length / pagination.limit))
)

const paginatedLogs = computed(() => {
    const start = (pagination.page - 1) * pagination.limit
    return filteredLogs.value.slice(start, start + pagination.limit)
})

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
}

function actionLabel(action) {
    const map = {
        'CREATED': 'สร้างคำร้อง',
        'STATUS_CHANGE': 'เปลี่ยนสถานะ',
        'APPROVED': 'อนุมัติ',
        'REJECTED': 'ปฏิเสธ',
        'REPLY': 'ตอบกลับ',
        'CLOSED': 'ปิดคำร้อง'
    }
    return map[action] || action
}

function roleLabel(role) {
    const map = {
        'ADMIN': 'แอดมิน',
        'DRIVER': 'คนขับ',
        'PASSENGER': 'ผู้โดยสาร'
    }
    return map[role] || role
}

function requestTypeLabel(type) {
    const map = {
        'deletion': 'ขอลบบัญชี',
        'incident': 'แจ้งเหตุการณ์',
        'behavior': 'รายงานพฤติกรรม'
    }
    return map[type] || type
}

function formatDate(iso) {
    if (!iso) return '-'
    const d = new Date(iso)
    const datePart = d.toLocaleDateString('th-TH', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    })
    const timePart = d.toLocaleTimeString('th-TH', {
        hour: '2-digit',
        minute: '2-digit'
    })
    return `${datePart} ${timePart}`
}

// ─── Navigation ───
function goToRequest(requestId) {
    navigateTo(`/admin/allrequests/${requestId}`)
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
