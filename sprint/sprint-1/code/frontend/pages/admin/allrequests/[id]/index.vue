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
                                        {{ getUserDisplayName(request.user) }}
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

                    <div v-if="request.type === 'deletion' && request.deletion?.backupData"
                        class="bg-white border border-gray-300 rounded-lg shadow-sm">
                        <div class="px-4 py-4 border-b border-gray-200 sm:px-6">
                            <h2 class="font-medium text-gray-800">ข้อมูล Backup ที่จัดเก็บ</h2>
                        </div>

                        <div class="grid grid-cols-1 gap-6 p-4 sm:p-6 sm:grid-cols-3">
                            <div>
                                <label class="block text-xs font-medium text-gray-500 uppercase">เริ่มขอเมื่อ</label>
                                <p class="mt-1 text-gray-900">{{ formatDate(request.deletion.backupData.initiatedAt) }}</p>
                            </div>
                            <div>
                                <label class="block text-xs font-medium text-gray-500 uppercase">จำนวนเส้นทางที่เก็บ</label>
                                <p class="mt-1 text-gray-900">{{ backupDriverRouteCount }}</p>
                            </div>
                            <div>
                                <label class="block text-xs font-medium text-gray-500 uppercase">จำนวนการจองที่เก็บ</label>
                                <p class="mt-1 text-gray-900">{{ backupPassengerBookingCount }}</p>
                            </div>
                        </div>

                        <div class="px-4 pb-4 sm:px-6 sm:pb-6">
                            <h3 class="mb-2 text-sm font-semibold text-gray-700">ตัวอย่างเส้นทางที่เก็บ (ล่าสุด)</h3>
                            <div class="overflow-x-auto border border-gray-200 rounded-lg">
                                <table class="min-w-full text-sm">
                                    <thead class="bg-gray-50">
                                        <tr>
                                            <th class="px-3 py-2 text-left text-gray-600">Route ID</th>
                                            <th class="px-3 py-2 text-left text-gray-600">ต้นทาง → ปลายทาง (จังหวัด)</th>
                                            <th class="px-3 py-2 text-left text-gray-600">สถานะ</th>
                                            <th class="px-3 py-2 text-left text-gray-600">สร้างเมื่อ</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="r in previewDriverRoutes" :key="r.id" class="border-t border-gray-100">
                                            <td class="px-3 py-2 text-gray-800">{{ r.id }}</td>
                                            <td class="px-3 py-2 text-gray-700">{{ routeProvinceText(r.startLocation, r.endLocation) }}</td>
                                            <td class="px-3 py-2 text-gray-700">{{ r.status || '-' }}</td>
                                            <td class="px-3 py-2 text-gray-700">{{ formatDate(r.createdAt) }}</td>
                                        </tr>
                                        <tr v-if="!previewDriverRoutes.length">
                                            <td colspan="4" class="px-3 py-3 text-center text-gray-500">ไม่พบข้อมูลเส้นทาง</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <div class="px-4 pb-4 sm:px-6 sm:pb-6">
                            <h3 class="mb-2 text-sm font-semibold text-gray-700">ตัวอย่างการจองที่เก็บ (ล่าสุด)</h3>
                            <div class="overflow-x-auto border border-gray-200 rounded-lg">
                                <table class="min-w-full text-sm">
                                    <thead class="bg-gray-50">
                                        <tr>
                                            <th class="px-3 py-2 text-left text-gray-600">Booking ID</th>
                                            <th class="px-3 py-2 text-left text-gray-600">ต้นทาง → ปลายทาง (จังหวัด)</th>
                                            <th class="px-3 py-2 text-left text-gray-600">สถานะ</th>
                                            <th class="px-3 py-2 text-left text-gray-600">สร้างเมื่อ</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="b in previewPassengerBookings" :key="b.id" class="border-t border-gray-100">
                                            <td class="px-3 py-2 text-gray-800">{{ b.id }}</td>
                                            <td class="px-3 py-2 text-gray-700">{{ routeProvinceText(b.route?.startLocation, b.route?.endLocation) }}</td>
                                            <td class="px-3 py-2 text-gray-700">{{ b.status || '-' }}</td>
                                            <td class="px-3 py-2 text-gray-700">{{ formatDate(b.createdAt) }}</td>
                                        </tr>
                                        <tr v-if="!previewPassengerBookings.length">
                                            <td colspan="4" class="px-3 py-3 text-center text-gray-500">ไม่พบข้อมูลการจอง</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
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
                    คำร้องของ {{ getUserDisplayName(request.user) }}
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

// ─── Real Data Fetching ───
const config = useRuntimeConfig()
const request = ref(null)

async function fetchRequest() {
    isLoading.value = true
    loadError.value = ''
    try {
        const token = useCookie('token').value || (process.client ? localStorage.getItem('token') : '')
        const res = await $fetch(`/deletion/admin/requests/${requestId}`, {
            baseURL: config.public.apiBase,
            headers: { Authorization: `Bearer ${token}` }
        })

        if (res) {
            const latestReviewAudit = Array.isArray(res.audits)
                ? res.audits.find((item) => item.status === 'APPROVED' || item.status === 'REJECTED')
                : null
            const rejectionInfo = res?.backupData?.rejection || {}

            // Map API response to UI model
            request.value = {
                id: res.id,
                type: 'deletion', // Currently backend only supports deletion request via this API
                status: res.status.toLowerCase(),
                createdAt: res.requestedAt || res.createdAt,
                updatedAt: res.updatedAt,
                user: res.user,
                deletion: {
                    reason: res.reason,
                    description: null,
                    backupData: res.backupData || {},
                    adminNote: rejectionInfo.adminReason || latestReviewAudit?.reason || null,
                    reviewedAt: latestReviewAudit?.eventTime || res.approvedAt || null,
                }
            }
        } else {
            loadError.value = 'ไม่พบข้อมูลคำร้อง'
        }
    } catch (err) {
        console.error(err)
        loadError.value = 'ไม่สามารถโหลดข้อมูลได้ หรือคำร้องถูกลบแล้ว'
    } finally {
        isLoading.value = false
    }
}

onMounted(() => {
    fetchRequest()
})

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
    return reason || 'ไม่ระบุ'
}

// RequestStatus: pending | approved | rejected | open | in_progress | resolved | closed
function statusBadge(status) {
    const map = {
        'pending': 'bg-yellow-100 text-yellow-700',
        'approved': 'bg-green-100 text-green-700',
        'rejected': 'bg-red-100 text-red-700',
        'cancelled': 'bg-gray-100 text-gray-600',
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

const backupDriverRouteCount = computed(() => {
    const summary = request.value?.deletion?.backupData?.transitionSummary?.travelRouteSnapshotSummary
    if (summary?.driverRouteCount != null) return summary.driverRouteCount
    const routes = request.value?.deletion?.backupData?.travelRouteSnapshot?.driverRoutes
    return Array.isArray(routes) ? routes.length : 0
})

const backupPassengerBookingCount = computed(() => {
    const summary = request.value?.deletion?.backupData?.transitionSummary?.travelRouteSnapshotSummary
    if (summary?.passengerBookingCount != null) return summary.passengerBookingCount
    const bookings = request.value?.deletion?.backupData?.travelRouteSnapshot?.passengerBookings
    return Array.isArray(bookings) ? bookings.length : 0
})

const previewDriverRoutes = computed(() => {
    const routes = request.value?.deletion?.backupData?.travelRouteSnapshot?.driverRoutes
    return Array.isArray(routes) ? routes.slice(0, 5) : []
})

const previewPassengerBookings = computed(() => {
    const bookings = request.value?.deletion?.backupData?.travelRouteSnapshot?.passengerBookings
    return Array.isArray(bookings) ? bookings.slice(0, 5) : []
})

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

function getUserDisplayName(user) {
    if (!user) return '-'
    const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim()
    return fullName || user.username || user.email || user.id || '-'
}

function extractProvince(location) {
    if (!location || typeof location !== 'object') return '-'

    const raw = [location.province, location.address, location.name]
        .filter(Boolean)
        .map(String)
        .join(', ')

    if (!raw) return '-'

    const explicitProvince = raw.match(/จังหวัด\s*([ก-๙A-Za-z\s]+)/)
    if (explicitProvince?.[1]) return `จังหวัด${explicitProvince[1].trim()}`

    if (raw.includes('กรุงเทพมหานคร')) return 'กรุงเทพมหานคร'

    const parts = raw
        .split(',')
        .map((part) => part.trim())
        .filter(Boolean)

    if (parts.length) return parts[parts.length - 1]
    return '-'
}

function routeProvinceText(startLocation, endLocation) {
    return `${extractProvince(startLocation)} → ${extractProvince(endLocation)}`
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
