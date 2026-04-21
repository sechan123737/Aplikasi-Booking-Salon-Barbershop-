# ✂️ SalonQ – Aplikasi Booking Salon & Barbershop

Aplikasi booking salon/barbershop berbasis **Vue 3 + Supabase** dengan tampilan mobile-first.

---

## 📁 Struktur Proyek

```
src/
├── main.js
├── App.vue
├── style.css
├── router/
│   └── index.js               ← Semua route (public + admin)
├── lib/
│   └── supabase.js            ← Inisialisasi Supabase client
├── stores/                    ← Pinia stores
│   ├── auth.js
│   ├── booking.js
│   ├── services.js
│   ├── staff.js
│   ├── reviews.js
│   └── notifications.js
├── composables/
│   └── useBookingReminder.js  ← Logika reminder notifikasi
├── components/
│   ├── public/
│   │   └── StatusBadge.vue
│   └── admin/
│       └── AdminStatusBadge.vue
└── views/
    ├── public/                ← Halaman user/pelanggan
    │   ├── PublicLayout.vue
    │   ├── HomeView.vue
    │   ├── ServicesView.vue
    │   ├── BookingView.vue       ← Booking 4 langkah (layanan → jadwal → data → konfirmasi)
    │   ├── BookingSuccessView.vue
    │   ├── BookingHistoryView.vue
    │   ├── ReviewView.vue
    │   ├── ProfileView.vue
    │   ├── NotificationsView.vue
    │   ├── LoginView.vue
    │   └── RegisterView.vue
    └── admin/                 ← Panel admin (route dilindungi)
        ├── AdminLayout.vue       ← Sidebar + mobile drawer
        ├── AdminDashboard.vue    ← Statistik & ringkasan
        ├── AdminBookings.vue     ← List semua booking + filter
        ├── AdminBookingDetail.vue← Detail + ubah status
        ├── AdminServices.vue     ← CRUD layanan
        ├── AdminStaff.vue        ← CRUD karyawan
        ├── AdminReviews.vue      ← Moderasi ulasan + statistik rating
        ├── AdminCustomers.vue    ← Data pelanggan agregat
        └── AdminSchedule.vue     ← Jam buka & tanggal libur
```

---

## 🚀 Cara Setup

### 1. Clone & Install

```bash
git clone <repo-url>
cd salon-booking
npm install
```

### 2. Setup Supabase

1. Buat project baru di [supabase.com](https://supabase.com)
2. Buka **SQL Editor** di dashboard Supabase
3. Copy seluruh isi file `supabase/schema.sql` dan jalankan
4. Verifikasi tabel-tabel berikut sudah terbuat:
   - `profiles`, `services`, `staff`, `bookings`, `reviews`
   - `working_hours`, `blocked_dates`, `notifications`
   - Function `get_available_slots`

### 3. Konfigurasi Environment

```bash
cp .env.example .env
```

Buka `.env` dan isi:
```
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

> Ambil dari: Supabase Dashboard → Settings → API

### 4. Jalankan Dev Server

```bash
npm run dev
```

Buka: http://localhost:5173

---

## 👤 Buat Akun Admin

Setelah mendaftar melalui aplikasi, ubah role di Supabase:

```sql
-- Jalankan di SQL Editor Supabase
UPDATE public.profiles
SET role = 'admin'
WHERE id = '<user-id-dari-auth.users>';
```

Atau langsung di **Table Editor** → tabel `profiles` → ubah kolom `role` menjadi `admin`.

Panel admin dapat diakses di: `/admin`

---

## 🗂️ Route Lengkap

### User (Public)
| Route | Halaman |
|---|---|
| `/` | Beranda |
| `/services` | Daftar Layanan |
| `/booking` | Form Booking (4 langkah) |
| `/booking/success` | Konfirmasi Berhasil |
| `/history` | Riwayat Booking *(login)* |
| `/review/:bookingId` | Beri Ulasan *(login)* |
| `/profile` | Profil & Pengaturan *(login)* |
| `/notifications` | Notifikasi *(login)* |
| `/login` | Masuk |
| `/register` | Daftar |

### Admin
| Route | Halaman |
|---|---|
| `/admin/dashboard` | Dashboard & Statistik |
| `/admin/bookings` | Semua Booking + Filter |
| `/admin/bookings/:id` | Detail & Ubah Status |
| `/admin/services` | CRUD Layanan |
| `/admin/staff` | CRUD Karyawan |
| `/admin/reviews` | Moderasi Ulasan |
| `/admin/customers` | Data Pelanggan |
| `/admin/schedule` | Jam Buka & Libur |

---

## ✨ Fitur Lengkap

### User
- ✅ Pilih layanan (berdasar kategori)
- ✅ Booking jadwal 4 langkah
- ✅ Pilih jam kosong real-time (via `get_available_slots` function)
- ✅ Pilih stylist / karyawan (opsional)
- ✅ Data pelanggan (nama, HP, email, catatan)
- ✅ Riwayat booking + filter status
- ✅ Batalkan booking
- ✅ Rating & Review (setelah booking selesai)
- ✅ Notifikasi in-app + real-time via Supabase Realtime
- ✅ Reminder booking H-1
- ✅ Profil & edit data

### Admin
- ✅ Dashboard statistik (booking hari ini, pendapatan, rating)
- ✅ Manajemen booking: list, filter, detail, ubah status, hapus
- ✅ CRUD Layanan (nama, harga, durasi, kategori, aktif/nonaktif)
- ✅ CRUD Karyawan (nama, HP, spesialisasi, bio)
- ✅ Moderasi ulasan (tampilkan/sembunyikan, hapus, rating chart)
- ✅ Data pelanggan agregat (total booking, total belanja)
- ✅ Jadwal jam buka per hari
- ✅ Blokir tanggal libur
- ✅ Kirim notifikasi otomatis (konfirmasi, selesai, dibatalkan)

---

## ⏰ Reminder Otomatis (Opsional)

Deploy Supabase Edge Function untuk reminder H-1:

```bash
npx supabase functions deploy send-reminders
```

Aktifkan cron di: Supabase Dashboard → Edge Functions → Schedules
- Schedule: `0 18 * * *` (setiap hari jam 18:00 WIB / 11:00 UTC)

---

## 🛠️ Tech Stack

| | |
|---|---|
| Frontend | Vue 3 (Composition API) |
| State Management | Pinia |
| Router | Vue Router 4 |
| Styling | Tailwind CSS v3 |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Build Tool | Vite |

---

## 📦 Build Production

```bash
npm run build
```

Output di folder `dist/` — bisa di-deploy ke Vercel, Netlify, atau hosting statis manapun.
