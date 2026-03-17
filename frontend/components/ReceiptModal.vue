<template>
  <div
    v-if="show"
    class="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 px-4"
    @click.self="$emit('close')"
  >
    <div class="bg-white rounded-xl shadow-2xl w-full max-w-md overflow-hidden max-h-[90vh] flex flex-col">

      <!-- Body -->
      <div class="overflow-y-auto flex-1 p-6 text-sm text-gray-800 font-sans">

        <!-- ชื่อเอกสาร + เลขที่ + วันที่ -->
        <div class="flex justify-between items-start gap-4 pb-4 border-b-2 border-gray-800 mb-4">
          <p class="text-lg font-bold text-green-700">ใบเสร็จรับเงิน</p>
          <div class="text-right flex-shrink-0 space-y-0.5 text-xs text-gray-600">
            <div class="flex justify-end gap-2">
              <span class="text-gray-400">เลขที่</span>
              <span class="font-mono font-semibold">{{ refNo }}</span>
            </div>
            <div class="flex justify-end gap-2">
              <span class="text-gray-400">วันที่</span>
              <span>{{ date }}</span>
            </div>
          </div>
        </div>

        <!-- ผู้ให้บริการ (คนขับ) -->
        <div class="py-3 border-b border-gray-200">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">ผู้ให้บริการ</p>
          <p class="font-semibold text-gray-900">{{ provider.name }}</p>
          <p v-if="provider.nationalIdNumber" class="text-xs text-gray-500 mt-0.5">
            เลขบัตรประชาชน: <span class="font-mono">{{ provider.nationalIdNumber }}</span>
          </p>
          <p v-if="provider.address" class="text-xs text-gray-500 mt-0.5">{{ formatAddress(provider.address) }}</p>
        </div>

        <!-- ลูกค้า (ผู้โดยสาร) -->
        <div class="py-3 border-b border-gray-200">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">ลูกค้า</p>
          <p class="font-semibold text-gray-900">{{ customer.name }}</p>
          <p v-if="customer.nationalIdNumber" class="text-xs text-gray-500 mt-0.5">
            เลขบัตรประชาชน: <span class="font-mono">{{ customer.nationalIdNumber }}</span>
          </p>
          <p v-if="customer.address" class="text-xs text-gray-500 mt-0.5">{{ formatAddress(customer.address) }}</p>
        </div>

        <!-- ตารางรายการ -->
        <div class="py-3 border-b border-gray-200">
          <table class="w-full text-xs">
            <colgroup>
              <col style="width:1.5rem" />
              <col />
              <col style="width:4rem" />
              <col style="width:5rem" />
              <col style="width:4.5rem" />
            </colgroup>
            <thead>
              <tr class="border-b border-gray-300 text-gray-500">
                <th class="text-left pb-2 font-semibold">#</th>
                <th class="text-left pb-2 font-semibold">รายการ</th>
                <th class="text-right pb-2 font-semibold">จำนวน</th>
                <th class="text-right pb-2 font-semibold">ราคา/ที่นั่ง</th>
                <th class="text-right pb-2 font-semibold">มูลค่า</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="pt-2 text-gray-500 align-top">1</td>
                <td class="pt-2 align-top pr-2">
                  <p class="font-medium">ค่าโดยสาร</p>
                  <p v-if="groupPaidFriends?.length" class="text-xs text-gray-600 mt-0.5">
                    ชำระแทน: {{ groupPaidFriends.map(f => f.name).join(', ') }}
                  </p>
                  <p class="text-gray-400 break-words mt-1"><span class="text-gray-500">จุดรับ</span> {{ pickupLocation || '-' }}</p>
                  <p class="text-gray-400 break-words"><span class="text-gray-500">จุดส่ง</span> {{ dropoffLocation || '-' }}</p>
                </td>
                <td class="pt-2 text-right align-top whitespace-nowrap">{{ seats }} ที่นั่ง</td>
                <td class="pt-2 text-right align-top whitespace-nowrap">฿{{ pricePerSeat.toLocaleString() }}</td>
                <td class="pt-2 text-right font-semibold align-top whitespace-nowrap">฿{{ total.toLocaleString() }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- ยอดรวม -->
        <div class="py-3 border-b border-gray-200 flex justify-end">
          <div class="space-y-1 text-xs w-48">
            <div class="flex justify-between text-gray-500">
              <span>รวมเงิน</span>
              <span>฿{{ total.toLocaleString() }}</span>
            </div>
            <div class="flex justify-between font-bold text-sm text-green-700 pt-1 border-t border-gray-200">
              <span>จำนวนเงินรวมทั้งสิ้น</span>
              <span>฿{{ total.toLocaleString() }}</span>
            </div>
          </div>
        </div>

        <!-- วิธีชำระเงิน -->
        <div class="pt-3 text-xs space-y-2">
          <!-- หมายเหตุ + checkboxes -->
          <div class="flex items-center gap-4 flex-wrap">
            <span class="text-gray-500">การชำระเงินจะสมบูรณ์เมื่อได้รับเงินเรียบร้อยแล้ว</span>
            <div class="flex gap-3">
              <label class="flex items-center gap-1">
                <input type="checkbox" :checked="paymentMethod === 'CASH'" disabled class="accent-gray-700" />
                <span>เงินสด</span>
              </label>
              <label class="flex items-center gap-1">
                <input type="checkbox" :checked="paymentMethod === 'BANK_TRANSFER' || paymentMethod === 'PROMPTPAY'" disabled class="accent-gray-700" />
                <span>โอนเงิน</span>
              </label>
            </div>
          </div>
          <!-- grid 2 คอลัมน์ -->
          <div class="grid grid-cols-2 gap-x-3 gap-y-2 border-t border-gray-200 pt-2">
            <div class="flex items-baseline gap-1 min-w-0">
              <span class="text-gray-500 flex-shrink-0">ธนาคาร</span>
              <span class="border-b border-gray-300 flex-1 pb-0.5 font-medium text-gray-800 truncate">
                <template v-if="paymentMethod === 'PROMPTPAY'">PromptPay</template>
                <template v-else-if="paymentMethod === 'BANK_TRANSFER' && paymentAccount.bankAccounts?.length">{{ getBankName(paymentAccount.bankAccounts[0].bankCode, paymentAccount.bankAccounts[0].customBankName) }}</template>
                <template v-else>&nbsp;</template>
              </span>
            </div>
            <div class="flex items-baseline gap-1 min-w-0">
              <span class="text-gray-500 flex-shrink-0">เลขที่</span>
              <span class="border-b border-gray-300 flex-1 pb-0.5 font-mono font-medium text-gray-800 truncate">
                <template v-if="paymentMethod === 'PROMPTPAY' && paymentAccount.promptPayId">{{ paymentAccount.promptPayId }}</template>
                <template v-else-if="paymentMethod === 'BANK_TRANSFER' && paymentAccount.bankAccounts?.length">{{ paymentAccount.bankAccounts[0].accountNumber }}</template>
                <template v-else>&nbsp;</template>
              </span>
            </div>
            <div class="flex items-baseline gap-1">
              <span class="text-gray-500 flex-shrink-0">วันที่</span>
              <span class="font-medium text-gray-800">{{ verifiedAt || '—' }}</span>
            </div>
            <div class="flex items-baseline gap-1">
              <span class="text-gray-500 flex-shrink-0">จำนวนเงิน</span>
              <span class="font-semibold text-gray-900">{{ total.toLocaleString('th-TH', { minimumFractionDigits: 2 }) }}</span>
            </div>
          </div>
        </div>

      </div>

      <!-- Footer Buttons -->
      <div class="px-6 pb-5 flex-shrink-0 flex gap-3 border-t border-gray-100 pt-4">
        <button
          v-if="slipUrl"
          @click="$emit('view-slip')"
          class="flex-1 flex items-center justify-center gap-1.5 px-4 py-2 text-sm text-blue-700 border border-blue-300 rounded-md hover:bg-blue-50 font-medium"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
          </svg>
          ดูสลิป
        </button>
        <button
          @click="$emit('close')"
          class="flex-1 px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50"
        >ปิด</button>
        <button
          @click="download"
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
</template>

<script setup>
import html2canvas from 'html2canvas'

// แปลง pipe-separated address → ข้อความสวยงาม
function formatAddress(raw) {
  if (!raw) return ''
  const [houseNo, subDistrict, district, province, postalCode] = raw.split('|').map(s => s.trim())
  const parts = []
  if (houseNo) parts.push(houseNo)
  if (subDistrict) parts.push(`ต.${subDistrict}`)
  if (district) parts.push(`อ.${district}`)
  if (province) parts.push(`จ.${province}`)
  if (postalCode) parts.push(postalCode)
  return parts.join(' ')
}

const BANK_MAP = {
  KBANK: 'ธนาคารกสิกรไทย',
  SCB:   'ธนาคารไทยพาณิชย์',
  BBL:   'ธนาคารกรุงเทพ',
  KTB:   'ธนาคารกรุงไทย',
  BAY:   'ธนาคารกรุงศรีอยุธยา',
  TTB:   'ธนาคารทหารไทยธนชาต',
  GSB:   'ธนาคารออมสิน',
  BAAC:  'ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร',
}
const getBankName = (code, custom) => custom || BANK_MAP[code] || 'ธนาคารอื่น'

const props = defineProps({
  show:            { type: Boolean, default: false },
  refNo:           { type: String,  default: '' },
  date:            { type: String,  default: '' },
  provider:        { type: Object,  default: () => ({}) },
  customer:        { type: Object,  default: () => ({}) },
  origin:          { type: String,  default: '' },
  destination:     { type: String,  default: '' },
  pickupLocation:  { type: String,  default: '' },
  dropoffLocation: { type: String,  default: '' },
  seats:           { type: Number,  default: 1 },
  pricePerSeat:    { type: Number,  default: 0 },
  total:           { type: Number,  default: 0 },
  paymentMethod:   { type: String,  default: '' },
  paymentAccount:    { type: Object,  default: () => ({}) },
  verifiedAt:        { type: String,  default: '' },
  slipUrl:           { type: String,  default: '' },
  groupPaidFriends:  { type: Array,   default: () => [] },
})

defineEmits(['close', 'view-slip'])

async function download() {
  const isCash     = props.paymentMethod === 'CASH'
  const isTransfer = props.paymentMethod === 'BANK_TRANSFER' || props.paymentMethod === 'PROMPTPAY'

  const bankName = props.paymentMethod === 'PROMPTPAY'
    ? 'PromptPay'
    : (props.paymentMethod === 'BANK_TRANSFER' && props.paymentAccount?.bankAccounts?.length
        ? getBankName(props.paymentAccount.bankAccounts[0].bankCode, props.paymentAccount.bankAccounts[0].customBankName)
        : '—')

  const accountNo = props.paymentMethod === 'PROMPTPAY' && props.paymentAccount?.promptPayId
    ? props.paymentAccount.promptPayId
    : (props.paymentMethod === 'BANK_TRANSFER' && props.paymentAccount?.bankAccounts?.length
        ? props.paymentAccount.bankAccounts[0].accountNumber
        : '—')

  const chk = (on) => on
    ? `<svg width="13" height="13" viewBox="0 0 13 13" style="display:inline-block;vertical-align:middle;margin-right:3px" xmlns="http://www.w3.org/2000/svg"><rect x="0.75" y="0.75" width="11.5" height="11.5" rx="1.5" fill="white" stroke="#374151" stroke-width="1.5"/><polyline points="2.5,6.5 5.5,9.5 10.5,3.5" fill="none" stroke="#374151" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>`
    : `<svg width="13" height="13" viewBox="0 0 13 13" style="display:inline-block;vertical-align:middle;margin-right:3px" xmlns="http://www.w3.org/2000/svg"><rect x="0.75" y="0.75" width="11.5" height="11.5" rx="1.5" fill="white" stroke="#9ca3af" stroke-width="1.5"/></svg>`

  const el = document.createElement('div')
  el.style.cssText = 'position:fixed;top:-9999px;left:-9999px'
  el.innerHTML = `
    <div style="font-family:sans-serif;font-size:13px;color:#111;background:#fff;width:560px;padding:28px 32px;box-sizing:border-box">

      <!-- header -->
      <div style="display:flex;justify-content:space-between;align-items:flex-start;padding-bottom:14px;border-bottom:2px solid #111;margin-bottom:14px">
        <p style="font-size:18px;font-weight:700;color:#16a34a;margin:0">ใบเสร็จรับเงิน</p>
        <table style="font-size:11px;color:#374151">
          <tr><td style="color:#9ca3af;padding-right:8px">เลขที่</td><td style="font-family:monospace;font-weight:600">${props.refNo}</td></tr>
          <tr><td style="color:#9ca3af;padding-right:8px">วันที่</td><td>${props.date}</td></tr>
        </table>
      </div>

      <!-- provider -->
      <div style="padding-bottom:12px;border-bottom:1px solid #e5e7eb;margin-bottom:12px">
        <p style="font-size:10px;color:#9ca3af;font-weight:600;text-transform:uppercase;letter-spacing:.05em;margin:0 0 4px">ผู้ให้บริการ</p>
        <p style="font-weight:600;margin:0 0 2px">${props.provider.name}</p>
        ${props.provider.nationalIdNumber ? `<p style="font-size:11px;color:#6b7280;margin:0">เลขบัตรประชาชน: <span style="font-family:monospace">${props.provider.nationalIdNumber}</span></p>` : ''}
        ${props.provider.address ? `<p style="font-size:11px;color:#6b7280;margin:2px 0 0">${formatAddress(props.provider.address)}</p>` : ''}
      </div>

      <!-- customer -->
      <div style="padding-bottom:12px;border-bottom:1px solid #e5e7eb;margin-bottom:12px">
        <p style="font-size:10px;color:#9ca3af;font-weight:600;text-transform:uppercase;letter-spacing:.05em;margin:0 0 4px">ลูกค้า</p>
        <p style="font-weight:600;margin:0 0 2px">${props.customer.name}</p>
        ${props.customer.nationalIdNumber ? `<p style="font-size:11px;color:#6b7280;margin:0">เลขบัตรประชาชน: <span style="font-family:monospace">${props.customer.nationalIdNumber}</span></p>` : ''}
        ${props.customer.address ? `<p style="font-size:11px;color:#6b7280;margin:2px 0 0">${formatAddress(props.customer.address)}</p>` : ''}
      </div>

      <!-- items table -->
      <table style="width:100%;border-collapse:collapse;font-size:12px;table-layout:fixed">
        <colgroup>
          <col style="width:24px"/>
          <col/>
          <col style="width:60px"/>
          <col style="width:72px"/>
          <col style="width:64px"/>
        </colgroup>
        <thead>
          <tr style="border-bottom:1.5px solid #111">
            <th style="text-align:left;padding:3px 6px 5px 0;color:#6b7280;font-weight:600">#</th>
            <th style="text-align:left;padding:3px 6px 5px;color:#6b7280;font-weight:600">รายการ</th>
            <th style="text-align:right;padding:3px 0 5px 6px;color:#6b7280;font-weight:600">จำนวน</th>
            <th style="text-align:right;padding:3px 0 5px 6px;color:#6b7280;font-weight:600">ราคา/ที่นั่ง</th>
            <th style="text-align:right;padding:3px 0 5px 6px;color:#6b7280;font-weight:600">มูลค่า</th>
          </tr>
        </thead>
        <tbody>
          <tr style="border-bottom:1px solid #e5e7eb">
            <td style="padding:8px 6px 8px 0;vertical-align:top;color:#9ca3af">1</td>
            <td style="padding:8px 6px 8px 4px;vertical-align:top;word-break:break-word">
              <p style="font-weight:500;margin:0 0 2px">ค่าโดยสาร</p>
              ${props.groupPaidFriends?.length ? `<p style="font-size:11px;color:#4b5563;margin:0 0 3px">ชำระแทน: ${props.groupPaidFriends.map(f => f.name).join(', ')}</p>` : ''}
              <p style="font-size:11px;color:#9ca3af;margin:0 0 1px"><span style="color:#6b7280">จุดรับ</span> ${props.pickupLocation || '-'}</p>
              <p style="font-size:11px;color:#9ca3af;margin:0"><span style="color:#6b7280">จุดส่ง</span> ${props.dropoffLocation || '-'}</p>
            </td>
            <td style="padding:8px 0 8px 6px;text-align:right;vertical-align:top;white-space:nowrap">${props.seats} ที่นั่ง</td>
            <td style="padding:8px 0 8px 6px;text-align:right;vertical-align:top;white-space:nowrap">฿${props.pricePerSeat.toLocaleString()}</td>
            <td style="padding:8px 0 8px 6px;text-align:right;vertical-align:top;font-weight:600;white-space:nowrap">฿${props.total.toLocaleString()}</td>
          </tr>
        </tbody>
      </table>

      <!-- total -->
      <div style="display:flex;justify-content:flex-end;padding:10px 0;border-bottom:1px solid #e5e7eb;margin-bottom:14px">
        <table style="font-size:12px;width:220px">
          <tr><td style="color:#6b7280;padding-bottom:3px">รวมเงิน</td><td style="text-align:right;padding-bottom:3px">฿${props.total.toLocaleString()}</td></tr>
          <tr style="border-top:1px solid #e5e7eb">
            <td style="font-weight:700;color:#16a34a;padding-top:5px">จำนวนเงินรวมทั้งสิ้น</td>
            <td style="text-align:right;font-weight:700;font-size:14px;color:#16a34a;padding-top:5px">฿${props.total.toLocaleString()}</td>
          </tr>
        </table>
      </div>

      <!-- payment section -->
      <div style="font-size:12px">
        <!-- หมายเหตุ + checkboxes -->
        <div style="display:flex;align-items:center;gap:16px;margin-bottom:8px;flex-wrap:wrap">
          <span style="color:#6b7280;font-size:11px">การชำระเงินจะสมบูรณ์เมื่อได้รับเงินเรียบร้อยแล้ว</span>
          <div style="display:flex;gap:12px;align-items:center">
            <span>${chk(isCash)}เงินสด</span>
            <span>${chk(isTransfer)}โอนเงิน</span>
          </div>
        </div>
        <!-- grid 2 คอลัมน์ -->
        <table style="width:100%;border-collapse:collapse;border-top:1px solid #e5e7eb;padding-top:8px;margin-top:8px;font-size:12px">
          <tr>
            <td style="width:50%;padding:3px 8px 3px 0">
              <span style="color:#6b7280">ธนาคาร</span>
              <span style="margin-left:4px;font-weight:500;border-bottom:1px solid #d1d5db;display:inline-block;min-width:100px">${bankName}</span>
            </td>
            <td style="width:50%;padding:3px 0">
              <span style="color:#6b7280">เลขที่</span>
              <span style="margin-left:4px;font-family:monospace;font-weight:500;border-bottom:1px solid #d1d5db;display:inline-block;min-width:100px">${accountNo}</span>
            </td>
          </tr>
          <tr>
            <td style="padding:3px 8px 0 0">
              <span style="color:#6b7280">วันที่</span>
              <span style="margin-left:4px;font-weight:500">${props.verifiedAt || '—'}</span>
            </td>
            <td style="padding:3px 0 0">
              <span style="color:#6b7280">จำนวนเงิน</span>
              <span style="margin-left:4px;font-weight:600">${props.total.toLocaleString('th-TH', { minimumFractionDigits: 2 })}</span>
            </td>
          </tr>
        </table>
      </div>

    </div>`

  document.body.appendChild(el)
  try {
    const canvas = await html2canvas(el.firstElementChild, {
      scale: 2, useCORS: true, backgroundColor: '#ffffff',
    })
    const link = document.createElement('a')
    link.download = `ใบเสร็จ-${props.refNo}.png`
    link.href = canvas.toDataURL('image/png')
    link.click()
  } finally {
    document.body.removeChild(el)
  }
}
</script>
