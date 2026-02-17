---

## 🐳 Docker Guide & Troubleshooting (คู่มือการใช้งาน)

โปรเจกต์นี้รันด้วย **Docker** 100% ไม่ต้องลง Node.js ในเครื่องก็รันได้ (ระบบจะใช้ Node v20 ให้เองอัตโนมัติ)

### 🚀 1. เริ่มต้นใช้งาน (Quick Start)

ก่อนรัน ตรวจสอบให้แน่ใจว่ามีไฟล์ >>>>>`.env`<<<<< อยู่ที่ Root Folder แล้ว

```bash
# สั่งรันระบบ (Build & Start)
docker-compose up -d --build

```

> *รอสัก 1-2 นาที ให้ Backend สร้าง Database และ Admin ให้เสร็จก่อนเข้าใช้งาน*

---

### 🎮 2. คำสั่งพื้นฐาน (Common Commands)

| การกระทำ | คำสั่ง |
| --- | --- |
| **เปิดเซิร์ฟเวอร์** | `docker-compose up -d` |
| **ปิดเซิร์ฟเวอร์** | `docker-compose down` |
| **ดู Logs ทั้งหมด** | `docker-compose logs -f` |
| **ดู Logs เฉพาะ Backend** | `docker logs -f painamnae-backend` |

---

### 🛠️ 3. วิธีแก้ปัญหา (Troubleshooting) - **สำคัญ!**

หากเจออาการเหล่านี้:

* ❌ Login ไม่ได้ (User Admin หาย)
* ❌ Database พัง / เชื่อมต่อไม่ได้
* ⚪ หน้าเว็บขาว (White Screen)
* 🔄 แก้โค้ดแล้วไม่เปลี่ยน

**ให้ล้างระบบใหม่ (Factory Reset):**

1. **ระเบิดถังข้อมูลทิ้ง** (ลบ Database และ Volumes เก่าที่ค้างค่าผิดๆ):
```bash
docker-compose down -v

```


2. **สร้างใหม่ทั้งหมด** (เริ่มระบบใหม่):
```bash
docker-compose up -d --build

```


3. **(ทางเลือก) ถ้า Admin ยังไม่มา**:
```bash
docker restart painamnae-backend

```



---

### 💻 4. คำสั่งขั้นสูง (Advanced)

**เข้าไปในกล่อง Backend (Shell Access):**

```bash
docker exec -it painamnae-backend sh
# พิมพ์ exit เพื่อออก

```

**สั่งอัปเดต Database (ถ้าแก้ schema.prisma):**

```bash
docker exec -it painamnae-backend npx prisma db push

```

**ดูข้อมูลใน DB ผ่าน Web (Prisma Studio):**

```bash
docker exec -it painamnae-backend npx prisma studio
# เปิด Browser ไปที่ http://localhost:5555

```
**ปริ้นท์ตัวแปร Environment ทั้งหมดในกล่องออกมา:**

```bash
docker exec painamnae-backend printenv

```

# Pai Nam Nae - A Safe Ride Sharing App

<!-- A safe ride-sharing application with a **Nuxt.js** frontend and **Express.js** backend, powered by **Prisma** ORM and **PostgreSQL**. -->
"Pai Nam Nae is a carpooling web application that connects drivers and passengers heading in the same direction, with a primary focus on safety and convenience. It is developed with a **Nuxt.js** frontend and an **Express.js**  backend, powered by the **Prisma** ORM and a **PostgreSQL** database."
## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Google Maps APIs Used](#google-maps-apis-used)
- [Prerequisites](#prerequisites)
- [Security & Rate Limiting](#security--rate-limiting)
- [Installation](#installation)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [API Endpoints](#api-endpoints)
- [License](#license)
- [Contact](#contact)

## Features

- User registration with multi-step identity verification
- JWT authentication
- Role-based access control (PASSENGER / DRIVER / ADMIN)
- Route & Trip Management: Drivers can create and manage their routes.
- Booking System: Passengers can find and book trips.
- Real-time Notifications: In-app notifications for booking status and other events.
- Google Maps Integration: For directions, geocoding, and distance calculation.
- Vehicle management (CRUD, set default)
- User profile management
- Admin capabilities for user management (list, update status, delete)
- Image uploads for verification handled via **Cloudinary**
- Input validation via **Zod**
- API documentation with Swagger UI
<!-- - Health-check & Metrics endpoints (`/health`, `/metrics`) -->

## Tech Stack

- **Frontend:** Nuxt.js, Tailwind CSS
- **Backend:** Express.js
- **ORM:** Prisma
- **Database:** PostgreSQL
- **Authentication:** JSON Web Tokens (JWT)
- **Image Storage:** Cloudinary
- **Validation:** Zod
- **API Docs:** Swagger (Swagger UI Express, Swagger JSDoc)

## Google Maps APIs Used

- **Backend**
  - Geocoding API
  - Directions API
  - Distance Matrix API

- **Frontend**
  - Maps JavaScript API
  - Places API
  - Places API (New)
  - Geocoding API
  - Distance Matrix API

## Prerequisites

- Node.js v16+
- npm or yarn
- PostgreSQL instance
- Cloudinary Account (for API Key, Secret, and Cloud Name)
- Google Maps API Keys (for both frontend and backend)

<!-- ## Security & Rate Limiting

- **Rate Limiting:** 100 requests per 15 minutes per IP (returns 429 Too Many Requests when exceeded)
- **Security Headers:** Helmet is used to set various security-related HTTP headers -->

## Installation

1.  **Clone the repository**

    ```bash
    git clone https://github.com/Pai-Nam-Nae-A-Safe-Ride-Sharing/PaiNamNaeWebApp.git
    cd PaiNamNaeWebApp
    ```

2.  **Install backend dependencies**

    ```bash
    cd backend
    npm install
    ```

3.  **Install frontend dependencies**

    ```bash
    cd ../frontend
    npm install
    ```

## Environment Variables

Create a `.env` file in the `backend` directory with the following:

```ini
# Server
PORT=3000

# Database
DATABASE_URL="postgresql://<user>:<password>@<host>:<port>/<database>?schema=public"

# JWT Secret
JWT_SECRET=your_super_secret_jwt_key

# Cloudinary Credentials
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Google Maps API Key (Backend)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_for_backend

# Google Maps API Key (Frontend)
NUXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key_for_frontend
```

## Database Setup

1.  **Navigate to the backend directory**
    ```bash
    cd backend
    ```
2.  **Generate Prisma Client**
    ```bash
    npx prisma generate
    ```
3.  **Run migrations**
    ```bash
    npx prisma migrate dev --name init
    ```

## Running the Application

1.  **Start the backend**
    ```bash
    cd backend
    npm run dev # starts Express server on http://localhost:3000
    ```
2.  **Start the frontend**
    ```bash
    cd frontend
    npm run dev # starts Nuxt.js on http://localhost:3001
    ```

## API Endpoints

Visit [**https://painamnaesoftenscrumteam-production.up.railway.app/documentation**](https://painamnaesoftenscrumteam-production.up.railway.app/documentation) for interactive Swagger UI and full API reference.

### Authentication

- `POST /api/auth/login` – Login with email/username & password.
- `PUT /api/auth/change-password` – Change current user's password.

### Users

- `POST /api/users` – Register a new user.
- `GET /api/users/me` – Get current user's profile.
- `PUT /api/users/me` – Update current user's profile.
- `GET /api/users/:id` – Get user's public profile by ID.
- `GET /api/users/admin` – List all users (Admin only).
- `GET /api/users/admin/:id` – Get a user's full details by ID (Admin only).
- `PUT /api/users/admin/:id` – Update user by ID (Admin only).
- `DELETE /api/users/admin/:id` – Delete user by ID (Admin only).
- `PATCH /api/users/admin/:id/status` – Set user's status (Admin only).

### Vehicles

- `GET /api/vehicles` – List all vehicles for the current user.
- `POST /api/vehicles` – Create a new vehicle.
- `GET /api/vehicles/:id` – Get vehicle by ID.
- `PUT /api/vehicles/:id` – Update a vehicle.
- `DELETE /api/vehicles/:id` – Delete a vehicle.
- `PUT /api/vehicles/:id/default` – Set a vehicle as the default.
- `GET /api/vehicles/admin` - List all vehicles in the system (Admin only).
- `GET /api/vehicles/admin/:id` - Get a vehicle by ID (Admin only).
- `GET /api/vehicles/admin/user/:userId` - List all vehicles for a specific user (Admin only).
- `POST /api/vehicles/admin` - Create a vehicle for a user (Admin only).
- `PUT /api/vehicles/admin/:id` - Update a vehicle (Admin only).
- `DELETE /api/vehicles/admin/:id` - Delete a vehicle (Admin only).

### Driver Verifications

- `GET /api/driver-verifications/me` – View your own verification record.
- `POST /api/driver-verifications` – Submit a new driver verification request.
- `PUT /api/driver-verifications/:id` – Update your verification request.
- `GET /api/driver-verifications/admin` – List all verification requests (Admin only).
- `GET /api/driver-verifications/admin/:id` – Get a specific verification record (Admin only).
- `POST /api/driver-verifications/admin` - Create a verification record for a user (Admin only).
- `PUT /api/driver-verifications/admin/:id` - Update a verification record (Admin only).
- `DELETE /api/driver-verifications/admin/:id` - Delete a verification record (Admin only).
- `PATCH /api/driver-verifications/:id/status` – Approve or reject a driver verification (Admin only).

### Routes

- `GET /api/routes` – List all available routes (Public).
- `GET /api/routes/:id` – Get route by ID (Public).
- `GET /api/routes/me` - List all routes created by the current logged-in driver.
- `POST /api/routes` – Create a new route (Driver only).
- `PUT /api/routes/:id` – Update your route (Driver only).
- `DELETE /api/routes/:id` – Delete your route (Driver only).
- `GET /api/routes/admin` - List all routes in the system (Admin only).
- `GET /api/routes/admin/driver/:driverId` - Get all routes for a specific driver (Admin only).
- `POST /api/routes/admin` - Create a route for a driver (Admin only).
- `PUT /api/routes/admin/:id` - Update a route (Admin only).
- `DELETE /api/routes/admin/:id` - Delete a route (Admin only).

### Bookings

- `GET /api/bookings/me` - List all bookings made by the current user.
- `GET /api/bookings/:id` - Get a booking by its ID.
- `POST /api/bookings` - Create a new booking for a route.
- `PATCH /api/bookings/:id/status` - Update a booking's status (e.g., confirm/reject) (Driver only).
- `PATCH /api/bookings/:id/cancel` - Cancel a booking.
- `DELETE /api/bookings/:id` - Delete a booking.
- `GET /api/bookings/admin` - List all bookings in the system (Admin only).
- `GET /api/bookings/admin/:id` - Get a booking by ID (Admin only).
- `POST /api/bookings/admin` - Create a booking for a user (Admin only).
- `PUT /api/bookings/admin/:id` - Update a booking (Admin only).
- `DELETE /api/bookings/admin/:id` - Delete a booking (Admin only).

### Notifications

- `GET /api/notifications` - List all notifications for the current user.
- `GET /api/notifications/unread-count` - Get the count of unread notifications.
- `PATCH /api/notifications/read-all` - Mark all notifications as read.
- `GET /api/notifications/:id` - Get a notification by ID.
- `PATCH /api/notifications/:id/read` - Mark a notification as read.
- `PATCH /api/notifications/:id/unread` - Mark a notification as unread.
- `DELETE /api/notifications/:id` - Delete a notification.
- `GET /api/notifications/admin` - List all notifications in the system (Admin only).
- `POST /api/notifications/admin` - Create a new notification (Admin only).
- `DELETE /api/notifications/admin/:id` - Delete a notification (Admin only).

### Maps

- `POST /api/maps/directions` – Get directions between locations.
- `GET /api/maps/geocode` – Convert an address to coordinates.
- `GET /api/maps/reverse-geocode` – Convert coordinates to an address.

### Health-check & Metrics

- `GET /health` – Check application & database health.
- `GET /metrics` – Expose Prometheus-compatible metrics.
- `GET /documentation` - Access the Swagger UI API documentation page.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


## Contact

For questions or feedback, reach out to:

**Email:**
- [jonathandoillon2002@gmail.com](mailto:jonathandoillon2002@gmail.com)
- [seth.s@kkumail.com](mailto:seth.s@kkumail.com)
