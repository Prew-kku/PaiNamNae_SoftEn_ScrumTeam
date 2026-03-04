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
                </div>
                <button
                  v-if="p.paymentStatus === 'VERIFIED'"
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

  <!-- ── Receipt Modal ── -->
  <div
    v-if="isReceiptVisible && receiptPassenger"
    class="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 px-4"
    @click.self="isReceiptVisible = false"
  >
    <div class="bg-white rounded-xl shadow-2xl w-full max-w-sm overflow-hidden max-h-[90vh] flex flex-col">
      <!-- Header -->
      <div class="px-6 py-5 text-white text-center flex-shrink-0 bg-green-600">
        <svg class="w-10 h-10 mx-auto mb-2 opacity-90" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <h3 class="text-lg font-bold">ใบสำคัญรับเงิน</h3>
        <p class="text-xs opacity-75 mt-0.5">เลขที่อ้างอิง: {{ receiptPassenger.id?.slice(-8).toUpperCase() }}</p>
      </div>

      <!-- Body -->
      <div class="px-6 py-4 space-y-0 text-sm overflow-y-auto flex-1">
        <!-- ข้อมูลการเดินทาง -->
        <div class="space-y-2.5 pb-3 border-b border-dashed border-gray-200">
          <div class="flex justify-between gap-2">
            <span class="text-gray-500 flex-shrink-0">วันที่</span>
            <span class="font-medium text-gray-900 text-right">{{ route?.date }} {{ route?.time }}</span>
          </div>
          <div class="flex justify-between gap-2">
            <span class="text-gray-500 flex-shrink-0">เส้นทาง</span>
            <span class="font-medium text-gray-900 text-right max-w-[60%]">{{ route?.origin }} → {{ route?.destination }}</span>
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

        <!-- ข้อมูลคู่สัญญา -->
        <div class="space-y-2.5 py-3 border-b border-dashed border-gray-200">
          <div class="flex justify-between gap-2">
            <span class="text-gray-500 flex-shrink-0">ผู้โดยสาร</span>
            <span class="font-medium text-gray-900">{{ receiptPassenger.name }}</span>
          </div>
          <div class="flex justify-between gap-2">
            <span class="text-gray-500 flex-shrink-0">ผู้ขับ</span>
            <span class="font-medium text-gray-900">{{ route?.driverName }}</span>
          </div>
        </div>

        <!-- ค่าโดยสาร -->
        <div class="space-y-2.5 py-3 border-b border-dashed border-gray-200">
          <div class="flex justify-between">
            <span class="text-gray-500">จำนวนที่นั่ง</span>
            <span class="font-medium text-gray-900">{{ receiptPassenger.seats }} ที่นั่ง</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-500">ราคาต่อที่นั่ง</span>
            <span class="font-medium text-gray-900">฿{{ (route?.pricePerSeat ?? 0).toLocaleString() }}</span>
          </div>
          <div class="flex justify-between text-base">
            <span class="font-semibold text-gray-800">รวมทั้งสิ้น</span>
            <span class="font-bold text-green-700">
              ฿{{ ((route?.pricePerSeat ?? 0) * receiptPassenger.seats).toLocaleString() }}
            </span>
          </div>
        </div>

        <!-- วิธีชำระเงิน -->
        <div class="space-y-2 py-3">
          <div class="flex justify-between items-start gap-2">
            <span class="text-gray-500 flex-shrink-0">ชำระโดย</span>
            <span class="font-medium text-gray-900">
              {{ receiptPassenger.paymentMethod === 'CASH' ? 'เงินสด' : 'โอนเงิน' }}
            </span>
          </div>
          <div class="flex justify-between gap-2 text-xs text-gray-400">
            <span>ยืนยันเมื่อ</span>
            <span>{{ confirmedAtFor(receiptPassenger.id) }}</span>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="px-6 pb-5 flex-shrink-0 flex gap-3">
        <button
          v-if="receiptPassenger.paymentSlipUrl"
          @click="slipPreviewUrl = receiptPassenger.paymentSlipUrl; isReceiptVisible = false"
          class="flex-1 flex items-center justify-center gap-1.5 px-4 py-2 text-sm text-blue-700 border border-blue-300 rounded-md hover:bg-blue-50 font-medium"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
          </svg>
          ดูสลิป
        </button>
        <button
          @click="isReceiptVisible = false"
          class="flex-1 px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50"
        >ปิด</button>
        <button
          @click="downloadReceipt"
          class="flex-1 flex items-center justify-center gap-1.5 px-4 py-2 text-sm text-white bg-green-600 rounded-md hover:bg-green-700 font-medium"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          ดาวน์โหลด
        </button>
      </div>
    </div>
  </div>

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
import html2canvas from 'html2canvas'
import { useToast } from '~/composables/useToast'

// ── Props & Emits ───────────────────────────────────────────
const props = defineProps({
  show:  { type: Boolean, required: true },
  /** route object จาก myRoute/index.vue (origin, destination, date, time, pricePerSeat, driverName, passengers[]) */
  route: { type: Object, default: null },
})
const emit = defineEmits(['close', 'updated'])

const { $api } = useNuxtApp()
const { toast } = useToast()

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
          }
        } catch {
          return { ...p, paymentStatus: 'PENDING', paymentMethod: null, paymentSlipUrl: null, paymentVerifiedAt: null }
        }
      })
    )

    passengers.value = updated

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

const downloadReceipt = async () => {
  if (!receiptPassenger.value || !props.route) return
  const p     = receiptPassenger.value
  const route = props.route
  const refNo = p.id?.slice(-8).toUpperCase()
  const total = ((route.pricePerSeat ?? 0) * p.seats).toLocaleString()
  const confirmedAt = confirmedAtFor(p.id)

  const s = {
    wrap:     'font-family:sans-serif;font-size:14px;color:#111;background:#fff;width:400px;border-radius:10px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.12)',
    hd:       'background:#16a34a;color:#fff;text-align:center;padding:22px 20px',
    hdH:      'font-size:18px;font-weight:700;margin:0 0 4px',
    hdP:      'font-size:11px;opacity:.75;margin:0',
    bd:       'padding:16px 18px',
    sec:      'border-bottom:1px dashed #d1d5db;padding-bottom:12px;margin-bottom:12px',
    secLast:  'padding-bottom:0',
    row:      'display:flex;justify-content:space-between;gap:12px;margin-bottom:7px',
    rowLast:  'display:flex;justify-content:space-between;gap:12px;margin-bottom:0',
    lbl:      'color:#6b7280;flex-shrink:0',
    val:      'font-weight:500;text-align:right',
    totalLbl: 'font-weight:600;color:#111;flex-shrink:0',
    totalVal: 'font-size:15px;font-weight:700;color:#16a34a;text-align:right',
  }

  const paymentLines = p.paymentMethod === 'CASH'
    ? `<div style="${s.rowLast}"><span style="${s.lbl}">ชำระโดย</span><span style="${s.val}">เงินสด</span></div>`
    : `<div style="${s.rowLast}"><span style="${s.lbl}">ชำระโดย</span><span style="${s.val}">โอนเงิน</span></div>`

  const el = document.createElement('div')
  el.style.cssText = 'position:fixed;top:-9999px;left:-9999px'
  el.innerHTML = `
    <div style="${s.wrap}">
      <div style="${s.hd}">
        <p style="${s.hdH}">ใบสำคัญรับเงิน</p>
        <p style="${s.hdP}">เลขที่อ้างอิง: ${refNo}</p>
      </div>
      <div style="${s.bd}">
        <div style="${s.sec}">
          <div style="${s.row}"><span style="${s.lbl}">วันที่</span><span style="${s.val}">${route.date} ${route.time}</span></div>
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
      scale: 2, useCORS: true, backgroundColor: '#ffffff',
    })
    const link = document.createElement('a')
    link.download = `ใบเสร็จ-${refNo}.png`
    link.href = canvas.toDataURL('image/png')
    link.click()
  } finally {
    document.body.removeChild(el)
  }
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
