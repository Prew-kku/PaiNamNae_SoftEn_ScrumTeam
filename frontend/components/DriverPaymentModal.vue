<template>
  <transition name="dp-fade">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4"
    >
      <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg overflow-hidden">

        <!-- ── Header ── -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">ตรวจสอบการชำระเงิน</h3>
            <p v-if="route" class="text-sm text-gray-500 mt-0.5">
              {{ route.origin }} → {{ route.destination }}
            </p>
          </div>
          <!-- แสดง X เฉพาะตอนที่ยังมีผู้โดยสารค้างชำระ -->
          <button v-if="!isReadOnlyMode" @click="emit('close')" class="text-gray-400 hover:text-gray-600">
            <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- ── Body ── -->
        <div class="px-6 py-4 space-y-4 max-h-[28rem] overflow-y-auto">
          <!-- Loading -->
          <div v-if="isLoadingPayments" class="py-6 text-center text-sm text-gray-500">
            กำลังโหลดข้อมูลการชำระเงิน...
          </div>

          <p v-else-if="!passengers.length" class="text-sm text-center text-gray-500 py-4">
            ไม่มีผู้โดยสารในเส้นทางนี้
          </p>

          <!-- ===== READ-ONLY MODE: ทุกคนชำระแล้ว ===== -->
          <template v-else-if="isReadOnlyMode">
            <div
              v-for="p in passengers"
              :key="p.id"
              class="p-4 border border-green-200 bg-green-50 rounded-lg"
            >
              <div class="flex items-center gap-3 mb-2.5">
                <img :src="p.image" :alt="p.name" class="w-10 h-10 rounded-full object-cover" />
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-gray-900 text-sm truncate">{{ p.name }}</div>
                  <div class="text-xs text-gray-500">{{ p.seats }} ที่นั่ง</div>
                  <div v-if="p.paidByName" class="flex items-center gap-1 mt-0.5 text-xs text-blue-600">
                    <svg class="w-3 h-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                    </svg>
                    จ่ายโดย {{ p.paidByName }}
                  </div>
                </div>
                <div class="flex items-center gap-2 flex-shrink-0">
                  <button
                    v-if="p.paymentSlipUrl"
                    @click="slipPreviewUrl = p.paymentSlipUrl"
                    class="flex items-center gap-1.5 px-2.5 py-1.5 text-xs text-blue-700 border border-blue-300 rounded-md hover:bg-blue-100 transition-colors"
                  >
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                    ดูสลิป
                  </button>
                  <button
                    v-if="!p.paidByName"
                    @click="showReceipt(p)"
                    class="flex items-center gap-1.5 px-2.5 py-1.5 text-xs text-green-700 border border-green-300 rounded-md hover:bg-green-100 transition-colors"
                  >
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    ใบเสร็จ
                  </button>
                </div>
              </div>
              <div class="flex items-center justify-between">
                <div v-if="p.paymentMethod === 'CASH'" class="flex items-center gap-1.5 text-xs text-yellow-700 bg-yellow-50 border border-yellow-200 px-2.5 py-1 rounded-md">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                  เงินสด
                </div>
                <div v-else class="flex items-center gap-1.5 text-xs text-purple-700 bg-purple-50 border border-purple-200 px-2.5 py-1 rounded-md">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  โอนเงิน
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-sm font-semibold text-gray-900">฿{{ (route.pricePerSeat * p.seats).toLocaleString() }}</span>
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
            <div
              v-for="p in passengers"
              :key="p.id"
              class="p-4 border rounded-lg transition-colors"
              :class="slipRejectMap[p.id] ? 'border-red-300 bg-red-50' : paymentVerifyMap[p.id] ? 'border-green-300 bg-green-50' : 'border-gray-200'"
            >
              <!-- Passenger info -->
              <div class="flex items-center gap-3 mb-3">
                <img :src="p.image" :alt="p.name" class="w-10 h-10 rounded-full object-cover" />
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-gray-900 text-sm truncate">{{ p.name }}</div>
                  <div class="text-xs text-gray-500">{{ p.seats }} ที่นั่ง · ฿{{ (route.pricePerSeat * p.seats).toLocaleString() }}</div>
                  <div v-if="p.paidByName" class="flex items-center gap-1 mt-0.5 text-xs text-blue-600">
                    <svg class="w-3 h-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                    </svg>
                    จ่ายโดย {{ p.paidByName }}
                  </div>
                </div>
                <button
                  v-if="p.paymentStatus === 'VERIFIED' && !p.paidByName"
                  @click="showReceipt(p)"
                  class="flex items-center gap-1.5 px-2.5 py-1.5 text-xs text-green-700 border border-green-300 rounded-md hover:bg-green-100 transition-colors flex-shrink-0"
                >
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  ใบเสร็จ
                </button>
              </div>

              <!-- PENDING + CASH: passenger แจ้งจ่ายเงินสดแล้ว -->
              <div
                v-if="p.paymentStatus === 'PENDING' && p.paymentMethod === 'CASH'"
                class="flex items-center justify-between gap-3 px-3 py-2 bg-amber-50 border border-amber-300 rounded-md"
              >
                <div class="flex items-center gap-2">
                  <svg class="w-4 h-4 text-amber-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                  <span class="text-sm text-amber-800 font-medium">ผู้โดยสารแจ้งจ่ายเงินสด</span>
                </div>
                <label class="flex items-center gap-2 cursor-pointer flex-shrink-0">
                  <input
                    type="checkbox"
                    :checked="pendingVerifyMap[p.id] || paymentVerifyMap[p.id]"
                    :disabled="lockedVerifyMap[p.id]"
                    @change="setVerify(p.id, $event.target.checked)"
                    :class="['w-5 h-5 rounded accent-green-600', lockedVerifyMap[p.id] ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer']"
                  />
                  <span class="text-sm text-gray-700 whitespace-nowrap">รับเงินสดแล้ว</span>
                </label>
              </div>

              <!-- PENDING: รอชำระ -->
              <div
                v-else-if="p.paymentStatus === 'PENDING'"
                class="flex items-center justify-between gap-3 px-3 py-2 bg-gray-50 border border-gray-200 rounded-md"
              >
                <div class="flex items-center gap-2">
                  <svg class="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span class="text-sm text-gray-500">รอการชำระเงิน</span>
                </div>
                <label class="flex items-center gap-2 cursor-pointer flex-shrink-0">
                  <input
                    type="checkbox"
                    :checked="pendingVerifyMap[p.id] || paymentVerifyMap[p.id]"
                    :disabled="lockedVerifyMap[p.id]"
                    @change="setVerify(p.id, $event.target.checked)"
                    :class="['w-5 h-5 rounded accent-green-600', lockedVerifyMap[p.id] ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer']"
                  />
                  <span class="text-sm text-gray-700 whitespace-nowrap">รับเงินสดแล้ว</span>
                </label>
              </div>

              <!-- SUBMITTED: ส่งสลิปแล้ว รอตรวจ -->
              <div v-else-if="p.paymentStatus === 'SUBMITTED'">
                <div class="flex items-center gap-3">
                  <div class="flex items-center gap-2 px-3 py-2 bg-blue-50 border border-blue-200 rounded-md flex-1">
                    <svg class="w-4 h-4 text-blue-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <span class="text-sm text-blue-800 font-medium">ส่งสลิปแล้ว — รอตรวจสอบ</span>
                  </div>
                  <div class="flex items-center gap-2 flex-shrink-0">
                    <!-- ดูสลิป -->
                    <button
                      v-if="p.paymentSlipUrl"
                      @click="slipPreviewUrl = p.paymentSlipUrl"
                      class="p-1.5 text-gray-500 rounded-md hover:text-blue-600 transition-colors"
                      title="ดูสลิป"
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                    </button>
                    <!-- ปุ่มปฏิเสธ -->
                    <button
                      v-if="pendingRejectPassengerId !== p.id"
                      @click="startRejectSlip(p.id)"
                      class="p-1.5 text-gray-500 rounded-md hover:text-red-600 transition-colors"
                      title="สลิปไม่ถูกต้อง"
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                    <!-- checkbox ยืนยันสลิป -->
                    <label class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm font-medium text-gray-500 rounded-md transition-colors cursor-pointer whitespace-nowrap">
                      <input
                        type="checkbox"
                        :checked="pendingVerifyMap[p.id] || paymentVerifyMap[p.id]"
                        @change="setVerify(p.id, $event.target.checked)"
                        class="w-4 h-4 accent-green-600 cursor-pointer"
                      />
                      สลิปถูกต้อง
                    </label>
                  </div>
                </div>
                <!-- Inline reject form -->
                <div
                  v-if="pendingRejectPassengerId === p.id"
                  class="mt-2 p-3 bg-red-50 border border-red-200 rounded-lg space-y-2.5"
                >
                  <p class="text-xs font-semibold text-red-700 flex items-center gap-1.5">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
                    </svg>
                    ระบุเหตุผลที่ปฏิเสธสลิป
                  </p>
                  <div class="relative">
                    <select
                      v-model="rejectReasonInput"
                      class="w-full appearance-none text-sm border border-red-300 rounded-lg px-3 py-2 bg-white text-gray-800 focus:outline-none focus:ring-2 focus:ring-red-400 cursor-pointer pr-8"
                    >
                      <option v-for="r in REJECT_REASONS" :key="r" :value="r">{{ r }}</option>
                    </select>
                    <div class="absolute inset-y-0 right-0 flex items-center pr-2.5 pointer-events-none">
                      <svg class="w-4 h-4 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </div>
                  </div>
                  <textarea
                    v-model="rejectNoteInput"
                    rows="2"
                    placeholder="อธิบายเพิ่มเติม (ไม่บังคับ)"
                    class="w-full text-sm border border-red-200 rounded-lg px-3 py-2 bg-white text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-red-400 resize-none"
                  />
                  <div class="flex gap-2 justify-end">
                    <button
                      @click="cancelRejectSlip"
                      class="px-3 py-1.5 text-xs text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                    >ยกเลิก</button>
                    <button
                      @click="confirmRejectSlip(p.id)"
                      class="px-3 py-1.5 text-xs text-white bg-red-500 rounded-lg hover:bg-red-600 font-medium transition-colors"
                    >ยืนยันการปฏิเสธ</button>
                  </div>
                </div>
              </div>

              <!-- VERIFIED: ชำระแล้ว -->
              <div
                v-else-if="p.paymentStatus === 'VERIFIED'"
                class="flex items-center justify-between px-3 py-2 bg-green-50 border border-green-200 rounded-md"
              >
                <div class="flex items-center gap-2">
                  <svg class="w-4 h-4 text-green-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                  </svg>
                  <span class="text-sm font-medium text-green-800">ชำระแล้ว</span>
                </div>
                <div class="flex items-center gap-2">
                  <button
                    v-if="p.paymentSlipUrl"
                    @click="slipPreviewUrl = p.paymentSlipUrl"
                    class="p-1.5 text-blue-600 border border-blue-200 rounded-md hover:bg-blue-50 transition-colors"
                    title="ดูสลิป"
                  >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  </button>
                  <span
                    class="text-xs px-2 py-0.5 rounded-full font-medium"
                    :class="p.paymentMethod === 'CASH' ? 'bg-yellow-100 text-yellow-700' : 'bg-blue-100 text-blue-700'"
                  >
                    {{ p.paymentMethod === 'CASH' ? 'เงินสด' : 'โอนเงิน' }}
                  </span>
                </div>
              </div>

              <!-- REJECTED: ปฏิเสธแล้ว รอส่งใหม่ -->
              <div
                v-else-if="p.paymentStatus === 'REJECTED'"
                class="px-3 py-2 bg-red-50 border border-red-200 rounded-md space-y-1"
              >
                <div class="flex items-center gap-2">
                  <svg class="w-4 h-4 text-red-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span class="text-sm text-red-700 font-medium">สลิปไม่ถูกต้อง — รอผู้โดยสารส่งใหม่</span>
                </div>
                <p v-if="p.paymentRejectReason" class="text-xs text-red-500 pl-6">
                  เหตุผล: {{ p.paymentRejectReason }}
                </p>
              </div>
            </div>
          </template>
        </div>

        <!-- ── Footer ── -->
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
              <button @click="emit('close')" class="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50">
                ปิด
              </button>
            </div>
          </template>

          <!-- INTERACTIVE footer -->
          <template v-else>
            <div
              v-if="unverifiedCount > 0"
              class="flex items-start gap-2 px-3 py-2 text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded-md"
            >
              <svg class="w-4 h-4 mt-0.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
              </svg>
              <span>ยังมี <strong>{{ unverifiedCount }} คน</strong> ที่ยังไม่ได้ยืนยันการชำระเงิน</span>
            </div>
            <div class="flex items-center justify-between gap-3">
              <p class="text-xs text-gray-500">
                ยืนยันแล้ว {{ verifiedCount }}/{{ passengers.length }} คน
                <span v-if="Object.values(slipRejectMap).some(Boolean)" class="text-red-500 ml-1">
                  · ปฏิเสธสลิป {{ Object.values(slipRejectMap).filter(Boolean).length }} คน
                </span>
              </p>
              <button
                @click="submitVerifications"
                :disabled="!hasPendingVerify"
                :class="['px-4 py-2 text-sm text-white rounded-md transition-colors font-medium',
                  hasPendingVerify ? 'bg-green-600 hover:bg-green-700' : 'bg-gray-300 cursor-not-allowed']"
              >
                ยืนยันการรับเงิน
                <span
                  v-if="pendingCount > 0"
                  class="ml-1 bg-white text-green-700 rounded-full px-1.5 py-0.5 text-xs font-bold"
                >{{ pendingCount }}</span>
              </button>
            </div>
          </template>
        </div>
      </div>
    </div>
  </transition>

  <!-- กรณี: ตัวเอง (คนขับ) ไม่มีที่อยู่ -->
  <ConfirmModal
    :show="isReceiptVisible && !!receiptPassenger && !currentUser?.address"
    title="กรุณากรอกที่อยู่ของคุณก่อน"
    message="ต้องมีข้อมูลที่อยู่ของคุณเพื่อออกใบเสร็จรับเงิน กรุณาไปกรอกที่หน้าโปรไฟล์"
    confirm-text="ไปที่โปรไฟล์"
    cancel-text="ปิด"
    variant="primary"
    @confirm="navigateTo('/profile')"
    @cancel="isReceiptVisible = false"
  />

  <!-- กรณี: ผู้โดยสารไม่มีที่อยู่ -->
  <ConfirmModal
    :show="isReceiptVisible && !!receiptPassenger && !!currentUser?.address && !receiptPassenger?.address"
    title="ผู้โดยสารยังไม่ได้กรอกที่อยู่"
    message="ผู้โดยสารรายนี้ยังไม่ได้กรอกข้อมูลที่อยู่ กรุณาแจ้งให้ผู้โดยสารไปกรอกที่อยู่ที่หน้าโปรไฟล์ก่อน"
    confirm-text="รับทราบ"
    cancel-text="ปิด"
    variant="primary"
    @confirm="isReceiptVisible = false"
    @cancel="isReceiptVisible = false"
  />

  <!-- ── Receipt Modal ── -->
  <ReceiptModal
    :show="isReceiptVisible && !!receiptPassenger && !!currentUser?.address && !!receiptPassenger?.address"
    :ref-no="receiptPassenger?.id?.slice(-8).toUpperCase() ?? ''"
    :date="route?.date ?? ''"
    :provider="{ name: route?.driverName ?? '-', nationalIdNumber: route?.driverNationalId ?? '', address: currentUser?.address ?? '' }"
    :customer="{ name: receiptPassenger?.name ?? '', nationalIdNumber: receiptPassenger?.nationalIdNumber ?? '', address: receiptPassenger?.address ?? '' }"
    :origin="route?.origin ?? ''"
    :destination="route?.destination ?? ''"
    :pickup-location="receiptPassenger?.pickupLocation ?? ''"
    :dropoff-location="receiptPassenger?.dropoffLocation ?? ''"
    :seats="(receiptPassenger?.seats ?? 1) + (receiptPassenger?.paidForFriends ?? []).reduce((s, f) => s + (f.seats || 1), 0)"
    :price-per-seat="route?.pricePerSeat ?? 0"
    :total="(route?.pricePerSeat ?? 0) * ((receiptPassenger?.seats ?? 1) + (receiptPassenger?.paidForFriends ?? []).reduce((s, f) => s + (f.seats || 1), 0))"
    :group-paid-friends="receiptPassenger?.paidForFriends ?? []"
    :payment-method="receiptPassenger?.paymentMethod ?? ''"
    :payment-account="{ promptPayId: route?.driverPromptPayId, bankAccounts: route?.driverBankAccounts ?? [] }"
    :verified-at="receiptPassenger ? confirmedAtFor(receiptPassenger.id) : ''"
    :slip-url="receiptPassenger?.paymentSlipUrl ?? ''"
    @close="isReceiptVisible = false"
    @view-slip="slipPreviewUrl = receiptPassenger?.paymentSlipUrl; isReceiptVisible = false"
  />

  <!-- ── Slip fullscreen preview ── -->
  <div
    v-if="slipPreviewUrl"
    class="fixed inset-0 z-[60] flex items-center justify-center bg-black/80"
    @click="slipPreviewUrl = null"
  >
    <div class="relative">
      <img :src="slipPreviewUrl" alt="Slip Preview" class="max-w-sm max-h-[85vh] object-contain rounded-lg shadow-2xl" />
      <button
        @click.stop="slipPreviewUrl = null"
        class="absolute -top-3 -right-3 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-md text-gray-700 hover:text-gray-900"
      >
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { navigateTo } from '#app'
import ReceiptModal from './ReceiptModal.vue'
import ConfirmModal from './ConfirmModal.vue'
import { useToast } from '~/composables/useToast'
import { useAuth } from '~/composables/useAuth'

// ── Props & Emits ───────────────────────────────────────────
const props = defineProps({
  show:  { type: Boolean, required: true },
  /** route object จาก myRoute/index.vue (origin, destination, date, time, pricePerSeat, driverName, passengers[]) */
  route: { type: Object, default: null },
})
const emit = defineEmits(['close', 'updated'])

const { $api } = useNuxtApp()
const { toast } = useToast()
const { user: currentUser } = useAuth()

// ── State ───────────────────────────────────────────────────
const isLoadingPayments  = ref(false)
const passengers         = ref([])          // รายชื่อ passenger พร้อม paymentStatus ล่าสุด
const paymentVerifyMap   = ref({})          // { [passengerId]: boolean } — ยืนยันแล้ว
const pendingVerifyMap   = ref({})          // { [passengerId]: boolean } — ติ๊กแล้วแต่ยังไม่กด confirm
const lockedVerifyMap    = ref({})          // { [passengerId]: boolean } — ล็อกหลัง verify/reject
const slipRejectMap      = ref({})          // { [passengerId]: boolean }
const slipPreviewUrl     = ref(null)
const confirmedAtMap     = ref({})          // { [passengerId]: ISO string }

const pendingRejectPassengerId = ref(null)
const rejectReasonInput        = ref('')
const rejectNoteInput          = ref('')

const isReceiptVisible  = ref(false)
const receiptPassenger  = ref(null)

const REJECT_REASONS = [
  'ยอดเงินไม่ถูกต้อง',
  'ชื่อผู้รับเงินไม่ตรง',
  'สลีปเก่า/ใช้ซ้ำ',
  'รูปภาพไม่ชัดเจน',
  'สงสัยสลีปปลอม',
  'อื่นๆ',
]

// ── Computed ────────────────────────────────────────────────
const isReadOnlyMode = computed(() =>
  passengers.value.length > 0 && passengers.value.every(p => p.paymentStatus === 'VERIFIED')
)

const unverifiedCount = computed(() =>
  passengers.value.filter(p => !['VERIFIED', 'REJECTED'].includes(p.paymentStatus)).length
)

const verifiedCount = computed(() =>
  Object.values(paymentVerifyMap.value).filter(Boolean).length
)

const hasPendingVerify = computed(() =>
  Object.values(pendingVerifyMap.value).some(Boolean)
)

const pendingCount = computed(() =>
  Object.values(pendingVerifyMap.value).filter(Boolean).length
)

// ── Watch — load data when modal opens ─────────────────────
watch(() => props.show, async (newVal) => {
  if (!newVal) return
  await loadPayments()
})

async function loadPayments() {
  if (!props.route?.passengers?.length) {
    passengers.value = []
    return
  }

  // reset
  paymentVerifyMap.value   = {}
  pendingVerifyMap.value   = {}
  lockedVerifyMap.value    = {}
  slipRejectMap.value      = {}
  confirmedAtMap.value     = {}
  pendingRejectPassengerId.value = null
  isReceiptVisible.value   = false
  slipPreviewUrl.value     = null

  isLoadingPayments.value = true
  try {
    const updated = await Promise.all(
      (props.route.passengers || []).map(async (p) => {
        try {
          const payment = await $api(`/bookings/${p.id}/payment`)
          return {
            ...p,
            paymentStatus:       payment?.status       || 'PENDING',
            paymentMethod:       payment?.method       || null,
            paymentSlipUrl:      payment?.slipUrl      || null,
            paymentRejectReason: payment?.rejectReason || null,
            paymentVerifiedAt:   payment?.verifiedAt   || null,
            _paidBy:             payment?.paidBy       || null,
          }
        } catch {
          return { ...p, paymentStatus: 'PENDING', paymentMethod: null, paymentSlipUrl: null, paymentVerifiedAt: null, _paidBy: null }
        }
      })
    )

    // re-compute paidForFriends และ paidByName จาก paidBy ที่ fresh
    const withFriends = updated.map(p => ({
      ...p,
      paidForFriends: updated
        .filter(other => other.id !== p.id && other._paidBy === p.userId)
        .map(other => ({
          bookingId: other.id,
          name: other.name,
          seats: other.seats || 1,
          price: (props.route?.pricePerSeat || 0) * (other.seats || 1),
        })),
      paidByName: p._paidBy
        ? (updated.find(other => other.userId === p._paidBy)?.name || null)
        : null,
    }))
    passengers.value = withFriends

    // init maps
    const verifyMap = {}
    const rejectMap = {}
    const lockedMap = {}
    updated.forEach(p => {
      verifyMap[p.id] = p.paymentStatus === 'VERIFIED'
      rejectMap[p.id] = p.paymentStatus === 'REJECTED'
      lockedMap[p.id] = ['VERIFIED', 'REJECTED'].includes(p.paymentStatus)
    })
    paymentVerifyMap.value = verifyMap
    slipRejectMap.value    = rejectMap
    lockedVerifyMap.value  = lockedMap
  } finally {
    isLoadingPayments.value = false
  }
}

// ── Methods ─────────────────────────────────────────────────

const setVerify = (passengerId, checked) => {
  pendingVerifyMap.value = { ...pendingVerifyMap.value, [passengerId]: checked }
}

const submitVerifications = async () => {
  const toVerify = Object.entries(pendingVerifyMap.value)
    .filter(([, checked]) => checked)
    .map(([id]) => id)
  if (!toVerify.length) return

  let successCount = 0
  for (const passengerId of toVerify) {
    try {
      const p = passengers.value.find(x => x.id === passengerId)
      const body = p?.paymentStatus === 'PENDING' ? { method: 'CASH' } : {}
      await $api(`/bookings/${passengerId}/payment/verify`, { method: 'PATCH', body })

      paymentVerifyMap.value  = { ...paymentVerifyMap.value,  [passengerId]: true }
      lockedVerifyMap.value   = { ...lockedVerifyMap.value,   [passengerId]: true }
      confirmedAtMap.value    = { ...confirmedAtMap.value,    [passengerId]: new Date().toISOString() }

      passengers.value = passengers.value.map(x =>
        x.id === passengerId
          ? { ...x, paymentStatus: 'VERIFIED', paymentMethod: x.paymentStatus === 'PENDING' ? 'CASH' : (x.paymentMethod || 'PROMPTPAY') }
          : x
      )
      successCount++
    } catch (e) {
      toast.error('เกิดข้อผิดพลาด', e?.data?.message || 'ไม่สามารถยืนยันรายการได้')
    }
  }
  pendingVerifyMap.value = {}
  if (successCount > 0) {
    toast.success('ยืนยันแล้ว', `บันทึกการรับเงิน ${successCount} รายการเรียบร้อย`)
    const allVerified = passengers.value.every(p => p.paymentStatus === 'VERIFIED')
    emit('updated', { allVerified })
  }
}

const startRejectSlip = (passengerId) => {
  pendingRejectPassengerId.value = passengerId
  rejectReasonInput.value = REJECT_REASONS[0]
  rejectNoteInput.value   = ''
}

const cancelRejectSlip = () => {
  pendingRejectPassengerId.value = null
  rejectReasonInput.value = ''
  rejectNoteInput.value   = ''
}

const confirmRejectSlip = async (passengerId) => {
  const base   = rejectReasonInput.value.trim() || REJECT_REASONS[0]
  const note   = rejectNoteInput.value.trim()
  const reason = note ? `${base} — ${note}` : base
  try {
    await $api(`/bookings/${passengerId}/payment/reject`, {
      method: 'PATCH',
      body: { rejectReason: reason }
    })
    slipRejectMap.value  = { ...slipRejectMap.value,  [passengerId]: true }
    lockedVerifyMap.value = { ...lockedVerifyMap.value, [passengerId]: true }
    passengers.value = passengers.value.map(x =>
      x.id === passengerId ? { ...x, paymentStatus: 'REJECTED', paymentRejectReason: reason } : x
    )
    pendingRejectPassengerId.value = null
    rejectReasonInput.value = ''
    rejectNoteInput.value   = ''
    toast.warning('แจ้งผู้โดยสาร', 'แจ้งผู้โดยสารว่าสลิปไม่ถูกต้องแล้ว')
    emit('updated')
  } catch (e) {
    toast.error('เกิดข้อผิดพลาด', e?.data?.message || 'ไม่สามารถปฏิเสธได้')
  }
}

const showReceipt = (passenger) => {
  receiptPassenger.value = passenger
  isReceiptVisible.value  = true
}

const confirmedAtFor = (passengerId) => {
  // ใช้เวลาจาก session ปัจจุบันก่อน ถ้าไม่มีค่อยใช้จาก API
  const ts = confirmedAtMap.value[passengerId]
  if (ts) {
    return new Date(ts).toLocaleString('th-TH', {
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute: '2-digit'
    })
  }
  const p = passengers.value.find(x => x.id === passengerId)
  if (p?.paymentVerifiedAt) {
    return new Date(p.paymentVerifiedAt).toLocaleString('th-TH', {
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute: '2-digit'
    })
  }
  return '-'
}

</script>

<style scoped>
.dp-fade-enter-active,
.dp-fade-leave-active {
  transition: opacity 0.2s ease;
}
.dp-fade-enter-from,
.dp-fade-leave-to {
  opacity: 0;
}
</style>
