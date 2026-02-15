# backend/Dockerfile

# ใช้ Node.js 18 ตัวเต็ม (Debian Slim) แทน Alpine เพื่อแก้ปัญหา OpenSSL/Prisma
FROM node:18-slim

# ติดตั้ง OpenSSL ที่ Prisma ต้องการ (เพื่อความชัวร์ 100%)
RUN apt-get update -y && apt-get install -y openssl

# กำหนดโฟลเดอร์ทำงาน
WORKDIR /app

# ก๊อปปี้ใบสั่งของ
COPY package*.json ./

# ติดตั้ง dependencies
RUN npm install

# ก๊อปปี้โค้ดทั้งหมด
COPY . .

# สร้าง Prisma Client
RUN npx prisma generate

# เปิดพอร์ต 3000
EXPOSE 3000

# สั่งรัน Server
CMD ["npm", "run", "start"]