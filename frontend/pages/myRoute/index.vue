<template>
    <div>
        <div class="px-4 py-8 mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="mb-8">
                <h2 class="text-2xl font-bold text-gray-900">คำขอจองเส้นทางของฉัน</h2>
                <p class="mt-2 text-gray-600">ดูและจัดการคำขอจองจากผู้โดยสารในเส้นทางที่คุณสร้าง</p>
            </div>

            <div class="p-6 mb-8 bg-white border border-gray-300 rounded-lg shadow-md">
                <div class="flex flex-wrap gap-2">
                    <button v-for="tab in tabs" :key="tab.status" @click="activeTab = tab.status"
                        :class="['tab-button px-4 py-2 rounded-md font-medium', { 'active': activeTab === tab.status }]">
                        {{ tab.label }} ({{ getTripCount(tab.status) }})
                    </button>
                </div>
            </div>

            <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                <div class="lg:col-span-2">
                    <div class="bg-white border border-gray-300 rounded-lg shadow-md">
                        <div class="p-6 border-b border-gray-300">
                            <h3 class="text-lg font-semibold text-gray-900">
                                {{ activeTab === 'myRoutes' ? 'เส้นทางของฉัน' : 'รายการคำขอจอง' }}
                            </h3>
                        </div>

                        <div v-if="isLoading" class="p-12 text-center text-gray-500">
                            <p>กำลังโหลดข้อมูล...</p>
                        </div>

                        <!-- ===== แท็บ: เส้นทางของฉัน ===== -->
                        <div v-else-if="activeTab === 'myRoutes'" class="divide-y divide-gray-200">
                            <div v-if="myRoutes.length === 0" class="p-12 text-center text-gray-500">
                                <p>ยังไม่มีเส้นทางที่คุณสร้าง</p>
                            </div>

                            <div v-for="route in myRoutes" :key="route.id"
                                class="p-6 transition-colors duration-200 cursor-pointer trip-card hover:bg-gray-50"
                                @click="toggleTripDetails(route.id)">
                                <div class="flex items-start justify-between mb-4">
                                    <div class="flex-1">
                                        <div class="flex items-center justify-between">
                                            <h4 class="text-lg font-semibold text-gray-900">
                                                {{ route.origin }} → {{ route.destination }}
                                            </h4>
                                            <span class="status-badge" :class="{
                                                'status-confirmed': route.status === 'available',
                                                'status-pending': route.status === 'full',
                                                'status-in-transit': route.status === 'in_transit',
                                                'status-arrived': route.status === 'arrived',
                                                'status-completed': route.status === 'completed',
                                                'status-cancelled': route.status === 'cancelled',
                                            }">
                                                {{ route.status === 'available' ? 'เปิดรับผู้โดยสาร'
                                                    : route.status === 'full' ? 'เต็ม'
                                                    : route.status === 'in_transit' ? 'กำลังเดินทาง'
                                                    : route.status === 'arrived' ? 'รอยืนยันชำระเงิน'
                                                    : route.status === 'completed' ? 'เสร็จสิ้น'
                                                    : route.status === 'cancelled' ? 'ยกเลิก'
                                                    : route.status }}
                                            </span>
                                        </div>
                                        <p class="mt-1 text-sm text-gray-600">
                                            วันที่: {{ route.date }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            เวลา: {{ route.time }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            ระยะเวลา: {{ route.durationText }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            ระยะทาง: {{ route.distanceText }}
                                        </p>
                                        <div class="mt-1 text-sm text-gray-600">
                                            <span class="font-medium">ที่นั่งว่าง:</span>
                                            <span class="ml-1">{{ route.availableSeats }}</span>
                                            <span class="mx-2 text-gray-300">|</span>
                                            <span class="font-medium">ราคาต่อที่นั่ง:</span>
                                            <span class="ml-1">{{ route.pricePerSeat }} บาท</span>
                                        </div>
                                    </div>
                                </div>

                                <!-- รายละเอียดเมื่อเปิด -->
                                <div v-if="selectedTripId === route.id"
                                    class="pt-4 mt-4 mb-5 duration-300 border-t border-gray-300 animate-in slide-in-from-top">
                                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดเส้นทาง</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li>
                                                    • จุดเริ่มต้น:
                                                    <span class="font-medium text-gray-900">{{ route.origin }}</span>
                                                    <span v-if="route.originAddress"> — {{ route.originAddress }}</span>
                                                </li>

                                                <template v-if="route.stops && route.stops.length">
                                                    <li class="mt-2 text-gray-700">• จุดแวะระหว่างทาง ({{
                                                        route.stops.length }} จุด):</li>
                                                    <li v-for="(stop, idx) in route.stops" :key="idx">  - จุดแวะ {{ idx
                                                        + 1 }}: {{ stop }}</li>
                                                </template>

                                                <li class="mt-1">
                                                    • จุดปลายทาง:
                                                    <span class="font-medium text-gray-900">{{ route.destination
                                                    }}</span>
                                                    <span v-if="route.destinationAddress"> — {{ route.destinationAddress
                                                    }}</span>
                                                </li>
                                            </ul>
                                        </div>
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดรถ</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li v-for="detail in route.carDetails" :key="detail">• {{ detail }}</li>
                                            </ul>
                                        </div>
                                    </div>

                                    <div class="mt-4 space-y-4">
                                        <div v-if="route.conditions">
                                            <h5 class="mb-2 font-medium text-gray-900">เงื่อนไขการเดินทาง</h5>
                                            <p
                                                class="p-3 text-sm text-gray-700 border border-gray-300 rounded-md bg-gray-50">
                                                {{ route.conditions }}
                                            </p>
                                        </div>

                                        <div v-if="route.photos && route.photos.length > 0">
                                            <h5 class="mb-2 font-medium text-gray-900">รูปภาพรถยนต์</h5>
                                            <div class="grid grid-cols-3 gap-2 mt-2">
                                                <div v-for="(photo, index) in route.photos.slice(0, 3)" :key="index">
                                                    <img :src="photo" alt="Vehicle photo"
                                                        class="object-cover w-full transition-opacity rounded-lg shadow-sm cursor-pointer aspect-video hover:opacity-90" />
                                                </div>
                                            </div>
                                        </div>

                                        <!-- ผู้โดยสารของเส้นทางนี้ -->
                                        <div v-if="route.passengers && route.passengers.length">
                                            <h5 class="mb-2 font-medium text-gray-900">ผู้โดยสาร ({{
                                                route.passengers.length }} คน)</h5>
                                            <div class="space-y-3">
                                                <div v-for="p in route.passengers" :key="p.id"
                                                    class="flex items-center space-x-3">
                                                    <img :src="p.image" :alt="p.name"
                                                        class="object-cover w-12 h-12 rounded-full" />
                                                    <div class="flex-1">
                                                        <div class="flex items-center">
                                                            <span class="font-medium text-gray-900">{{ p.name }}</span>
                                                            <div v-if="p.isVerified"
                                                                class="relative group ml-1.5 flex items-center">
                                                                <svg class="w-4 h-4 text-blue-600" viewBox="0 0 24 24"
                                                                    fill="currentColor">
                                                                    <path fill-rule="evenodd"
                                                                        d="M8.603 3.799A4.49 4.49 0 0112 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 013.498 1.307 4.491 4.491 0 011.307 3.497A4.49 4.49 0 0121.75 12c0 1.357-.6 2.573-1.549 3.397a4.49 4.49 0 01-1.307 3.498 4.491 4.491 0 01-3.497 1.307A4.49 4.49 0 0112 21.75a4.49 4.49 0 01-3.397-1.549 4.49 4.49 0 01-3.498-1.306 4.491 4.491 0 01-1.307-3.498A4.49 4.49 0 012.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 011.307-3.497 4.49 4.49 0 013.497-1.307zm7.007 6.387a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.07-.01l3.5-4.875z"
                                                                        clip-rule="evenodd" />
                                                                </svg>
                                                            </div>
                                                        </div>
                                                        <div class="text-sm text-gray-600">
                                                            ที่นั่ง: {{ p.seats }}
                                                            <span v-if="p.email" class="mx-2 text-gray-300">|</span>
                                                            <a v-if="p.email" :href="`mailto:${p.email}`"
                                                                class="text-blue-600 hover:underline" @click.stop>
                                                                {{ p.email }}
                                                            </a>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- ปุ่มขวาล่าง -->
                                <div class="flex justify-end gap-3" :class="{ 'mt-4': selectedTripId !== route.id }">
                                    <!-- ขั้น 1: แจ้งถึงที่หมาย (ก่อน arrived) -->
                                    <button
                                        v-if="['available', 'full', 'in_transit'].includes(route.status)"
                                        @click.stop="openConfirmModal(route, 'arrive')"
                                        class="px-4 py-2 text-sm text-white transition duration-200 bg-green-600 rounded-md hover:bg-green-700">
                                        ถึงที่หมายแล้ว
                                    </button>
                                    <!-- ขั้น 2: ตรวจสอบการชำระเงิน (หลัง arrived หรือ completed ที่ยังค้างอยู่) -->
                                    <button
                                        v-else-if="['arrived', 'completed'].includes(route.status)"
                                        @click.stop="openConfirmModal(route, 'complete-route')"
                                        class="px-4 py-2 text-sm text-white transition duration-200 bg-blue-600 rounded-md hover:bg-blue-700 flex items-center gap-2">
                                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                                        </svg>
                                        {{ route.status === 'completed' ? 'ประวัติการชำระเงิน' : 'ยืนยันการชำระเงิน' }}
                                    </button>
                                    <NuxtLink
                                        v-if="!['arrived', 'completed'].includes(route.status)"
                                        :to="`/myRoute/${route.id}/edit`"
                                        class="px-4 py-2 text-sm text-white transition duration-200 bg-blue-600 rounded-md hover:bg-blue-700"
                                        @click.stop>
                                        แก้ไขเส้นทาง
                                    </NuxtLink>
                                </div>
                            </div>
                        </div>

                        <!-- ===== แท็บ: คำขอจอง (เดิม) ===== -->
                        <div v-else class="divide-y divide-gray-200">
                            <div v-if="filteredTrips.length === 0" class="p-12 text-center text-gray-500">
                                <p>ไม่พบรายการในหมวดหมู่นี้</p>
                            </div>

                            <div v-for="trip in filteredTrips" :key="trip.id"
                                class="p-6 transition-colors duration-200 cursor-pointer trip-card hover:bg-gray-50"
                                @click="toggleTripDetails(trip.id)">
                                <div class="flex items-start justify-between mb-4">
                                    <div class="flex-1">
                                        <div class="flex items-center justify-between">
                                            <h4 class="text-lg font-semibold text-gray-900">
                                                {{ trip.origin }} → {{ trip.destination }}
                                            </h4>
                                            <span v-if="trip.status === 'pending'"
                                                class="status-badge status-pending">รอดำเนินการ</span>
                                            <span v-else-if="trip.status === 'confirmed'"
                                                class="status-badge status-confirmed">ยืนยันแล้ว</span>
                                            <span v-else-if="trip.status === 'rejected'"
                                                class="status-badge status-rejected">ปฏิเสธ</span>
                                            <span v-else-if="trip.status === 'cancelled'"
                                                class="status-badge status-cancelled">ยกเลิก</span>
                                        </div>
                                        <p class="mt-1 text-sm text-gray-600">จุดนัดพบ: {{ trip.pickupPoint }}</p>
                                        <p class="text-sm text-gray-600">
                                            วันที่: {{ trip.date }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            เวลา: {{ trip.time }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            ระยะเวลา: {{ trip.durationText }}
                                            <span class="mx-2 text-gray-300">|</span>
                                            ระยะทาง: {{ trip.distanceText }}
                                        </p>
                                        <div v-if="activeTab === 'cancelled' && trip.status === 'cancelled' && trip.cancelReason"
                                            class="p-2 mt-2 border border-gray-200 rounded-md bg-gray-50">
                                            <span class="text-sm text-gray-700">
                                                เหตุผลการยกเลิกของผู้โดยสาร:
                                                <span class="font-medium">{{ reasonLabel(trip.cancelReason) }}</span>
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div class="flex items-center mb-4 space-x-4">
                                    <img :src="trip.passenger.image" :alt="trip.passenger.name"
                                        class="object-cover rounded-full w-15 h-15" />
                                    <div class="flex-1">
                                        <div class="flex items-center">
                                            <h5 class="font-medium text-gray-900">{{ trip.passenger.name }}</h5>

                                            <div v-if="trip.passenger.isVerified"
                                                class="relative group ml-1.5 flex items-center">
                                                <svg class="w-5 h-5 text-blue-600" viewBox="0 0 24 24"
                                                    fill="currentColor">
                                                    <path fill-rule="evenodd"
                                                        d="M8.603 3.799A4.49 4.49 0 0112 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 013.498 1.307 4.491 4.491 0 011.307 3.497A4.49 4.49 0 0121.75 12c0 1.357-.6 2.573-1.549 3.397a4.49 4.49 0 01-1.307 3.498 4.491 4.491 0 01-3.497 1.307A4.49 4.49 0 0112 21.75a4.49 4.49 0 01-3.397-1.549 4.49 4.49 0 01-3.498-1.306 4.491 4.491 0 01-1.307-3.498A4.49 4.49 0 012.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 011.307-3.497 4.49 4.49 0 013.497-1.307zm7.007 6.387a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.07-.01l3.5-4.875z"
                                                        clip-rule="evenodd" />
                                                </svg>
                                                <span
                                                    class="absolute px-2 py-1 mb-2 text-xs text-white transition-opacity -translate-x-1/2 bg-gray-800 rounded-md opacity-0 pointer-events-none bottom-full left-1/2 w-max group-hover:opacity-100">
                                                    ผู้โดยสารยืนยันตัวตนแล้ว
                                                </span>
                                            </div>
                                        </div>

                                        <div class="flex">
                                            <p v-if="trip.passenger.email" class="text-xs text-gray-500 mt-0.5">
                                                อีเมล:
                                                <a :href="`mailto:${trip.passenger.email}`"
                                                    class="text-blue-600 hover:underline" @click.stop>
                                                    {{ trip.passenger.email }}
                                                </a>
                                            </p>
                                            <button v-if="trip.passenger.email"
                                                class="inline-flex items-center ml-1 text-gray-500 rounded hover:text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                                                title="คัดลอกอีเมล" aria-label="คัดลอกอีเมล"
                                                @click.stop="copyEmail(trip.passenger.email)">
                                                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none"
                                                    stroke="currentColor">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                        stroke-width="2"
                                                        d="M8 7h8a2 2 0 012 2v8a2 2 0 01-2 2H8a2 2 0 01-2-2V9a2 2 0 012-2z" />
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                        stroke-width="2" d="M16 7V5a2 2 0 00-2-2H8a2 2 0 00-2 2v2" />
                                                </svg>
                                            </button>
                                        </div>

                                        <div class="flex items-center mt-1">
                                            <div class="flex text-sm text-yellow-400">
                                                <span>
                                                    {{ '★'.repeat(Math.round(trip.passenger.rating)) }}{{ '☆'.repeat(5 -
                                                        Math.round(trip.passenger.rating)) }}
                                                </span>
                                            </div>
                                            <span class="ml-2 text-sm text-gray-600">
                                                {{ trip.passenger.rating }} ({{ trip.passenger.reviews }} รีวิว)
                                            </span>
                                        </div>
                                    </div>
                                    <div class="text-right">
                                        <div class="text-lg font-bold text-blue-600">{{ trip.price }} บาท</div>
                                        <div class="text-sm text-gray-600">จำนวน {{ trip.seats }} ที่นั่ง</div>
                                    </div>
                                </div>

                                <!-- รายละเอียดเส้นทาง + จุดแวะ -->
                                <div v-if="selectedTripId === trip.id"
                                    class="pt-4 mt-4 mb-5 duration-300 border-t border-gray-300 animate-in slide-in-from-top">
                                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดเส้นทาง</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li>
                                                    • จุดเริ่มต้น:
                                                    <span class="font-medium text-gray-900">{{ trip.origin }}</span>
                                                    <span v-if="trip.originAddress"> — {{ trip.originAddress }}</span>
                                                </li>

                                                <template v-if="trip.stops && trip.stops.length">
                                                    <li class="mt-2 text-gray-700">• จุดแวะระหว่างทาง ({{
                                                        trip.stops.length }} จุด):</li>
                                                    <li v-for="(stop, idx) in trip.stops" :key="idx">  - จุดแวะ {{ idx +
                                                        1 }}: {{ stop }}</li>
                                                </template>

                                                <li class="mt-1">
                                                    • จุดปลายทาง:
                                                    <span class="font-medium text-gray-900">{{ trip.destination
                                                    }}</span>
                                                    <span v-if="trip.destinationAddress"> — {{ trip.destinationAddress
                                                    }}</span>
                                                </li>
                                            </ul>
                                        </div>
                                        <div>
                                            <h5 class="mb-2 font-medium text-gray-900">รายละเอียดรถ</h5>
                                            <ul class="space-y-1 text-sm text-gray-600">
                                                <li v-for="detail in trip.carDetails" :key="detail">• {{ detail }}</li>
                                            </ul>
                                        </div>
                                    </div>
                                    <div class="mt-4 space-y-4">
                                        <div v-if="trip.conditions">
                                            <h5 class="mb-2 font-medium text-gray-900">เงื่อนไขการเดินทาง</h5>
                                            <p
                                                class="p-3 text-sm text-gray-700 border border-gray-300 rounded-md bg-gray-50">
                                                {{ trip.conditions }}
                                            </p>
                                        </div>
                                        <div v-if="trip.photos && trip.photos.length > 0">
                                            <h5 class="mb-2 font-medium text-gray-900">รูปภาพรถยนต์</h5>
                                            <div class="grid grid-cols-3 gap-2 mt-2">
                                                <div v-for="(photo, index) in trip.photos.slice(0, 3)" :key="index">
                                                    <img :src="photo" alt="Vehicle photo"
                                                        class="object-cover w-full transition-opacity rounded-lg shadow-sm cursor-pointer aspect-video hover:opacity-90" />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="flex justify-end space-x-3" :class="{ 'mt-4': selectedTripId !== trip.id }">
                                    <template v-if="trip.status === 'pending'">
                                        <button @click.stop="openConfirmModal(trip, 'confirm')"
                                            class="px-4 py-2 text-sm text-white transition duration-200 bg-blue-600 rounded-md hover:bg-blue-700">
                                            ยืนยันคำขอ
                                        </button>
                                        <button @click.stop="openConfirmModal(trip, 'reject')"
                                            class="px-4 py-2 text-sm text-red-600 transition duration-200 border border-red-300 rounded-md hover:bg-red-50">
                                            ปฏิเสธ
                                        </button>
                                    </template>

                                    <button v-else-if="trip.status === 'confirmed'"
                                        class="px-4 py-2 text-sm text-white transition duration-200 bg-blue-600 rounded-md hover:bg-blue-700">
                                        แชทกับผู้โดยสาร
                                    </button>

                                    <button v-else-if="['rejected', 'cancelled'].includes(trip.status)"
                                        @click.stop="openConfirmModal(trip, 'delete')"
                                        class="px-4 py-2 text-sm text-gray-600 transition duration-200 border border-gray-300 rounded-md hover:bg-gray-50">
                                        ลบรายการ
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- แผนที่ -->
                <div class="lg:col-span-1">
                    <div class="sticky overflow-hidden bg-white border border-gray-300 rounded-lg shadow-md top-8">
                        <div class="p-3 border-gray-300">
                            <h3 class="text-lg font-semibold text-gray-900">แผนที่เส้นทาง</h3>
                            <p class="mt-1 text-sm text-gray-600">
                                {{ selectedLabel ? selectedLabel : 'คลิกที่รายการเพื่อดูเส้นทาง' }}
                            </p>
                        </div>
                        <div ref="mapContainer" id="map"></div>
                    </div>
                </div>
            </div>
        </div>

        <ConfirmModal :show="isModalVisible" :title="modalContent.title" :message="modalContent.message"
            :confirmText="modalContent.confirmText" :variant="modalContent.variant" @confirm="handleConfirmAction"
            @cancel="closeConfirmModal" />

        <!-- Payment Verification Modal -->
        <div v-if="isPaymentModalVisible" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
            <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg overflow-hidden">
                <!-- Header -->
                <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
                    <div>
                        <h3 class="text-lg font-semibold text-gray-900">ตรวจสอบการชำระเงิน</h3>
                        <p class="text-sm text-gray-500 mt-0.5" v-if="paymentModalRoute">
                            {{ paymentModalRoute.origin }} → {{ paymentModalRoute.destination }}
                        </p>
                    </div>
                    <button @click="isPaymentModalVisible = false" class="text-gray-400 hover:text-gray-600">
                        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                <!-- Body -->
                <div class="px-6 py-4 space-y-4 max-h-[28rem] overflow-y-auto">
                    <p v-if="!paymentModalRoute?.passengers?.length" class="text-sm text-center text-gray-500 py-4">
                        ไม่มีผู้โดยสารในเส้นทางนี้
                    </p>

                    <!-- ===== READ-ONLY MODE: ทุกคนอนุมัติแล้ว ===== -->
                    <template v-if="isReadOnlyMode">
                        <div v-for="p in paymentModalRoute?.passengers" :key="p.id"
                            class="p-4 border border-green-200 bg-green-50 rounded-lg">
                            <div class="flex items-center gap-3 mb-2.5">
                                <img :src="p.image" :alt="p.name" class="w-10 h-10 rounded-full object-cover" />
                                <div class="flex-1 min-w-0">
                                    <div class="font-medium text-gray-900 text-sm truncate">{{ p.name }}</div>
                                    <div class="text-xs text-gray-500">{{ p.seats }} ที่นั่ง</div>
                                </div>
                                <button @click="showReceipt(p)"
                                    class="flex items-center gap-1.5 px-2.5 py-1.5 text-xs text-green-700 border border-green-300 rounded-md hover:bg-green-100 transition-colors flex-shrink-0">
                                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                    ใบเสร็จ
                                </button>
                            </div>
                            <div class="flex items-center justify-between">
                                <!-- Payment method badge -->
                                <div v-if="p.paymentMethod === 'CASH'" class="flex items-center gap-1.5 text-xs text-yellow-700 bg-yellow-50 border border-yellow-200 px-2.5 py-1 rounded-md">
                                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                                    </svg>
                                    เงินสด
                                </div>
                                <div v-else-if="p.paymentMethod === 'FRIEND_PAID'" class="flex items-center gap-1.5 text-xs text-blue-700 bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-md">
                                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                                    </svg>
                                    เพื่อนร่วมทางจ่ายให้
                                </div>
                                <div v-else class="flex items-center gap-1.5 text-xs text-purple-700 bg-purple-50 border border-purple-200 px-2.5 py-1 rounded-md">
                                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                    โอนเงิน
                                </div>
                                <!-- Amount + status -->
                                <div class="flex items-center gap-2">
                                    <span class="text-sm font-semibold text-gray-900">฿{{ (paymentModalRoute.pricePerSeat * p.seats).toLocaleString() }}</span>
                                    <span class="flex items-center gap-1 px-2 py-0.5 text-xs text-green-700 bg-green-100 rounded-full font-medium">
                                        <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                                        </svg>
                                        ชำระแล้ว
                                    </span>
                                </div>
                            </div>
                        </div>
                    </template>

                    <!-- ===== INTERACTIVE MODE ===== -->
                    <template v-else>
                    <div v-for="p in paymentModalRoute?.passengers" :key="p.id"
                        class="p-4 border rounded-lg transition-colors"
                        :class="slipRejectMap[p.id] ? 'border-red-300 bg-red-50' : paymentVerifyMap[p.id] ? 'border-green-300 bg-green-50' : 'border-gray-200'">
                        <!-- Passenger info -->
                        <div class="flex items-center gap-3 mb-3">
                            <img :src="p.image" :alt="p.name" class="w-10 h-10 rounded-full object-cover" />
                            <div class="flex-1 min-w-0">
                                <div class="font-medium text-gray-900 text-sm truncate">{{ p.name }}</div>
                                <div class="text-xs text-gray-500">{{ p.seats }} ที่นั่ง · ฿{{ (paymentModalRoute.pricePerSeat * p.seats).toLocaleString() }}</div>
                            </div>
                            <!-- ปุ่มใบเสร็จ — แสดงเมื่อกด "ยืนยันถึงที่หมาย" แล้วเท่านั้น -->
                            <button v-if="confirmedVerifyHistory[paymentModalRoute?.id]?.[p.id]" @click="showReceipt(p)"
                                class="flex items-center gap-1.5 px-2.5 py-1.5 text-xs text-green-700 border border-green-300 rounded-md hover:bg-green-100 transition-colors flex-shrink-0"
                                title="ดู/ส่งใบเสร็จ">
                                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                                ใบเสร็จ
                            </button>
                        </div>
                        <!-- FRIEND_PAID: เพื่อนร่วมทางจ่ายให้ -->
                        <div v-if="p.paymentMethod === 'FRIEND_PAID'"
                            class="flex items-center justify-between gap-3 px-3 py-2 bg-blue-50 border border-blue-200 rounded-md">
                            <div class="flex items-center gap-2">
                                <svg class="w-4 h-4 text-blue-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                                </svg>
                                <span class="text-sm text-blue-800 font-medium">เพื่อนร่วมทางชำระให้</span>
                            </div>
                            <label class="flex items-center gap-2 cursor-pointer flex-shrink-0">
                                <input type="checkbox" :checked="paymentVerifyMap[p.id]"
                                    :disabled="lockedVerifyMap[p.id]"
                                    @change="setVerify(p.id, $event.target.checked)"
                                    :class="['w-5 h-5 rounded text-blue-600', lockedVerifyMap[p.id] ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer']" />
                                <span class="text-sm text-gray-700 whitespace-nowrap">ยืนยันแล้ว</span>
                            </label>
                        </div>
                        <!-- CASH payment -->
                        <div v-else-if="p.paymentMethod === 'CASH'" class="flex items-center gap-3">
                            <div class="flex items-center gap-2 px-3 py-2 bg-yellow-50 border border-yellow-200 rounded-md flex-1">
                                <svg class="w-4 h-4 text-yellow-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                                </svg>
                                <span class="text-sm text-yellow-800 font-medium">ชำระเงินสด</span>
                            </div>
                            <label class="flex items-center gap-2 cursor-pointer flex-shrink-0">
                                <input type="checkbox" :checked="paymentVerifyMap[p.id]"
                                    :disabled="lockedVerifyMap[p.id]"
                                    @change="setVerify(p.id, $event.target.checked)"
                                    :class="['w-5 h-5 rounded text-green-600', lockedVerifyMap[p.id] ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer']" />
                                <span class="text-sm text-gray-700 whitespace-nowrap">รับเงินสดแล้ว</span>
                            </label>
                        </div>
                        <!-- SLIP payment -->
                        <div v-else-if="p.paymentMethod === 'SLIP'">
                            <!-- สถานะปฏิเสธแล้ว -->
                            <div v-if="slipRejectMap[p.id]"
                                class="px-3 py-2 bg-red-50 border border-red-200 rounded-md space-y-1">
                                <div class="flex items-center gap-2">
                                    <svg class="w-4 h-4 text-red-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    </svg>
                                    <span class="text-sm text-red-700 font-medium">สลีปไม่ถูกต้อง — รอผู้โดยสารส่งหลักฐานใหม่</span>
                                </div>
                                <p v-if="slipRejectReasonMap[p.id]" class="text-xs text-red-500 pl-6">
                                    เหตุผล: {{ slipRejectReasonMap[p.id] }}
                                </p>
                            </div>
                            <!-- สถานะปกติ -->
                            <div v-else>
                                <div class="flex items-center gap-3">
                                    <div class="flex items-center gap-2 px-3 py-2 bg-blue-50 border border-blue-200 rounded-md flex-1">
                                        <svg class="w-4 h-4 text-blue-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                        </svg>
                                        <span class="text-sm text-blue-800 font-medium">โอนเงิน</span>
                                        <span v-if="p.paymentSlipUrl" class="text-xs text-blue-600">(มีสลีป)</span>
                                        <span v-else class="text-xs text-gray-400">(ยังไม่มีสลีป)</span>
                                    </div>
                                    <div class="flex items-center gap-2 flex-shrink-0">
                                        <!-- ดูสลีป -->
                                        <button v-if="p.paymentSlipUrl" @click="slipPreviewUrl = p.paymentSlipUrl"
                                            class="p-1.5 text-blue-600 border border-blue-200 rounded-md hover:bg-blue-50 transition-colors"
                                            title="ดูสลีป">
                                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                            </svg>
                                        </button>
                                        <!-- ปุ่มปฏิเสธสลีป -->
                                        <button v-if="p.paymentSlipUrl && !lockedVerifyMap[p.id] && pendingRejectPassengerId !== p.id"
                                            @click="startRejectSlip(p.id)"
                                            class="p-1.5 text-red-500 border border-red-200 rounded-md hover:bg-red-50 transition-colors"
                                            title="สลีปไม่ถูกต้อง">
                                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                            </svg>
                                        </button>
                                        <!-- checkbox ยืนยันสลีป -->
                                        <label class="flex items-center gap-2 cursor-pointer">
                                            <input type="checkbox" :checked="paymentVerifyMap[p.id]"
                                                :disabled="!p.paymentSlipUrl || lockedVerifyMap[p.id]"
                                                @change="setVerify(p.id, $event.target.checked)"
                                                :class="['w-5 h-5 rounded', !p.paymentSlipUrl || lockedVerifyMap[p.id] ? 'opacity-40 cursor-not-allowed' : 'text-green-600 cursor-pointer']" />
                                            <span :class="['text-sm whitespace-nowrap', p.paymentSlipUrl ? 'text-gray-700' : 'text-gray-400']">สลีปถูกต้อง</span>
                                        </label>
                                    </div>
                                </div>
                                <!-- Inline reject reason form -->
                                <div v-if="pendingRejectPassengerId === p.id"
                                    class="mt-2 p-3 bg-red-50 border border-red-200 rounded-lg space-y-2.5">
                                    <p class="text-xs font-semibold text-red-700 flex items-center gap-1.5">
                                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
                                        </svg>
                                        ระบุเหตุผลที่ปฏิเสธสลีป
                                    </p>
                                    <!-- Styled dropdown -->
                                    <div class="relative">
                                        <select v-model="rejectReasonInput"
                                            class="w-full appearance-none text-sm border border-red-300 rounded-lg px-3 py-2 bg-white text-gray-800 focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-red-400 cursor-pointer pr-8">
                                            <option v-for="r in REJECT_REASONS" :key="r" :value="r">{{ r }}</option>
                                        </select>
                                        <div class="absolute inset-y-0 right-0 flex items-center pr-2.5 pointer-events-none">
                                            <svg class="w-4 h-4 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                                            </svg>
                                        </div>
                                    </div>
                                    <!-- Additional note -->
                                    <textarea v-model="rejectNoteInput" rows="2"
                                        placeholder="อธิบายเพิ่มเติม เช่น ยอดที่โอนมา ฿450 แต่ต้องชำระ ฿500 (ไม่บังคับ)"
                                        class="w-full text-sm border border-red-200 rounded-lg px-3 py-2 bg-white text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-red-400 resize-none" />
                                    <div class="flex gap-2 justify-end">
                                        <button @click="cancelRejectSlip"
                                            class="px-3 py-1.5 text-xs text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
                                            ยกเลิก
                                        </button>
                                        <button @click="confirmRejectSlip(p.id)"
                                            class="px-3 py-1.5 text-xs text-white bg-red-500 rounded-lg hover:bg-red-600 font-medium transition-colors">
                                            ยืนยันการปฏิเสธ
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    </template><!-- end interactive mode -->
                </div>
                <!-- Footer -->
                <div class="px-6 py-4 border-t border-gray-200 space-y-3">
                    <!-- READ-ONLY footer -->
                    <template v-if="isReadOnlyMode">
                        <div class="flex items-center justify-between gap-3">
                            <div class="flex items-center gap-2 text-sm text-green-700 font-medium">
                                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                ชำระเงินครบทั้งหมดแล้ว
                            </div>
                            <button @click="isPaymentModalVisible = false"
                                class="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50">
                                ปิด
                            </button>
                        </div>
                    </template>
                    <!-- INTERACTIVE footer -->
                    <template v-else>
                        <!-- warning กรณียังมีคนที่ไม่ได้ยืนยัน -->
                        <div v-if="unverifiedCount > 0"
                            class="flex items-start gap-2 px-3 py-2 text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded-md">
                            <svg class="w-4 h-4 mt-0.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
                            </svg>
                            <span>ยังมี <strong>{{ unverifiedCount }} คน </strong>ที่ยังไม่ได้ยืนยันการชำระเงิน — กดยืนยันถึงที่หมายได้เลย หรือรอให้ครบก่อน</span>
                        </div>
                        <div class="flex items-center justify-between gap-3">
                            <p class="text-xs text-gray-500">
                                ยืนยันแล้ว {{ verifiedCount }}/{{ paymentModalRoute?.passengers?.length ?? 0 }} คน
                                <span v-if="Object.values(slipRejectMap).some(Boolean)" class="text-red-500 ml-1">
                                    · ปฏิเสธสลีป {{ Object.values(slipRejectMap).filter(Boolean).length }} คน
                                </span>
                            </p>
                            <div class="flex gap-3">
                                <button @click="isPaymentModalVisible = false"
                                    class="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50">
                                    ปิด
                                </button>
                                <button @click="completeWithPaymentVerification"
                                    :class="['px-4 py-2 text-sm text-white rounded-md transition-colors font-medium', allPaymentsVerified ? 'bg-green-600 hover:bg-green-700' : 'bg-amber-500 hover:bg-amber-600']">
                                    {{ paymentModalRoute?.status === 'completed' ? 'บันทึกการยืนยัน' : 'ยืนยันถึงที่หมาย' }}
                                </button>
                            </div>
                        </div>
                    </template>
                </div>
            </div>
        </div>

        <!-- Receipt Modal -->
        <div v-if="isReceiptModalVisible && receiptPassenger" class="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 px-4"
            @click.self="isReceiptModalVisible = false">
            <div class="bg-white rounded-xl shadow-2xl w-full max-w-sm overflow-hidden max-h-[90vh] flex flex-col">
                <!-- Receipt header -->
                <div :class="['px-6 py-5 text-white text-center flex-shrink-0', receiptPassenger.paymentMethod === 'FRIEND_PAID' ? 'bg-blue-600' : 'bg-green-600']">
                    <svg class="w-10 h-10 mx-auto mb-2 opacity-90" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <h3 class="text-lg font-bold">ใบสำคัญรับเงิน</h3>
                    <p class="text-xs opacity-75 mt-0.5">เลขที่อ้างอิง: {{ receiptPassenger.id?.slice(-8).toUpperCase() }}</p>
                </div>

                <!-- Receipt body -->
                <div class="px-6 py-4 space-y-0 text-sm overflow-y-auto flex-1">
                    <!-- กรณีเพื่อนร่วมทางจ่ายให้ -->
                    <div v-if="receiptPassenger.paymentMethod === 'FRIEND_PAID'"
                        class="mb-3 px-3 py-2 bg-blue-50 border border-blue-200 rounded-md flex items-start gap-2">
                        <svg class="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <p class="text-xs text-blue-700">เพื่อนร่วมทางชำระค่าโดยสารให้ผู้โดยสารท่านนี้</p>
                    </div>

                    <!-- Section: ข้อมูลการเดินทาง -->
                    <div class="space-y-2.5 pb-3 border-b border-dashed border-gray-200">
                        <div class="flex justify-between gap-2">
                            <span class="text-gray-500 flex-shrink-0">วันที่</span>
                            <span class="font-medium text-gray-900 text-right">{{ paymentModalRoute?.date }} · {{ paymentModalRoute?.time }}</span>
                        </div>
                        <div class="flex justify-between gap-2">
                            <span class="text-gray-500 flex-shrink-0">เส้นทาง</span>
                            <span class="font-medium text-gray-900 text-right max-w-[60%]">{{ paymentModalRoute?.origin }} → {{ paymentModalRoute?.destination }}</span>
                        </div>
                        <div class="flex justify-between gap-2">
                            <span class="text-gray-500 flex-shrink-0">จุดรับ</span>
                            <span class="font-medium text-gray-900 text-right max-w-[60%]">{{ receiptPassenger.pickupLocation || '-' }}</span>
                        </div>
                        <div class="flex justify-between gap-2">
                            <span class="text-gray-500 flex-shrink-0">จุดส่ง</span>
                            <span class="font-medium text-gray-900 text-right max-w-[60%]">{{ receiptPassenger.dropoffLocation || '-' }}</span>
                        </div>
                    </div>

                    <!-- Section: ข้อมูลคู่สัญญา -->
                    <div class="space-y-2.5 py-3 border-b border-dashed border-gray-200">
                        <div class="flex justify-between gap-2">
                            <span class="text-gray-500 flex-shrink-0">ผู้โดยสาร</span>
                            <span class="font-medium text-gray-900">{{ receiptPassenger.name }}</span>
                        </div>
                        <div class="flex justify-between gap-2">
                            <span class="text-gray-500 flex-shrink-0">ผู้ขับ</span>
                            <span class="font-medium text-gray-900">{{ paymentModalRoute?.driverName }}</span>
                        </div>
                    </div>

                    <!-- Section: ค่าโดยสาร -->
                    <div class="space-y-2.5 py-3 border-b border-dashed border-gray-200">
                        <div class="flex justify-between">
                            <span class="text-gray-500">จำนวนที่นั่ง</span>
                            <span class="font-medium text-gray-900">{{ receiptPassenger.seats }} ที่นั่ง</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-500">ราคาต่อที่นั่ง</span>
                            <span class="font-medium text-gray-900">฿{{ (paymentModalRoute?.pricePerSeat ?? 0).toLocaleString() }}</span>
                        </div>
                        <div class="flex justify-between text-base">
                            <span class="font-semibold text-gray-800">รวมทั้งสิ้น</span>
                            <span :class="['font-bold', receiptPassenger.paymentMethod === 'FRIEND_PAID' ? 'text-blue-700' : 'text-green-700']">
                                ฿{{ ((paymentModalRoute?.pricePerSeat ?? 0) * receiptPassenger.seats).toLocaleString() }}
                            </span>
                        </div>
                    </div>

                    <!-- Section: วิธีชำระเงิน -->
                    <div class="space-y-2 py-3">
                        <div class="flex justify-between items-start gap-2">
                            <span class="text-gray-500 flex-shrink-0">ชำระโดย</span>
                            <div class="text-right">
                                <span v-if="receiptPassenger.paymentMethod === 'CASH'"
                                    class="font-medium text-gray-900">เงินสด</span>
                                <span v-else-if="receiptPassenger.paymentMethod === 'FRIEND_PAID'"
                                    class="font-medium text-blue-700">เพื่อนร่วมทางชำระให้</span>
                                <div v-else class="space-y-0.5">
                                    <p class="font-medium text-gray-900">โอนผ่านธนาคาร</p>
                                    <p class="text-xs text-gray-500">{{ receiptPassenger.bankName }}</p>
                                    <p class="text-xs text-gray-500">ชื่อบัญชี: {{ receiptPassenger.bankAccountName }}</p>
                                    <p class="text-xs font-mono text-gray-700">เลขบัญชี: {{ receiptPassenger.bankAccount }}</p>
                                </div>
                            </div>
                        </div>
                        <div class="flex justify-between gap-2 text-xs text-gray-400">
                            <span>ยืนยันเมื่อ</span>
                            <span>{{ confirmedAtMap[paymentModalRoute?.id]?.[receiptPassenger.id]
                                ? new Date(confirmedAtMap[paymentModalRoute.id][receiptPassenger.id]).toLocaleString('th-TH', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
                                : '-' }}</span>
                        </div>
                    </div>
                </div>

                <!-- Receipt footer -->
                <div class="px-6 pb-5 flex-shrink-0 flex gap-3">
                    <button @click="isReceiptModalVisible = false"
                        class="flex-1 px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50">
                        ปิด
                    </button>
                    <button @click="downloadReceipt"
                        class="flex-1 flex items-center justify-center gap-1.5 px-4 py-2 text-sm text-white bg-green-600 rounded-md hover:bg-green-700 font-medium">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                        ดาวน์โหลด
                    </button>
                </div>
            </div>
        </div>

        <!-- Slip image fullscreen preview -->
        <div v-if="slipPreviewUrl" class="fixed inset-0 z-[60] flex items-center justify-center bg-black/80"
            @click="slipPreviewUrl = null">
            <div class="relative">
                <img :src="slipPreviewUrl" alt="Slip Preview"
                    class="max-w-sm max-h-[85vh] object-contain rounded-lg shadow-2xl" />
                <button @click.stop="slipPreviewUrl = null"
                    class="absolute -top-3 -right-3 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-md text-gray-700 hover:text-gray-900">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import html2canvas from 'html2canvas'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import buddhistEra from 'dayjs/plugin/buddhistEra'
import ConfirmModal from '~/components/ConfirmModal.vue'
import { useToast } from '~/composables/useToast'

dayjs.locale('th')
dayjs.extend(buddhistEra)

const { $api } = useNuxtApp()
const { toast } = useToast()

// --- State Management ---
const activeTab = ref('pending')
const selectedTripId = ref(null)
const isLoading = ref(false)
const mapContainer = ref(null)
const allTrips = ref([])
const myRoutes = ref([])

// ---------- Google Maps states ----------
let gmap = null
let activePolyline = null
let startMarker = null
let endMarker = null
let geocoder = null
let placesService = null
const mapReady = ref(false)
const GMAPS_CB = '__gmapsReady__'
// NEW: เก็บหมุดจุดแวะ
let stopMarkers = []

const tabs = [
    { status: 'pending', label: 'รอดำเนินการ' },
    { status: 'confirmed', label: 'ยืนยันแล้ว' },
    { status: 'rejected', label: 'ปฏิเสธ' },
    { status: 'cancelled', label: 'ยกเลิก' },
    { status: 'all', label: 'ทั้งหมด' },
    { status: 'myRoutes', label: 'เส้นทางของฉัน' },
]

definePageMeta({ middleware: 'auth' })

// --- Helpers ---
function cleanAddr(a) {
    return (a || '')
        .replace(/,?\s*(Thailand|ไทย|ประเทศ)\s*$/i, '')
        .replace(/\s{2,}/g, ' ')
        .trim()
}

const reasonLabelMap = {
    CHANGE_OF_PLAN: 'เปลี่ยนแผน/มีธุระกะทันหัน',
    FOUND_ALTERNATIVE: 'พบวิธีเดินทางอื่นแล้ว',
    DRIVER_DELAY: 'คนขับล่าช้าหรือเลื่อนเวลา',
    PRICE_ISSUE: 'ราคาหรือค่าใช้จ่ายไม่เหมาะสม',
    WRONG_LOCATION: 'เลือกจุดรับ–ส่งผิด',
    DUPLICATE_OR_WRONG_DATE: 'จองซ้ำหรือจองผิดวัน',
    SAFETY_CONCERN: 'กังวลด้านความปลอดภัย',
    WEATHER_OR_FORCE_MAJEURE: 'สภาพอากาศ/เหตุสุดวิสัย',
    COMMUNICATION_ISSUE: 'สื่อสารไม่สะดวก/ติดต่อไม่ได้',
}
function reasonLabel(v) { return reasonLabelMap[v] || v }

// --- Computed ---
const filteredTrips = computed(() => {
    if (activeTab.value === 'all') return allTrips.value
    return allTrips.value.filter(trip => trip.status === activeTab.value)
})

// สำหรับหัวข้อบนแผนที่
const selectedLabel = computed(() => {
    if (activeTab.value === 'myRoutes') {
        const r = myRoutes.value.find(x => x.id === selectedTripId.value)
        return r ? `${r.origin} → ${r.destination}` : null
    }
    const t = allTrips.value.find(x => x.id === selectedTripId.value)
    return t ? `${t.origin} → ${t.destination}` : null
})

// --- Methods ---
async function fetchMyRoutes() {
    isLoading.value = true
    try {
        const routes = await $api('/routes/me')

        const allowedRouteStatuses = new Set(['AVAILABLE', 'FULL', 'IN_TRANSIT', 'COMPLETED'])

        const formatted = []
        const ownRoutes = []

        for (const r of routes) {
            const carDetailsList = []
            const routeStatus = String(r.status || '').toUpperCase()
            if (!allowedRouteStatuses.has(routeStatus)) continue

            if (r.vehicle) {
                carDetailsList.push(`${r.vehicle.vehicleModel} (${r.vehicle.vehicleType})`)
                if (Array.isArray(r.vehicle.amenities) && r.vehicle.amenities.length > 0) {
                    carDetailsList.push(...r.vehicle.amenities)
                }
            } else {
                carDetailsList.push('ไม่มีข้อมูลรถ')
            }

            const start = r.startLocation
            const end = r.endLocation
            const coords = [[start.lat, start.lng], [end.lat, end.lng]]

            // stops / stopsCoords จาก waypoints
            const wp = r.waypoints || {}
            const baseList = (Array.isArray(wp.used) && wp.used.length
                ? wp.used
                : Array.isArray(wp.requested) ? wp.requested : [])
            const orderedList = (Array.isArray(wp.optimizedOrder) && wp.optimizedOrder.length === baseList.length)
                ? wp.optimizedOrder.map(i => baseList[i])
                : baseList

            const stops = orderedList.map(p => {
                const name = p?.name || ''
                const address = cleanAddr(p?.address || '')
                const fallback = (p?.lat != null && p?.lng != null) ? `(${p.lat.toFixed(6)}, ${p.lng.toFixed(6)})` : ''
                const title = name || fallback
                return address ? `${title} — ${address}` : title
            }).filter(Boolean)

            const stopsCoords = orderedList
                .map(p => (p && typeof p.lat === 'number' && typeof p.lng === 'number')
                    ? { lat: p.lat, lng: p.lng, name: p.name || '', address: p.address || '' }
                    : null
                )
                .filter(Boolean)

            // แปลงเป็น "คำขอจอง" ต่อ booking
            for (const b of (r.bookings || [])) {
                formatted.push({
                    id: b.id,
                    status: (b.status || '').toLowerCase(),
                    origin: start?.name || `(${Number(start.lat).toFixed(2)}, ${Number(start.lng).toFixed(2)})`,
                    destination: end?.name || `(${Number(end.lat).toFixed(2)}, ${Number(end.lng).toFixed(2)})`,
                    originHasName: !!start?.name,
                    destinationHasName: !!end?.name,
                    pickupPoint: b.pickupLocation?.name || '-',
                    date: dayjs(r.departureTime).format('D MMMM BBBB'),
                    time: dayjs(r.departureTime).format('HH:mm น.'),
                    price: (r.pricePerSeat || 0) * (b.numberOfSeats || 0),
                    seats: b.numberOfSeats || 0,
                    passenger: {
                        name: `${b.passenger?.firstName || ''} ${b.passenger?.lastName || ''}`.trim() || 'ผู้โดยสาร',
                        image: b.passenger?.profilePicture || `https://ui-avatars.com/api/?name=${encodeURIComponent(b.passenger?.firstName || 'P')}&background=random&size=64`,
                        email: b.passenger?.email || '',
                        isVerified: !!b.passenger?.isVerified,
                        rating: 4.5,
                        reviews: Math.floor(Math.random() * 50) + 5,
                    },
                    coords,
                    polyline: r.routePolyline || null,
                    stops,
                    stopsCoords,
                    cancelReason: b.cancelReason || null,
                    carDetails: carDetailsList,
                    conditions: r.conditions,
                    photos: r.vehicle?.photos || [],
                    originAddress: start?.address ? cleanAddr(start.address) : null,
                    destinationAddress: end?.address ? cleanAddr(end.address) : null,
                    durationText: (typeof r.duration === 'string' ? formatDuration(r.duration) : r.duration) || (r.durationSeconds ? `${Math.round(r.durationSeconds / 60)} นาที` : '-'),
                    distanceText: (typeof r.distance === 'string' ? formatDistance(r.distance) : r.distance) || (r.distanceMeters ? `${(r.distanceMeters / 1000).toFixed(1)} กม.` : '-'),
                })
            }

            // เก็บ “เส้นทางของฉัน”
            const confirmedBookings = (r.bookings || []).filter(
                b => (b.status || '').toUpperCase() === 'CONFIRMED'
            )
            ownRoutes.push({
                id: r.id,
                status: (r.status || '').toLowerCase(),
                origin: start?.name || `(${Number(start.lat).toFixed(2)}, ${Number(start.lng).toFixed(2)})`,
                destination: end?.name || `(${Number(end.lat).toFixed(2)}, ${Number(end.lng).toFixed(2)})`,
                originAddress: start?.address ? cleanAddr(start.address) : null,
                destinationAddress: end?.address ? cleanAddr(end.address) : null,
                date: dayjs(r.departureTime).format('D MMMM BBBB'),
                time: dayjs(r.departureTime).format('HH:mm น.'),
                pricePerSeat: r.pricePerSeat || 0,
                availableSeats: r.availableSeats ?? 0,
                coords: [[start.lat, start.lng], [end.lat, end.lng]],
                polyline: r.routePolyline || null,
                stops,
                stopsCoords,
                driverName: `${r.driver?.firstName || ''} ${r.driver?.lastName || ''}`.trim() || 'คนขับ',
                licensePlate: r.vehicle?.licensePlate || '-',
                vehicleModel: r.vehicle?.vehicleModel || '-',
                carDetails: (r.vehicle
                    ? [`${r.vehicle.vehicleModel} (${r.vehicle.vehicleType})`, ...(r.vehicle.amenities || [])]
                    : ['ไม่มีข้อมูลรถ']),
                photos: r.vehicle?.photos || [],
                conditions: r.conditions || '',
                passengers: confirmedBookings.map((b, idx) => ({
                    id: b.id,
                    seats: b.numberOfSeats || 0,
                    status: 'confirmed',
                    name: `${b.passenger?.firstName || ''} ${b.passenger?.lastName || ''}`.trim() || 'ผู้โดยสาร',
                    image: b.passenger?.profilePicture || `https://ui-avatars.com/api/?name=${encodeURIComponent(b.passenger?.firstName || 'P')}&background=random&size=64`,
                    email: b.passenger?.email || '',
                    isVerified: !!b.passenger?.isVerified,
                    rating: 4.5,
                    reviews: Math.floor(Math.random() * 50) + 5,
                    pickupLocation: b.pickupLocation?.name || b.pickupLocation?.address || '-',
                    dropoffLocation: b.dropoffLocation?.name || b.dropoffLocation?.address || '-',
                    // --- MOCK payment data (replace with real fields when backend is ready) ---
                    paymentMethod: idx % 3 === 2 ? 'FRIEND_PAID' : idx % 2 === 0 ? 'CASH' : 'SLIP',
                    paymentStatus: 'SUBMITTED',
                    paymentSlipUrl: idx % 3 !== 2 && idx % 2 !== 0 ? 'https://placehold.co/400x600/22c55e/ffffff?text=สลีปโอนเงิน' : null,
                    bankName: idx % 2 !== 0 ? 'ธนาคารกสิกรไทย (KBank)' : null,
                    bankAccount: idx % 2 !== 0 ? '123-4-56789-0' : null,
                    bankAccountName: idx % 2 !== 0 ? 'สมชาย ใจดี' : null,
                })),
                durationText: (typeof r.duration === 'string' ? formatDuration(r.duration) : r.duration) || (r.durationSeconds ? `${Math.round(r.durationSeconds / 60)} นาที` : '-'),
                distanceText: (typeof r.distance === 'string' ? formatDistance(r.distance) : r.distance) || (r.distanceMeters ? `${(r.distanceMeters / 1000).toFixed(1)} กม.` : '-'),
            })
        }

        allTrips.value = formatted
        myRoutes.value = ownRoutes

        // รอแผนที่พร้อม แล้ว reverse เฉพาะกรณีที่ backend ไม่มี name (เฉพาะ list คำขอจอง)
        await waitMapReady()
        const jobs = allTrips.value.map(async (t, idx) => {
            const [o, d] = await Promise.all([
                reverseGeocode(t.coords[0][0], t.coords[0][1]),
                reverseGeocode(t.coords[1][0], t.coords[1][1])
            ])
            const oParts = await extractNameParts(o)
            const dParts = await extractNameParts(d)
            if (!allTrips.value[idx].originHasName && oParts.name) {
                allTrips.value[idx].origin = oParts.name
            }
            if (!allTrips.value[idx].destinationHasName && dParts.name) {
                allTrips.value[idx].destination = dParts.name
            }
        })
        await Promise.allSettled(jobs)

    } catch (error) {
        console.error('Failed to fetch routes:', error)
        allTrips.value = []
        myRoutes.value = []
        toast.error('เกิดข้อผิดพลาด', error?.data?.message || 'ไม่สามารถโหลดข้อมูลได้')
    } finally {
        isLoading.value = false
    }
}

const getTripCount = (status) => {
    if (status === 'all') return allTrips.value.length
    if (status === 'myRoutes') return myRoutes.value.length
    return allTrips.value.filter(trip => trip.status === status).length
}

const toggleTripDetails = (id) => {
    // หา item ตามแท็บที่เปิดอยู่ เพื่ออัปเดตแผนที่
    const item = activeTab.value === 'myRoutes'
        ? myRoutes.value.find(r => r.id === id)
        : allTrips.value.find(t => t.id === id)
    if (item) updateMap(item)

    selectedTripId.value = (selectedTripId.value === id) ? null : id
}

// ---------- Google Maps helpers ----------
function waitMapReady() {
    return new Promise((resolve) => {
        if (mapReady.value) return resolve(true)
        const t = setInterval(() => {
            if (mapReady.value) { clearInterval(t); resolve(true) }
        }, 50)
    })
}

function reverseGeocode(lat, lng) {
    return new Promise((resolve) => {
        if (!geocoder) return resolve(null)
        geocoder.geocode({ location: { lat, lng } }, (results, status) => {
            if (status !== 'OK' || !results?.length) return resolve(null)
            resolve(results[0])
        })
    })
}

async function extractNameParts(geocodeResult) {
    if (!geocodeResult) return { name: null, area: null }
    const comps = geocodeResult.address_components || []
    const types = geocodeResult.types || []
    const isPoi = types.includes('point_of_interest') || types.includes('establishment') || types.includes('premise')

    let name = null
    if (isPoi && geocodeResult.place_id) {
        const poiName = await getPlaceName(geocodeResult.place_id)
        if (poiName) name = poiName
    }
    if (!name) {
        const streetNumber = comps.find(c => c.types.includes('street_number'))?.long_name
        const route = comps.find(c => c.types.includes('route'))?.long_name
        name = (streetNumber && route) ? `${streetNumber} ${route}` : (route || geocodeResult.formatted_address || null)
    }
    if (name) name = name.replace(/,?\s*(Thailand|ไทย)\s*$/i, '')
    return { name }
}

function getPlaceName(placeId) {
    return new Promise((resolve) => {
        if (!placesService || !placeId) return resolve(null)
        placesService.getDetails({ placeId, fields: ['name'] }, (place, status) => {
            if (status === google.maps.places.PlacesServiceStatus.OK && place?.name) resolve(place.name)
            else resolve(null)
        })
    })
}

async function updateMap(trip) {
    if (!trip) return
    await waitMapReady()
    if (!gmap) return

    // cleanup เดิม
    if (activePolyline) { activePolyline.setMap(null); activePolyline = null }
    if (startMarker) { startMarker.setMap(null); startMarker = null }
    if (endMarker) { endMarker.setMap(null); endMarker = null }
    if (stopMarkers.length) {
        stopMarkers.forEach(m => m.setMap(null))
        stopMarkers = []
    }

    const start = { lat: Number(trip.coords[0][0]), lng: Number(trip.coords[0][1]) }
    const end = { lat: Number(trip.coords[1][0]), lng: Number(trip.coords[1][1]) }

    startMarker = new google.maps.Marker({ position: start, map: gmap, label: 'A' })
    endMarker = new google.maps.Marker({ position: end, map: gmap, label: 'B' })

    // หมุดจุดแวะ
    if (Array.isArray(trip.stopsCoords) && trip.stopsCoords.length) {
        stopMarkers = trip.stopsCoords.map((s, idx) => new google.maps.Marker({
            position: { lat: s.lat, lng: s.lng },
            map: gmap,
            icon: 'http://maps.google.com/mapfiles/ms/icons/green-dot.png',
            title: s.name || s.address || `จุดแวะ ${idx + 1}`
        }))
    }

    // polyline
    if (trip.polyline && google.maps.geometry?.encoding) {
        const path = google.maps.geometry.encoding.decodePath(trip.polyline)
        activePolyline = new google.maps.Polyline({
            path,
            map: gmap,
            strokeColor: '#2563eb',
            strokeOpacity: 0.9,
            strokeWeight: 5,
        })
        const bounds = new google.maps.LatLngBounds()
        path.forEach(p => bounds.extend(p))
        if (trip.stopsCoords?.length) {
            trip.stopsCoords.forEach(s => bounds.extend(new google.maps.LatLng(s.lat, s.lng)))
        }
        gmap.fitBounds(bounds)
    } else {
        const bounds = new google.maps.LatLngBounds()
        bounds.extend(start)
        bounds.extend(end)
        if (trip.stopsCoords?.length) {
            trip.stopsCoords.forEach(s => bounds.extend(new google.maps.LatLng(s.lat, s.lng)))
        }
        gmap.fitBounds(bounds)
    }
}

// --- Modal ---
const isModalVisible = ref(false)
const tripToAction = ref(null)
const modalContent = ref({ title: '', message: '', confirmText: '', action: null, variant: 'danger' })

// --- Payment verification modal state ---
const isPaymentModalVisible = ref(false)
const paymentModalRoute = ref(null)
const paymentVerifyMap = ref({})
const lockedVerifyMap = ref({}) // { [passengerId]: boolean } — ล็อกหลังจากยืนยันแล้ว ห้าม uncheck
const slipPreviewUrl = ref(null)
const verifyHistory = ref({}) // { [routeId]: { [passengerId]: boolean } } — state ล่าสุดใน session
const confirmedVerifyHistory = ref({}) // { [routeId]: { [passengerId]: boolean } } — บันทึกหลัง "ยืนยันถึงที่หมาย"
const confirmedAtMap = ref({}) // { [routeId]: { [passengerId]: string } } — เวลาที่ยืนยัน
const slipRejectMap = ref({}) // { [passengerId]: boolean }
const slipRejectReasonMap = ref({}) // { [passengerId]: string } — เหตุผลที่ปฏิเสธ
const rejectHistory = ref({}) // { [routeId]: { [passengerId]: boolean } }
const rejectReasonHistory = ref({}) // { [routeId]: { [passengerId]: string } }
const pendingRejectPassengerId = ref(null) // รอกรอกเหตุผลก่อน confirm reject
const rejectReasonInput = ref('')
const rejectNoteInput = ref('')
const isReceiptModalVisible = ref(false)
const receiptPassenger = ref(null)

const REJECT_REASONS = [
    'ยอดเงินไม่ถูกต้อง',
    'ชื่อผู้รับเงินไม่ตรง',
    'สลีปเก่า/ใช้ซ้ำ',
    'รูปภาพไม่ชัดเจน',
    'สงสัยสลีปปลอม',
    'อื่นๆ',
]

// ใช้ method แทน inline mutation เพื่อให้ Vue detect การเปลี่ยนแปลงได้ทั้ง check และ uncheck
const setVerify = (passengerId, checked) => {
    paymentVerifyMap.value = { ...paymentVerifyMap.value, [passengerId]: checked }
    if (paymentModalRoute.value?.id) {
        verifyHistory.value[paymentModalRoute.value.id] = { ...paymentVerifyMap.value }
    }
    // ไม่ lock ทันที — lock จะเกิดขึ้นเมื่อกด "ยืนยันถึงที่หมาย" และเปิด modal ครั้งต่อไป
}

const startRejectSlip = (passengerId) => {
    pendingRejectPassengerId.value = passengerId
    rejectReasonInput.value = REJECT_REASONS[0]
    rejectNoteInput.value = ''
}

const cancelRejectSlip = () => {
    pendingRejectPassengerId.value = null
    rejectReasonInput.value = ''
    rejectNoteInput.value = ''
}

const confirmRejectSlip = (passengerId) => {
    const base = rejectReasonInput.value.trim() || REJECT_REASONS[0]
    const note = rejectNoteInput.value.trim()
    const reason = note ? `${base} — ${note}` : base
    slipRejectMap.value = { ...slipRejectMap.value, [passengerId]: true }
    slipRejectReasonMap.value = { ...slipRejectReasonMap.value, [passengerId]: reason }
    lockedVerifyMap.value = { ...lockedVerifyMap.value, [passengerId]: true }
    if (paymentModalRoute.value?.id) {
        const routeId = paymentModalRoute.value.id
        rejectHistory.value[routeId] = { ...(rejectHistory.value[routeId] || {}), [passengerId]: true }
        rejectReasonHistory.value[routeId] = { ...(rejectReasonHistory.value[routeId] || {}), [passengerId]: reason }
    }
    pendingRejectPassengerId.value = null
    rejectReasonInput.value = ''
    rejectNoteInput.value = ''
    toast.warning('แจ้งผู้โดยสาร', 'แจ้งผู้โดยสารว่าสลีปไม่ถูกต้องแล้ว')
}

const showReceipt = (passenger) => {
    receiptPassenger.value = passenger
    isReceiptModalVisible.value = true
}

const downloadReceipt = async () => {
    if (!receiptPassenger.value || !paymentModalRoute.value) return
    const p = receiptPassenger.value
    const route = paymentModalRoute.value
    const refNo = p.id?.slice(-8).toUpperCase()
    const total = ((route.pricePerSeat ?? 0) * p.seats).toLocaleString()
    const confirmedAt = confirmedAtMap.value[route.id]?.[p.id]
        ? new Date(confirmedAtMap.value[route.id][p.id]).toLocaleString('th-TH', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
        : '-'

    // สร้าง HTML ของใบเสร็จด้วย inline styles ทั้งหมด (html2canvas ต้องการ inline styles)
    const s = {
        wrap: 'font-family:sans-serif;font-size:14px;color:#111;background:#fff;width:400px;border-radius:10px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.12)',
        hd: `background:${p.paymentMethod === 'FRIEND_PAID' ? '#2563eb' : '#16a34a'};color:#fff;text-align:center;padding:22px 20px`,
        hdH: 'font-size:18px;font-weight:700;margin:0 0 4px',
        hdP: 'font-size:11px;opacity:.75;margin:0',
        bd: 'padding:16px 18px',
        note: 'background:#eff6ff;border:1px solid #bfdbfe;border-radius:6px;padding:8px 12px;margin-bottom:14px;font-size:12px;color:#1d4ed8',
        sec: 'border-bottom:1px dashed #d1d5db;padding-bottom:12px;margin-bottom:12px',
        secLast: 'padding-bottom:0',
        row: 'display:flex;justify-content:space-between;gap:12px;margin-bottom:7px',
        rowLast: 'display:flex;justify-content:space-between;gap:12px;margin-bottom:0',
        lbl: 'color:#6b7280;flex-shrink:0',
        val: 'font-weight:500;text-align:right',
        totalLbl: 'font-weight:600;color:#111;flex-shrink:0',
        totalVal: `font-size:15px;font-weight:700;color:${p.paymentMethod === 'FRIEND_PAID' ? '#1d4ed8' : '#16a34a'};text-align:right`,
    }

    let paymentLines = ''
    if (p.paymentMethod === 'CASH') {
        paymentLines = `<div style="${s.rowLast}"><span style="${s.lbl}">ชำระโดย</span><span style="${s.val}">เงินสด</span></div>`
    } else if (p.paymentMethod === 'FRIEND_PAID') {
        paymentLines = `<div style="${s.rowLast}"><span style="${s.lbl}">ชำระโดย</span><span style="${s.val};color:#2563eb">เพื่อนร่วมทางชำระให้</span></div>`
    } else {
        paymentLines = `
        <div style="${s.row}"><span style="${s.lbl}">ชำระโดย</span><span style="${s.val}">โอนผ่านธนาคาร</span></div>
        <div style="${s.row}"><span style="${s.lbl}">ธนาคาร</span><span style="${s.val}">${p.bankName || '-'}</span></div>
        <div style="${s.row}"><span style="${s.lbl}">ชื่อบัญชี</span><span style="${s.val}">${p.bankAccountName || '-'}</span></div>
        <div style="${s.rowLast}"><span style="${s.lbl}">เลขบัญชี</span><span style="${s.val};font-family:monospace">${p.bankAccount || '-'}</span></div>`
    }

    const noteHtml = p.paymentMethod === 'FRIEND_PAID'
        ? `<div style="${s.note}">เพื่อนร่วมทางชำระค่าโดยสารให้ผู้โดยสารท่านนี้</div>`
        : ''

    const el = document.createElement('div')
    el.style.cssText = 'position:fixed;top:-9999px;left:-9999px'
    el.innerHTML = `
    <div style="${s.wrap}">
      <div style="${s.hd}">
        <p style="${s.hdH}">ใบสำคัญรับเงิน</p>
        <p style="${s.hdP}">เลขที่อ้างอิง: ${refNo}</p>
      </div>
      <div style="${s.bd}">
        ${noteHtml}
        <div style="${s.sec}">
          <div style="${s.row}"><span style="${s.lbl}">วันที่</span><span style="${s.val}">${route.date} · ${route.time}</span></div>
          <div style="${s.row}"><span style="${s.lbl}">เส้นทาง</span><span style="${s.val}">${route.origin} → ${route.destination}</span></div>
          <div style="${s.row}"><span style="${s.lbl}">จุดรับ</span><span style="${s.val}">${p.pickupLocation || '-'}</span></div>
          <div style="${s.rowLast}"><span style="${s.lbl}">จุดส่ง</span><span style="${s.val}">${p.dropoffLocation || '-'}</span></div>
        </div>
        <div style="${s.sec}">
          <div style="${s.row}"><span style="${s.lbl}">ผู้โดยสาร</span><span style="${s.val}">${p.name}</span></div>
          <div style="${s.rowLast}"><span style="${s.lbl}">ผู้ขับ</span><span style="${s.val}">${route.driverName}</span></div>
        </div>
        <div style="${s.sec}">
          <div style="${s.row}"><span style="${s.lbl}">จำนวนที่นั่ง</span><span style="${s.val}">${p.seats} ที่นั่ง</span></div>
          <div style="${s.row}"><span style="${s.lbl}">ราคาต่อที่นั่ง</span><span style="${s.val}">฿${(route.pricePerSeat ?? 0).toLocaleString()}</span></div>
          <div style="${s.rowLast}"><span style="${s.totalLbl}">รวมทั้งสิ้น</span><span style="${s.totalVal}">฿${total}</span></div>
        </div>
        <div style="${s.secLast}">
          ${paymentLines}
          <div style="${s.row};margin-top:7px"><span style="${s.lbl}">ยืนยันเมื่อ</span><span style="${s.val}">${confirmedAt}</span></div>
        </div>
      </div>
    </div>`

    document.body.appendChild(el)
    try {
        const canvas = await html2canvas(/** @type {HTMLElement} */ (el.firstElementChild), {
            scale: 2,
            useCORS: true,
            backgroundColor: '#ffffff',
        })
        const link = document.createElement('a')
        link.download = `ใบเสร็จ-${refNo}.png`
        link.href = canvas.toDataURL('image/png')
        link.click()
    } finally {
        document.body.removeChild(el)
    }
}


const allPaymentsVerified = computed(() => {
    const passengers = paymentModalRoute.value?.passengers
    if (!passengers?.length) return true
    return passengers.every(p => paymentVerifyMap.value[p.id] || slipRejectMap.value[p.id])
})

// read-only mode: route เสร็จแล้ว + ทุกคนผ่านการกด "ยืนยันถึงที่หมาย" แล้ว (ไม่มีปฏิเสธค้างอยู่)
// ใช้ confirmedVerifyHistory แทน paymentVerifyMap เพื่อไม่ให้การ check checkbox เปลี่ยน mode ทันที
const isReadOnlyMode = computed(() => {
    if (paymentModalRoute.value?.status !== 'completed') return false
    const passengers = paymentModalRoute.value?.passengers
    if (!passengers?.length) return true
    const routeId = paymentModalRoute.value.id
    const confirmed = confirmedVerifyHistory.value[routeId] || {}
    const rejected = rejectHistory.value[routeId] || {}
    return passengers.every(p => confirmed[p.id] === true && !rejected[p.id])
})

const unverifiedCount = computed(() => {
    const passengers = paymentModalRoute.value?.passengers
    if (!passengers?.length) return 0
    return passengers.filter(p => !paymentVerifyMap.value[p.id] && !slipRejectMap.value[p.id]).length
})

const verifiedCount = computed(() => {
    return Object.values(paymentVerifyMap.value).filter(Boolean).length
})


const openConfirmModal = (trip, action) => {
    tripToAction.value = trip
    if (action === 'confirm') {
        modalContent.value = {
            title: 'ยืนยันคำขอจอง',
            message: `ยืนยันคำขอของผู้โดยสาร "${trip.passenger.name}" ใช่หรือไม่?`,
            confirmText: 'ยืนยันคำขอ',
            action: 'confirm',
            variant: 'primary',
        }
    } else if (action === 'reject') {
        modalContent.value = {
            title: 'ปฏิเสธคำขอจอง',
            message: `ต้องการปฏิเสธคำขอของ "${trip.passenger.name}" ใช่หรือไม่?`,
            confirmText: 'ปฏิเสธ',
            action: 'reject',
            variant: 'danger',
        }
    } else if (action === 'delete') {
        modalContent.value = {
            title: 'ยืนยันการลบรายการ',
            message: `ต้องการลบคำขอนี้ออกจากรายการใช่หรือไม่?`,
            confirmText: 'ลบรายการ',
            action: 'delete',
            variant: 'danger',
        }
    } else if (action === 'arrive') {
        modalContent.value = {
            title: 'ยืนยันการถึงที่หมาย',
            message: `ยืนยันว่าเส้นทาง "${trip.origin} → ${trip.destination}" ถึงที่หมายแล้วใช่หรือไม่?\n\nผู้โดยสารจะได้รับแจ้งให้ชำระค่าโดยสาร`,
            confirmText: 'ใช่ ถึงที่หมายแล้ว',
            action: 'arrive',
            variant: 'primary',
        }
    } else if (action === 'complete-route') {
        const saved = verifyHistory.value[trip.id] || {}
        const confirmed = confirmedVerifyHistory.value[trip.id] || {}
        const savedReject = rejectHistory.value[trip.id] || {}
        const savedRejectReason = rejectReasonHistory.value[trip.id] || {}
        const verifyMap = {}
        const rejectMap = {}
        const rejectReasonMap = {}
        const lockedMap = {}
        ;(trip.passengers || []).forEach(p => {
            // แสดง state ล่าสุด (จาก session ก่อน) หรือจาก confirmedHistory
            verifyMap[p.id] = saved[p.id] || confirmed[p.id] || false
            rejectMap[p.id] = savedReject[p.id] || false
            rejectReasonMap[p.id] = savedRejectReason[p.id] || ''
            // lock เฉพาะถ้าเคยกด "ยืนยันถึงที่หมาย" แล้ว (มีใน confirmedVerifyHistory)
            lockedMap[p.id] = confirmed[p.id] === true || savedReject[p.id] === true
        })
        paymentVerifyMap.value = verifyMap
        slipRejectMap.value = rejectMap
        slipRejectReasonMap.value = rejectReasonMap
        lockedVerifyMap.value = lockedMap
        pendingRejectPassengerId.value = null
        paymentModalRoute.value = trip
        isPaymentModalVisible.value = true
        return
    }
    isModalVisible.value = true
}

const closeConfirmModal = () => {
    isModalVisible.value = false
    tripToAction.value = null
}

const handleConfirmAction = async () => {
    if (!tripToAction.value) return
    const action = modalContent.value.action
    const bookingId = tripToAction.value.id
    try {
        if (action === 'confirm') {
            await $api(`/bookings/${bookingId}/status`, { method: 'PATCH', body: { status: 'CONFIRMED' } })
            toast.success('สำเร็จ', 'ยืนยันคำขอแล้ว')
        } else if (action === 'reject') {
            await $api(`/bookings/${bookingId}/status`, { method: 'PATCH', body: { status: 'REJECTED' } })
            toast.success('สำเร็จ', 'ปฏิเสธคำขอแล้ว')
        } else if (action === 'delete') {
            await $api(`/bookings/${bookingId}`, { method: 'DELETE' })
            toast.success('ลบรายการสำเร็จ', 'ลบคำขอออกจากรายการแล้ว')
        } else if (action === 'arrive') {
            // Mock: อัปเดต local state ไม่ต้องเรียก API
            const idx = myRoutes.value.findIndex(r => r.id === bookingId)
            if (idx !== -1) myRoutes.value[idx].status = 'arrived'
            toast.success('บันทึกสำเร็จ', 'ผู้โดยสารจะได้รับแจ้งให้ชำระค่าโดยสาร')
            closeConfirmModal()
            return
        }
        closeConfirmModal()
        await fetchMyRoutes()
    } catch (error) {
        console.error(`Failed to ${action} booking:`, error)
        toast.error('เกิดข้อผิดพลาด', error?.data?.message || 'ไม่สามารถดำเนินการได้')
        closeConfirmModal()
    }
}

const completeWithPaymentVerification = () => {
    if (!paymentModalRoute.value) return
    const routeId = paymentModalRoute.value.id
    const passengers = paymentModalRoute.value.passengers || []
    // หาผู้โดยสารที่เพิ่งได้รับการยืนยันใหม่ (ยังไม่เคยอยู่ใน confirmedVerifyHistory)
    const prevConfirmed = confirmedVerifyHistory.value[routeId] || {}
    const newlyVerified = passengers.filter(
        p => paymentVerifyMap.value[p.id] && !prevConfirmed[p.id] && !slipRejectMap.value[p.id]
    )
    // บันทึก state ที่ confirmed ณ ตอนนี้ → ใช้เป็น lock เมื่อเปิด modal ครั้งต่อไป
    confirmedVerifyHistory.value[routeId] = { ...paymentVerifyMap.value }
    // บันทึกเวลายืนยันสำหรับผู้โดยสารที่เพิ่งได้รับการยืนยันใหม่
    const nowIso = new Date().toISOString()
    const prevAtMap = confirmedAtMap.value[routeId] || {}
    confirmedAtMap.value[routeId] = {
        ...prevAtMap,
        ...Object.fromEntries(newlyVerified.map(p => [p.id, nowIso]))
    }
    // Mock: อัปเดต local state ไม่ต้องเรียก API
    const idx = myRoutes.value.findIndex(r => r.id === routeId)
    if (idx !== -1) myRoutes.value[idx].status = 'completed'
    // Auto-send receipt ให้ผู้โดยสารที่เพิ่งยืนยัน
    if (newlyVerified.length > 0) {
        toast.success('ส่งใบเสร็จแล้ว', `ส่งใบสำคัญรับเงินให้ผู้โดยสาร ${newlyVerified.length} คน เรียบร้อยแล้ว`)
    } else {
        toast.success('บันทึกสำเร็จ', 'บันทึกการยืนยันเรียบร้อยแล้ว')
    }
    isPaymentModalVisible.value = false
    paymentModalRoute.value = null
}

const copyEmail = async (email) => {
    try {
        await navigator.clipboard.writeText(email)
        toast.success('คัดลอกแล้ว', email)
    } catch (e) {
        toast.error('คัดลอกไม่สำเร็จ', 'ลองใหม่อีกครั้ง')
    }
}

function formatDistance(input) {
    if (typeof input !== 'string') return input
    const parts = input.split('+')
    if (parts.length <= 1) return input

    let meters = 0
    for (const seg of parts) {
        const n = parseFloat(seg.replace(/[^\d.]/g, ''))
        if (Number.isNaN(n)) continue
        if (/กม/.test(seg)) meters += n * 1000
        else if (/เมตร|ม\./.test(seg)) meters += n
        else meters += n
    }

    if (meters >= 1000) {
        const km = Math.round((meters / 1000) * 10) / 10
        return `${(km % 1 === 0 ? km.toFixed(0) : km)} กม.`
    }
    return `${Math.round(meters)} ม.`
}

function formatDuration(input) {
    if (typeof input !== 'string') return input
    const parts = input.split('+')
    if (parts.length <= 1) return input

    let minutes = 0
    for (const seg of parts) {
        const n = parseFloat(seg.replace(/[^\d.]/g, ''))
        if (Number.isNaN(n)) continue
        if (/ชม/.test(seg)) minutes += n * 60
        else minutes += n
    }

    const h = Math.floor(minutes / 60)
    const m = Math.round(minutes % 60)
    return h ? (m ? `${h} ชม. ${m} นาที` : `${h} ชม.`) : `${m} นาที`
}

// --- Lifecycle ---
useHead({
    title: 'คำขอจองเส้นทางของฉัน - ไปนำแหน่',
    script: import.meta.client && !window.google?.maps ? [{
        key: 'gmaps',
        src: `https://maps.googleapis.com/maps/api/js?key=${useRuntimeConfig().public.googleMapsApiKey}&libraries=places,geometry&callback=${GMAPS_CB}`,
        async: true,
        defer: true
    }] : []
})

onMounted(() => {
    if (window.google?.maps) {
        initializeMap()
        fetchMyRoutes().then(() => {
            if (activeTab.value === 'myRoutes') {
                if (myRoutes.value.length) updateMap(myRoutes.value[0])
            } else {
                if (filteredTrips.value.length) updateMap(filteredTrips.value[0])
            }
        })
        return
    }

    window[GMAPS_CB] = () => {
        try { delete window[GMAPS_CB] } catch { }
        initializeMap()
        fetchMyRoutes().then(() => {
            if (activeTab.value === 'myRoutes') {
                if (myRoutes.value.length) updateMap(myRoutes.value[0])
            } else {
                if (filteredTrips.value.length) updateMap(filteredTrips.value[0])
            }
        })
    }
})

function initializeMap() {
    if (!mapContainer.value || gmap) return
    gmap = new google.maps.Map(mapContainer.value, {
        center: { lat: 13.7563, lng: 100.5018 },
        zoom: 6,
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: true,
    })
    geocoder = new google.maps.Geocoder()
    placesService = new google.maps.places.PlacesService(gmap)
    mapReady.value = true
}

watch(activeTab, () => {
    selectedTripId.value = null
    if (activeTab.value === 'myRoutes') {
        if (myRoutes.value.length > 0) updateMap(myRoutes.value[0])
    } else {
        if (filteredTrips.value.length > 0) updateMap(filteredTrips.value[0])
    }
})
</script>

<style scoped>
/* (สไตล์ทั้งหมดคงเดิม) */
.trip-card {
    transition: all 0.3s ease;
    cursor: pointer;
}

.trip-card:hover {
    /* transform: translateY(-2px); */
    box-shadow: 0 10px 25px rgba(59, 130, 246, 0.1);
}

.tab-button {
    transition: all 0.3s ease;
}

.tab-button.active {
    background-color: #3b82f6;
    color: white;
    box-shadow: 0 4px 14px rgba(59, 130, 246, 0.3);
}

.tab-button:not(.active) {
    background-color: white;
    color: #6b7280;
    border: 1px solid #d1d5db;
}

.tab-button:not(.active):hover {
    background-color: #f9fafb;
    color: #374151;
}

#map {
    height: 100%;
    min-height: 600px;
    border-radius: 0 0 0.5rem 0.5rem;
}

.status-badge {
    display: inline-flex;
    align-items: center;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.875rem;
    font-weight: 500;
}

.status-pending {
    background-color: #fef3c7;
    color: #d97706;
}

.status-confirmed {
    background-color: #d1fae5;
    color: #065f46;
}

.status-rejected {
    background-color: #fee2e2;
    color: #dc2626;
}

.status-cancelled {
    background-color: #f3f4f6;
    color: #6b7280;
}

.status-in-transit {
    background-color: #dbeafe;
    color: #1d4ed8;
}

.status-arrived {
    background-color: #fef9c3;
    color: #a16207;
    border: 1px solid #fde047;
}

.status-completed {
    background-color: #dcfce7;
    color: #15803d;
}

@keyframes slide-in-from-top {
    from {
        opacity: 0;
        transform: translateY(-10px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.animate-in {
    animation-fill-mode: both;
}

.slide-in-from-top {
    animation-name: slide-in-from-top;
}

.duration-300 {
    animation-duration: 300ms;
}
</style>
