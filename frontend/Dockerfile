# frontend/Dockerfile

# เปลี่ยนจาก 18-alpine เป็น 20 (ตัวเต็ม) เพื่อรองรับ Nuxt รุ่นใหม่และแก้ปัญหา Binding
FROM node:20

# กำหนดโฟลเดอร์ทำงาน
WORKDIR /app

# ก๊อปปี้ใบสั่งของ
COPY package*.json ./

# ติดตั้ง dependencies
RUN npm install

# ก๊อปปี้โค้ดทั้งหมด
COPY . .

# สร้าง Production Build
RUN npm run build

# กำหนดค่า Environment เบื้องต้น
ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=3000

# เปิดพอร์ต 3000
EXPOSE 3000

# สั่งรันไฟล์ที่ Build เสร็จแล้ว
CMD ["node", ".output/server/index.mjs"]