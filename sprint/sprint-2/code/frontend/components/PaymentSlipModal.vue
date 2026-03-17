<!--
  ============================================================
  Thongchai595-6
    flow การทำงาน
    - Step 1 : แสดง QR PromptPay + บัญชีธนาคารคนขับ
    - Step 2 : อัปโหลดสลิปการโอนเงิน
    - Step 3 : ยืนยันและส่ง

  Backend endpoint ที่ต้องทำต่อ:
    POST /bookings/:id/payment-slip   (multipart/form-data)
      fields: slip (File), memo (String, optional)
    POST /bookings/:id/payment-cash   (JSON)
      body: { memo?: string }
    GET  /bookings/:id/payment-status
  ============================================================
-->

<template>
  <transition name="ps-fade">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm flex flex-col overflow-hidden">

        <!-- ── Header ── -->
        <div class="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div>
            <p class="text-xs font-medium text-gray-400 uppercase tracking-wide">ชำระค่าโดยสาร</p>
            <h3 class="text-base font-bold text-gray-800 leading-tight">
              {{ currentStepLabel }}
            </h3>
          </div>
          <!-- Step dots (ปรับตามจำนวน step จริง) -->
          <div class="flex items-center gap-3">
            <div class="flex items-center gap-1">
              <div
                v-for="s in totalSteps"
                :key="s"
                class="rounded-full transition-all duration-300"
                :class="s < displayStep
                  ? 'w-2 h-2 bg-green-500'
                  : s === displayStep
                    ? 'w-3 h-3 bg-blue-600 ring-2 ring-blue-200'
                    : 'w-2 h-2 bg-gray-200'"
              />
            </div>
            <button
              @click="handleClose"
              class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- ── Body ── -->
        <div class="flex-1 overflow-y-auto px-5 py-4 max-h-[65vh]">

          <!-- ===== STEP 1: ข้อมูลการชำระเงิน ===== -->
          <div v-if="step === 1">
            <!-- Amount summary -->
            <div class="text-center mb-4 py-3 bg-blue-50 rounded-xl border border-blue-100">
              <p class="text-sm text-gray-500">ชำระให้ <span class="font-semibold text-gray-800">{{ booking?.driver?.name }}</span></p>
              <p class="text-3xl font-extrabold text-blue-600 mt-1">
                {{ totalAmount.toLocaleString('th-TH') }}
                <span class="text-lg font-semibold text-blue-400">บาท</span>
              </p>
              <p class="text-xs text-gray-400 mt-0.5">{{ booking?.seats }} ที่นั่ง {{ booking?.origin }} → {{ booking?.destination }}</p>
            </div>

            <!-- ── จ่ายแทนผู้ร่วมเดินทาง ── -->
            <div v-if="fellowPassengers.length > 0" class="mb-4">
              <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">จ่ายแทนผู้ร่วมเดินทาง</p>
              <div class="space-y-1.5">
                <label
                  v-for="f in fellowPassengers"
                  :key="f.bookingId"
                  class="flex items-center gap-3 p-2.5 rounded-xl border cursor-pointer transition-all"
                  :class="selectedFriendIds.has(f.bookingId)
                    ? 'border-blue-400 bg-blue-50'
                    : 'border-gray-200 bg-gray-50 hover:border-blue-200 hover:bg-blue-50/50'"
                >
                  <input
                    type="checkbox"
                    class="w-4 h-4 accent-blue-600 rounded shrink-0"
                    :checked="selectedFriendIds.has(f.bookingId)"
                    @change="toggleFriend(f.bookingId)"
                  />
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-gray-800 leading-tight">{{ f.name }}</p>
                    <p class="text-xs text-gray-500">{{ f.seats }} ที่นั่ง</p>
                  </div>
                  <span class="text-sm font-bold text-blue-700 shrink-0">+{{ f.price.toLocaleString('th-TH') }}</span>
                </label>
              </div>
              <p v-if="selectedFriendIds.size > 0" class="text-xs text-blue-600 mt-1.5 text-right font-medium">
                รวมทั้งหมด {{ totalAmount.toLocaleString('th-TH') }} บาท
              </p>
            </div>

            <!-- ── เลือกวิธีชำระเงิน (Thongchai595-6) ── -->
            <div class="flex gap-2 mb-4">
              <button
                @click="paymentMethod = 'transfer'"
                class="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 text-sm font-semibold transition-all"
                :class="paymentMethod === 'transfer'
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                </svg>
                โอนเงิน
              </button>
              <button
                @click="paymentMethod = 'cash'"
                class="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 text-sm font-semibold transition-all"
                :class="paymentMethod === 'cash'
                  ? 'border-green-500 bg-green-50 text-green-700'
                  : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/>
                </svg>
                เงินสด
              </button>
            </div>

            <!-- PromptPay QR section (โอนเงิน เท่านั้น) (โอนเงิน เท่านั้น) -->
            <div v-if="paymentMethod === 'transfer'">
            <div v-if="promptPayId">
              <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">พร้อมเพย์</p>
              <div class="flex flex-col items-center p-4 bg-gray-50 border border-gray-200 rounded-xl mb-4">
                <!-- QR image (generated from EMV payload via QR Server API) -->
                <div class="relative w-48 h-48 rounded-xl overflow-hidden bg-white border border-gray-100 shadow-sm">
                  <img
                    v-if="!qrError"
                    :src="promptPayQrUrl"
                    alt="QR Code พร้อมเพย์"
                    class="w-full h-full object-contain p-1"
                    @error="qrError = true"
                  />
                  <!-- QR error fallback -->
                  <div v-else class="flex flex-col items-center justify-center w-full h-full text-center p-4">
                    <svg class="w-10 h-10 text-gray-300 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                    </svg>
                    <p class="text-xs text-gray-400">ไม่สามารถสร้าง QR ได้<br>กรุณาใช้เลขพร้อมเพย์ด้านล่าง</p>
                  </div>
                </div>

                <!-- PromptPay ID display + copy ไว้กดคัดลอกไปวางโอน -->
                <div class="flex items-center gap-2 mt-3 px-3 py-2 bg-white border border-gray-100 rounded-xl shadow-sm w-full max-w-xs">
                  <svg class="w-4 h-4 text-blue-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                  </svg>
                  <span class="flex-1 text-sm text-gray-700 font-mono tracking-wide text-center">{{ promptPayId }}</span>
                  <button
                    @click="copyPromptPayId"
                    class="p-1 text-gray-400 hover:text-blue-600 transition-colors rounded"
                    title="คัดลอกเลขพร้อมเพย์"
                  >
                    <svg v-if="!copied" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                    <svg v-else class="w-4 h-4 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
                    </svg>
                  </button>
                </div>
                <p v-if="copied" class="text-xs text-green-600 mt-1 animate-pulse">คัดลอกสำเร็จ!</p>
              </div>
            </div>

            <!-- No PromptPay warning -->
            <div v-else class="flex items-center gap-3 p-3 bg-amber-50 border border-amber-200 rounded-xl mb-4">
              <svg class="w-5 h-5 text-amber-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
              </svg>
              <p class="text-sm text-amber-700">คนขับไม่ได้ตั้งค่าพร้อมเพย์ กรุณาโอนผ่านบัญชีธนาคารด้านล่าง</p>
            </div>

            <!-- Bank accounts section -->
            <div v-if="bankAccounts.length > 0">
              <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                {{ promptPayId ? 'หรือโอนผ่านบัญชีธนาคาร' : 'บัญชีธนาคาร' }}
              </p>
              <div class="space-y-2 mb-2">
                <div
                  v-for="acc in bankAccounts"
                  :key="acc.id"
                  class="flex items-center gap-3 p-3 bg-gray-50 border border-gray-100 rounded-xl"
                >
                  <div
                    class="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 overflow-hidden"
                    :style="bankInfo(acc.bankCode).logo ? {} : { background: bankInfo(acc.bankCode).bg }"
                  >
                    <img
                      v-if="bankInfo(acc.bankCode).logo"
                      :src="bankInfo(acc.bankCode).logo"
                      :alt="bankInfo(acc.bankCode).nameTh"
                      class="w-full h-full object-cover"
                    />
                    <span v-else class="text-xs font-bold" :style="{ color: bankInfo(acc.bankCode).color }">
                      {{ (acc.bankCode || 'BK').slice(0, 2) }}
                    </span>
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-gray-800">{{ bankInfo(acc.bankCode).nameTh }}</p>
                    <p class="text-sm text-gray-600 font-mono">{{ acc.accountNumber }}</p>
                    <p class="text-xs text-gray-400">{{ acc.accountName }}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- No payment info at all -->
            <div
              v-if="!promptPayId && bankAccounts.length === 0"
              class="text-center py-8 text-sm text-gray-500"
            >
              <svg class="w-10 h-10 text-gray-300 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
              </svg>
              <p class="font-medium text-gray-600">คนขับยังไม่ตั้งค่าช่องทางรับเงิน</p>
              <p class="text-xs text-gray-400 mt-1">กรุณาติดต่อคนขับโดยตรง</p>
            </div>
            </div><!-- end transfer block -->

            <!-- ── กรณีเงินสด (Thongchai595-6) ── -->
            <div v-if="paymentMethod === 'cash'" class="space-y-3">
              <div class="flex items-start gap-3 p-4 bg-green-50 border border-green-200 rounded-2xl">
                <svg class="w-8 h-8 text-green-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/>
                </svg>
                <div>
                  <p class="text-sm font-bold text-green-800">ชำระด้วยเงินสดกับคนขับโดยตรง</p>
                  <p class="text-xs text-green-700 mt-1 leading-relaxed">
                    เตรียมเงิน <span class="font-extrabold text-green-900">{{ totalAmount.toLocaleString('th-TH') }} บาท</span>
                    มอบให้คนขับเมื่อถึงจุดหมาย
                  </p>
                </div>
              </div>
              <div class="flex items-start gap-2 p-3 bg-amber-50 border border-amber-100 rounded-xl">
                <svg class="w-4 h-4 text-amber-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <p class="text-xs text-amber-700">กรุณาเตรียมเงินให้พอดี คนขับอาจไม่มีทอนเหรียญ</p>
              </div>
            </div>
          </div>

          <!-- ===== STEP 2: แนบสลิปการโอน (โอนเงิน เท่านั้น) ===== -->
          <div v-if="step === 2 && paymentMethod === 'transfer'">
            <p class="text-sm text-gray-500 mb-4">
              อัปโหลดรูปสลิปหรือภาพหน้าจอยืนยันการโอนเงินจำนวน
              <span class="font-bold text-gray-800">{{ totalAmount.toLocaleString('th-TH') }} บาท</span>
            </p>

            <!-- Upload drop zone -->
            <div
              class="relative border-2 border-dashed rounded-2xl transition-all duration-200 cursor-pointer select-none"
              :class="[
                isDragging ? 'border-blue-400 bg-blue-50 scale-[0.99]' : '',
                slipFile ? 'border-green-300 bg-green-50' : (!isDragging ? 'border-gray-300 hover:border-blue-400 hover:bg-gray-50' : '')
              ]"
              @click="triggerFileInput"
              @dragenter.prevent="isDragging = true"
              @dragleave.prevent="isDragging = false"
              @dragover.prevent
              @drop.prevent="onFileDrop"
            >
              <!-- Preview when file selected -->
              <div v-if="slipPreviewUrl" class="relative p-2">
                <img
                  :src="slipPreviewUrl"
                  alt="ตัวอย่างสลิป"
                  class="w-full rounded-xl max-h-60 object-contain"
                />
                <!-- File info overlay -->
                <div class="flex items-center justify-between mt-2 px-1">
                  <div class="flex items-center gap-1.5">
                    <svg class="w-4 h-4 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                    </svg>
                    <span class="text-xs text-green-700 font-medium truncate max-w-[160px]">{{ slipFile?.name }}</span>
                  </div>
                  <span class="text-xs text-gray-400">{{ formatFileSize(slipFile?.size) }}</span>
                </div>
                <!-- Remove button -->
                <button
                  @click.stop="clearFile"
                  class="absolute top-4 right-4 w-7 h-7 bg-red-500 hover:bg-red-600 text-white rounded-full flex items-center justify-center shadow transition-colors"
                >
                  <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/>
                  </svg>
                </button>
              </div>

              <!-- Placeholder when no file -->
              <div v-else class="flex flex-col items-center py-10 px-4 text-center">
                <div
                  class="w-14 h-14 rounded-full flex items-center justify-center mb-3 transition-colors"
                  :class="isDragging ? 'bg-blue-100' : 'bg-gray-100'"
                >
                  <svg class="w-7 h-7" :class="isDragging ? 'text-blue-500' : 'text-gray-400'" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/>
                  </svg>
                </div>
                <p class="text-sm font-semibold text-gray-700">
                  {{ isDragging ? 'วางไฟล์ที่นี่' : 'คลิกหรือลากไฟล์มาวาง' }}
                </p>
                <p class="text-xs text-gray-400 mt-1">JPG, PNG, PDF · สูงสุด 10 MB</p>
              </div>
            </div>

            <!-- Hidden file input -->
            <input
              ref="fileInputRef"
              type="file"
              accept="image/*,application/pdf"
              class="hidden"
              @change="onFileSelected"
            />

            <!-- Upload error message -->
            <p v-if="uploadError" class="mt-2 text-sm text-red-600 flex items-center gap-1">
              <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
              </svg>
              {{ uploadError }}
            </p>
          </div>

          <!-- ===== STEP 3: ยืนยันก่อนส่ง ===== -->
          <div v-if="step === 3">
            <!-- Summary card -->
            <div class="p-4 bg-blue-50 border border-blue-100 rounded-2xl mb-4">
              <div class="flex items-start gap-3">
                <div class="w-9 h-9 bg-blue-600 rounded-full flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-bold text-gray-800">สรุปรายการชำระเงิน</p>
                  <div class="mt-1.5 space-y-0.5">
                    <p class="text-xs text-gray-600">ผู้รับ: <span class="font-semibold text-gray-800">{{ booking?.driver?.name }}</span></p>
                    <p class="text-xs text-gray-600">
                      จำนวน:
                      <span class="font-bold text-blue-700 text-sm">{{ totalAmount.toLocaleString('th-TH') }} บาท</span>
                    </p>
                    <p class="text-xs text-gray-600">
                      วิธีชำระ:
                      <span class="font-semibold" :class="paymentMethod === 'cash' ? 'text-green-700' : 'text-gray-800'">
                        {{ paymentMethod === 'cash' ? 'เงินสด' : 'เงินโอน' }}
                      </span>
                    </p>
                    <p class="text-xs text-gray-500">{{ booking?.origin }} → {{ booking?.destination }}</p>
                    <!-- Selected friends summary -->
                    <template v-if="selectedFriendIds.size > 0">
                      <p class="text-xs text-blue-600 mt-1 font-medium">
                        ชำระแทน {{ selectedFriendIds.size }} คน:
                        {{ fellowPassengers.filter(f => selectedFriendIds.has(f.bookingId)).map(f => f.name).join(', ') }}
                      </p>
                    </template>
                  </div>
                </div>
              </div>
            </div>

            <!-- Slip preview thumbnail (โอนเงิน เท่านั้น) -->
            <div v-if="slipPreviewUrl && paymentMethod === 'transfer'" class="mb-4">
              <p class="text-sm font-semibold text-gray-700 mb-2">หลักฐานการโอน</p>
              <div class="relative rounded-2xl overflow-hidden border border-gray-200 bg-gray-50">
                <img :src="slipPreviewUrl" alt="สลิปการโอน" class="w-full max-h-48 object-contain" />
                <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/30 to-transparent px-3 py-2">
                  <p class="text-xs text-white font-medium truncate">{{ slipFile?.name }}</p>
                </div>
              </div>
            </div>

            <!-- Disclaimer -->
            <div class="flex items-start gap-2 p-3 bg-amber-50 border border-amber-100 rounded-xl">
              <svg class="w-4 h-4 text-amber-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              <p v-if="paymentMethod === 'transfer'" class="text-xs text-amber-700">เมื่อส่งแล้วระบบจะแจ้งคนขับให้ยืนยัน กรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนกด "ส่งหลักฐาน"</p>
              <p v-else class="text-xs text-amber-700">ระบบจะแจ้งคนขับว่าคุณระบุชำระด้วยเงินสด กรุณาเตรียมเงินให้พร้อมก่อนเดินทาง</p>
            </div>
          </div>

        </div>
        <!-- ── Footer ── -->
        <div class="flex gap-2 px-5 py-4 border-t border-gray-100">
          <!-- Back button (step 2+) -->
          <button
            v-if="step > 1 && !isSubmitting"
            @click="goBack"
            class="px-4 py-2.5 text-sm font-medium text-gray-600 bg-gray-100 rounded-xl hover:bg-gray-200 transition-colors"
          >
            ย้อนกลับ
          </button>

          <!-- Step 1: ปุ่มปรับตามวิธีชำระ -->
          <button
            v-if="step === 1"
            @click="nextStep"
            class="flex-1 px-4 py-2.5 text-sm font-semibold text-white rounded-xl active:scale-[0.98] transition-all"
            :class="paymentMethod === 'cash'
              ? 'bg-green-600 hover:bg-green-700'
              : 'bg-blue-600 hover:bg-blue-700'"
          >
            {{ paymentMethod === 'cash' ? 'ดำเนินการต่อ' : 'แนบสลิป' }}
          </button>

          <!-- Step 2 → 3: ตรวจสอบ (โอนเงิน เท่านั้น) -->
          <button
            v-if="step === 2 && paymentMethod === 'transfer'"
            @click="nextStep"
            class="flex-1 px-4 py-2.5 text-sm font-semibold text-white bg-blue-600 rounded-xl hover:bg-blue-700 active:scale-[0.98] transition-all"
          >
            ตรวจสอบ
          </button>

          <!-- Step 3: ยืนยัน (ปรับตามวิธีชำระ) -->
          <button
            v-if="step === 3"
            @click="submitPayment"
            :disabled="isSubmitting"
            class="flex-1 px-4 py-2.5 text-sm font-semibold text-white rounded-xl active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            :class="paymentMethod === 'cash'
              ? 'bg-green-600 hover:bg-green-700'
              : 'bg-green-600 hover:bg-green-700'"
          >
            <span v-if="isSubmitting" class="flex items-center justify-center gap-2">
              <svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
              </svg>
              กำลังส่ง...
            </span>
            <span v-else>{{ paymentMethod === 'cash' ? 'แจ้งชำระเงินสด' : 'ส่งหลักฐาน' }}</span>
          </button>
        </div>

      </div>
    </div>
  </transition>
</template>

<script setup>
// ============================================================
// Thongchai595-6
// ============================================================

import { ref, computed, watch } from 'vue'
import { useToast } from '~/composables/useToast'
import { useAuth } from '~/composables/useAuth'

// ── ข้อมูลธนาคารไทย ────────────────────────────────────────
const BANK_MAP = {
  KBANK:  { nameTh: 'ธนาคารกสิกรไทย',          color: '#1d9b45', bg: '#e8f5ec', logo: '/banks/kbank.png' },
  SCB:    { nameTh: 'ธนาคารไทยพาณิชย์',         color: '#4a154b', bg: '#f3e8f7', logo: '/banks/scb.png' },
  BBL:    { nameTh: 'ธนาคารกรุงเทพ',            color: '#1a3a8f', bg: '#e8edfa', logo: '/banks/bangkok.png' },
  KTB:    { nameTh: 'ธนาคารกรุงไทย',            color: '#009fda', bg: '#e0f5fd', logo: '/banks/krungthai.png' },
  BAY:    { nameTh: 'ธนาคารกรุงศรีอยุธยา',      color: '#c8a000', bg: '#fffbe6', logo: '/banks/krungsri.png' },
  TTB:    { nameTh: 'ธนาคารทหารไทยธนชาต',       color: '#d81b60', bg: '#fce4ec', logo: '/banks/ttb.png' },
  GSB:    { nameTh: 'ธนาคารออมสิน',             color: '#6a1b9a', bg: '#f3e5f5', logo: '/banks/gsb.png' },
  BAAC:   { nameTh: 'ธนาคารเพื่อการเกษตรฯ',    color: '#2e7d32', bg: '#e8f5e9', logo: '/banks/baac.png' },
  UOB:    { nameTh: 'ธนาคารยูโอบี',             color: '#dc2626', bg: '#fef2f2', logo: null },
  CIMBT:  { nameTh: 'ธนาคารซีไอเอ็มบีไทย',     color: '#b91c1c', bg: '#fef2f2', logo: null },
  LHBANK: { nameTh: 'ธนาคารแลนด์แอนด์เฮ้าส์', color: '#0f766e', bg: '#f0fdfa', logo: null },
  TISCO:  { nameTh: 'ธนาคารทิสโก้',             color: '#1e3a8a', bg: '#eff6ff', logo: null },
  KKP:    { nameTh: 'ธนาคารเกียรตินาคินภัทร',   color: '#92400e', bg: '#fef3c7', logo: null },
  OTHER:  { nameTh: 'ธนาคารอื่น',               color: '#6b7280', bg: '#f3f4f6', logo: null },
}

const bankInfo = (bankCode) => BANK_MAP[bankCode] || BANK_MAP['OTHER']

// ── Props & Emits ──────────────────────────────────────────
const props = defineProps({
  /** ควบคุมการเปิด/ปิด modal */
  show: { type: Boolean, required: true },
  /**
   * ข้อมูล booking ที่ส่งมาจาก myTrip/index.vue
   * ควรมีฟิลด์:
   *   id, routeId, price, seats, origin, destination,
   *   driver: { name, image },
   *   driverPayment: { promptPayId, bankAccounts[] }
   */
  booking: { type: Object, default: null },
})

const emit = defineEmits(['close', 'submitted'])

const { $api } = useNuxtApp()
const { toast } = useToast()
const { user } = useAuth()

// ── State ──────────────────────────────────────────────────
const step          = ref(1)
// paymentMethod: 'transfer' | 'cash' (Thongchai595-6)
const paymentMethod = ref('transfer')

// Step-1 state
const qrError  = ref(false)
const copied   = ref(false)

// ── Friend payment state ──────────────────────────────────
const fellowPassengers = ref([])   // ผู้ร่วมเดินทางคนอื่น
const selectedFriendIds = ref(new Set()) // bookingId ที่เลือกจ่ายแทน

// Step-2 state
const fileInputRef  = ref(null)
const slipFile      = ref(null)
const slipPreviewUrl = ref(null)
const uploadError   = ref('')
const isDragging    = ref(false)

// Step-3 state
const isSubmitting  = ref(false)

// ── Computed ───────────────────────────────────────────────
const promptPayId  = computed(() => props.booking?.driverPayment?.promptPayId || null)
const bankAccounts = computed(() => props.booking?.driverPayment?.bankAccounts || [])

const totalAmount = computed(() => {
  let total = props.booking?.price || 0
  for (const f of fellowPassengers.value) {
    if (selectedFriendIds.value.has(f.bookingId)) total += f.price
  }
  return total
})

const toggleFriend = (bookingId) => {
  const s = new Set(selectedFriendIds.value)
  if (s.has(bookingId)) s.delete(bookingId)
  else s.add(bookingId)
  selectedFriendIds.value = s
}

// ── Step labels & navigation (Thongchai595-6) ──────────────
// โอนเงิน = 3 steps, เงินสด = 2 steps (ข้ามขั้นแนบสลิป)
const totalSteps = computed(() => paymentMethod.value === 'cash' ? 2 : 3)

// แปลง step จริง (1,2,3) → display step สำหรับ dots
const displayStep = computed(() => {
  if (paymentMethod.value === 'cash') return step.value === 3 ? 2 : 1
  return step.value
})

const stepLabelsTransfer = ['ข้อมูลการชำระเงิน', 'แนบหลักฐานการโอน', 'ยืนยันและส่ง']
const stepLabelsCash     = ['ข้อมูลการชำระเงิน', 'ยืนยันและส่ง']

const currentStepLabel = computed(() => {
  if (paymentMethod.value === 'cash') {
    return step.value === 3 ? stepLabelsCash[1] : stepLabelsCash[0]
  }
  return stepLabelsTransfer[step.value - 1] || ''
})

/**
 * สร้าง EMV PromptPay QR payload แบบ pure JS แล้วส่งไปให้
 * api.qrserver.com เรนเดอร์เป็นรูป PNG
 * (ไม่ต้องติดตั้ง library เพิ่ม)
 */
const promptPayQrUrl = computed(() => {
  if (!promptPayId.value) return null

  const payload = buildPromptPayEMV(promptPayId.value, props.booking?.price)
  return `https://api.qrserver.com/v1/create-qr-code/?size=220x220&ecc=M&data=${encodeURIComponent(payload)}`
})

// ── PromptPay EMV payload generator ───────────────────────
/**
 * สร้าง EMV QR payload ตามมาตรฐาน PromptPay ของ BOT
 * Ref: https://www.bot.or.th/Thai/PaymentAndBond/EPayment/Pages/PromptPay.aspx
 *
 * @param {string} target  - เบอร์โทร (10 หลัก) หรือเลขบัตร ปชช. (13 หลัก)
 * @param {number} amount  - จำนวนเงิน (บาท), 0 = ไม่ระบุ
 * @returns {string} EMV QR string
 */
function buildPromptPayEMV(target, amount) {
  // CRC-16/CCITT-FALSE
  function crc16(str) {
    let crc = 0xFFFF
    for (let i = 0; i < str.length; i++) {
      crc ^= str.charCodeAt(i) << 8
      for (let j = 0; j < 8; j++) {
        crc = (crc & 0x8000) ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF
      }
    }
    return crc.toString(16).toUpperCase().padStart(4, '0')
  }

  // TLV helper
  const tlv = (id, value) => `${id}${String(value.length).padStart(2, '0')}${value}`

  // แปลงเบอร์โทรเป็น format พร้อมเพย์: 08xxxxxxxx → 0066xxxxxxxx
  const isPhone = /^\d{10}$/.test(target)
  const isNid   = /^\d{13}$/.test(target)
  const accType = isPhone ? '01' : isNid ? '02' : '03'
  const accVal  = isPhone ? '0066' + target.substring(1) : target

  const merchantInfo = tlv('00', 'A000000677010111') + tlv(accType, accVal)

  const amtStr    = amount && amount > 0 ? Number(amount).toFixed(2) : null
  const amtTlv    = amtStr ? tlv('54', amtStr) : ''

  let payload =
    tlv('00', '01') +         // Payload Format Indicator
    tlv('01', '12') +         // Point of Initiation Method (static)
    tlv('29', merchantInfo) + // Merchant Account Info (PromptPay)
    tlv('53', '764') +        // Transaction Currency (THB)
    amtTlv +                  // Transaction Amount (optional)
    tlv('58', 'TH') +         // Country Code
    '6304'                    // CRC placeholder

  return payload + crc16(payload)
}

// ── Methods ────────────────────────────────────────────────

/** คัดลอกเลขพร้อมเพย์ */
async function copyPromptPayId() {
  try {
    await navigator.clipboard.writeText(promptPayId.value)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch {
    // fallback สำหรับ browser เก่า
    const el = document.createElement('textarea')
    el.value = promptPayId.value
    document.body.appendChild(el)
    el.select()
    document.execCommand('copy')
    document.body.removeChild(el)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  }
}

/** ไปขั้นตอนถัดไปพร้อม validate (Thongchai595-6) */
function nextStep() {
  if (paymentMethod.value === 'cash') {
    // เงินสด: ข้ามไป step 3 ทันที
    step.value = 3
    return
  }
  // โอนเงิน: validate ที่ step 2
  if (step.value === 2) {
    if (!slipFile.value) {
      uploadError.value = 'กรุณาแนบสลิปการโอนเงินก่อนดำเนินการต่อ'
      return
    }
    uploadError.value = ''
  }
  step.value++
}

/** ย้อนกลับ (Thongchai595-6) */
function goBack() {
  if (paymentMethod.value === 'cash') {
    // เงินสด step 3 → กลับ step 1
    step.value = 1
  } else {
    step.value--
  }
}

/** เปิด file picker */
function triggerFileInput() {
  fileInputRef.value?.click()
}

/** รับไฟล์จาก input */
function onFileSelected(event) {
  const file = event.target.files?.[0]
  if (file) processFile(file)
  // reset input เพื่อให้เลือกไฟล์เดิมซ้ำได้
  event.target.value = ''
}

/** รับไฟล์จาก แบบลากวาง */
function onFileDrop(event) {
  isDragging.value = false
  const file = event.dataTransfer.files?.[0]
  if (file) processFile(file)
}

/** validate และ preview ไฟล์ */
function processFile(file) {
  uploadError.value = ''
  const MAX_SIZE = 10 * 1024 * 1024 // 10 MB
  const ALLOWED  = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf']

  if (!ALLOWED.includes(file.type)) {
    uploadError.value = 'รองรับเฉพาะไฟล์ JPG, PNG หรือ PDF เท่านั้น'
    return
  }
  if (file.size > MAX_SIZE) {
    uploadError.value = 'ขนาดไฟล์ต้องไม่เกิน 10 MB'
    return
  }

  slipFile.value = file

  // สร้าง preview URL
  if (file.type.startsWith('image/')) {
    const reader = new FileReader()
    reader.onload = (e) => { slipPreviewUrl.value = e.target.result }
    reader.readAsDataURL(file)
  } else {
    // PDF → ใช้ icon แทน preview
    slipPreviewUrl.value = '/pdf-placeholder.png'
  }
}

/** แสดงขนาดไฟล์ให้อ่านง่าย */
function formatFileSize(bytes) {
  if (!bytes) return ''
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

/** ล้างไฟล์ที่เลือก */
function clearFile() {
  slipFile.value      = null
  slipPreviewUrl.value = null
  uploadError.value   = ''
}

/**
 * ส่งการชำระเงินไปยัง backend (Thongchai595-6)
 *
 * Backend ต้องทำ endpoint:
 *   POST /bookings/:id/payment-slip  (multipart/form-data)  → โอนเงิน
 *     body: { slip: File, memo?: string }
 *   POST /bookings/:id/payment-cash  (JSON)                 → เงินสด
 *     body: { memo?: string }
 *   Response ทั้งคู่: { success: true, booking: {...} }
 */
async function submitPayment() {
  isSubmitting.value = true
  try {
    const friendIds = [...selectedFriendIds.value]

    if (paymentMethod.value === 'cash') {
      // แจ้ง backend ว่า passenger เลือกจ่ายเงินสด (method → CASH, status ยัง PENDING)
      await $api(`/bookings/${props.booking.id}/payment/cash`, { method: 'PATCH' })
      // แจ้งเพื่อนที่เลือกจ่ายแทนด้วย
      for (const bookingId of friendIds) {
        await $api(`/bookings/${bookingId}/payment/cash`, { method: 'PATCH' })
      }
      const extra = friendIds.length > 0 ? ` (รวม ${friendIds.length} คน)` : ''
      toast.success('รับทราบแล้ว', `กรุณาเตรียมเงินสดให้พร้อม${extra} คนขับจะยืนยันการรับเงินให้`)
      emit('submitted', { bookingId: props.booking.id, method: 'cash' })
      return
    }

    // โอนเงิน: ส่งสลิป
    if (!slipFile.value) {
      toast.error('ไม่มีไฟล์', 'กรุณาแนบสลิปการโอนเงิน')
      step.value = 2
      isSubmitting.value = false
      return
    }

    // ส่งสลิปสำหรับ booking ของตัวเอง
    const formData = new FormData()
    formData.append('slip', slipFile.value)
    formData.append('method', 'PROMPTPAY')
    await $api(`/bookings/${props.booking.id}/payment/slip`, { method: 'POST', body: formData })

    // ส่งสลิปเดิมให้กับ booking ของเพื่อนที่เลือก
    for (const bookingId of friendIds) {
      const fd = new FormData()
      fd.append('slip', slipFile.value)
      fd.append('method', 'PROMPTPAY')
      await $api(`/bookings/${bookingId}/payment/slip`, { method: 'POST', body: fd })
    }

    const extra = friendIds.length > 0 ? ` (รวม ${friendIds.length + 1} รายการ)` : ''
    toast.success('ส่งหลักฐานสำเร็จ', `ระบบจะแจ้งคนขับให้ยืนยันการชำระเงิน${extra}`)
    emit('submitted', { bookingId: props.booking.id, method: 'transfer' })
  } catch (err) {
    console.error('[PaymentSlipModal] submitPayment error:', err)
    toast.error('ส่งหลักฐานไม่สำเร็จ', err?.data?.message || 'กรุณาลองใหม่อีกครั้ง')
  } finally {
    isSubmitting.value = false
  }
}

/** ปิด modal พร้อม reset state */
function handleClose() {
  if (isSubmitting.value) return
  emit('close')
}

// reset + fetch fellow passengers ทุกครั้งที่ show เปลี่ยนจาก false → true
watch(() => props.show, async (newVal) => {
  if (newVal) {
    step.value            = 1
    paymentMethod.value   = 'transfer'
    qrError.value         = false
    copied.value          = false
    slipFile.value        = null
    slipPreviewUrl.value  = null
    uploadError.value     = ''
    isDragging.value      = false
    isSubmitting.value    = false
    selectedFriendIds.value = new Set()
    fellowPassengers.value  = []

    // ดึงรายชื่อผู้ร่วมเดินทางในเส้นทางเดียวกัน
    if (props.booking?.routeId) {
      try {
        const route = await $api(`/routes/${props.booking.routeId}`)
        if (route?.bookings && route.pricePerSeat) {
          fellowPassengers.value = route.bookings
            .filter(b => b.status === 'COMPLETED' && b.passengerId !== user.value?.id)
            .map(b => ({
              bookingId: b.id,
              name: `${b.passenger?.firstName || ''} ${b.passenger?.lastName || ''}`.trim() || 'ผู้โดยสาร',
              seats: b.numberOfSeats || 1,
              price: (b.numberOfSeats || 1) * route.pricePerSeat,
            }))
        }
      } catch (e) {
        console.error('[PaymentSlipModal] fetch route error:', e)
      }
    }
  }
})
</script>

<style scoped>
/* ── Modal fade transition ── */
.ps-fade-enter-active,
.ps-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.ps-fade-enter-from,
.ps-fade-leave-to {
  opacity: 0;
}
.ps-fade-enter-from .bg-white,
.ps-fade-leave-to .bg-white {
  transform: scale(0.95) translateY(8px);
}
</style>
