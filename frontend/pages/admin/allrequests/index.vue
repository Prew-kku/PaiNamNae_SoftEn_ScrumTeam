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
                        <h1 class="text-2xl font-semibold text-gray-800">All Requests</h1>
                    </div>

                    <!-- Right: Quick Search -->
                    <div class="flex items-center gap-2">
                        <div class="relative">
                            <i class="absolute text-gray-400 transform -translate-y-1/2 fa-solid fa-magnifying-glass left-3 top-1/2"></i>
                            <input v-model.trim="filters.q" @keyup.enter="applyFilters" type="text"
                                placeholder="Email / User / Name"
                                class="py-2 pl-10 pr-4 border border-gray-300 rounded-lg w-72 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                        </div>
                        <button @click="applyFilters"
                            class="px-4 py-2 text-white transition-colors bg-blue-600 rounded-lg cursor-pointer hover:bg-blue-700">
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
                                <option value="cancelled">ยกเลิกแล้ว</option>
                                <option value="deleted">ลบ/นิรนามแล้ว</option>
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
                    <div class="flex items-center justify-between px-5 py-3.5 border-b border-gray-100 bg-gray-50/50">
                        <div class="flex items-center gap-2 text-sm text-gray-600">
                            <i class="text-gray-400 fa-solid fa-list-ul"></i>
                            หน้าที่ {{ pagination.page }} / {{ totalPages }}
                            <span class="text-gray-300">|</span>
                            ทั้งหมด <span class="font-semibold text-gray-800">{{ pagination.total }}</span> คำร้อง
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
                                            <img :src="`https://ui-avatars.com/api/?name=${encodeURIComponent(getUserDisplayName(r.user) || 'U')}&background=random&size=64`"
                                                class="object-cover rounded-full w-9 h-9" alt="avatar" />
                                            <div>
                                                <div class="font-medium text-gray-900">
                                                    {{ getUserDisplayName(r.user) }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-4 py-3 text-gray-700">{{ r.user.email }}</td>
                                    <td class="px-4 py-3 text-gray-700">{{ r.user.username }}</td>
                                    <td class="px-4 py-3 text-sm text-gray-700">
                                        {{ r.user.role }}
                                    </td>


                                    <td class="px-4 py-3 text-sm text-gray-700">
                                        {{ typeLabel(r.type) }}
                                    </td>


                                    <td class="px-4 py-3">
                                        <span
                                            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full"
                                            :class="statusBadge(r.status)">
                                            {{ statusLabel(r.status) }}
                                        </span>
                                    </td>

                                    <!-- row ของ สร้างเมื่อ -->
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
                    คำร้องของ {{ getUserDisplayName(modal.request?.user) }}
                </p>

                <template v-if="modal.action !== 'approve'">
                    <label class="block mb-1 text-sm font-medium text-gray-700">หมายเหตุแอดมิน</label>
                    <textarea v-model="modal.adminNote" rows="3"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="ระบุหมายเหตุ (ไม่บังคับ)"></textarea>
                </template>
                <div v-else class="p-4 mb-4 text-sm text-yellow-700 bg-yellow-50 rounded-md">
                    ยืนยันการอนุมัติ? ระบบจะทำการลบบัญชีและแจ้งเตือนผู้ใช้ทางอีเมลทันที
                </div>

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
import { useToast } from '~/composables/useToast'

const { toast } = useToast()
const config = useRuntimeConfig()

function closeMobileSidebar() {
    const sidebar = document.getElementById('sidebar')
    const overlay = document.getElementById('overlay')
    if (!sidebar || !overlay) return
    sidebar.classList.remove('mobile-open')
    overlay.classList.add('hidden')
}

useHead({
    title: 'All Requests • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const isLoading = ref(false)
const loadError = ref('')
const requests = ref([])

// ─── Filters ───
const filters = reactive({
    q: '',
    type: '',
    status: 'pending',
    role: ''
})

// ─── Pagination ───
const pagination = reactive({
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 1
})

const totalPages = computed(() =>
    Math.max(1, pagination.totalPages || Math.ceil((pagination.total || 0) / (pagination.limit || 20)))
)

const filteredRequests = computed(() => requests.value) // API กรองมาให้แล้ว

function normalizeRequestItem(r) {
    return {
        id: r.id,
        type: 'deletion',
        status: String(r.status || '').toLowerCase(),
        createdAt: r.requestedAt || r.createdAt,
        user: r.user || {},
        deletion: {
            reason: r.reason,
            backupData: r.backupData,
        },
    }
}

async function fetchRequests(page = 1) {
    isLoading.value = true
    loadError.value = ''
    try {
        const token = useCookie('token').value || (process.client ? localStorage.getItem('token') : '')
        
        // TODO: ปรับ URL ให้ตรงกับ Backend Route จริง
        // คาดว่าเป็น GET /api/deletion/admin/requests (สำหรับ deletion) 
        // หรือถ้ามี รวมทุก request ต้องเช็คว่า backend endpoint คืออะไร
        // ในที่นี้ user พูดถึง "User ที่ยื่นคำร้องขอลบบัญชีจะมาขึ้นแสดง" -> น่าจะเน้น DeletionRequest
        
        const res = await $fetch('/deletion/admin/requests', {
            baseURL: config.public.apiBase,
            headers: { Authorization: `Bearer ${token}` },
            query: {
                page,
                limit: pagination.limit,
                status: filters.status,
                role: filters.role,
                type: filters.type,
                q: filters.q
            }
        })

        // res อาจจะเป็น array ตรงๆ หรือ object { data: [], pagination: {} } 
        // ตาม deletion.controller.js: res.status(200).json(requests); -> เป็น Array
        
        if (Array.isArray(res)) {
            requests.value = res.map(normalizeRequestItem)
            pagination.total = res.length
            pagination.totalPages = 1
        } else {
            requests.value = Array.isArray(res?.data) ? res.data.map(normalizeRequestItem) : []
            pagination.total = Number(res?.pagination?.total || requests.value.length)
            pagination.totalPages = Number(res?.pagination?.totalPages || 1)
        }

    } catch (err) {
        console.error(err)
        loadError.value = 'ไม่สามารถโหลดข้อมูลได้'
    } finally {
        isLoading.value = false
    }
}

const pageButtons = computed(() => {
    // ... logic เดิม ...
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
    fetchRequests(next)
}

function applyFilters() {
    pagination.page = 1
    fetchRequests(1)
}

// ─── Helpers: badges & labels ───
function roleBadge(role) {
    if (role === 'DRIVER') return 'bg-blue-100 text-blue-700'
    return 'bg-gray-100 text-gray-700'
}

function typeBadge(type) {
    const map = {
        'deletion': 'bg-red-100 text-red-700'
    }
    return map[type] || 'bg-gray-100 text-gray-700'
}

function typeLabel(type) {
    const map = {
        'deletion': 'ขอลบบัญชี'
    }
    return map[type] || type
}

function statusBadge(status) {
    const map = {
        'pending': 'bg-yellow-100 text-yellow-700',
        'approved': 'bg-green-100 text-green-700',
        'rejected': 'bg-red-100 text-red-700',
        'cancelled': 'bg-gray-100 text-gray-700',
        'deleted': 'bg-slate-200 text-slate-700'
    }
    return map[status] || 'bg-gray-100 text-gray-700'
}

function statusLabel(status) {
    const map = {
        'pending': 'รอดำเนินการ',
        'approved': 'อนุมัติแล้ว',
        'rejected': 'ปฏิเสธแล้ว',
        'cancelled': 'ยกเลิกแล้ว',
        'deleted': 'ลบ/นิรนามแล้ว'
    }
    return map[status] || status
}

function getUserDisplayName(user) {
    if (!user) return '-'
    const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim()
    return fullName || user.username || user.email || user.id || '-'
}

function formatDate(iso) {
    if (!iso) return '-'
    const d = new Date(iso)
    return d.toLocaleDateString('th-TH', {
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
    action: '',       // 'approve', 'reject'
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

async function confirmModal() {
    if (!modal.request) return
    const r = modal.request
    const token = useCookie('token').value || (process.client ? localStorage.getItem('token') : '')
    
    try {
        if (modal.action === 'approve') {
            // Approve: Soft delete 90 days
            // PATCH /api/deletion/admin/requests/:id/approve
             await $fetch(`/deletion/admin/requests/${r.id}/approve`, {
                baseURL: config.public.apiBase,
                method: 'PATCH',
                headers: { Authorization: `Bearer ${token}` }
            })
            toast.success('อนุมัติคำร้องแล้ว', 'ระบบจะทำการลบบัญชีในอีก 90 วัน')
            
        } else {
            // Reject: Require reason
            if (!modal.adminNote.trim()) {
                toast.error('กรุณาระบุเหตุผล', 'การปฏิเสธต้องระบุเหตุผลเสมอ')
                return
            }
             await $fetch(`/deletion/admin/requests/${r.id}/reject`, {
                baseURL: config.public.apiBase,
                method: 'PATCH',
                headers: { Authorization: `Bearer ${token}` },
                body: { adminReason: modal.adminNote }
            })
            toast.success('ปฏิเสธคำร้องแล้ว', 'ระบบได้แจ้งเตือนผู้ใช้เรียบร้อยแล้ว')
        }
        
        // Refresh list
        fetchRequests(pagination.page)
        
    } catch (err) {
        console.error(err)
        toast.error('เกิดข้อผิดพลาด', err?.data?.message || 'ทำรายการไม่สำเร็จ')
    } finally {
        closeModal()
    }
}

// ─── Actions ───
function onViewRequest(r) {
    return navigateTo(`/admin/allrequests/${r.id}`)
}

function onApprove(r) {
    // User requested: "Admin กดเครื่องหมายถูก ระบบจะลบ... (90 วัน)"
    // Confirm first? Or just do it?
    // Modal is good for confirming.
    openModal('approve', r)
}

function onReject(r) {
    // User requested: "กดเครื่องหมายกากะบาด ระบบจะขึ้นป็อปอัพให้ Admin เขียนเหตุผล"
    openModal('reject', r)
}

onMounted(() => {
    fetchRequests()
})
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
