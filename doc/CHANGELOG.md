# Changelog

บันทึกการเปลี่ยนแปลงของโปรเจกต์บน branch `main` ตั้งแต่วันที่ 26 กุมภาพันธ์ 2569

---

## [2026-02-27]

### pichamon395-4
- สร้าง folder structure สำหรับ sprint 2 พร้อม README.md ใน `doc/pbi-16/`, `doc/pbi-bonus/`, `test/pbi-16/`, `test/pbi-bonus/`

---

## [2026-02-28]

### pichamon395-4
- เพิ่มหน้า `profile/payment-info.vue` ฉบับเริ่มต้น
- ปรับ `ConfirmModal.vue` ให้เป็นมาตรฐานเดียวกัน
- เพิ่มลิงก์ใน `ProfileSidebar.vue`
- ปรับปรุง `admin/allrequests/` (index และ [id])

---

## [2026-03-01]

### Jularat387-4
- เพิ่ม optional chaining (`?.`) ดักตัวแปร `user` ทั่ว frontend admin pages เพื่อป้องกัน runtime error ตอน build
- เปลี่ยนชื่อ folder จาก `pbi-16` → `Product_Backlog_Items-16` และ `pbi-bonus` → `Product_Backlog_Items-bonus` ใน `doc/` และ `test/`

---

## [2026-03-02]

### pichamon395-4
- เพิ่ม payment verification flow ใน `myRoute/index.vue` (Driver ยืนยัน/ปฏิเสธการชำระเงิน)
- เพิ่มหน้า `profile/payment-info.vue` สำหรับจัดการข้อมูลรับเงิน (PromptPay / บัญชีธนาคาร)
- เพิ่มโลโก้ธนาคารใน `frontend/public/banks/` (8 ธนาคาร)
- แก้ layout หน้า `payment-info.vue` ผิดตำแหน่ง
- แก้ bug modal ไม่ปิดหลัง admin ปฏิเสธคำขอลบบัญชีใน `admin/allrequests/index.vue`

### Thongchai595-6
- เพิ่ม `PaymentSlipModal.vue` (3 ขั้นตอน: เลือกวิธี, อัปโหลดสลิป/เงินสด, ยืนยัน) พร้อม QR PromptPay
- เชื่อมต่อ `myTrip/index.vue` ให้แสดงสถานะชำระเงินและเปิด modal

### Jularat387-4
- เพิ่ม payment methods API (`paymentMethod.controller.js`, `paymentMethod.route.js`)
- อัปเดต `prisma/schema.prisma` เพิ่ม model รองรับข้อมูลการรับเงิน

---

## [2026-03-03]

### pichamon395-4
- ปรับปรุง payment system: refactor `DriverPaymentModal.vue` แยกออกจาก `myRoute/index.vue`, อัปเดต `PaymentSlipModal.vue`, ปรับ `myTrip/index.vue`, แก้ `admin/bookings/`, ปรับปรุง `route.service.js`

### Kittikorn587-5
- แก้ SMTP email delivery ใน `backend/`
- อัปเดต Postman collection และเพิ่ม logic สำหรับ 90-day test validation ใน `backend/src/utils/cronJobs.js`

---

## [2026-03-04]

### Jularat387-4
- แก้ merge conflict ใน `backend/src/routes/index.js` และแก้ค่า `docker-compose.yml`
- อัพโหลด source code sprint 1 ลง `sprint/sprint-1/code/` (frontend + backend ทั้งหมด)

### Thongchai595-6
- เพิ่ม UAT Robot tests สำหรับ PBI-16 (UAT_TEST10–13, UAT_TEST2) ใน `test/Product_Backlog_Items-16/uat/Robot/`
- แก้ `backend/src/routes/test.routes.js` และ `backend/src/services/deletion.service.js` ให้ set `scheduledDeleteAt` ถูกต้อง
- ปรับ audit service ให้ filter ถูกต้องและเพิ่มการตรวจ audit log ใน UAT

### Bunyasak604-1
- เพิ่ม User Manual Sprint 2 (`doc/USER_MANUAL_SPRINT2.md`)

### Kittikorn587-5
- อัปเดต Postman collection สำหรับ PBI-16 และแก้ 90-day time machine (`test/Product_Backlog_Items-16/api/`)
- อัปเดตไฟล์ API testing PDF ใน `sprint/sprint-1/test/API/`

### Ammika356-3
- อัปโหลดเอกสาร ADAPT-blueprint (PBI 16, Acceptance Test, Customer Invisible, UI) ในรูปแบบ PNG แทน PDF เดิม (`doc/`)

---

## [2026-03-05]

### Jularat387-4
- อัพโหลด sprint backlog ลง `sprint-backlog/`

### pichamon395-4
- เพิ่ม `USERMANUAL.md` (PBI-16, PBI-bonus), `CHANGELOG.md` และอัปเดต API Testing collection (85/85 assertions ผ่าน)
- แก้ bug modal ไม่ปิดหลัง admin ปฏิเสธคำขอลบบัญชีใน `admin/allrequests/index.vue` — เพิ่ม loading state และข้อความ "กำลังดำเนินการ..."

### Kittikorn587-5
- ทดสอบ 90-day time machine API บน Production สำเร็จ
- อัปเดต Postman collection — แก้ API paths และเพิ่ม response structure สำหรับ cron deletion

### Siwawit402-3
- เพิ่ม UAT Robot tests สำหรับ PBI-bonus (UAT_TEST08–14) และเอกสารชำระเงินใน `test/Product_Backlog_Items-bonus/uat/`
