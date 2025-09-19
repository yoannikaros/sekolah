# Catatan Lengkap Fitur Project Seangkatan.id

## 📋 Ringkasan Project
**Seangkatan.id** adalah Platform Evolution Journey yang memungkinkan satu akun tumbuh, berkembang, dan terhubung selamanya dari bangku sekolah sampai karier. Platform ini menggabungkan sistem manajemen sekolah dengan fitur sosial dan edukasi yang terintegrasi.

### 🎯 Target Pengguna
- **Siswa**: Akses penuh ke fitur kelas, quiz, mading, chat
- **Guru/Wali Kelas**: Kelola kelas, buat quiz, moderasi konten
- **Orang Tua**: Akses Parent Channel, lihat progress anak
- **Admin Sekolah**: Kelola seluruh ekosistem sekolah

---

## 🏗️ Arsitektur Teknologi

### Backend
- **Framework**: Node.js dengan Express.js
- **Database**: MySQL dengan schema lengkap
- **Authentication**: JWT dengan bcrypt
- **File Upload**: Multer dengan watermark otomatis
- **Real-time**: WebSocket untuk chat
- **Validation**: Joi schema validation

### Frontend
- **Framework**: Next.js 15.5.3 dengan React 19.1.0
- **Styling**: Tailwind CSS 4
- **Animation**: Framer Motion 12.23.12
- **Icons**: Lucide React
- **TypeScript**: Full TypeScript support

---

## 🔐 Sistem Autentikasi & Otorisasi

### Endpoint Autentikasi

#### POST `/api/auth/register`
**Deskripsi**: Registrasi pengguna baru
**Input**:
```json
{
  "username": "string",
  "email": "string", 
  "password": "string",
  "full_name": "string",
  "role": "owner|school_admin|teacher|parent|student",
  "phone": "string"
}
```
**Output**:
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "student"
  }
}
```

#### POST `/api/auth/login`
**Deskripsi**: Login pengguna
**Input**:
```json
{
  "email": "string",
  "password": "string"
}
```
**Output**:
```json
{
  "success": true,
  "message": "Login successful",
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "student"
  }
}
```

#### POST `/api/auth/logout`
**Deskripsi**: Logout pengguna
**Output**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 📚 Sistem Event Planner

### Endpoint Event Management

#### GET `/api/events`
**Deskripsi**: Mendapatkan daftar semua event
**Query Parameters**:
- `type`: parent_meeting|class_competition|school_event
- `status`: active|cancelled|completed
- `class_id`: ID kelas (opsional)

**Output**:
```json
{
  "success": true,
  "events": [
    {
      "id": 1,
      "title": "Pertemuan Orang Tua",
      "description": "Diskusi progress siswa",
      "type": "parent_meeting",
      "event_date": "2024-02-15",
      "start_time": "09:00:00",
      "end_time": "11:00:00",
      "location": "Ruang Kelas 5A",
      "status": "active",
      "max_participants": 30
    }
  ]
}
```

#### POST `/api/events`
**Deskripsi**: Membuat event baru
**Input**:
```json
{
  "title": "string",
  "description": "string",
  "type": "parent_meeting|class_competition|school_event",
  "event_date": "YYYY-MM-DD",
  "start_time": "HH:MM:SS",
  "end_time": "HH:MM:SS",
  "location": "string",
  "max_participants": "number",
  "class_id": "number (optional)"
}
```

#### PUT `/api/events/:id`
**Deskripsi**: Update event
**Input**: Same as POST `/api/events`

#### DELETE `/api/events/:id`
**Deskripsi**: Hapus event

#### POST `/api/events/:id/book`
**Deskripsi**: Booking slot event
**Input**:
```json
{
  "time_slot": "2024-02-15T09:00:00Z",
  "student_id": "number (for parent meetings)",
  "notes": "string"
}
```

---

## 🧠 Sistem Quiz Center

### Endpoint Quiz Management

#### GET `/api/quizzes`
**Deskripsi**: Mendapatkan daftar quiz
**Query Parameters**:
- `category`: reading|writing|math|science
- `difficulty`: easy|medium|hard
- `class_id`: ID kelas

**Output**:
```json
{
  "success": true,
  "quizzes": [
    {
      "id": 1,
      "title": "Quiz Matematika Dasar",
      "description": "Quiz tentang penjumlahan dan pengurangan",
      "category": "math",
      "difficulty": "easy",
      "time_limit": 30,
      "question_count": 10
    }
  ]
}
```

#### POST `/api/quizzes`
**Deskripsi**: Membuat quiz baru
**Input**:
```json
{
  "title": "string",
  "description": "string",
  "category": "reading|writing|math|science",
  "difficulty": "easy|medium|hard",
  "time_limit": "number (minutes)",
  "class_id": "number"
}
```

#### GET `/api/quizzes/:id`
**Deskripsi**: Mendapatkan detail quiz beserta soal-soalnya

#### POST `/api/quizzes/:id/start`
**Deskripsi**: Memulai attempt quiz baru
**Output**:
```json
{
  "success": true,
  "attempt_id": 123,
  "quiz": {
    "id": 1,
    "title": "Quiz Matematika",
    "time_limit": 30,
    "questions": [
      {
        "id": 1,
        "question": "Berapa hasil 2 + 2?",
        "type": "multiple_choice",
        "options": ["3", "4", "5", "6"],
        "points": 1
      }
    ]
  }
}
```

#### POST `/api/quizzes/:id/answer`
**Deskripsi**: Submit jawaban soal
**Input**:
```json
{
  "attempt_id": "number",
  "question_id": "number", 
  "answer": "string"
}
```

#### POST `/api/quizzes/:id/complete`
**Deskripsi**: Menyelesaikan quiz dan mendapatkan hasil
**Input**:
```json
{
  "attempt_id": "number"
}
```
**Output**:
```json
{
  "success": true,
  "result": {
    "total_score": 8,
    "max_score": 10,
    "percentage": 80,
    "time_spent": 1200,
    "badges_earned": [
      {
        "id": 1,
        "name": "Math Beginner",
        "description": "Completed first math quiz"
      }
    ]
  }
}
```

---

## 🎨 Sistem Mading Online

### Endpoint Mading Management

#### GET `/api/posts`
**Deskripsi**: Mendapatkan daftar postingan mading
**Query Parameters**:
- `type`: artwork|assignment|project
- `status`: draft|pending|approved|rejected
- `class_id`: ID kelas
- `author_id`: ID penulis

**Output**:
```json
{
  "success": true,
  "posts": [
    {
      "id": 1,
      "title": "Lukisan Pemandangan",
      "description": "Karya seni lukisan pemandangan gunung",
      "type": "artwork",
      "author": {
        "id": 5,
        "name": "Andi Pratama",
        "avatar": "/uploads/avatars/andi.jpg"
      },
      "status": "approved",
      "likes_count": 15,
      "comments_count": 3,
      "media_files": [
        {
          "id": 1,
          "filename": "lukisan_001.jpg",
          "path": "/uploads/posts/lukisan_001.jpg",
          "thumbnail_path": "/uploads/thumbnails/lukisan_001_thumb.jpg"
        }
      ],
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

#### POST `/api/posts`
**Deskripsi**: Membuat postingan baru
**Input**: Multipart form data
```
title: string
description: string
type: artwork|assignment|project
subject: string
tags: JSON array
files: File[] (gambar/dokumen)
```

#### PUT `/api/posts/:id`
**Deskripsi**: Update postingan
**Input**: Same as POST `/api/posts`

#### POST `/api/posts/:id/approve`
**Deskripsi**: Menyetujui postingan (hanya guru/admin)

#### POST `/api/posts/:id/reject`
**Deskripsi**: Menolak postingan (hanya guru/admin)
**Input**:
```json
{
  "rejection_reason": "string"
}
```

#### POST `/api/posts/:id/like`
**Deskripsi**: Like/unlike postingan

#### GET `/api/posts/:id/comments`
**Deskripsi**: Mendapatkan komentar postingan

#### POST `/api/posts/:id/comments`
**Deskripsi**: Menambah komentar
**Input**:
```json
{
  "content": "string",
  "parent_comment_id": "number (optional, for replies)"
}
```

---

## 📸 Sistem Galeri Foto

### Endpoint Album Management

#### GET `/api/albums`
**Deskripsi**: Mendapatkan daftar album
**Query Parameters**:
- `class_id`: ID kelas
- `is_public`: true|false

**Output**:
```json
{
  "success": true,
  "albums": [
    {
      "id": 1,
      "title": "Kegiatan Olahraga 2024",
      "description": "Dokumentasi kegiatan olahraga semester 1",
      "cover_photo": "/uploads/albums/cover_001.jpg",
      "photo_count": 25,
      "is_public": true,
      "created_by": {
        "id": 2,
        "name": "Bu Sari"
      }
    }
  ]
}
```

#### POST `/api/albums`
**Deskripsi**: Membuat album baru
**Input**:
```json
{
  "title": "string",
  "description": "string",
  "class_id": "number",
  "is_public": "boolean",
  "allow_download": "boolean",
  "tags": ["string"]
}
```

#### PUT `/api/albums/:id`
**Deskripsi**: Update album

#### POST `/api/albums/:id/photos`
**Deskripsi**: Upload foto ke album
**Input**: Multipart form data
```
photos: File[] (multiple images)
captions: string[] (optional)
tags: JSON array (optional)
```

#### GET `/api/albums/:id/photos`
**Deskripsi**: Mendapatkan foto dalam album

#### DELETE `/api/albums/:id/photos/:photoId`
**Deskripsi**: Hapus foto dari album

---

## 💬 Sistem Chat Real-time

### Endpoint Chat Management

#### GET `/api/chat/rooms`
**Deskripsi**: Mendapatkan daftar chat room
**Output**:
```json
{
  "success": true,
  "rooms": [
    {
      "id": 1,
      "name": "Kelas 5A - Siswa",
      "type": "class_chat",
      "class_id": 1,
      "member_count": 25,
      "last_message": {
        "content": "Jangan lupa PR matematika ya!",
        "sender_name": "Bu Sari",
        "created_at": "2024-01-15T14:30:00Z"
      }
    }
  ]
}
```

#### POST `/api/chat/rooms`
**Deskripsi**: Membuat chat room baru
**Input**:
```json
{
  "name": "string",
  "type": "class_chat|parent_channel|teacher_room",
  "class_id": "number",
  "description": "string"
}
```

#### POST `/api/chat/rooms/:id/join`
**Deskripsi**: Bergabung ke chat room

#### GET `/api/chat/rooms/:id/messages`
**Deskripsi**: Mendapatkan pesan dalam room
**Query Parameters**:
- `limit`: number (default 50)
- `offset`: number (default 0)

#### POST `/api/chat/rooms/:id/messages`
**Deskripsi**: Mengirim pesan
**Input**:
```json
{
  "content": "string",
  "type": "text|sticker|file|image",
  "sticker_id": "number (optional)",
  "reply_to_id": "number (optional)"
}
```

#### DELETE `/api/chat/messages/:id`
**Deskripsi**: Hapus pesan

---

## 🏫 Sistem Manajemen Kelas

### Endpoint Class Management

#### GET `/api/classes`
**Deskripsi**: Mendapatkan daftar kelas
**Output**:
```json
{
  "success": true,
  "classes": [
    {
      "id": 1,
      "name": "Kelas 5A",
      "grade_level": "5",
      "academic_year": "2023/2024",
      "teacher": {
        "id": 2,
        "name": "Bu Sari Wulandari"
      },
      "student_count": 25,
      "is_active": true
    }
  ]
}
```

#### POST `/api/classes`
**Deskripsi**: Membuat kelas baru
**Input**:
```json
{
  "name": "string",
  "grade_level": "string",
  "academic_year": "string",
  "teacher_id": "number",
  "description": "string"
}
```

#### GET `/api/classes/:id`
**Deskripsi**: Mendapatkan detail kelas

#### PUT `/api/classes/:id`
**Deskripsi**: Update kelas

#### DELETE `/api/classes/:id`
**Deskripsi**: Hapus kelas

#### GET `/api/classes/:id/students`
**Deskripsi**: Mendapatkan daftar siswa dalam kelas

---

## 🏆 Sistem Badge & Achievement

### Endpoint Badge Management

#### GET `/api/badges`
**Deskripsi**: Mendapatkan daftar badge
**Output**:
```json
{
  "success": true,
  "badges": [
    {
      "id": 1,
      "name": "Quiz Master",
      "description": "Complete 10 quizzes with 80% score",
      "icon": "/icons/quiz-master.svg",
      "category": "quiz",
      "criteria_type": "quiz_count",
      "criteria_value": 10
    }
  ]
}
```

#### POST `/api/badges`
**Deskripsi**: Membuat badge baru (admin only)

#### GET `/api/badges/:id`
**Deskripsi**: Detail badge

#### PUT `/api/badges/:id`
**Deskripsi**: Update badge

#### DELETE `/api/badges/:id`
**Deskripsi**: Hapus badge

#### POST `/api/badges/:id/award`
**Deskripsi**: Berikan badge ke user
**Input**:
```json
{
  "user_id": "number",
  "quiz_attempt_id": "number (optional)"
}
```

#### POST `/api/badges/:id/revoke`
**Deskripsi**: Cabut badge dari user

---

## 📊 Database Schema

### Tabel Utama

#### users
- **id**: Primary key
- **username**: Unique username
- **email**: Unique email
- **password_hash**: Encrypted password
- **role**: owner|school_admin|teacher|parent|student
- **full_name**: Nama lengkap
- **phone**: Nomor telepon
- **avatar**: Path foto profil
- **is_active**: Status aktif
- **last_login**: Waktu login terakhir

#### classes
- **id**: Primary key
- **name**: Nama kelas
- **grade_level**: Tingkat kelas
- **academic_year**: Tahun ajaran
- **teacher_id**: Foreign key ke users
- **description**: Deskripsi kelas
- **is_active**: Status aktif

#### events
- **id**: Primary key
- **title**: Judul event
- **description**: Deskripsi event
- **type**: parent_meeting|class_competition|school_event
- **event_date**: Tanggal event
- **start_time**: Waktu mulai
- **end_time**: Waktu selesai
- **location**: Lokasi event
- **created_by**: Foreign key ke users
- **max_participants**: Maksimal peserta
- **status**: active|cancelled|completed

#### quizzes
- **id**: Primary key
- **title**: Judul quiz
- **description**: Deskripsi quiz
- **category**: reading|writing|math|science
- **difficulty**: easy|medium|hard
- **time_limit**: Batas waktu (menit)
- **created_by**: Foreign key ke users
- **class_id**: Foreign key ke classes
- **is_active**: Status aktif

#### posts (Mading)
- **id**: Primary key
- **title**: Judul postingan
- **description**: Deskripsi
- **type**: artwork|assignment|project
- **author_id**: Foreign key ke users
- **class_id**: Foreign key ke classes
- **status**: draft|pending|approved|rejected
- **views**: Jumlah views
- **approved_by**: Foreign key ke users (yang approve)

#### albums
- **id**: Primary key
- **title**: Judul album
- **description**: Deskripsi album
- **cover_photo**: Path foto cover
- **class_id**: Foreign key ke classes
- **created_by**: Foreign key ke users
- **is_public**: Status public
- **allow_download**: Izin download
- **photo_count**: Jumlah foto

#### chat_rooms
- **id**: Primary key
- **name**: Nama room
- **type**: class_chat|parent_channel|teacher_room
- **class_id**: Foreign key ke classes
- **created_by**: Foreign key ke users
- **slow_mode_enabled**: Status slow mode
- **allow_stickers**: Izin sticker
- **allow_files**: Izin file
- **is_active**: Status aktif

#### messages
- **id**: Primary key
- **room_id**: Foreign key ke chat_rooms
- **sender_id**: Foreign key ke users
- **content**: Isi pesan
- **type**: text|sticker|file|image
- **reply_to_id**: Foreign key ke messages (untuk reply)
- **is_edited**: Status edit
- **is_deleted**: Status hapus

---

## 🔧 Fitur Khusus

### 1. Watermark Otomatis
- Semua foto yang diupload otomatis diberi watermark sekolah
- Opacity watermark dapat diatur di system settings
- Watermark menggunakan logo sekolah + nama sekolah

### 2. Slow Mode Chat
- Mencegah spam dengan membatasi interval pengiriman pesan
- Interval dapat diatur per room
- Default 5 detik antar pesan

### 3. Content Moderation
- Semua postingan mading harus disetujui guru/admin
- Komentar dapat dimoderasi
- Auto-filter kata kasar di chat

### 4. Gamification System
- Badge otomatis berdasarkan achievement
- Leaderboard quiz per kelas
- Progress tracking untuk setiap siswa

### 5. File Upload Security
- Validasi tipe file yang diizinkan
- Maksimal ukuran file 5MB (configurable)
- Scan virus untuk file upload
- Thumbnail otomatis untuk gambar

---

## 🚀 Deployment & Environment

### Environment Variables
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=password
DB_NAME=seangkatan_db
JWT_SECRET=your_jwt_secret
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=5242880
WATERMARK_OPACITY=0.3
```

### Folder Structure
```
backend/
├── server.js (Main server file)
├── mysql_complete_schema.sql (Database schema)
├── uploads/ (File uploads)
├── package.json
└── node_modules/

frontend/
├── src/
│   ├── app/ (Next.js pages)
│   └── components/ (React components)
├── public/ (Static assets)
├── package.json
└── node_modules/
```

---

## 📝 Catatan Pengembangan

### Status Implementasi
✅ **Completed Features**:
- Authentication & Authorization system
- Event Planner dengan booking system
- Quiz Center dengan gamification
- Mading Online dengan moderation
- Gallery dengan watermark
- Real-time Chat system
- Class Management
- Badge & Achievement system

### API Response Format
Semua API menggunakan format response yang konsisten:
```json
{
  "success": boolean,
  "message": "string",
  "data": object|array,
  "error": "string (jika ada error)"
}
```

### Error Handling
- HTTP Status Code yang sesuai (200, 400, 401, 403, 404, 500)
- Error message yang informatif
- Logging untuk debugging
- Validation error yang detail

### Security Features
- JWT token authentication
- Password hashing dengan bcrypt
- Input validation dengan Joi
- File upload validation
- SQL injection prevention
- XSS protection
- CORS configuration

---

*Dokumentasi ini dibuat berdasarkan analisis lengkap kode server.js, database schema, dan struktur frontend project Seangkatan.id*