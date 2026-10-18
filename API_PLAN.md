# API Plan: TryTuist Backend (Go + PostgreSQL)

Rencana backend untuk aplikasi iOS **TryTuist** (pesan makanan & minuman). Dokumen ini adalah **kontrak** antara iOS dan backend. Semua nama field dan bentuk JSON di sini sudah sama persis dengan DTO di aplikasi, jadi begitu backend jadi, iOS cukup mengganti `USE_MOCK_DATA = NO`.

> Backend ada di repo terpisah `trytuist-api/`, berdampingan dengan `trytuist/` (iOS) dan `trytuistadmin/` (web admin).

---

## Daftar isi

1. [Ringkasan & stack](#1-ringkasan--stack)
2. [Environment](#2-environment)
3. [Konvensi API](#3-konvensi-api)
4. [Daftar endpoint](#4-daftar-endpoint) · [4.1 Status data per screen](#41-status-data-per-screen-dari-api-atau-masih-di-aplikasi)
5. [Detail endpoint](#5-detail-endpoint)
6. [Skema database (PostgreSQL)](#6-skema-database-postgresql)
7. [Aturan bisnis](#7-aturan-bisnis)
8. [Struktur project Go](#8-struktur-project-go)
9. [Seed data](#9-seed-data)
10. [Roadmap & checklist](#10-roadmap--checklist)
11. [Integrasi ke iOS](#11-integrasi-ke-ios)

---

## 1. Ringkasan & stack

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| Bahasa | **Go 1.23+** | |
| HTTP router | [`go-chi/chi/v5`](https://github.com/go-chi/chi) | Ringan, kompatibel `net/http`, middleware jelas |
| Database | **PostgreSQL 16** | |
| Driver | [`jackc/pgx/v5`](https://github.com/jackc/pgx) (`pgxpool`) | Driver Postgres paling lengkap |
| Query | [`sqlc`](https://sqlc.dev) | Tulis SQL biasa → dapat kode Go yang type-safe |
| Migrasi | [`golang-migrate`](https://github.com/golang-migrate/migrate) | File `.up.sql` / `.down.sql` |
| Auth | JWT ([`golang-jwt/jwt/v5`](https://github.com/golang-jwt/jwt)) + refresh token di DB | |
| Password | `golang.org/x/crypto/bcrypt` | |
| Validasi | [`go-playground/validator/v10`](https://github.com/go-playground/validator) | |
| Logging | `log/slog` (stdlib), format JSON | |
| Lokal | Docker Compose (Postgres) | |

Arsitektur backend sengaja dibuat mirip dengan iOS: **handler (HTTP) → service (aturan bisnis) → repository (SQL)**. DTO request/response dipisah dari model database.

---

## 2. Environment

Satu backend, tiga environment. Masing-masing berpasangan dengan scheme iOS:

| Backend `APP_ENV` | Base URL | Database | Scheme iOS | `API_KEY` iOS |
|---|---|---|---|---|
| `dev` | `http://localhost:8080` | Postgres lokal (Docker) | `TryTuist-Dev` | `dev-local-api-key` |
| `staging` | `https://staging-api.trytuist.com` | Postgres staging | `TryTuist-Staging` | `staging-api-key-change-me` |
| `prod` | `https://api.trytuist.com` | Postgres production (managed, backup harian) | `TryTuist-Prod` | `prod-api-key-change-me` |

Variabel environment backend (`.env.example`):

```dotenv
APP_ENV=dev                       # dev | staging | prod
PORT=8080
DATABASE_URL=postgres://trytuist:trytuist@localhost:5432/trytuist?sslmode=disable
API_KEYS=dev-local-api-key        # dipisah koma; dicocokkan dengan header X-API-Key
JWT_SECRET=ganti-dengan-random-64-byte
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=720h              # 30 hari
LOG_LEVEL=debug                   # debug (dev) | info (staging/prod)
GOOGLE_CLIENT_IDS=                # client ID iOS Google (dipisah koma per env); kosong = login Google nonaktif
# Pembayaran online (§5.27)
MIDTRANS_SERVER_KEY=              # sandbox: SB-Mid-server-…; kosong = Bayar Online nonaktif
MIDTRANS_IS_PRODUCTION=false
PUBLIC_BASE_URL=http://localhost:8080   # finish URL Snap; webhook butuh URL publik (tunnel) di dev
PAYMENT_EXPIRY=15m
COD_ENABLED=true
# Notifikasi push APNs (§5.28). Kosong = push hanya dicatat di log.
APNS_KEY_ID=                      # Key ID dari developer.apple.com → Keys (APNs)
APNS_TEAM_ID=                     # Team ID (Membership)
APNS_KEY_FILE=                    # path file AuthKey_XXXX.p8 (jangan di-commit)
```

`docker-compose.yml` untuk dev:

```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: trytuist
      POSTGRES_PASSWORD: trytuist
      POSTGRES_DB: trytuist
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
volumes:
  pgdata:
```

> ⚠️ Simulator iOS bisa langsung mengakses `localhost` Mac. Untuk device fisik, ganti `API_BASE_URL` di `Configs/Dev.xcconfig` dengan IP Mac di jaringan yang sama, misalnya `http:/$()/192.168.1.10:8080`.

---

## 3. Konvensi API

### 3.1 Umum

| Aturan | Nilai |
|---|---|
| Prefix versi | `/v1` |
| Format | JSON, `Content-Type: application/json` |
| Penamaan field | **snake_case** (`product_id`, `access_token`) |
| Uang | **integer Rupiah** tanpa desimal (`15000` = Rp 15.000). iOS memetakannya ke `Decimal` |
| Waktu | ISO‑8601 dengan zona waktu (`2024-08-20T12:46:00+07:00`). Pengecualian: `expires_at` token berupa **unix seconds** |
| ID | `string`. Katalog memakai kode (`P01`, `coffee`); user/order memakai UUID |
| Header wajib | `X-API-Key: <key>` di semua endpoint (kecuali `/healthz`) |
| Header auth | `Authorization: Bearer <access_token>` untuk endpoint 🔒 |
| Bahasa pesan | Bahasa Indonesia (pesan bisa langsung ditampilkan) |

> Pakai `X-API-Key`, **bukan** `API_KEY`. Header dengan underscore dibuang diam-diam oleh Nginx dan beberapa proxy.

### 3.2 Envelope sukses

Semua response sukses dibungkus seperti ini (iOS: `APIEnvelope<T>`):

```json
{
  "code": 200,
  "message": "success",
  "data": { },
  "meta": { "page": 1, "limit": 20, "total": 14 }
}
```

`meta` hanya ada pada endpoint list yang berpaginasi. iOS mengabaikan field yang tidak dikenal.

### 3.3 Envelope error

```json
{
  "code": 401,
  "message": "Email atau password salah.",
  "error": {
    "type": "INVALID_CREDENTIALS",
    "details": [ { "field": "email", "message": "wajib diisi" } ]
  }
}
```

| HTTP | `error.type` | Kapan | Dipetakan iOS ke |
|---|---|---|---|
| 400 | `VALIDATION_ERROR` | Body/query tidak valid | `AuthError.invalidCredentials` (login) |
| 401 | `INVALID_CREDENTIALS` | Email/password salah | `AuthError.invalidCredentials` |
| 401 | `UNAUTHORIZED` / `TOKEN_EXPIRED` | Token tidak ada/kedaluwarsa | (refresh token → retry) |
| 403 | `INVALID_API_KEY` | `X-API-Key` salah | `.unknown` |
| 404 | `NOT_FOUND` | Resource tidak ada | `.unknown` |
| 409 | `EMAIL_ALREADY_REGISTERED` | Register email yang sudah ada | `AuthError.emailAlreadyRegistered` |
| 422 | `PRODUCT_UNAVAILABLE`, `INVALID_QUANTITY`, `EMPTY_CART`, `INVALID_VOUCHER` | Aturan bisnis gagal | `CartError.*` |
| 429 | `RATE_LIMITED` | Terlalu banyak request (login) | `.unknown` |
| 500 | `INTERNAL_ERROR` | Error server | `.unknown` |

### 3.4 Paginasi

Query: `?page=1&limit=20` (default `page=1`, `limit=20`, maksimal `100`). Response menyertakan `meta`.

---

## 4. Daftar endpoint

🔒 = butuh `Authorization: Bearer`. **Fase** menunjukkan urutan pengerjaan (lihat §10).

| # | Method | Path | 🔒 | Fase | Dipakai di iOS |
|---|---|---|---|---|---|
| 1 | `GET` | `/healthz` | | 1 | (monitoring) |
| 2 | `POST` | `/v1/auth/register` | | 1 | Sign Up → `AuthAPIDataSource.register` |
| 3 | `POST` | `/v1/auth/login` | | 1 | Sign In → `AuthAPIDataSource.login` |
| 4 | `POST` | `/v1/auth/refresh` | | 1 | (auto refresh token) |
| 5 | `POST` | `/v1/auth/logout` | 🔒 | 1 | Profil → Keluar |
| 5b | `POST` | `/v1/auth/google` | | 1 | Sign In & Sign Up → "Lanjutkan dengan Google" → `AuthAPIDataSource.google` (§5.3b) |
| 6 | `GET` | `/v1/banners` | | 1 | Beranda → carousel promo |
| 7 | `GET` | `/v1/categories` | | 1 | Beranda (grid), Menu (chip) |
| 8 | `GET` | `/v1/products` | | 1 | Beranda (Paling Laris, Rekomendasi), Menu |
| 9 | `GET` | `/v1/products/{id}` | | 1 | Detail produk (deeplink / refresh) |
| 10 | `POST` | `/v1/orders/quote` | 🔒 | 2 | Keranjang → hitung subtotal, ongkir, diskon, total |
| 11 | `POST` | `/v1/orders` | 🔒 | 2 | Keranjang → Pesan Sekarang |
| 12 | `GET` | `/v1/orders` | 🔒 | 2 | Tab Pesanan → `OrderAPIDataSource` |
| 13 | `GET` | `/v1/orders/{id}` | 🔒 | 2 | Detail pesanan |
| 14 | `POST` | `/v1/orders/{id}/cancel` | 🔒 | 2 | Batalkan pesanan (status `PENDING`) |
| 15 | `POST` | `/v1/orders/{id}/rating` | 🔒 | 3 | Pesanan → Beri Nilai |
| 16 | `GET` | `/v1/me` | 🔒 | 3 | Profil (nama, tier, poin, voucher, saldo) |
| 17 | `PATCH` | `/v1/me` | 🔒 | 3 | Profil → Edit Profil (`ProfileAPIDataSource.updateProfile`) |
| 18 | `GET`/`POST` | `/v1/me/addresses` | 🔒 | 3 | Profil → Alamat Pengiriman, header "Antar ke" |
| 19 | `PATCH`/`DELETE` | `/v1/me/addresses/{id}` | 🔒 | 3 | Alamat → ubah, jadikan utama, hapus |
| 20 | `GET` | `/v1/me/favorites` | 🔒 | 3 | Profil → Menu Favorit |
| 21 | `PUT`/`DELETE` | `/v1/me/favorites/{product_id}` | 🔒 | 3 | Detail produk → ❤️ |
| 22 | `GET` | `/v1/me/vouchers` | 🔒 | 3 | Profil → Voucher |
| 23 | `GET` | `/v1/stores?lat=&lng=` | | 3d | Beranda → "Dari: <outlet>" (outlet terdekat dari alamat utama, bisa diganti) (§5.26) |
| 24 | `GET` | `/v1/home` | 🔒* | 1b | Beranda: semua isi halaman dalam satu request (§5.18) |
| 25 | `GET` | `/v1/app-config` | | 1b | Onboarding, ongkir, menu Profil, link bantuan, versi minimal (§5.19) |
| 26 | `GET` | `/v1/promotions/featured` | 🔒* | 3 | Kartu promo langganan di Profil (§5.20) |
| 27 | `POST` | `/v1/subscriptions/{plan_id}/activate` | 🔒 | 3 | Profil → tombol "Aktifkan" (§5.20) |
| 28 | `GET`/`POST` | `/v1/me/payment-methods` | 🔒 | 3b | Profil → Metode Pembayaran; tambah e-wallet (§5.21) |
| 29 | `PUT` | `/v1/me/payment-methods/default` | 🔒 | 3b | Metode Pembayaran → pilih metode utama (§5.21) |
| 30 | `DELETE` | `/v1/me/payment-methods/{id}` | 🔒 | 3b | Metode Pembayaran → hapus e-wallet (§5.21) |
| 31 | `GET` | `/v1/help` | | 3b | Profil → Pusat Bantuan (topik, FAQ, kontak, cari) (§5.22) |
| 32 | `GET` | `/v1/legal/{slug}` | | 3b | Profil → Kebijakan Privasi, Syarat & Ketentuan (§5.23) |
| 33 | `GET` | `/v1/promotions/popup` | | 3c | Beranda → popup promo makanan/minuman murah → Detail menu (§5.24) |
| 34 | `GET` | `/v1/admin/me` | 🛡 | 4 | Web admin: cek akun admin setelah login (§5.25) |
| 35 | `GET` | `/v1/admin/dashboard?from=&to=` | 🛡 | 4 | Web admin → Dashboard penjualan & pembelian |
| 36 | `GET` | `/v1/admin/orders` · `/v1/admin/orders/{id}` | 🛡 | 4 | Web admin → Pesanan (semua pelanggan) |
| 37 | `PATCH` | `/v1/admin/orders/{id}/status` | 🛡 | 4 | Web admin → Tandai sukses / gagal / batal, majukan status |
| 38 | `GET` `POST` · `PATCH` | `/v1/admin/products[/{id}]` | 🛡 | 4 | Web admin → Tambah menu; ubah harga, varian, foto, stok, nama, deskripsi |
| 39 | `GET` `POST` · `PATCH` `DELETE` | `/v1/admin/deals[/{id}]` | 🛡 | 4 | Web admin → Promo (§5.24) |
| 40 | `GET` | `/v1/admin/customers` · `/v1/admin/audit-logs` | 🛡 | 4 | Web admin → Pelanggan, Aktivitas |
| 41 | `GET` `POST` · `PATCH` | `/v1/admin/stores[/{id}]` | 🛡 | 4b | Web admin → Outlet: tambah, jam buka, radius, tutup sementara (§5.26) |
| 42 | `PUT` | `/v1/admin/stores/{id}/products/{product_id}` | 🛡 | 4b | Web admin → Menu → stok per outlet (habis / tersedia) |
| 43 | `POST` | `/v1/checkout` | 🔒 | 5 | Keranjang → Pesan Sekarang / Bayar: COD → pesanan, Bayar Online → sesi Midtrans (§5.27) |
| 44 | `GET` | `/v1/payments/{id}` · `/v1/payments?status=PENDING` | 🔒 | 5 | Layar Pembayaran (polling), kartu "Menunggu pembayaran" |
| 45 | `POST` | `/v1/payments/{id}/cancel` | 🔒 | 5 | Batalkan pembayaran |
| 46 | `POST` | `/v1/payments/midtrans/notification` | publik (signature) | 5 | Webhook Midtrans |
| 47 | `GET` | `/v1/payments/finish` · `/v1/admin/payments` | publik · 🛡 | 5 | Finish URL Snap · Web admin → Pembayaran (*belum*, fase 5b) |
| 48 | `PUT` | `/v1/me/devices` | 🔒 | 5c | Setelah login: daftarkan device token APNs (§5.28) |
| 49 | `POST` | `/v1/devices/unregister` | (API key saja) | 5c | Logout / sesi habis / cold start: berhenti menerima push |
| 50 | `POST` | `/v1/dev/push-test` | 🔒 dev | 5c | Kirim notifikasi contoh ke device sendiri (`APP_ENV=dev`) |

🛡 = 🔒 + akun ber-role `ADMIN` (403 `FORBIDDEN` untuk akun biasa). Dipakai web admin `trytuistadmin` (§5.25).

🔒* = token **opsional**. Tanpa token, response tetap berhasil tetapi bagian yang personal (nama, poin, alamat) kosong.

Endpoint yang **sudah terdaftar di `EndpointAPI.swift`**: 2, 3, 4, 5b, 6, 7, 8 (`store_id`), 11, 12 (filter + paginasi), 13, 15, 16, 17, 18, 19, 23, 28, 29, 30, 31, 32, 33, 43, 44, 45, 48, 49.

### 4.1 Status data per screen: dari API atau masih di aplikasi

Dengan `USE_MOCK_DATA = NO`, banner, kategori, dan produk di Beranda & Menu **sudah dari API** (`/v1/banners`, `/v1/categories`, `/v1/products`). Yang masih ditulis langsung di kode iOS adalah data di bawah ini. Semuanya ditargetkan pindah ke backend:

| Screen | Data | Sekarang di iOS | Pindah ke |
|---|---|---|---|
| Beranda | Nama user ("Ishinkuro") | `HomeState.userName` | `/v1/home` → `user.name` |
| Beranda | Alamat "Antar ke" | ✅ API (`/v1/me/addresses`) + lokasi perangkat (CoreLocation) → outlet terdekat lewat `/v1/stores?lat=&lng=` | — |
| Beranda | Isi & urutan section "Paling Laris" / "Rekomendasi" | dihitung di `GetHomeContentUseCase` (sort `sold_count` / `rating`) | `/v1/home` → `sections` (server yang menentukan) |
| Beranda | Teks sapaan ("Selamat pagi") | `HomeState.greeting` (jam lokal) | `/v1/home` → `greeting` (opsional, boleh tetap lokal) |
| Beranda | Placeholder kolom cari | `HomeView` | `/v1/app-config` → `search_placeholder` |
| Menu | Daftar kategori & produk | ✅ API | — |
| Detail produk | Varian, harga | ✅ API (bagian dari `/v1/products`) | — |
| Detail produk | Batas jumlah (1–20) & catatan (100) | `AddToCartUseCase`, `ProductDetailState` | `/v1/app-config` → `order_rules` |
| Detail produk | Status favorit ❤️ | lokal (`isFavorite`) | `/v1/me/favorites` (§5.17) |
| Keranjang | Ongkir Rp 10.000 | `CartState.standardDeliveryFee` | `POST /v1/orders/quote` (§5.10) |
| Keranjang | Bayar online sebelum pesanan dibuat | ✅ API (`POST /v1/checkout` + Midtrans Snap, §5.27) | — |
| Keranjang | Alamat & metode bayar | ✅ API (`/v1/me/addresses`, `/v1/me/payment-methods`) → `address_id`, `payment_method_id` | — |
| Beranda, Menu, Keranjang | Outlet & stok per outlet | ✅ API (`/v1/stores?lat=&lng=`, `/v1/products?store_id=`, `store_id` di checkout) | — |
| Pesanan | Daftar pesanan | ✅ API | — |
| Profil | Nama, tier member, voucher, poin, saldo | ✅ API (`/v1/me`) | — |
| Edit Profil | Nama, nomor HP | ✅ API (`PATCH /v1/me`) | — |
| Alamat Pengiriman | Daftar, tambah, ubah, utama, hapus | ✅ API (`/v1/me/addresses`) | — |
| Metode Pembayaran | COD, QRIS, e-wallet tersimpan, metode utama | ✅ API (`/v1/me/payment-methods`) | — |
| Pusat Bantuan | Topik, FAQ, kontak | ✅ API (`/v1/help`) | — |
| Kebijakan Privasi | Isi dokumen | ✅ API (`/v1/legal/privacy-policy`) | — |
| Profil | Kartu promo langganan | `ProfileView.promoCard` | `/v1/promotions/featured` (§5.20) |
| Profil | Daftar menu pengaturan | `ProfileState.settings` | `/v1/app-config` → `profile_menu` |
| Onboarding | 3 slide (foto & teks) | `OnboardingItem.defaults` | `/v1/app-config` → `onboarding` |
| Splash | Judul sambutan | `Localizable.strings` | boleh tetap lokal (splash tampil sebelum network) |

---

## 5. Detail endpoint

### 5.1 `GET /healthz`

```json
{ "status": "ok", "env": "dev", "db": "ok" }
```

### 5.2 `POST /v1/auth/register`

Request:

```json
{ "email": "kholis@gmail.com", "password": "12345678", "name": "Kholis", "fcm_token": "optional" }
```

Validasi: `email` format valid, `password` ≥ 8 karakter, `name` opsional (default: bagian depan email).
Response **201**: sama dengan login (user langsung masuk). Error **409** `EMAIL_ALREADY_REGISTERED`.

### 5.3 `POST /v1/auth/login`

Request:

```json
{ "email": "kholis@gmail.com", "password": "12345678", "fcm_token": "optional" }
```

Response **200** (iOS: `SessionDTO`):

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "user_name": "Kholis",
    "user_image": "https://cdn.trytuist.com/avatars/u1.jpg",
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "rt_6f1c0e...",
    "expires_at": 1792218000
  }
}
```

- `expires_at` = waktu kedaluwarsa **access token** (unix seconds).
- Error **401** `INVALID_CREDENTIALS`. Pesan selalu sama untuk email tidak terdaftar maupun password salah (jangan bocorkan email mana yang terdaftar).
- Rate limit: 5 percobaan / menit / IP + email.
- Akun yang dibuat lewat Google (tanpa password) → **401** `USE_GOOGLE_SIGN_IN` ("Akun ini terdaftar dengan Google…"), supaya iOS bisa mengarahkan ke tombol Google.

### 5.3b `POST /v1/auth/google` — daftar & masuk dengan Google

Satu endpoint untuk **daftar dan masuk**. iOS memakai SDK [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) untuk mendapat **ID token**, lalu mengirimnya ke backend. Backend tidak pernah menerima password Google.

```
iOS: GIDSignIn.signIn → idToken (JWT dari Google)
  → POST /v1/auth/google { id_token }
  → backend verifikasi token → cari / tautkan / buat user → SessionDTO (sama dengan login)
```

Request:

```json
{ "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...", "fcm_token": "optional" }
```

Response **201** (akun baru) / **200** (akun sudah ada) — `SessionDTO` + `is_new_user`:

```json
{
  "code": 201,
  "message": "success",
  "data": {
    "user_name": "Budi Santoso",
    "user_image": "https://lh3.googleusercontent.com/a/…",
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "rt_6f1c0e...",
    "expires_at": 1792218000,
    "is_new_user": true
  }
}
```

Verifikasi token di backend (tanpa library tambahan, `internal/auth/google.go`):

| Cek | Aturan |
|---|---|
| Tanda tangan | RS256 dengan kunci `kid` dari `GOOGLE_JWKS_URL` (`https://www.googleapis.com/oauth2/v3/certs`), di-cache sesuai `Cache-Control` |
| `iss` | `accounts.google.com` atau `https://accounts.google.com` |
| `aud` | salah satu `GOOGLE_CLIENT_IDS` (client ID iOS per environment) |
| `exp` | belum lewat (toleransi 1 menit) |
| `email` / `email_verified` | wajib ada / `true` |

Mencari akun:

1. `users.google_sub = sub` → masuk.
2. Email sudah terdaftar dengan password (belum tertaut) → **tautkan** Google ke akun itu (email sudah diverifikasi Google), lalu masuk. Password lama tetap berlaku. Foto Google dipakai bila user belum punya foto.
3. Belum ada → buat akun baru tanpa password (nama & foto dari Google, nama kosong → bagian depan email), `is_new_user: true`.

| Error | Kapan |
|---|---|
| `400 VALIDATION_ERROR` | `id_token` kosong |
| `401 INVALID_GOOGLE_TOKEN` | token palsu / kedaluwarsa / bukan untuk app ini / email belum diverifikasi |
| `409 EMAIL_ALREADY_REGISTERED` | email sudah tertaut ke akun Google **lain** |
| `429 RATE_LIMITED` | > `LOGIN_RATE_LIMIT` percobaan / menit / IP |
| `503 GOOGLE_SIGN_IN_DISABLED` | `GOOGLE_CLIENT_IDS` belum diisi |

`POST /v1/auth/register` & `/login` juga mengirim `is_new_user` (register = `true`).

#### Setup Google Cloud & iOS

1. Google Cloud Console → **Credentials → Create OAuth client ID → iOS**, satu per bundle ID: `com.lshinkuro.TryTuist.dev`, `com.lshinkuro.TryTuist.staging`, `com.lshinkuro.TryTuist`.
2. Backend `.env`: `GOOGLE_CLIENT_IDS=<dev>,<staging>,<prod>`.
3. iOS `Configs/<Env>.xcconfig`: `GOOGLE_CLIENT_ID` dan `GOOGLE_REVERSED_CLIENT_ID` (dipakai `Info.plist` → `GIDClientID` & URL scheme callback).
4. Dependency iOS: `https://github.com/google/GoogleSignIn-iOS` (`GoogleSignIn`) di `Tuist/Package.swift`, dipakai `AuthenticationFeature`.

### 5.4 `POST /v1/auth/refresh`

```json
{ "refresh_token": "rt_6f1c0e..." }
```

Response: sama dengan login. Refresh token lama **dicabut** dan diganti yang baru (rotation). Kalau token yang sudah dicabut dipakai lagi, cabut semua sesi user tersebut (reuse detection).

### 5.5 `POST /v1/auth/logout` 🔒

```json
{ "refresh_token": "rt_6f1c0e..." }
```

Response **200** `data: null`. Refresh token dicabut.

### 5.6 `GET /v1/banners`

Hanya banner aktif (`is_active` dan dalam rentang `starts_at`–`ends_at`), urut `sort_order`. iOS: `BannerDTO`.

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "B1",
      "title": "Diskon 30% Makan Siang",
      "subtitle": "Semua menu makanan, khusus jam 11–14",
      "image_url": "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=1200&q=80&auto=format&fit=crop"
    }
  ]
}
```

### 5.7 `GET /v1/categories`

iOS: `CategoryDTO`.

```json
{
  "code": 200,
  "message": "success",
  "data": [
    { "id": "coffee", "name": "Kopi", "icon": "☕️" },
    { "id": "non_coffee", "name": "Non-Kopi", "icon": "🍵" }
  ]
}
```

### 5.8 `GET /v1/products`

Query (semua opsional):

| Param | Contoh | Keterangan |
|---|---|---|
| `category_id` | `coffee` | Filter kategori |
| `q` | `latte` | Cari di nama & deskripsi (`ILIKE`, atau `pg_trgm` bila data besar) |
| `best_seller` | `true` | Hanya produk terlaris |
| `sort` | `popular` \| `rating` \| `price_asc` \| `price_desc` | Default: `sort_order` |
| `page`, `limit` | `1`, `50` | iOS saat ini mengambil semua: kirim `limit=100` |

Response (iOS: `ProductDTO`):

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "product_id": "P01",
      "product_name": "Es Kopi Susu Gula Aren",
      "description": "Espresso, susu segar, dan gula aren asli.",
      "category_id": "coffee",
      "price": 22000,
      "image_url": "https://images.unsplash.com/photo-1767471716700-2b3aa77b1ab6?w=800&q=80&auto=format&fit=crop",
      "rating": 4.9,
      "sold_count": 1520,
      "is_available": true,
      "tags": ["best_seller"],
      "options": [
        { "id": "regular", "name": "Regular", "extra_price": 0 },
        { "id": "large", "name": "Large", "extra_price": 5000 }
      ]
    }
  ],
  "meta": { "page": 1, "limit": 100, "total": 14 }
}
```

- Produk habis tetap dikirim dengan `is_available: false` (iOS menampilkan label "Habis").
- `tags` saat ini: `best_seller`, `promo`. Tag lain (`new`, `spicy`) boleh ditambah; iOS mengabaikan yang tidak dikenal.
- **Harga promo (§5.24):** `price` selalu harga yang berlaku sekarang. Bila produk sedang promo, `original_price` berisi harga normal dan `discount_percent` potongannya (dibulatkan ke bawah); bila tidak, `original_price: null` dan `discount_percent: 0`. `sort=price_asc|price_desc` memakai harga berlaku.

  ```json
  { "product_id": "P07", "price": 19900, "original_price": 32000, "discount_percent": 37, "tags": ["best_seller", "promo"], "...": "..." }
  ```
- `options` boleh `[]` atau tidak dikirim.

### 5.9 `GET /v1/products/{id}`

`data` = satu objek produk (bentuk sama dengan item di 5.8). **404** bila tidak ada.

### 5.10 `POST /v1/orders/quote` 🔒

Menghitung ulang harga di server **sebelum** checkout. iOS memanggilnya saat halaman Keranjang dibuka atau isi keranjang berubah.

Request (juga dipakai `POST /v1/orders`):

```json
{
  "store_id": "ST01",
  "address_id": "8f0f2c1e-...",
  "voucher_code": "HEMAT10",
  "items": [
    { "product_id": "P01", "option_id": "large", "quantity": 2, "note": "less sugar" },
    { "product_id": "P11", "option_id": null, "quantity": 1, "note": "" }
  ]
}
```

Response:

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      { "product_id": "P01", "product_name": "Es Kopi Susu Gula Aren", "option_id": "large", "option_name": "Large",
        "unit_price": 27000, "quantity": 2, "note": "less sugar", "subtotal": 54000 }
    ],
    "subtotal": 96000,
    "delivery_fee": 10000,
    "discount": 9600,
    "total": 96400
  }
}
```

### 5.11 `POST /v1/orders` 🔒

Header tambahan: `Idempotency-Key: <uuid dari iOS>`. Kalau request yang sama terkirim dua kali (misalnya jaringan putus lalu retry), server mengembalikan order yang sama dan tidak membuat order baru.

Body: sama dengan quote, ditambah field pembayaran dan `"note"` opsional. **Semua field selain `items` boleh kosong**: server memakai pilihan utama user.

| Field | Kosong → | Diisi |
|---|---|---|
| `store_id` | outlet terbaik untuk alamat (§5.26: buka → menjangkau → terdekat) | outlet tertentu: tidak dikenal → `400`; tutup → `422 STORE_CLOSED`; alamat di luar radius → `422 OUT_OF_DELIVERY_AREA`; menu habis di outlet itu → `422 PRODUCT_UNAVAILABLE` "X sedang habis di outlet Y." |
| `address_id` | alamat utama user (`addresses.is_default`); user tanpa alamat → pesanan tanpa alamat | alamat milik user, selain itu `404 NOT_FOUND` |
| `payment_method_id` | metode utama user (`users.default_payment_method`); e-wallet utama sudah dihapus → `COD` | `"COD"`, `"QRIS"`, atau uuid e-wallet milik user (`404` bila bukan miliknya) |
| `payment_method` | — | tipe saja (`COD`/`QRIS`/`EWALLET`), untuk app lama. Bila diisi bersama `payment_method_id` dan tidak cocok → `400` |

iOS (Keranjang) selalu mengirim `address_id` & `payment_method_id` pilihan user. Default-nya = alamat & metode utama dari tab Profil, bisa diganti per pesanan tanpa mengubah utama.

Contoh body iOS:

```json
{
  "address_id": "6f0e…",
  "payment_method_id": "8b1c…",
  "items": [{ "product_id": "P01", "option_id": "large", "quantity": 2, "note": "less sugar" }]
}
```

Response **201** (iOS: `PlacedOrder` → `order_number`, `total`):

```json
{
  "code": 201,
  "message": "Pesanan diterima",
  "data": {
    "order_id": "1b7d3c3a-...",
    "order_number": "ORD-20261017-0042",
    "status": "PENDING",
    "subtotal": 96000,
    "delivery_fee": 10000,
    "discount": 9600,
    "total": 96400,
    "payment_method": "EWALLET",
    "payment_method_id": "8b1c…",
    "payment_provider": "GOPAY",
    "payment_account_masked": "0812••••7890",
    "address": { "id": "6f0e…", "label": "Rumah", "recipient": "Kholis", "phone": "081234567890", "address": "Jl. …", "notes": null, "lat": null, "lng": null },
    "created_at": "2026-10-17T14:30:00+07:00",
    "items": [ ]
  }
}
```

- `payment_method_id`: `"COD"` / `"QRIS"` / uuid e-wallet; `null` bila e-wallet-nya sudah dihapus.
- `payment_provider` & `payment_account_masked` disalin ke pesanan saat checkout (snapshot), jadi riwayat tetap terbaca walau e-wallet dihapus. `null` untuk COD/QRIS.

### 5.12 `GET /v1/orders` 🔒

Query: `status` (opsional, bisa koma: `PENDING,PROCESSING`), `from` / `to` (opsional, RFC3339, rentang `[from, to)`; iOS mengirim awal hari di zona waktu perangkat dalam UTC `…Z`, karena `+` di query terbaca spasi), `sort` (`desc` default = terbaru dulu, `asc` = terlama dulu), `page`, `limit` (default 20, maks. 100). Format salah → `400 VALIDATION_ERROR`.

Response: **ringkasan** per order, sesuai `OrderDTO` di iOS:

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "order_id": "1b7d3c3a-...",
      "order_number": "ORD-20261017-0042",
      "store_name": "Gandaria City",
      "product_name": "Es Kopi Susu Gula Aren +1 lainnya",
      "created_at": "2026-10-17T14:30:00+07:00",
      "total_price": 96400,
      "qty": 3,
      "status": "PENDING",
      "can_rate": false
    }
  ],
  "meta": { "page": 1, "limit": 20, "total": 1 }
}
```

- `product_name`: nama item pertama, ditambah ` +N lainnya` bila lebih dari satu item.
- `qty`: total kuantitas semua item.
- `can_rate`: `true` bila `COMPLETED` dan belum dinilai (tombol "Beri Nilai" di iOS).
- `status`: `PENDING` | `PAID` | `PROCESSING` | `DELIVERING` | `COMPLETED` | `CANCELLED` | `FAILED`. iOS mengelompokkannya: `PENDING/PAID/PROCESSING/DELIVERING` → *Diproses*, `COMPLETED` → *Selesai*, `CANCELLED/FAILED` → *Gagal*.

### 5.13 `GET /v1/orders/{id}` 🔒

Detail lengkap (bentuk sama dengan response 5.11, ditambah `store`, `address`, dan `status_history: [{ "status", "at" }]`). **404** bila bukan milik user.

### 5.14 `POST /v1/orders/{id}/cancel` 🔒

Hanya bila status `PENDING`. Selain itu **422** `ORDER_NOT_CANCELLABLE`.

### 5.15 `POST /v1/orders/{id}/rating` 🔒

```json
{ "rating": 5, "comment": "Kopinya enak!" }
```

Hanya untuk order `COMPLETED`, satu kali per order. Rating produk (`products.rating`) diperbarui sebagai rata-rata.

### 5.16 `GET /v1/me` 🔒 · `PATCH /v1/me` 🔒

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "5c3e...",
    "name": "Ishinkuro",
    "email": "ishinkuro@mail.com",
    "phone": "081234567890",
    "avatar_url": null,
    "member_tier": "GOLD",
    "points": 1250,
    "voucher_count": 3,
    "balance": 50000
  }
}
```

`PATCH` menerima `name`, `phone`, `avatar_url` (sebagian saja boleh). Response = profil terbaru.

| Field | Aturan | Error |
|---|---|---|
| `name` | wajib bila dikirim, maks. 100 karakter, di-trim | `400 VALIDATION_ERROR` field `name` |
| `phone` | `""` = hapus nomor. Bila diisi: spasi/strip/titik dibuang lalu harus `08…`, `628…`, atau `+628…` (10–15 digit) | `400` field `phone` |
| `avatar_url` | `""` = hapus. Bila diisi harus `https://` | `400` field `avatar_url` |

Email tidak bisa diubah lewat endpoint ini (dipakai untuk login).

### 5.17 Alamat · Favorit · Voucher · Outlet (fase 3)

| Endpoint | Body / Response `data` |
|---|---|
| `GET /v1/me/addresses` | `[{ "id", "label", "recipient", "phone", "address", "notes", "lat", "lng", "is_default" }]` |
| `POST /v1/me/addresses` | body = objek di atas tanpa `id` → `201` + objek |
| `PATCH/DELETE /v1/me/addresses/{id}` | sebagian field / `data: null` |
| `GET /v1/me/favorites` | `[ProductDTO]` (bentuk sama dengan 5.8) |
| `PUT/DELETE /v1/me/favorites/{product_id}` | `data: null` (idempotent) |
| `GET /v1/me/vouchers` | `[{ "code", "title", "description", "discount_type": "PERCENT"\|"FIXED", "discount_value", "min_subtotal", "max_discount", "ends_at" }]` |
| `GET /v1/stores?lat=&lng=` | lihat §5.26 |

### 5.18 `GET /v1/home` 🔒*

Semua isi Beranda dalam **satu request**, supaya urutan dan isi section diatur dari backend (tanpa update app). iOS cukup merender `sections` sesuai urutan.

Query opsional: `lat`, `lng` (untuk outlet terdekat).

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "greeting": "Selamat malam 🌙",
    "user": { "name": "Kholis", "points": 1250, "voucher_count": 3 },
    "delivery_address": {
      "id": "8f0f2c1e-...",
      "label": "Rumah",
      "address": "Jl. Sudirman No. 21, Jakarta"
    },
    "store": { "id": "ST01", "name": "Gandaria City", "is_open": true },
    "sections": [
      { "id": "promo", "type": "BANNER_CAROUSEL", "title": null,
        "banners": [ { "id": "B1", "title": "Diskon 30% Makan Siang", "subtitle": "...", "image_url": "https://..." } ] },
      { "id": "categories", "type": "CATEGORY_GRID", "title": "Kategori",
        "categories": [ { "id": "coffee", "name": "Kopi", "icon": "☕️" } ] },
      { "id": "best_seller", "type": "PRODUCT_CAROUSEL", "title": "🔥 Paling Laris", "see_all": { "sort": "popular" },
        "products": [ { "product_id": "P01", "product_name": "Es Kopi Susu Gula Aren", "...": "bentuk sama dengan §5.8" } ] },
      { "id": "recommended", "type": "PRODUCT_LIST", "title": "Rekomendasi Buat Kamu", "see_all": null,
        "products": [ ] }
    ]
  }
}
```

| Field | Keterangan |
|---|---|
| `greeting` | Dihitung server dengan zona waktu user (default `Asia/Jakarta`) |
| `user` | `null` bila tanpa token |
| `delivery_address` | Alamat default user (`addresses.is_default`); `null` bila belum ada → iOS menampilkan "Pilih alamat" |
| `sections[].type` | `BANNER_CAROUSEL` \| `CATEGORY_GRID` \| `PRODUCT_CAROUSEL` \| `PRODUCT_LIST`. Tipe yang tidak dikenal iOS **dilewati** (aman menambah tipe baru) |
| `sections[].see_all` | Filter untuk tombol "Lihat semua" → dipakai sebagai query `GET /v1/products`; `null` = tidak ada tombol |
| Isi section produk | Diatur tabel `home_sections` (§6): `rule = BEST_SELLER` (urut `sold_count`), `TOP_RATED` (urut `rating`), atau `MANUAL` (daftar `product_ids`) |

Produk habis (`is_available = false`) tidak dimasukkan ke section Beranda, tapi tetap tampil di Menu.

### 5.19 `GET /v1/app-config`

Konfigurasi yang sering berubah tanpa perlu update app. iOS memanggilnya saat Splash, lalu menyimpannya di cache (dipakai lagi bila offline).

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "min_supported_version": "1.0.0",
    "latest_version": "1.2.0",
    "search_placeholder": "Cari kopi, nasi goreng, burger…",
    "order_rules": {
      "min_quantity": 1,
      "max_quantity": 20,
      "max_note_length": 100,
      "delivery_fee": 10000,
      "free_delivery_min_subtotal": 50000
    },
    "payment_methods": [
      { "id": "COD", "name": "Bayar di Tempat", "icon": "banknote", "is_enabled": true },
      { "id": "QRIS", "name": "QRIS", "icon": "qrcode", "is_enabled": true },
      { "id": "EWALLET", "name": "E-Wallet", "icon": "wallet.pass", "is_enabled": false }
    ],
    "onboarding": [
      { "image_url": "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&q=80&auto=format&fit=crop",
        "title": "Semua favoritmu di sini", "subtitle": "Kopi, nasi goreng, burger, sampai dessert. Tinggal pilih." },
      { "image_url": "https://images.unsplash.com/photo-1767471716700-2b3aa77b1ab6?w=800&q=80&auto=format&fit=crop",
        "title": "Pesan cepat tanpa antre", "subtitle": "Atur varian, jumlah, dan catatan sesuai seleramu." },
      { "image_url": "https://images.unsplash.com/photo-1543339469-94ba2391431f?w=800&q=80&auto=format&fit=crop",
        "title": "Diantar hangat ke rumah", "subtitle": "Nikmati promo dan gratis ongkir setiap hari." }
    ],
    "profile_menu": [
      { "id": "addresses", "title": "Alamat Pengiriman", "icon": "location.fill", "tint": "blue", "action": "trytuist://addresses" },
      { "id": "payment", "title": "Metode Pembayaran", "icon": "creditcard.fill", "tint": "green", "action": "trytuist://payment-methods" },
      { "id": "favorites", "title": "Menu Favorit", "icon": "heart.fill", "tint": "pink", "action": "trytuist://favorites" },
      { "id": "help", "title": "Pusat Bantuan", "icon": "questionmark.circle.fill", "tint": "teal", "action": "https://trytuist.com/bantuan" },
      { "id": "language", "title": "Bahasa", "icon": "globe", "tint": "indigo", "action": "trytuist://language" },
      { "id": "privacy", "title": "Kebijakan Privasi", "icon": "lock.fill", "tint": "gray", "action": "https://trytuist.com/privasi" }
    ]
  }
}
```

- `icon` = nama SF Symbol, `tint` = nama warna (`blue`, `green`, `pink`, `teal`, `indigo`, `gray`, `orange`, `red`). iOS memakai ikon fallback bila nama tidak dikenal.
- `action` diawali `https://` → dibuka di browser in-app. Diawali `trytuist://` → navigasi ke screen di app.
- Versi app di bawah `min_supported_version` → iOS menampilkan layar "Perbarui aplikasi".
- Response boleh di-cache: kirim header `Cache-Control: max-age=300` dan `ETag`.

### 5.20 Promo langganan (Profil)

`GET /v1/promotions/featured` 🔒* → kartu promo di Profil:

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "plan_id": "daily-coffee",
    "eyebrow": "LANGGANAN KOPI HARIAN",
    "title": "1 cup cuma 15rb / hari",
    "price": 15000,
    "period": "DAILY",
    "image_url": null,
    "is_active": false,
    "active_until": null
  }
}
```

`data: null` = tidak ada promo → iOS menyembunyikan kartu.

`POST /v1/subscriptions/{plan_id}/activate` 🔒 → **201**, `data` = objek yang sama dengan `is_active: true` dan `active_until`. Bila sudah aktif → **409** `ALREADY_SUBSCRIBED`.

### 5.21 Metode pembayaran 🔒

Metode **bawaan** (`COD`, `QRIS`) berasal dari `app_config.payment_methods` dan tidak disimpan per user. User hanya menyimpan **akun e-wallet** (GoPay, OVO, DANA, ShopeePay). Nomor kartu kredit/debit **tidak pernah** dikirim ke atau disimpan oleh backend ini.

Keempat endpoint mengembalikan bentuk `data` yang sama (overview terbaru), jadi iOS cukup mengganti state dengan response:

`GET /v1/me/payment-methods`

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "default_id": "8b1c…",
    "can_add_ewallet": true,
    "methods": [
      { "id": "COD", "type": "COD", "provider": null, "name": "Bayar di Tempat",
        "description": "Bayar tunai ke kurir saat pesanan tiba", "icon": "banknote",
        "account_masked": null, "account_name": null,
        "is_enabled": true, "is_default": false, "is_removable": false },
      { "id": "QRIS", "type": "QRIS", "provider": null, "name": "QRIS", "icon": "qrcode", "…": "…" },
      { "id": "8b1c…", "type": "EWALLET", "provider": "GOPAY", "name": "GoPay", "description": null,
        "icon": "wallet.pass.fill", "account_masked": "0812••••7890", "account_name": "Kholis",
        "is_enabled": true, "is_default": true, "is_removable": true }
    ],
    "ewallet_providers": [
      { "id": "GOPAY", "name": "GoPay", "icon": "wallet.pass.fill", "tint": "teal" },
      { "id": "OVO", "name": "OVO", "icon": "wallet.pass.fill", "tint": "purple" },
      { "id": "DANA", "name": "DANA", "icon": "wallet.pass.fill", "tint": "blue" },
      { "id": "SHOPEEPAY", "name": "ShopeePay", "icon": "wallet.pass.fill", "tint": "orange" }
    ]
  }
}
```

| Endpoint | Body | Sukses | Error |
|---|---|---|---|
| `POST /v1/me/payment-methods` | `{ "provider": "GOPAY", "account_number": "0812 3456 7890", "account_name": "Kholis", "set_default": true }` | **201** overview | `400` provider tidak dikenal / nomor tidak valid · `409 PAYMENT_METHOD_EXISTS` · `422 PAYMENT_METHOD_LIMIT` (maks. 10) · `422 PAYMENT_METHOD_UNAVAILABLE` (e-wallet dimatikan di app_config) |
| `PUT /v1/me/payment-methods/default` | `{ "id": "QRIS" }` atau uuid e-wallet | **200** overview | `404 NOT_FOUND` (id bukan milik user) · `422 PAYMENT_METHOD_UNAVAILABLE` |
| `DELETE /v1/me/payment-methods/{id}` | — | **200** overview | `404` · `422 PAYMENT_METHOD_BUILTIN` (COD/QRIS) |

Aturan:
- `account_number` dinormalisasi (buang spasi, strip, titik) lalu harus nomor HP Indonesia: `08…`, `628…`, atau `+628…`, 10–15 digit. Response hanya mengirim versi tersamar (`account_masked`).
- `provider` harus ada di `app_config.ewallet_providers` (huruf besar/kecil bebas).
- Metode utama disimpan di `users.default_payment_method`. Menghapus e-wallet yang sedang jadi utama → utama kembali ke `COD`. Bila utama menunjuk metode yang dimatikan, response mengirim `default_id: "COD"`.
- `can_add_ewallet = false` bila e-wallet dimatikan, sudah 10 akun, atau belum ada provider.

### 5.22 `GET /v1/help?q=` — Pusat Bantuan

Publik (cukup API key). `q` opsional (maks. 100 karakter) untuk mencari di pertanyaan & jawaban; topik tanpa hasil tidak dikirim. Tanpa `q` → `Cache-Control: max-age=300`.

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "query": null,
    "operating_hours": "Setiap hari, 08.00–22.00 WIB",
    "topics": [
      { "id": "order", "title": "Pesanan", "icon": "bag.fill",
        "articles": [
          { "id": "order-cancel", "question": "Bisakah saya membatalkan pesanan?",
            "answer": "Bisa, selama status pesanan masih \"Menunggu\". …\n\nPesanan yang sudah diproses …",
            "updated_at": "2026-10-18T01:00:00+07:00" }
        ] }
    ],
    "contacts": [
      { "type": "WHATSAPP", "label": "Chat WhatsApp", "value": "+62 812-1000-2000", "icon": "message.fill", "url": "https://wa.me/6281210002000" },
      { "type": "EMAIL", "label": "Email", "value": "halo@trytuist.com", "icon": "envelope.fill", "url": "mailto:halo@trytuist.com" },
      { "type": "PHONE", "label": "Telepon", "value": "1500-123", "icon": "phone.fill", "url": "tel:1500123" }
    ]
  }
}
```

- `answer` teks biasa; paragraf dipisah baris kosong (`\n\n`).
- Topik & artikel dari tabel `help_topics` / `help_articles` (`is_active`, `sort_order`). Kontak dari `app_config.help_contacts`.
- Karakter `%` dan `_` di `q` dianggap huruf biasa.

### 5.23 `GET /v1/legal/{slug}` — Kebijakan Privasi & S&K

Publik. `slug`: `privacy-policy`, `terms`. Selain itu → `404 NOT_FOUND`. `Cache-Control: max-age=3600`.

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "slug": "privacy-policy",
    "title": "Kebijakan Privasi",
    "version": "1.0",
    "summary": "Kami hanya mengumpulkan data yang dibutuhkan …",
    "effective_at": "2026-10-01",
    "updated_at": "2026-10-18T01:00:00+07:00",
    "sections": [
      { "heading": "1. Data yang kami kumpulkan", "body": "Nama, email, nomor HP, …" }
    ]
  }
}
```

Isi diubah lewat `UPDATE legal_documents` (naikkan `version` & `effective_at`), tanpa update app.

---

### 5.24 `GET /v1/promotions/popup` — popup promo Beranda

Publik. Mengembalikan **satu** promo harga produk yang ditandai `show_as_popup`, sedang berlaku (`starts_at ≤ now < ends_at`), lebih murah dari harga normal, produknya tersedia, dan kategorinya aktif. Urutan: `sort_order`, lalu yang paling cepat berakhir. Tidak ada → `data: null`.

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "D01",
    "title": "Nasi Goreng Spesial cuma 19rb!",
    "subtitle": "Promo makan hemat minggu ini. Selama persediaan ada.",
    "badge": "HEMAT 37%",
    "image_url": "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&q=80&auto=format&fit=crop",
    "ends_at": "2026-11-17T10:00:00+07:00",
    "product": { "product_id": "P07", "price": 19900, "original_price": 32000, "discount_percent": 37, "...": "bentuk sama dengan §5.8" }
  }
}
```

- `image_url` = gambar khusus promo, atau foto produk bila `product_deals.image_url` kosong. `badge` kosong di DB → server mengisi `HEMAT {discount_percent}%`.
- Harga promo berlaku **di semua endpoint**: `/v1/products`, `/v1/products/{id}`, `/v1/home`, favorit, serta `POST /v1/orders/quote` dan `POST /v1/orders` (`unit_price` = harga promo + `extra_price` varian). Jadi item yang dibuka dari popup lalu ditambah ke keranjang otomatis dibayar dengan potongan; server tetap menghitung ulang harga saat checkout, jadi promo yang sudah lewat tidak bisa dipakai.
- Beberapa deal aktif untuk produk yang sama → yang termurah dipakai.
- iOS: popup muncul sekali setelah Beranda termuat. Ditutup (✕ / tap di luar) atau di-tap → promo yang sama tidak muncul lagi **hari itu** (disimpan di `UserDefaults`, `home.promoPopup.dismissedOn`). Tap → Detail menu dengan harga coret & badge diskon. Gagal memuat popup tidak menampilkan error.
- Gambar: foto Unsplash (lisensi gratis). Gambar hasil generate AI bisa dipakai lewat `image_url` yang sama, cukup diunggah ke storage/CDN lalu diisi di `product_deals.image_url`.

### 5.25 Web admin `/v1/admin/*` 🛡

Dipakai `trytuistadmin` (Next.js, port 3000) lewat BFF server-side; lihat `trytuistadmin/WEBPLAN.md`.

**Akses.**

- Login memakai `POST /v1/auth/login` yang sama dengan aplikasi.
- Semua route `/v1/admin/*` memakai `Auth` + `RequireAdmin`, yang membaca `users.role` di DB **setiap request**. Akun biasa → **403 `FORBIDDEN`** "Akun ini tidak punya akses admin.".
- Admin dev dibuat oleh seed: `admin@trytuist.com / admin12345`.
- Production: `UPDATE users SET role = 'ADMIN' WHERE lower(email) = '…';`

**Audit.** Semua perubahan (status pesanan, produk, promo) dicatat di `admin_audit_logs`.

| Endpoint | Keterangan |
|---|---|
| `GET /v1/admin/me` | `{ id, name, email, role: "ADMIN" }` |
| `GET /v1/admin/dashboard?from=YYYY-MM-DD&to=YYYY-MM-DD` | Default 30 hari terakhir (WIB), maks. 366 hari. `from > to` → 400 |
| `GET /v1/admin/orders?status=PENDING,PAID&q=&from=&to=&page=&limit=` | Semua pelanggan; `q` = nomor pesanan / nama / email; status tidak dikenal → 400 |
| `GET /v1/admin/orders/{id}` | Bentuk `OrderDTO` (§5.13) + `customer`, `status_history[].note/changed_by`, `next_statuses` |
| `PATCH /v1/admin/orders/{id}/status` | `{ status, note }` → pesanan terbaru |
| `GET /v1/admin/products?q=&category_id=&available=true\|false` | Termasuk produk habis & kategori nonaktif; `price` = harga normal, `deal_price`, `effective_price` |
| `POST /v1/admin/products` | Tambah menu → **201**. Wajib `category_id`, `product_name`, `price`; opsional `description`, `image_url` (https), `is_available` (default true), `is_best_seller`, `options` |
| `PATCH /v1/admin/products/{id}` | Field yang sama, semua opsional; `price` 0–10.000.000; `image_url: ""` = hapus foto; `options` dikirim = daftar varian diganti seluruhnya (`[]` = tanpa varian); body kosong → 400 |
| `GET /v1/admin/deals` · `POST` · `PATCH /{id}` · `DELETE /{id}` | Promo §5.24. `deal_price ≥` harga normal → 422 `DEAL_PRICE_TOO_HIGH`; `ends_at ≤ starts_at` → 400; `status` dihitung: `ACTIVE` \| `SCHEDULED` \| `EXPIRED` \| `INACTIVE` |
| `GET /v1/admin/customers?q=&page=&limit=` | User + `orders_count`, `total_spent` (COMPLETED), `last_order_at` |
| `GET /v1/admin/audit-logs?page=&limit=` | `{ action, entity, entity_id, summary, data, admin_name, created_at }` |

**Tambah menu.**

```json
POST /v1/admin/products
{ "category_id": "non_coffee", "product_name": "Es Teh Manis", "price": 8000,
  "description": "Teh melati dingin.", "image_url": "https://images.unsplash.com/…",
  "options": [ { "name": "Regular" }, { "name": "Porsi Jumbo", "extra_price": 3000 } ] }
→ 201 { "message": "Menu ditambahkan",
        "data": { "product_id": "P15", "options": [ { "id": "regular", … }, { "id": "porsi-jumbo", "extra_price": 3000 } ], … } }
```

- `product_id` dibuat berurutan (`P15`, `P16`, …) dengan advisory lock, jadi dua admin yang menambah bersamaan tidak bentrok.
- Menu baru tampil di akhir urutan.
- Varian:
  - Tanpa `id` → id dari nama (slug), unik per menu.
  - Nama varian kosong / kembar (tanpa beda huruf besar) → 400 `options[i].name`.
  - `extra_price` 0–1.000.000, maksimal 10 varian.
- `category_id` tidak ada → 400.
- Menu langsung bisa dipesan (`POST /v1/orders/quote`) dan tampil di `GET /v1/products` bila tersedia.
- Menu tidak bisa dihapus (dirujuk `order_items`); matikan `is_available` untuk menyembunyikan.

**Ubah status pesanan.**

```
PENDING → PAID → PROCESSING → DELIVERING → COMPLETED   (maju, boleh melompat; COMPLETED = "sukses")
  aktif mana pun → FAILED ("gagal") / CANCELLED          (note wajib, dilihat pelanggan)
  COMPLETED / FAILED / CANCELLED                          → terkunci (422 INVALID_STATUS_TRANSITION)
```

- `FAILED` dan `CANCELLED` mengembalikan voucher dan `sold_count`.
- `note` (maks. 300) dan nama admin disimpan di `order_status_history`.
- Pelanggan melihat `note` di `GET /v1/orders/{id}` → `status_history[].note`.

```json
PATCH /v1/admin/orders/{id}/status
{ "status": "FAILED", "note": "Stok nasi goreng habis" }
→ 200 { "message": "Status pesanan diperbarui", "data": { "status": "FAILED", "next_statuses": [],
        "status_history": [ …, { "status": "FAILED", "note": "Stok nasi goreng habis", "changed_by": "Admin TryTuist" } ] } }
```

**Dashboard.**

- *Penjualan* = pesanan `COMPLETED` yang dibuat dalam rentang.
- *Pembelian* = semua transaksi pelanggan dalam rentang, apa pun statusnya.

```json
{
  "range": { "from": "2026-09-19", "to": "2026-10-18" },
  "sales": { "revenue": 1384200, "orders_completed": 18, "average_order_value": 76900, "items_sold": 55,
             "discount_total": 0, "delivery_fee_total": 180000, "revenue_change_pct": 12.5 },
  "purchases": { "orders": 26, "buyers": 2, "new_buyers": 2, "repeat_buyers": 0, "in_progress": 4,
                 "failed": 2, "cancelled": 2, "success_rate_pct": 69.2, "gross_value": 1962100, "orders_change_pct": null },
  "daily": [ { "date": "2026-10-18", "revenue": 0, "orders": 1, "orders_completed": 0 } ],
  "by_status": [ { "status": "COMPLETED", "count": 18, "total": 1384200 } ],
  "top_products": [ { "product_id": "P12", "product_name": "Kentang Goreng", "quantity": 20, "revenue": 240000 } ],
  "payment_methods": [ { "method": "COD", "count": 15, "total": 1227200 } ]
}
```

- `*_change_pct` dibanding periode sebelumnya dengan panjang yang sama; `null` bila periode sebelumnya 0.
- `daily` selalu berisi setiap hari dalam rentang (hari kosong = 0).
- *Pembeli baru* = pesanan pertamanya sepanjang waktu ada di rentang ini.

### 5.26 Multi-outlet: `GET /v1/stores` + stok per outlet

**Aturan.** Harga menu **sama di semua outlet**. Yang berbeda per outlet:

- stok: menu bisa ditandai habis khusus di satu outlet (`store_product_availability`);
- jam buka (`opens_at`–`closes_at`, WIB);
- radius antar (`delivery_radius_km`);
- tombol tutup sementara.

`products.is_available = false` tetap berarti habis di **semua** outlet.

**`GET /v1/stores?lat=&lng=`** (publik). Hanya outlet aktif. Urutan: buka sekarang → menjangkau koordinat → terdekat → `sort_order`. `lat`/`lng` opsional tetapi harus dikirim berdua (salah satu saja / di luar rentang → 400).

```json
{ "code": 200, "message": "success", "data": [
  { "id": "ST01", "name": "Gandaria City", "address": "Jl. Sultan Iskandar Muda, Jakarta Selatan",
    "lat": -6.2443, "lng": 106.7834, "phone": "021-2900-1001",
    "is_open": true, "opens_at": "00:00", "closes_at": "00:00", "hours_label": "24 jam",
    "delivery_radius_km": 7, "distance_km": 0.6, "is_deliverable": true, "closed_note": null },
  { "id": "ST03", "name": "Kelapa Gading", "is_open": false, "opens_at": "10:00", "closes_at": "22:00",
    "hours_label": "10:00–22:00", "delivery_radius_km": 6, "distance_km": 19.2, "is_deliverable": false,
    "closed_note": "Outlet Kelapa Gading buka 10:00–22:00.", "...": "…" }
] }
```

- `is_open` = buka **sekarang** (jam buka dan tidak tutup sementara).
- `opens_at == closes_at` = 24 jam; `closes_at < opens_at` = lewat tengah malam (mis. 18:00–02:00).
- `distance_km` / `is_deliverable` hanya terisi bila koordinat dikirim.
- `closed_note` = kalimat untuk pelanggan, `null` bila buka.

**Stok per outlet.** `GET /v1/products?store_id=ST02`, `GET /v1/products/{id}?store_id=`, dan `GET /v1/home?store_id=` mengisi `is_available` sesuai outlet. `store_id` tidak dikenal → 400. Tanpa `store_id` → stok pusat (`/v1/home` memakai outlet terbaik). `/v1/home` juga membuang menu yang habis dari section-nya.

**Checkout.** `store_id` di `POST /v1/orders/quote` dan `POST /v1/orders` (§5.11). Kosong → server memilih seperti `GET /v1/stores` memakai koordinat alamat pesanan. Response quote berisi `store_name`.

**Admin** (🛡, audit `STORE_CREATE` / `STORE_UPDATE` / `STORE_STOCK`):

| Endpoint | Keterangan |
|---|---|
| `GET /v1/admin/stores` | Semua outlet (termasuk nonaktif) + `is_temporarily_closed`, `is_open_now`, `unavailable_products`, `today { orders, revenue, active }` |
| `POST /v1/admin/stores` | Wajib `name`, `address`, `lat`, `lng`; opsional `phone`, `opens_at`/`closes_at` (`HH:MM`), `delivery_radius_km` (0 < r ≤ 50, default 7), `sort_order` → **201**, id berurutan `ST04`, `ST05`, … |
| `PATCH /v1/admin/stores/{id}` | Field yang sama + `is_active`, `is_temporarily_closed`; semua opsional |
| `PUT /v1/admin/stores/{id}/products/{product_id}` | `{ "is_available": false }` = habis di outlet ini; `true` = ikut stok pusat |
| `GET /v1/admin/products?store_id=` | Tiap produk + `store_available`, `store_sold_out` |
| `GET /v1/admin/orders?store_id=` · `GET /v1/admin/dashboard?store_id=` | Filter per outlet. Dashboard tanpa filter menambah `by_store` (perbandingan omzet & pesanan per outlet) |

**iOS.**

- Beranda: baris "Dari <outlet> · 1,4 km · 24 jam — Ganti" di bawah "Antar ke".
- Outlet awal dipilih dari `GET /v1/stores` dengan koordinat alamat utama. Pilihan user disimpan di `UserDefaults` (`home.selectedOutletID`) dan dipakai lagi selama outlet masih aktif.
- Ganti outlet:
  - Stok outlet baru diambil dulu (gagal → outlet lama tetap dipakai).
  - Item keranjang yang habis di sana dikeluarkan, dengan toast.
  - Beranda & Menu dimuat ulang.
- Keranjang menampilkan "Dikirim dari" dan mengirim `store_id`. Pesan `STORE_CLOSED` / `OUT_OF_DELIVERY_AREA` / `PRODUCT_UNAVAILABLE` dari server ditampilkan apa adanya.

### 5.27 Pembayaran online (Midtrans Snap)

> Status: **sudah dibuat** — backend (`internal/payment`, migrasi `0009_payments`, `TestPayments`) dan iOS (layar Pembayaran).
> Aktif bila `MIDTRANS_SERVER_KEY` diisi; tanpa key, checkout memakai alur lama. Mulai di **sandbox**; produksi tinggal ganti key + URL (§5.27.10).
> Belum diuji ke server sandbox Midtrans sungguhan (tes memakai fake Midtrans).

#### 5.27.1 Keputusan

| Hal | Pilihan | Alasan |
|---|---|---|
| Penyedia | **Midtrans** (GoTo), mode **Snap** | Satu integrasi untuk GoPay, QRIS, ShopeePay, VA bank, kartu. Dok berbahasa Indonesia, sandbox gratis. |
| UI pembayaran di iOS | **Halaman Snap (`redirect_url`) di `WKWebView`**, bukan Mobile SDK, bukan Core API | Lihat 5.27.2 |
| Kapan pesanan dibuat | **Setelah lunas.** Checkout membuat **sesi pembayaran** (`payments`); baris `orders` baru dibuat saat Midtrans melaporkan lunas | Sesuai alur "bayar dulu baru pesanan dibuat". Outlet & admin tidak pernah melihat pesanan yang belum dibayar; tab Pesanan pelanggan tetap bersih |
| Sumber kebenaran status | **Webhook Midtrans** (HTTP notification), dicek ulang ke **GET Status API** | Redirect/finish di app bisa dipalsukan atau tidak terpanggil |
| COD | Tetap ada (langsung jadi pesanan `PENDING` seperti sekarang), bisa dimatikan `COD_ENABLED=false` | Supaya alur lama dan tes lama tetap jalan |
| Library Go | `net/http` biasa (±150 baris) di `internal/payment/midtrans`, di balik interface | Hanya 3 panggilan (create Snap, get status, expire); mudah di-fake di tes |

#### 5.27.2 Kenapa Snap di WebView

| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| **Snap di `WKWebView`** ✅ | UI semua metode bayar sudah jadi & dirawat Midtrans; 3DS kartu, QR, nomor VA, deeplink GoPay ditangani Snap; data kartu tidak lewat app/backend kita (aman PCI) | Tampilan bukan native; perlu atur WebView (deeplink, finish URL) |
| Mobile SDK iOS (MidtransKit) | UI native | Midtrans menghentikan dukungan Mobile SDK bertahap mulai Juni 2026; integrasi baru sejak 6 Maret 2026 diminta memakai Snap atau Core API |
| Core API (bikin UI sendiri) | Tampilan 100% sesuai TTUI | Harus membuat UI tiap channel (QR, VA, deeplink, form kartu + tokenisasi + 3DS) dan menanganinya satu per satu |

Rencana ke depan: bila nanti ingin tampilan native untuk metode favorit (mis. QRIS / GoPay), metode itu saja yang dipindah ke Core API. Kontrak `payments` di bawah tetap sama.

#### 5.27.3 Alur end-to-end

```mermaid
sequenceDiagram
    participant App as iOS
    participant API as trytuist-api
    participant MT as Midtrans (sandbox)
    App->>API: POST /v1/checkout (keranjang, alamat, outlet, ONLINE)
    API->>API: quote + validasi (outlet buka, radius, stok, voucher)
    API->>API: INSERT payments (PENDING, snapshot quote, expires_at = now+15m)
    API->>MT: POST /snap/v1/transactions
    MT-->>API: token, redirect_url
    API-->>App: 201 { payment_id, redirect_url, amount, expires_at }
    App->>MT: buka redirect_url di WKWebView, user pilih GoPay/QRIS/VA/kartu & bayar
    MT->>API: POST /v1/payments/midtrans/notification (settlement)
    API->>API: cek signature + GET Status API → PAID → INSERT orders (status PAID) dalam 1 transaksi
    App->>API: GET /v1/payments/{id} (polling tiap 3 detik)
    API-->>App: status PAID + order { id, order_number }
    App->>App: kosongkan keranjang → layar "Pembayaran berhasil" → detail pesanan
```

- **Polling + cek mandiri.** Saat iOS polling dan status masih `PENDING`, server sendiri ikut menanyakan ke Midtrans (paling sering tiap 5 detik per pembayaran). Jadi alur tetap jalan di laptop dev walau webhook belum tersambung.
- **Keranjang** baru dikosongkan setelah `PAID`. Gagal / batal / kedaluwarsa → kembali ke Keranjang dengan isi utuh.
- **Satu sesi aktif per user.** Checkout baru otomatis membatalkan sesi `PENDING` sebelumnya (status lokal `CANCELLED` + `expire` ke Midtrans), supaya user tidak membayar dua VA.

#### 5.27.4 Status pembayaran

```
PENDING ──settlement / capture+accept──▶ PAID      (pesanan dibuat)
   │──deny / failure──────────────────▶ FAILED
   │──expire / lewat expires_at────────▶ EXPIRED
   └──user batal / checkout baru────────▶ CANCELLED

EXPIRED / CANCELLED / FAILED ──settlement datang terlambat──▶ PAID   (uang sudah masuk → pesanan tetap dibuat)
PAID ──refund / chargeback (dari Midtrans)──▶ PAID + refund_status   (pesanan tidak otomatis diubah; admin memutuskan)
```

Pemetaan `transaction_status` Midtrans:

| Midtrans | `payments.status` |
|---|---|
| `settlement` | `PAID` |
| `capture` + `fraud_status=accept` | `PAID` |
| `capture` + `fraud_status=challenge`, `authorize`, `pending` | tetap `PENDING` |
| `deny`, `failure` | `FAILED` |
| `expire` | `EXPIRED` |
| `cancel` | `CANCELLED` |
| `refund`, `partial_refund`, `chargeback`, `partial_chargeback` | status tetap; `refund_status` diisi |
| `settlement` → `deny` (reversal VA/Indomaret, jarang) | `FAILED` bila pesanan belum diproses; bila sudah → `refund_status = REVERSED` untuk ditangani admin |

#### 5.27.5 Endpoint

| Method | Path | Auth | Keterangan |
|---|---|---|---|
| `POST` | `/v1/checkout` | 🔒 + `Idempotency-Key` | Body = `POST /v1/orders` (§5.11). `payment_method_id: "ONLINE"` (atau `QRIS` / e-wallet / metode utama online) → sesi Midtrans (201 di bawah). `"COD"` → langsung pesanan: `data = { "next": "ORDER", "order": <OrderDTO §5.11> }`. Midtrans nonaktif → selalu `ORDER` (alur lama) |
| `GET` | `/v1/payments/{id}` | 🔒 pemilik | Status sesi; bila `PENDING` server ikut cek ke Midtrans |
| `GET` | `/v1/payments?status=PENDING` | 🔒 | Sesi milik user (untuk kartu "Menunggu pembayaran") |
| `POST` | `/v1/payments/{id}/cancel` | 🔒 pemilik | Batalkan sesi `PENDING` (expire ke Midtrans). Sudah final → `409 PAYMENT_ALREADY_FINAL` |
| `POST` | `/v1/payments/midtrans/notification` | **publik**, tanpa `X-API-Key`, divalidasi `signature_key` | Webhook Midtrans. Dibalas `200` secepatnya |
| `GET` | `/v1/payments/finish` | publik | Finish URL Snap. Halaman HTML kecil "Kembali ke aplikasi"; di iOS URL ini dicegat WebView sehingga tidak pernah benar-benar dimuat |
| `GET` | `/v1/admin/payments?status=&q=&from=&to=` | 🛡 | Web admin → Pembayaran (fase 5b) |

`POST /v1/orders` lama tetap ada untuk COD. Saat Midtrans aktif, dipanggil dengan `ONLINE` / `QRIS` / e-wallet (termasuk metode utama user) → `422 PAYMENT_REQUIRED`, supaya pesanan online tidak bisa dibuat tanpa bayar. Tanpa Midtrans, `QRIS`/e-wallet tetap seperti dulu; `ONLINE` → `422 PAYMENT_METHOD_UNAVAILABLE`.

**`POST /v1/checkout` (ONLINE) → 201** (Idempotency-Key yang sama → **200**, sesi yang sama)

```json
{
  "code": 201,
  "message": "Silakan selesaikan pembayaran",
  "data": {
    "next": "PAYMENT",
    "payment": {
      "id": "6c2f…",
      "provider": "MIDTRANS",
      "provider_order_id": "TT-DEV-20261018-7K3QX9PA",
      "status": "PENDING",
      "amount": 49800,
      "expires_at": "2026-10-18T15:55:00+07:00",
      "redirect_url": "https://app.sandbox.midtrans.com/snap/v4/redirection/66e4…",
      "finish_url_prefix": "https://<PUBLIC_BASE_URL>/v1/payments/finish",
      "store": { "id": "ST01", "name": "Gandaria City" },
      "quote": { "subtotal": 39800, "delivery_fee": 10000, "discount": 0, "total": 49800, "items": [ "…bentuk §5.10…" ] },
      "order": null
    }
  }
}
```

**`GET /v1/payments/{id}` → 200.** Bentuk sama dengan `payment` di atas, ditambah:

- `payment_type`: `"gopay"`, `"qris"`, `"bank_transfer"`, `"credit_card"`, …; `null` bila user belum memilih.
- `paid_at`.
- `status_message`, untuk ditampilkan saat `FAILED` / `EXPIRED`.
- `order`: `{ "id", "order_number", "status" }` setelah `PAID`, selain itu `null`.

`redirect_url` dikosongkan setelah status final.

**Error checkout** (selain error quote yang sudah ada: `EMPTY_CART`, `PRODUCT_UNAVAILABLE`, `STORE_CLOSED`, `OUT_OF_DELIVERY_AREA`, `INVALID_VOUCHER`):

| Kode | Kapan |
|---|---|
| `422 PAYMENT_METHOD_UNAVAILABLE` | `ONLINE` dimatikan (`MIDTRANS_SERVER_KEY` kosong) atau `COD_ENABLED=false` |
| `422 AMOUNT_TOO_SMALL` | Total < Rp 1.000 (batas minimum transaksi; cek ulang di sandbox) |
| `502 PAYMENT_GATEWAY_ERROR` | Midtrans menolak / timeout (10 detik). Sesi ditandai `FAILED`, iOS boleh mencoba lagi dengan `Idempotency-Key` baru |
| `409 IDEMPOTENCY_CONFLICT` | `Idempotency-Key` sama dipakai untuk isi keranjang berbeda |

Idempotency: `Idempotency-Key` yang sama + isi keranjang sama → sesi yang sama dikembalikan (200, status apa pun), tanpa memanggil Midtrans lagi. Setelah sesi gagal / dibatalkan, iOS memakai key baru.

#### 5.27.6 Panggilan ke Midtrans (server → Midtrans)

Header semua panggilan: `Authorization: Basic base64("<MIDTRANS_SERVER_KEY>:")`, `Accept` & `Content-Type: application/json`.

| Fungsi | Sandbox | Produksi |
|---|---|---|
| Buat transaksi Snap | `POST https://app.sandbox.midtrans.com/snap/v1/transactions` | `POST https://app.midtrans.com/snap/v1/transactions` |
| Cek status | `GET https://api.sandbox.midtrans.com/v2/{order_id}/status` | `GET https://api.midtrans.com/v2/{order_id}/status` |
| Hentikan transaksi pending | `POST https://api.sandbox.midtrans.com/v2/{order_id}/expire` | `POST https://api.midtrans.com/v2/{order_id}/expire` |

Body Snap yang dikirim:

```json
{
  "transaction_details": { "order_id": "TT-DEV-20261018-7K3QX9PA", "gross_amount": 49800 },
  "item_details": [
    { "id": "P07-regular", "name": "Nasi Goreng Spesial", "price": 19900, "quantity": 2 },
    { "id": "DELIVERY", "name": "Ongkos kirim", "price": 10000, "quantity": 1 }
  ],
  "customer_details": { "first_name": "Kholis", "email": "kholis@…", "phone": "081234567890" },
  "expiry": { "start_time": "2026-10-18 15:40:00 +0700", "unit": "minutes", "duration": 15 },
  "callbacks": { "finish": "https://<PUBLIC_BASE_URL>/v1/payments/finish" },
  "custom_field1": "6c2f…"
}
```

- `order_id` = `provider_order_id`: `TT-{APP_ENV}-{YYYYMMDD}-{8 karakter acak}`, maks. 50 karakter.
  - **Jangan** pakai nomor urut atau `order_number`. Midtrans menolak `order_id` yang pernah dipakai, dan nomor urut akan bentrok setelah DB dev di-reset.
- `gross_amount` **harus sama** dengan jumlah `price × quantity` semua `item_details`. Server menghitung dari snapshot quote, lalu memeriksa sebelum mengirim.
  - Diskon voucher dikirim sebagai baris harga negatif, mis. `{ "id": "DISCOUNT", "name": "Voucher HEMAT10", "price": -3980, "quantity": 1 }` (cek di sandbox).
  - Bila ditolak, fallback: satu baris "Pesanan TryTuist" seharga total.
- `name` item dipotong 50 karakter. `price` = harga satuan **termasuk** `extra_price` varian & harga promo.
- `enabled_payments` hanya dikirim bila `MIDTRANS_ENABLED_PAYMENTS` diisi. Kosong = semua channel yang aktif di dashboard sandbox.
- Webhook dan GET Status: jawab `200` paling lama 5 detik (batas Midtrans 30 detik). Selain 2xx, Midtrans mengulang beberapa kali dengan jeda 1 menit.

#### 5.27.7 Webhook `POST /v1/payments/midtrans/notification`

1. Baca body (maks. 64 KB, JSON longgar: field baru diabaikan).
2. Cek `signature_key == SHA512(order_id + status_code + gross_amount + MIDTRANS_SERVER_KEY)` (hex, bandingkan constant-time). Salah → `403`, dicatat di `payment_events`.
3. Cari `payments` berdasarkan `provider_order_id` (`SELECT … FOR UPDATE`). Tidak ada → `200` (abaikan; mungkin dari env lain yang memakai akun sandbox sama).
4. Cek `gross_amount` sama dengan `payments.amount`. Beda → tandai `FAILED` + log error.
5. **Konfirmasi** lewat GET Status API (notifikasi bisa datang tidak berurutan). Pakai status dari GET Status bila berhasil.
6. Terapkan transisi 5.27.4 secara **idempotent**:
   - Sudah `PAID` → tidak membuat pesanan kedua.
   - Pembuatan pesanan memakai `orders.payment_id UNIQUE`.
7. Saat menjadi `PAID`, dalam **satu transaksi DB**:
   - `INSERT orders` dari snapshot: harga tidak dihitung ulang, dan stok / jam buka tidak dicek ulang karena uang sudah masuk.
   - Kolom: `status = 'PAID'`, `payment_method = 'ONLINE'`, `payment_provider = payment_type`.
   - `order_items`, `order_status_history` ("Dibayar via GoPay"), `sold_count`, voucher terpakai, `payments.order_id`, `paid_at`.
8. Simpan payload mentah di `payment_events`, lalu balas `200 {"status":"ok"}`.

Sweeper (goroutine tiap 1 menit) untuk `PENDING` yang lewat `expires_at` + 2 menit:

- Cek GET Status.
- Bila belum dibayar: `expire` ke Midtrans, lalu tandai `EXPIRED`.

#### 5.27.8 Skema (migrasi `0009_payments`)

```sql
CREATE TYPE payment_status AS ENUM ('PENDING','PAID','FAILED','EXPIRED','CANCELLED');

CREATE TABLE payments (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID           NOT NULL REFERENCES users(id),
    store_id           TEXT           NOT NULL REFERENCES stores(id),
    provider           TEXT           NOT NULL DEFAULT 'MIDTRANS',
    provider_order_id  TEXT           NOT NULL UNIQUE,         -- dikirim sebagai order_id ke Midtrans
    status             payment_status NOT NULL DEFAULT 'PENDING',
    amount             BIGINT         NOT NULL CHECK (amount > 0),
    quote              JSONB          NOT NULL,                -- snapshot: items, alamat, voucher, outlet, ongkir, catatan
    idempotency_key    TEXT,
    snap_token         TEXT,
    redirect_url       TEXT,
    payment_type       TEXT,                                   -- gopay | qris | bank_transfer | credit_card | …
    provider_txn_id    TEXT,                                   -- transaction_id Midtrans
    provider_status    TEXT,                                   -- transaction_status terakhir (mentah)
    status_message     TEXT,
    refund_status      TEXT,                                   -- NULL | REFUND | PARTIAL_REFUND | CHARGEBACK | REVERSED | REQUIRED
    expires_at         TIMESTAMPTZ    NOT NULL,
    paid_at            TIMESTAMPTZ,
    last_checked_at    TIMESTAMPTZ,                            -- batasi cek GET Status (5 detik)
    order_id           UUID UNIQUE REFERENCES orders(id),
    created_at         TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX payments_idempotency ON payments (user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX payments_pending_idx ON payments (expires_at) WHERE status = 'PENDING';
CREATE INDEX payments_user_idx ON payments (user_id, created_at DESC);

CREATE TABLE payment_events (                                  -- audit setiap notifikasi / cek status
    id            BIGSERIAL PRIMARY KEY,
    payment_id    UUID REFERENCES payments(id),
    source        TEXT        NOT NULL,                        -- webhook | status_api | client | sweeper
    provider_status TEXT,
    signature_ok  BOOLEAN,
    payload       JSONB       NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE orders DROP CONSTRAINT orders_payment_method_check;
ALTER TABLE orders ADD CONSTRAINT orders_payment_method_check
    CHECK (payment_method IN ('COD','QRIS','EWALLET','ONLINE'));
ALTER TABLE orders ADD COLUMN payment_id UUID UNIQUE REFERENCES payments(id);
```

`app_config.payment_methods` mendapat metode bawaan baru:

```json
{ "id": "ONLINE", "type": "ONLINE", "name": "Bayar Online",
  "description": "GoPay, QRIS, ShopeePay, transfer bank (VA), kartu", "icon": "creditcard.fill" }
```

- Saat Midtrans aktif: `QRIS` tidak dikirim di `GET /v1/me/payment-methods`, akun e-wallet tersimpan (§5.21) tampil `is_enabled: false` dan tidak bisa ditambah. Endpoint §5.21 tetap ada untuk app lama.
- Metode utama user yang menunjuk QRIS / e-wallet dibaca sebagai `ONLINE` (`default_id: "ONLINE"`).
- Midtrans nonaktif → `ONLINE` tidak dikirim sama sekali. `COD_ENABLED=false` → COD `is_enabled: false`.

#### 5.27.9 iOS

**Layer.** Ikuti pola HomeFeature; Keranjang tetap jadi pintu masuk.

- Domain:
  - `PaymentSession` (id, status, amount, expiresAt, redirectURL, finishURLPrefix, order?);
  - `PaymentRepository` (`start(selection)`, `status(id)`, `cancel(id)`, `pending()`);
  - use case: `StartCheckoutUseCase` → `.order(PlacedOrder)` untuk COD atau `.payment(PaymentSession)`; `PollPaymentUseCase`; `CancelPaymentUseCase`.
- Data:
  - `PaymentDTOs`, `PaymentMapper`;
  - `PaymentAPIDataSource` (`.checkout`, `.payment(id)`, `.cancelPayment(id)`, `.pendingPayments`);
  - `PaymentMockDataSource` + `PaymentMockStore`: sesi palsu tanpa halaman Snap, otomatis `PAID` 4 detik setelah dibuat.
- Presentation:
  - `PaymentStore` + `PaymentView`, layar penuh dari `CatalogFlow`:
    - header "Bayar Rp 49.800" + hitung mundur `expires_at`;
    - `MidtransWebView` (`UIViewRepresentable` `WKWebView`);
    - tombol Tutup ("Batalkan pembayaran?" → cancel / lanjut nanti).
  - `PaymentResultView`: sukses → "Lihat pesanan" (tab Pesanan); gagal / kedaluwarsa → "Kembali ke keranjang".

**`MidtransWebView`** (`WKNavigationDelegate.decidePolicyFor`):

- URL berawalan `finish_url_prefix` → batalkan navigasi, tutup WebView, lanjut polling. Status dari query **tidak dipercaya**; server yang menentukan.
- Scheme selain `http`/`https` (`gojek://`, `shopeeid://`, `bca://`, …) → `UIApplication.shared.open`. Gagal dibuka → biarkan Snap menampilkan QR.
- Tidak menyuntikkan JavaScript ke halaman Snap (larangan Midtrans).
- Tidak menyimpan cookie di luar sesi (`WKWebsiteDataStore.nonPersistent()`).

**Polling.**

- Tiap 3 detik selama `PaymentView` tampil, dan saat app kembali aktif (`scenePhase`).
- Berhenti saat status final atau setelah 2 menit sejak WebView ditutup. Setelah itu tampil "Kami masih menunggu konfirmasi pembayaran" + "Cek lagi".

**Lainnya.**

- **Keranjang:** baru dikosongkan setelah `PAID`.
- **Menunggu pembayaran:** sesi `PENDING` muncul sebagai kartu di Beranda ("Menunggu pembayaran Rp … · Bayar"), termasuk setelah app di-kill. Tab Pesanan belum (berikutnya).
- **Metode Pembayaran** (Profil & Keranjang): "Bayar Online" (default) + "Bayar di Tempat" bila COD aktif.
- **Error:** `PAYMENT_GATEWAY_ERROR` → "Pembayaran sedang gangguan, coba lagi."; `PAYMENT_REQUIRED` tidak muncul di app versi baru.

#### 5.27.10 Konfigurasi & testing sandbox

```dotenv
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxx     # Dashboard sandbox → Settings → Access Keys. JANGAN ditaruh di iOS / web admin
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_ENABLED_PAYMENTS=                     # kosong = semua channel aktif; contoh: gopay,shopeepay,bca_va,bni_va,credit_card
PAYMENT_EXPIRY=15m
PUBLIC_BASE_URL=http://localhost:8080          # dev: ganti dengan URL tunnel supaya webhook masuk
COD_ENABLED=true
```

- Client Key **tidak dibutuhkan**: iOS memakai `redirect_url`, bukan `snap.js`.
- **Webhook di laptop.** Midtrans tidak bisa mengirim ke `localhost`.
  - Jalankan tunnel, mis. `cloudflared tunnel --url http://localhost:8080`.
  - Isi URL-nya di Dashboard sandbox → Settings → Configuration → **Payment Notification URL** = `https://<tunnel>/v1/payments/midtrans/notification`.
  - Tanpa tunnel pun alur tetap selesai lewat cek GET Status saat polling (5.27.3), hanya sedikit lebih lambat.
- **Bayar di sandbox** (jangan pakai uang asli):
  - QRIS / GoPay / ShopeePay: salin URL/QR ke `https://simulator.sandbox.midtrans.com/v2/qris/index` atau `…/v2/deeplink/index`.
  - VA: simulator per bank, mis. BCA `https://simulator.sandbox.midtrans.com/bca/va/index`.
  - Kartu: `4811 1111 1111 1114`, CVV `123`, OTP `112233`, masa berlaku tahun depan.
- **Tes otomatis.** `midtrans.Client` berupa interface. `TestPayments` memakai fake untuk:
  - sukses → pesanan dibuat sekali walau webhook dikirim 3×;
  - signature salah;
  - amount beda;
  - expire;
  - settlement terlambat;
  - idempotency;
  - satu sesi aktif per user;
  - `POST /v1/orders` ONLINE → 422.
- **Produksi:** `MIDTRANS_IS_PRODUCTION=true` + server key produksi + `PUBLIC_BASE_URL` https asli. Notification URL diisi di dashboard produksi.

#### 5.27.11 Di luar cakupan tahap ini

- Refund otomatis (Refund API). Sementara: admin menandai pesanan `FAILED`/`CANCELLED` → `refund_status = REQUIRED` tampil di admin, refund dilakukan manual dari dashboard Midtrans.
- Simpan kartu / GoPay tokenization (one-click).
- Pembayaran di web admin (kasir).

### 5.28 Notifikasi push (APNs)

Dikirim langsung ke **APNs** (Apple Push Notification service) dengan *token-based auth* (file `.p8`), tanpa Firebase: tidak perlu SDK tambahan di iOS maupun service account Google. Bila nanti butuh Android, `push.Sender` bisa ditambah implementasi FCM.

**Kapan dikirim** (setelah transaksi DB commit, di background, maks. 15 detik):

| Kejadian | Judul | `type` di payload |
|---|---|---|
| Pembayaran online lunas (§5.27) | Pembayaran berhasil 🎉 — "Pesanan ORD-… diteruskan ke outlet …" | `payment_paid` (+ `payment_id`, `order_id`) |
| Pembayaran kedaluwarsa | Waktu pembayaran habis | `payment_expired` (+ `payment_id`) |
| Admin / outlet: `PROCESSING` | Pesanan sedang disiapkan 👨‍🍳 | `order_status` (+ `order_id`, `status`) |
| `DELIVERING` | Pesanan dalam perjalanan 🛵 | `order_status` |
| `COMPLETED` | Pesanan selesai ✅ — ajakan memberi nilai | `order_status` |
| `FAILED` / `CANCELLED` oleh admin | Pesanan gagal / dibatalkan + alasan admin | `order_status` |

Payload APNs:

```json
{ "aps": { "alert": { "title": "Pembayaran berhasil 🎉", "body": "Pesanan ORD-20261018-0007 diteruskan ke outlet Gandaria City." },
           "sound": "default", "thread-id": "<order_id>" },
  "type": "payment_paid", "payment_id": "6c2f…", "order_id": "1b7d…" }
```

**Endpoint.**

| Endpoint | Body | Keterangan |
|---|---|---|
| `PUT /v1/me/devices` 🔒 | `{ "token": "<hex>", "bundle_id": "com.lshinkuro.try-tuist.dev", "environment": "sandbox" }` | `environment`: `sandbox` (build Debug) \| `production` (TestFlight/App Store). Token yang sama dari akun lain dipindahkan ke user ini. → `{ "push_enabled": bool }` |
| `POST /v1/devices/unregister` | `{ "token": "<hex>" }` | Tanpa login (dipanggil setelah token sesi dihapus). Idempotent |
| `POST /v1/dev/push-test` 🔒 | — | Hanya `APP_ENV=dev` |

- APNs membalas `410` / `BadDeviceToken` / `DeviceTokenNotForTopic` → token dihapus otomatis.
- `apns-topic` = `bundle_id` yang dikirim app, jadi build Dev (`….dev`) dan Prod memakai key `.p8` yang sama.
- Tabel `push_devices` (migrasi `0010_push_devices`): `token` (PK), `user_id`, `platform`, `bundle_id`, `environment`, `last_seen_at`.

**iOS.**

- `NotificationManager` meminta izin. Bila diizinkan → `registerForRemoteNotifications`.
- `AppDelegate` meneruskan device token ke `PushRegistrar` (App target).
- `PushRegistrar` mengirim `PUT /v1/me/devices` setelah login (`AppRouter.showMain`) dan setiap token baru.
- Saat sesi berakhir (cold start, logout Profil, sesi habis 401, Debugger) → `POST /v1/devices/unregister`.
- Tap notifikasi `payment_paid` / `order_status` → tab Pesanan. Bila app dibuka dari notifikasi lalu harus login dulu, tab Pesanan dipilih setelah login.
- `TryTuist.entitlements` (`aps-environment = development`) dipasang di target app lewat `Project.swift`.

**Setup.**

1. Developer account berbayar → developer.apple.com → Certificates, IDs & Profiles → **Keys** → `+` → centang **Apple Push Notifications service (APNs)** → unduh `AuthKey_XXXXXXXXXX.p8` (hanya bisa diunduh sekali). Catat **Key ID** dan **Team ID**.
2. Backend `.env`: `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_KEY_FILE=/path/AuthKey_….p8`. Log start: `push APNs aktif`.
3. Xcode: target TryTuist → Signing & Capabilities harus menampilkan **Push Notifications** (dari entitlements). App ID `com.lshinkuro.try-tuist.dev` otomatis mendapat capability Push dengan Automatic signing.
4. Jalankan di **iPhone asli**, atau Simulator iOS 16+ di Mac Apple silicon. Izinkan notifikasi, login, lalu `curl -X POST …/v1/dev/push-test` dengan token login.
5. Tes tanpa backend: `xcrun simctl push booted com.lshinkuro.try-tuist.dev payload.apns`.

---

## 6. Skema database (PostgreSQL)

`db/migrations/0001_init.up.sql`:

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()

-- ========== User & Auth ==========
CREATE TABLE users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name           TEXT        NOT NULL,
    email          TEXT        NOT NULL,
    password_hash  TEXT,                                 -- NULL = akun Google tanpa password (migrasi 0005)
    phone          TEXT,
    avatar_url     TEXT,
    member_tier    TEXT        NOT NULL DEFAULT 'SILVER' CHECK (member_tier IN ('SILVER','GOLD','PLATINUM')),
    points         INTEGER     NOT NULL DEFAULT 0 CHECK (points >= 0),
    balance        BIGINT      NOT NULL DEFAULT 0 CHECK (balance >= 0),
    fcm_token      TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_email_key ON users (lower(email));

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT        NOT NULL UNIQUE,          -- simpan SHA-256, bukan token asli
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    user_agent  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX refresh_tokens_user_idx ON refresh_tokens (user_id);

-- ========== Katalog ==========
CREATE TABLE categories (
    id          TEXT PRIMARY KEY,                     -- 'coffee', 'rice', ...
    name        TEXT    NOT NULL,
    icon        TEXT    NOT NULL DEFAULT '🍽️',
    sort_order  INTEGER NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE products (
    id              TEXT PRIMARY KEY,                 -- 'P01', ...
    category_id     TEXT          NOT NULL REFERENCES categories(id),
    name            TEXT          NOT NULL,
    description     TEXT          NOT NULL DEFAULT '',
    price           BIGINT        NOT NULL CHECK (price >= 0),   -- Rupiah
    image_url       TEXT,
    rating          NUMERIC(2,1)  NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    sold_count      INTEGER       NOT NULL DEFAULT 0,
    is_available    BOOLEAN       NOT NULL DEFAULT TRUE,
    is_best_seller  BOOLEAN       NOT NULL DEFAULT FALSE,
    sort_order      INTEGER       NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX products_category_idx ON products (category_id, sort_order);

CREATE TABLE product_options (
    product_id   TEXT    NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    id           TEXT    NOT NULL,                    -- 'regular', 'large', 'spicy', ...
    name         TEXT    NOT NULL,
    extra_price  BIGINT  NOT NULL DEFAULT 0 CHECK (extra_price >= 0),
    sort_order   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (product_id, id)
);

CREATE TABLE banners (
    id          TEXT PRIMARY KEY,
    title       TEXT        NOT NULL,
    subtitle    TEXT        NOT NULL DEFAULT '',
    image_url   TEXT        NOT NULL,
    deeplink    TEXT,                                -- mis. 'trytuist://category/coffee'
    starts_at   TIMESTAMPTZ,
    ends_at     TIMESTAMPTZ,
    sort_order  INTEGER     NOT NULL DEFAULT 0,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE stores (
    id        TEXT PRIMARY KEY,                      -- 'ST01'
    name      TEXT             NOT NULL,             -- 'Gandaria City'
    address   TEXT             NOT NULL,
    lat       DOUBLE PRECISION NOT NULL,
    lng       DOUBLE PRECISION NOT NULL,
    is_open   BOOLEAN          NOT NULL DEFAULT TRUE  -- false = tutup sementara (tombol admin)
    -- 0008_multi_outlet:
    -- phone TEXT, opens_at TIME DEFAULT '00:00', closes_at TIME DEFAULT '00:00' (sama = 24 jam),
    -- delivery_radius_km NUMERIC(4,1) DEFAULT 7 CHECK (> 0 AND <= 50),
    -- is_active BOOLEAN DEFAULT TRUE, sort_order INT DEFAULT 0, created_at TIMESTAMPTZ
);

-- 0008_multi_outlet: menu habis khusus di satu outlet (tidak ada baris = ikut products.is_available)
CREATE TABLE store_product_availability (
    store_id     TEXT        NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_id   TEXT        NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    is_available BOOLEAN     NOT NULL,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (store_id, product_id)
);
-- + index orders (store_id, created_at) untuk filter outlet di admin

-- ========== Alamat, favorit, voucher ==========
CREATE TABLE addresses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label       TEXT    NOT NULL,                    -- 'Rumah', 'Kantor'
    recipient   TEXT    NOT NULL,
    phone       TEXT    NOT NULL,
    address     TEXT    NOT NULL,
    notes       TEXT,
    lat         DOUBLE PRECISION,
    lng         DOUBLE PRECISION,
    is_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX addresses_one_default ON addresses (user_id) WHERE is_default;

CREATE TABLE favorites (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id  TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, product_id)
);

CREATE TABLE vouchers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            TEXT   NOT NULL UNIQUE,
    title           TEXT   NOT NULL,
    description     TEXT   NOT NULL DEFAULT '',
    discount_type   TEXT   NOT NULL CHECK (discount_type IN ('PERCENT','FIXED')),
    discount_value  BIGINT NOT NULL CHECK (discount_value > 0),
    min_subtotal    BIGINT NOT NULL DEFAULT 0,
    max_discount    BIGINT,
    starts_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    ends_at         TIMESTAMPTZ NOT NULL,
    quota           INTEGER
);

CREATE TABLE user_vouchers (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    voucher_id  UUID NOT NULL REFERENCES vouchers(id) ON DELETE CASCADE,
    used_at     TIMESTAMPTZ,
    PRIMARY KEY (user_id, voucher_id)
);

-- ========== Pesanan ==========
CREATE TYPE order_status AS ENUM ('PENDING','PAID','PROCESSING','DELIVERING','COMPLETED','CANCELLED','FAILED');

CREATE TABLE orders (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number     TEXT          NOT NULL UNIQUE,      -- 'ORD-20261017-0042'
    user_id          UUID          NOT NULL REFERENCES users(id),
    store_id         TEXT          NOT NULL REFERENCES stores(id),
    address_id       UUID          REFERENCES addresses(id),
    status           order_status  NOT NULL DEFAULT 'PENDING',
    subtotal         BIGINT        NOT NULL,
    delivery_fee     BIGINT        NOT NULL DEFAULT 0,
    discount         BIGINT        NOT NULL DEFAULT 0,
    total            BIGINT        NOT NULL CHECK (total >= 0),
    voucher_id       UUID          REFERENCES vouchers(id),
    payment_method   TEXT          NOT NULL CHECK (payment_method IN ('COD','QRIS','EWALLET')),
    note             TEXT,
    idempotency_key  TEXT,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX orders_user_created_idx ON orders (user_id, created_at DESC);
CREATE UNIQUE INDEX orders_idempotency_key ON orders (user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;

CREATE TABLE order_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id      UUID    NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id    TEXT    NOT NULL REFERENCES products(id),
    product_name  TEXT    NOT NULL,                  -- snapshot saat order dibuat
    option_id     TEXT,
    option_name   TEXT,
    unit_price    BIGINT  NOT NULL,                  -- snapshot harga (produk + opsi)
    quantity      INTEGER NOT NULL CHECK (quantity BETWEEN 1 AND 20),
    note          VARCHAR(100) NOT NULL DEFAULT '',
    subtotal      BIGINT  NOT NULL
);
CREATE INDEX order_items_order_idx ON order_items (order_id);

CREATE TABLE order_status_history (
    order_id  UUID         NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status    order_status NOT NULL,
    at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE order_ratings (
    order_id    UUID PRIMARY KEY REFERENCES orders(id) ON DELETE CASCADE,
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Relasi utama:

```mermaid
erDiagram
    users ||--o{ refresh_tokens : has
    users ||--o{ addresses : has
    users ||--o{ orders : places
    users ||--o{ favorites : likes
    users ||--o{ user_payment_methods : "menautkan"
    help_topics ||--o{ help_articles : contains
    categories ||--o{ products : groups
    products ||--o{ product_options : has
    products ||--o{ order_items : "dipesan di"
    stores ||--o{ orders : fulfils
    orders ||--|{ order_items : contains
    orders ||--o{ order_status_history : tracks
    orders ||--o| order_ratings : rated
    vouchers ||--o{ orders : "dipakai di"
```

`db/migrations/0002_home_config.up.sql` (untuk §5.18–5.20):

```sql
-- Isi & urutan section Beranda, diatur dari backend
CREATE TABLE home_sections (
    id           TEXT PRIMARY KEY,                    -- 'best_seller', 'recommended'
    type         TEXT    NOT NULL CHECK (type IN ('BANNER_CAROUSEL','CATEGORY_GRID','PRODUCT_CAROUSEL','PRODUCT_LIST')),
    title        TEXT,
    rule         TEXT    CHECK (rule IN ('BEST_SELLER','TOP_RATED','MANUAL')),   -- khusus section produk
    product_ids  TEXT[],                              -- dipakai bila rule = 'MANUAL'
    item_limit   INTEGER NOT NULL DEFAULT 6,
    see_all      JSONB,                               -- mis. {"sort":"popular"}
    sort_order   INTEGER NOT NULL DEFAULT 0,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE
);

-- Konfigurasi app (satu baris per key, nilai JSON)
CREATE TABLE app_config (
    key         TEXT PRIMARY KEY,                     -- 'order_rules', 'onboarding', 'profile_menu', ...
    value       JSONB       NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Paket langganan & langganan user
CREATE TABLE subscription_plans (
    id          TEXT PRIMARY KEY,                     -- 'daily-coffee'
    eyebrow     TEXT    NOT NULL,
    title       TEXT    NOT NULL,
    price       BIGINT  NOT NULL,
    period      TEXT    NOT NULL CHECK (period IN ('DAILY','WEEKLY','MONTHLY')),
    image_url   TEXT,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_subscriptions (
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id       TEXT NOT NULL REFERENCES subscription_plans(id),
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    active_until  TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, plan_id)
);

-- Seed (sama dengan tampilan iOS sekarang)
INSERT INTO home_sections (id, type, title, rule, item_limit, see_all, sort_order) VALUES
  ('promo',       'BANNER_CAROUSEL',  NULL,                     NULL,          5, NULL,                   1),
  ('categories',  'CATEGORY_GRID',    'Kategori',               NULL,         12, NULL,                   2),
  ('best_seller', 'PRODUCT_CAROUSEL', '🔥 Paling Laris',        'BEST_SELLER', 6, '{"sort":"popular"}',   3),
  ('recommended', 'PRODUCT_LIST',     'Rekomendasi Buat Kamu',  'TOP_RATED',   5, NULL,                   4);

INSERT INTO subscription_plans (id, eyebrow, title, price, period, is_featured) VALUES
  ('daily-coffee', 'LANGGANAN KOPI HARIAN', '1 cup cuma 15rb / hari', 15000, 'DAILY', TRUE);

-- app_config: isi `value` dengan JSON di §5.19 (order_rules, payment_methods, onboarding, profile_menu, ...)
```

`db/migrations/0003_profile_features.up.sql` (untuk §5.21–5.23):

```sql
-- E-wallet yang ditautkan user. COD & QRIS bawaan, tidak disimpan per user.
-- Nomor kartu TIDAK pernah disimpan.
CREATE TABLE user_payment_methods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            TEXT        NOT NULL DEFAULT 'EWALLET' CHECK (type IN ('EWALLET')),
    provider        TEXT        NOT NULL,                 -- id dari app_config.ewallet_providers
    account_number  TEXT        NOT NULL,                 -- nomor HP e-wallet (sudah dinormalisasi)
    account_name    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, provider, account_number)
);
CREATE INDEX user_payment_methods_user ON user_payment_methods (user_id, created_at);

-- 'COD' | 'QRIS' | id (uuid) dari user_payment_methods
ALTER TABLE users ADD COLUMN default_payment_method TEXT NOT NULL DEFAULT 'COD';

CREATE TABLE help_topics (
    id          TEXT PRIMARY KEY,                         -- 'order', 'payment'
    title       TEXT    NOT NULL,
    icon        TEXT    NOT NULL,                         -- SF Symbol
    sort_order  INTEGER NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE help_articles (
    id          TEXT PRIMARY KEY,                         -- 'order-cancel'
    topic_id    TEXT    NOT NULL REFERENCES help_topics(id) ON DELETE CASCADE,
    question    TEXT    NOT NULL,
    answer      TEXT    NOT NULL,                         -- paragraf dipisah baris kosong
    sort_order  INTEGER NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX help_articles_topic ON help_articles (topic_id, sort_order);

CREATE TABLE legal_documents (
    slug          TEXT PRIMARY KEY,                       -- 'privacy-policy', 'terms'
    title         TEXT        NOT NULL,
    version       TEXT        NOT NULL,
    summary       TEXT,
    sections      JSONB       NOT NULL,                   -- [{"heading": "...", "body": "..."}]
    effective_at  DATE        NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (jsonb_typeof(sections) = 'array')
);

-- app_config: payment_methods (EWALLET aktif + description), ewallet_providers (baru),
-- help_contacts (baru), profile_menu (action → trytuist://help, trytuist://legal/privacy-policy,
-- trytuist://profile/edit). Isi awal 5 topik / 12 FAQ bantuan + 2 dokumen legal ikut migrasi
-- (staging/prod juga butuh).
```

`db/migrations/0004_checkout_defaults.up.sql` (untuk §5.11, checkout memakai pilihan utama):

```sql
-- Snapshot akun e-wallet di pesanan: riwayat tetap terbaca walau e-wallet dihapus.
ALTER TABLE orders
    ADD COLUMN payment_account_id     UUID REFERENCES user_payment_methods(id) ON DELETE SET NULL,
    ADD COLUMN payment_provider       TEXT,
    ADD COLUMN payment_account_masked TEXT;
```

`db/migrations/0005_google_auth.up.sql` (untuk §5.3b):

```sql
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
ALTER TABLE users ADD COLUMN google_sub TEXT;                 -- claim `sub` dari Google
CREATE UNIQUE INDEX users_google_sub_key ON users (google_sub) WHERE google_sub IS NOT NULL;
ALTER TABLE users ADD CONSTRAINT users_has_login_method
    CHECK (password_hash IS NOT NULL OR google_sub IS NOT NULL);
```

---

## 7. Aturan bisnis

| Aturan | Nilai | Sama dengan iOS |
|---|---|---|
| Harga **selalu dihitung ulang di server** dari tabel `products` + `product_options`. Harga dari client diabaikan. | | |
| Jumlah per item | 1–20 | `AddToCartUseCase.quantityRange` |
| Panjang catatan item | ≤ 100 karakter | `ProductDetailState.noteLimit` |
| Ongkir | flat Rp 10.000 | `CartState.standardDeliveryFee` |
| Gratis ongkir | subtotal ≥ Rp 50.000 dengan voucher/banner promo B2 | (belum di iOS) |
| Produk habis | `is_available = false` (pusat) atau habis di outlet (§5.26) → 422 `PRODUCT_UNAVAILABLE` | `CartError.productUnavailable` / pesan server |
| Outlet | tutup → 422 `STORE_CLOSED`; alamat di luar radius → 422 `OUT_OF_DELIVERY_AREA`; harga sama di semua outlet | `CartError.rejected(pesan)` |
| Keranjang kosong | 422 `EMPTY_CART` | `CartError.emptyCart` |
| Password | ≥ 8 karakter, disimpan bcrypt (cost 12) | `CredentialValidator` |
| Nomor order | `ORD-YYYYMMDD-NNNN` (urut per hari) | |
| Checkout | satu transaksi DB: validasi → hitung → insert `orders` + `order_items` → update `sold_count` | |

Transisi status pesanan:

```mermaid
stateDiagram-v2
    [*] --> PENDING
    PENDING --> PAID : bayar (QRIS/e-wallet)
    PENDING --> PROCESSING : COD diterima outlet
    PAID --> PROCESSING
    PROCESSING --> DELIVERING
    DELIVERING --> COMPLETED
    PENDING --> CANCELLED : user batal
    PENDING --> FAILED : pembayaran gagal / timeout 15 menit
    COMPLETED --> [*]
```

---

## 8. Struktur project Go

```
trytuist-api/
├── cmd/api/main.go                 # load config → pgxpool → router → http.Server (graceful shutdown)
├── internal/
│   ├── config/config.go            # baca env (APP_ENV, DATABASE_URL, JWT_SECRET, API_KEYS, ...)
│   ├── httpx/                      # helper bersama
│   │   ├── response.go             # JSON(w, status, data, meta) & Error(w, status, type, msg)
│   │   ├── middleware.go           # RequestID, Logger, Recover, APIKey, Auth(JWT), RateLimit
│   │   └── router.go               # chi.Router: /healthz, /v1/...
│   ├── auth/                       # handler.go · service.go · repository.go · dto.go · jwt.go
│   ├── catalog/                    # banners, categories, products
│   ├── order/                      # quote, create, list, detail, cancel, rating
│   ├── user/                       # me, addresses, favorites, vouchers, payment-methods
│   ├── content/                    # help (FAQ + kontak), legal (kebijakan privasi, S&K)
│   └── db/                         # kode hasil sqlc (jangan diedit manual)
├── db/
│   ├── migrations/                 # 0001_init.up.sql / .down.sql, ...
│   ├── queries/                    # auth.sql, catalog.sql, order.sql, user.sql (input sqlc)
│   └── seed/dev_seed.sql           # data contoh (§9) — hanya untuk dev/staging
├── sqlc.yaml
├── docker-compose.yml
├── Makefile                        # run, migrate-up, migrate-down, sqlc, seed, test, lint
├── .env.example
└── README.md
```

Pola per modul (sama seperti layer iOS):

```go
// handler.go — HTTP saja: parse & validasi request, panggil service, tulis response.
func (h *Handler) ListProducts(w http.ResponseWriter, r *http.Request) {
    filter, err := parseProductFilter(r.URL.Query())
    if err != nil { httpx.Error(w, 400, "VALIDATION_ERROR", err.Error()); return }
    products, total, err := h.svc.ListProducts(r.Context(), filter)
    if err != nil { httpx.FromError(w, err); return }
    httpx.JSON(w, 200, toProductDTOs(products), httpx.Meta{Page: filter.Page, Limit: filter.Limit, Total: total})
}

// service.go — aturan bisnis, tanpa HTTP.
// repository.go — query sqlc, map row DB → model domain.
// dto.go — struct JSON (snake_case) + mapper model → DTO.
type ProductDTO struct {
    ProductID   string      `json:"product_id"`
    ProductName string      `json:"product_name"`
    Description string      `json:"description"`
    CategoryID  string      `json:"category_id"`
    Price       int64       `json:"price"`
    ImageURL    string      `json:"image_url"`
    Rating      float64     `json:"rating"`
    SoldCount   int         `json:"sold_count"`
    IsAvailable bool        `json:"is_available"`
    Tags        []string    `json:"tags"`
    Options     []OptionDTO `json:"options"`
}
```

Middleware per grup route:

```go
r.Get("/healthz", health)
r.Route("/v1", func(r chi.Router) {
    r.Use(mw.APIKey(cfg.APIKeys))
    r.Post("/auth/login", auth.Login)          // + mw.RateLimit
    r.Post("/auth/register", auth.Register)
    r.Post("/auth/refresh", auth.Refresh)
    r.Get("/banners", catalog.Banners)
    r.Get("/categories", catalog.Categories)
    r.Get("/products", catalog.ListProducts)
    r.Get("/products/{id}", catalog.GetProduct)

    r.Group(func(r chi.Router) {
        r.Use(mw.Auth(cfg.JWTSecret))          // 🔒
        r.Post("/auth/logout", auth.Logout)
        r.Post("/orders/quote", order.Quote)
        r.Post("/orders", order.Create)
        r.Get("/orders", order.List)
        r.Get("/orders/{id}", order.Get)
        r.Post("/orders/{id}/cancel", order.Cancel)
        r.Post("/orders/{id}/rating", order.Rate)
        r.Get("/me", user.Me)
        r.Patch("/me", user.UpdateMe)
        // addresses, favorites, vouchers ...
        r.Get("/me/payment-methods", payment.List)
        r.Post("/me/payment-methods", payment.Add)
        r.Put("/me/payment-methods/default", payment.SetDefault)
        r.Delete("/me/payment-methods/{id}", payment.Remove)
    })
})
```

---

## 9. Seed data

`db/seed/dev_seed.sql` berisi data yang **sama dengan mock iOS** (`CatalogFixtures.swift`), jadi tampilan app tidak berubah saat pindah dari Mock ke API:

```sql
-- Kategori
INSERT INTO categories (id, name, icon, sort_order) VALUES
  ('coffee', 'Kopi', '☕️', 1),
  ('non_coffee', 'Non-Kopi', '🍵', 2),
  ('rice', 'Nasi & Mie', '🍛', 3),
  ('fast_food', 'Burger & Ayam', '🍔', 4),
  ('snack', 'Camilan', '🍟', 5),
  ('dessert', 'Dessert', '🍰', 6);

-- Banner promo
INSERT INTO banners (id, title, subtitle, image_url, sort_order) VALUES
  ('B1', 'Diskon 30% Makan Siang', 'Semua menu makanan, khusus jam 11–14', 'https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=1200&q=80&auto=format&fit=crop', 1),
  ('B2', 'Gratis Ongkir Rp 0', 'Min. belanja Rp 50.000 se-Jakarta', 'https://images.unsplash.com/photo-1424847651672-bf20a4b0982b?w=1200&q=80&auto=format&fit=crop', 2),
  ('B3', 'Kopi Pagi Cuma 15rb', 'Setiap hari sebelum jam 10 pagi', 'https://images.unsplash.com/photo-1596018589878-217d8603c4c6?w=1200&q=80&auto=format&fit=crop', 3);

-- Produk (foto: Unsplash, lisensi gratis)
INSERT INTO products (id, category_id, name, description, price, image_url, rating, sold_count, is_available, is_best_seller, sort_order) VALUES
  ('P01', 'coffee', 'Es Kopi Susu Gula Aren', 'Espresso, susu segar, dan gula aren asli. Manisnya pas, cocok buat semangat seharian.', 22000, 'https://images.unsplash.com/photo-1767471716700-2b3aa77b1ab6?w=800&q=80&auto=format&fit=crop', 4.9, 1520, TRUE, TRUE, 1),
  ('P02', 'coffee', 'Cappuccino', 'Espresso dengan foam susu yang lembut dan tebal.', 25000, 'https://images.unsplash.com/photo-1563311977-d285756282dc?w=800&q=80&auto=format&fit=crop', 4.7, 640, TRUE, FALSE, 2),
  ('P03', 'coffee', 'Caffe Latte', 'Espresso dan susu steamed dengan latte art cantik.', 24000, 'https://images.unsplash.com/photo-1593443320739-77f74939d0da?w=800&q=80&auto=format&fit=crop', 4.6, 580, TRUE, FALSE, 3),
  ('P04', 'coffee', 'Iced Americano', 'Double shot espresso dengan air dingin dan es batu. Segar tanpa gula.', 20000, 'https://images.unsplash.com/photo-1676506739319-70bff65bfc48?w=800&q=80&auto=format&fit=crop', 4.5, 410, TRUE, FALSE, 4),
  ('P05', 'non_coffee', 'Iced Matcha Latte', 'Matcha premium dari Uji, Jepang, dengan susu segar dan es.', 27000, 'https://images.unsplash.com/photo-1749280447307-31a68eb38673?w=800&q=80&auto=format&fit=crop', 4.8, 890, TRUE, TRUE, 5),
  ('P06', 'non_coffee', 'Hot Matcha', 'Matcha hangat yang creamy, pas untuk sore hari.', 25000, 'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?w=800&q=80&auto=format&fit=crop', 4.4, 220, FALSE, FALSE, 6),
  ('P07', 'rice', 'Nasi Goreng Spesial', 'Nasi goreng bumbu rumahan dengan telur, ayam suwir, dan kerupuk.', 32000, 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800&q=80&auto=format&fit=crop', 4.8, 1210, TRUE, TRUE, 7),
  ('P08', 'rice', 'Nasi Goreng Udang', 'Nasi goreng dengan udang segar dan sayuran.', 38000, 'https://images.unsplash.com/photo-1551326844-4df70f78d0e9?w=800&q=80&auto=format&fit=crop', 4.6, 530, TRUE, FALSE, 8),
  ('P09', 'rice', 'Ramen Pedas', 'Kuah kaldu kaya rasa, mie kenyal, telur ajitama, dan chashu.', 45000, 'https://images.unsplash.com/photo-1509680859026-7d8cfc6894f4?w=800&q=80&auto=format&fit=crop', 4.7, 760, TRUE, FALSE, 9),
  ('P10', 'fast_food', 'Ayam Goreng Krispi', 'Ayam goreng tepung renyah dengan saus sambal spesial.', 29000, 'https://images.unsplash.com/photo-1585703900468-13c7a978ad86?w=800&q=80&auto=format&fit=crop', 4.6, 980, TRUE, FALSE, 10),
  ('P11', 'fast_food', 'Classic Beef Burger', 'Patty daging sapi, keju cheddar, selada, dan saus rahasia.', 42000, 'https://images.unsplash.com/photo-1543339469-94ba2391431f?w=800&q=80&auto=format&fit=crop', 4.8, 1040, TRUE, TRUE, 11),
  ('P12', 'snack', 'Kentang Goreng', 'Kentang goreng renyah dengan saus tomat.', 18000, 'https://images.unsplash.com/photo-1716042998725-0e0b957b9d99?w=800&q=80&auto=format&fit=crop', 4.5, 870, TRUE, FALSE, 12),
  ('P13', 'snack', 'Butter Croissant', 'Croissant mentega yang flaky, dipanggang setiap pagi.', 21000, 'https://images.unsplash.com/photo-1623334044303-241021148842?w=800&q=80&auto=format&fit=crop', 4.6, 450, TRUE, FALSE, 13),
  ('P14', 'dessert', 'Chocolate Cake', 'Kue cokelat lembap dengan ganache dark chocolate.', 35000, 'https://images.unsplash.com/photo-1517427294546-5aa121f68e8a?w=800&q=80&auto=format&fit=crop', 4.9, 690, TRUE, TRUE, 14);

-- Varian produk
INSERT INTO product_options (product_id, id, name, extra_price, sort_order) VALUES
  ('P01', 'regular', 'Regular', 0, 1),
  ('P01', 'large', 'Large', 5000, 2),
  ('P02', 'regular', 'Regular', 0, 1),
  ('P02', 'large', 'Large', 5000, 2),
  ('P03', 'regular', 'Regular', 0, 1),
  ('P03', 'large', 'Large', 5000, 2),
  ('P04', 'regular', 'Regular', 0, 1),
  ('P04', 'large', 'Large', 5000, 2),
  ('P05', 'regular', 'Regular', 0, 1),
  ('P05', 'large', 'Large', 5000, 2),
  ('P06', 'regular', 'Regular', 0, 1),
  ('P06', 'large', 'Large', 5000, 2),
  ('P07', 'normal', 'Normal', 0, 1),
  ('P07', 'spicy', 'Pedas', 0, 2),
  ('P07', 'jumbo', 'Porsi Jumbo', 8000, 3),
  ('P08', 'normal', 'Normal', 0, 1),
  ('P08', 'spicy', 'Pedas', 0, 2),
  ('P08', 'jumbo', 'Porsi Jumbo', 8000, 3),
  ('P09', 'normal', 'Normal', 0, 1),
  ('P09', 'spicy', 'Pedas', 0, 2),
  ('P09', 'jumbo', 'Porsi Jumbo', 8000, 3),
  ('P10', 'normal', 'Normal', 0, 1),
  ('P10', 'spicy', 'Pedas', 0, 2),
  ('P10', 'jumbo', 'Porsi Jumbo', 8000, 3);

-- Outlet
-- Outlet (lengkap di db/seed/dev_seed.sql): ST01 & ST02 24 jam (radius 7 & 5 km),
-- ST03 Kelapa Gading 10:00–22:00 (radius 6 km). Stok: Ramen Pedas (P09) habis di ST02,
-- Chocolate Cake (P14) habis di ST03.
INSERT INTO stores (id, name, address, lat, lng) VALUES
  ('ST01', 'Gandaria City', 'Jl. Sultan Iskandar Muda, Jakarta Selatan', -6.2443, 106.7834),
  ('ST02', 'Kemang Utara', 'Jl. Kemang Utara Raya, Jakarta Selatan', -6.2608, 106.8133),
  ('ST03', 'Kelapa Gading', 'Jl. Boulevard Raya, Jakarta Utara', -6.1588, 106.9057);

-- Akun demo (password: 12345678 & password123) — hash dibuat dengan bcrypt saat seeding:
--   go run ./cmd/seed  (atau isi password_hash dengan hasil bcrypt.GenerateFromPassword)
-- kholis@gmail.com / 12345678, demo@trytuist.com / password123  (sama dengan AuthMockDataSource)
```

`db/migrations/0006_product_deals.up.sql` (untuk §5.24):

```sql
CREATE TABLE product_deals (
    id            TEXT PRIMARY KEY,
    product_id    TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    title         TEXT NOT NULL,
    subtitle      TEXT NOT NULL DEFAULT '',
    badge         TEXT NOT NULL DEFAULT '',           -- kosong = "HEMAT {persen}%"
    image_url     TEXT,                               -- NULL = foto produk
    deal_price    BIGINT NOT NULL CHECK (deal_price > 0),
    starts_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    ends_at       TIMESTAMPTZ NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    show_as_popup BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order    INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at)
);
CREATE INDEX product_deals_active_idx ON product_deals (product_id) WHERE is_active;
CREATE INDEX product_deals_popup_idx ON product_deals (sort_order) WHERE is_active AND show_as_popup;
```

`db/migrations/0007_admin.up.sql` (untuk §5.25):

```sql
ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'CUSTOMER' CHECK (role IN ('CUSTOMER', 'ADMIN'));
ALTER TABLE order_status_history
    ADD COLUMN note       TEXT,
    ADD COLUMN changed_by UUID REFERENCES users(id) ON DELETE SET NULL;
CREATE TABLE admin_audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    action      TEXT NOT NULL,          -- ORDER_STATUS | PRODUCT_CREATE | PRODUCT_UPDATE | DEAL_CREATE | DEAL_UPDATE | DEAL_DELETE
    entity      TEXT NOT NULL,          -- order | product | deal
    entity_id   TEXT NOT NULL,
    summary     TEXT NOT NULL,
    data        JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX admin_audit_logs_created_idx ON admin_audit_logs (created_at DESC);
CREATE INDEX orders_created_idx ON orders (created_at DESC);
CREATE INDEX orders_status_created_idx ON orders (status, created_at DESC);
```

Harga berlaku dihitung di query katalog: `COALESCE((SELECT min(deal_price) … deal aktif & < p.price), p.price)`. Seed dev: `D01` Nasi Goreng Spesial 32.000 → 19.900 (popup), `D02` Iced Matcha Latte 27.000 → 17.900, `D03` Kentang Goreng 18.000 → 12.000; semuanya berlaku 30 hari sejak seed dijalankan.

---

## 10. Roadmap & checklist

**Fase 1: Auth + Katalog** (cukup untuk login dan Beranda/Menu tanpa mock)

- [x] Init repo, `go mod init`, docker-compose Postgres, `Makefile`
- [x] `config`, `httpx` (envelope, error), middleware RequestID/Logger/Recover/APIKey
- [x] Migrasi `0001_init` + seed
- [x] `GET /healthz`
- [x] `POST /v1/auth/register`, `/login`, `/refresh`, `/logout` (JWT + refresh token rotation)
- [x] `GET /v1/banners`, `/v1/categories`, `/v1/products`, `/v1/products/{id}`
- [x] Test: unit service + integration test handler (DB test lokal `trytuist_test`: `TestAuthFlow`, `TestCatalog`)
- [x] iOS: `USE_MOCK_DATA = NO` di Dev → login & katalog jalan dari API
- [x] `POST /v1/auth/google` (daftar & masuk dengan Google, migrasi `0005_google_auth`, `TestGoogleSignIn`)
- [x] iOS: tombol "Lanjutkan dengan Google" di Sign In & Sign Up (GoogleSignIn-iOS)

**Fase 1b: Semua data Beranda, Menu & konfigurasi dari backend**

- [x] Migrasi `0002_home_config` + seed `home_sections` & `app_config`
- [x] `GET /v1/home` (section dinamis, alamat default, sapaan)
- [x] `GET /v1/app-config` (+ `ETag` / `Cache-Control`)
- [ ] iOS: `HomeAPIDataSource` → `/v1/home`; Beranda merender `sections` dari server (bukan dihitung di `GetHomeContentUseCase`)
- [ ] iOS: `AppConfigRepository` dipanggil saat Splash (onboarding, ongkir, aturan jumlah/catatan, menu Profil, cek versi)

**Fase 2: Checkout & Pesanan**

- [x] `POST /v1/orders/quote`, `POST /v1/orders` (transaksi + idempotency)
- [x] `GET /v1/orders`, `/v1/orders/{id}`, `POST /v1/orders/{id}/cancel`
- [x] iOS: checkout via API (`CheckoutAPIDataSource` → `POST /v1/checkout`, keranjang tetap lokal) + tab Pesanan dari API
- [ ] iOS: Keranjang memakai `POST /v1/orders/quote` (ongkir & diskon dari server, bukan `CartState.standardDeliveryFee`)

**Fase 3: Profil & fitur tambahan**

- [x] `GET/PATCH /v1/me`, alamat, favorit, voucher, outlet, rating
- [x] `GET /v1/promotions/featured`, `POST /v1/subscriptions/{plan_id}/activate`
- [x] iOS: Profil dari `/v1/me`
- [ ] iOS: kartu promo dari `/v1/promotions/featured`; ❤️ di Detail & Menu Favorit ke `/v1/me/favorites`
- [x] Push notification status pesanan → APNs langsung (§5.28), bukan FCM

**Fase 3b: Pengaturan Profil**

- [x] Migrasi `0003_profile_features` (e-wallet tersimpan, pusat bantuan, dokumen legal)
- [x] `GET/POST /v1/me/payment-methods`, `PUT /v1/me/payment-methods/default`, `DELETE /v1/me/payment-methods/{id}`
- [x] `GET /v1/help?q=`, `GET /v1/legal/{slug}`
- [x] Validasi `PATCH /v1/me` (format nomor HP, `avatar_url` https)
- [x] Integration test `TestProfileFeatures`
- [x] iOS: Edit Profil, Alamat Pengiriman (CRUD), Metode Pembayaran, Pusat Bantuan, Kebijakan Privasi (`ProfileFeature`)
- [x] Checkout memakai metode utama & alamat utama user (migrasi `0004_checkout_defaults`, `TestCheckoutDefaults`)
- [x] iOS: Keranjang → "Antar ke" & "Pembayaran" (default = utama, bisa diganti per pesanan; tombol kelola → tab Profil)
- [ ] Hapus akun (`DELETE /v1/me`) dari Pusat Bantuan

**Fase 3c: Promo harga produk**

- [x] Migrasi `0006_product_deals` + seed `D01`–`D03`
- [x] Harga promo di katalog, `/v1/home`, favorit, quote & checkout (`original_price`, `discount_percent`, tag `promo`)
- [x] `GET /v1/promotions/popup` (`TestProductDeals`)
- [x] iOS: popup promo di Beranda (bisa ditutup, sekali per hari) → Detail menu → tambah ke keranjang dengan harga promo; section "Promo Hemat"; harga coret & badge diskon di kartu, list, dan detail
- [x] CMS / endpoint admin untuk membuat promo (fase 4: `/v1/admin/deals`, halaman Promo di web admin)

**Fase 4: Web admin (`trytuistadmin`)**

- [x] Migrasi `0007_admin` (role, alasan & pengubah status, audit log) + seed akun admin
- [x] `/v1/admin/*`: dashboard, pesanan + ubah status (sukses/gagal/batal), tambah & ubah menu (varian, foto), promo, pelanggan, audit log (`TestAdmin`)
- [x] Web Next.js 16 (port 3000), login biasa + role ADMIN, BFF cookie httpOnly; lihat `trytuistadmin/WEBPLAN.md`
- [ ] Ekspor CSV, notifikasi pesanan baru, kelola kategori/banner/voucher
- [ ] Pembelian bahan baku (stok & HPP)

**Fase 4b: Multi-outlet (§5.26)**

- [x] Migrasi `0008_multi_outlet` (jam buka, radius, aktif, urutan; stok per outlet) + seed `ST03`
- [x] `GET /v1/stores` diurutkan buka → menjangkau → terdekat; `store_id` di `/v1/products`, `/v1/home`, quote & checkout (`STORE_CLOSED`, `OUT_OF_DELIVERY_AREA`) (`TestMultiOutlet`)
- [x] Admin: `/v1/admin/stores`, stok per outlet, filter outlet di pesanan & dashboard (`by_store`)
- [x] Web admin: halaman Outlet, pilih outlet di Menu / Pesanan / Dashboard
- [x] iOS: pilih outlet di Beranda, stok Menu ikut outlet, keranjang dibersihkan dari menu yang habis, `store_id` di checkout
- [ ] Admin per outlet (role `OUTLET_STAFF` yang hanya melihat outletnya)
- [ ] Ongkir per jarak, estimasi waktu antar

**Fase 5: Pembayaran online Midtrans (§5.27)**

- [ ] Akun Midtrans sandbox: server key, aktifkan channel (GoPay, QRIS, ShopeePay, VA, kartu), isi Payment Notification URL (tunnel)
- [x] Migrasi `0009_payments` (`payments`, `payment_events`, `orders.payment_id`, metode `ONLINE`)
- [x] `internal/payment`: klien Midtrans (Snap, status, expire), `POST /v1/checkout`, `GET /v1/payments[/{id}]`, cancel, webhook (signature + konfirmasi status), sweeper kedaluwarsa
- [x] Pesanan dibuat saat lunas dari snapshot (idempotent); `POST /v1/orders` menolak metode online (`PAYMENT_REQUIRED`)
- [x] `TestPayments` + `TestPaymentsDisabled` dengan fake Midtrans; unit test signature & klien HTTP
- [x] iOS: `PaymentView` (Snap di `WKWebView`, deeplink e-wallet, cegat finish URL), polling, layar hasil, kartu "Menunggu pembayaran" di Beranda, metode "Bayar Online"
- [ ] Uji end-to-end di sandbox: GoPay/QRIS (simulator), VA BCA, kartu 3DS, kedaluwarsa, batal
- [ ] Fase 5b: web admin → Pembayaran + info pembayaran di detail pesanan; tanda `refund_status`
- [ ] Nanti: Refund API, pindah QRIS/GoPay ke Core API bila ingin UI native

**Fase 5c: Notifikasi push (§5.28)**

- [x] Migrasi `0010_push_devices`, `internal/push` (APNs HTTP/2 + JWT ES256, hapus token mati), `PUT /v1/me/devices`, `POST /v1/devices/unregister`, `POST /v1/dev/push-test`
- [x] Push: pembayaran lunas / kedaluwarsa, status pesanan dari admin (`TestPush`, unit test klien APNs)
- [x] iOS: daftar token setelah login, unregister saat sesi berakhir, tap → tab Pesanan, entitlements
- [ ] Uji di device asli dengan key `.p8` (butuh Apple Developer Program berbayar)
- [ ] Badge jumlah pesanan aktif, notifikasi promo (opt-in), Android (FCM)

**Siap staging/prod**

- [ ] Dockerfile multi-stage (`distroless`), deploy (Fly.io / Railway / VPS + Nginx)
- [ ] HTTPS, `API_KEYS` & `JWT_SECRET` dari secret manager, `LOG_LEVEL=info`
- [ ] Backup harian Postgres prod, migrasi dijalankan di pipeline CI sebelum deploy
- [x] Rate limit login, timeout request 30 detik, batas ukuran body 1 MB

---

## 11. Integrasi ke iOS

1. Jalankan backend lokal: `docker compose up -d && make migrate-up seed run` (port 8080).
2. Di iOS, buka `Configs/Dev.xcconfig` dan ubah `USE_MOCK_DATA = NO`. `API_KEY` harus sama dengan salah satu nilai `API_KEYS` di backend.
3. Pilih scheme **TryTuist-Dev**, lalu jalankan di simulator.
4. Pemetaan endpoint di iOS (`Foundations/NetworkManager/Sources/API/EndpointAPI.swift`):

| `EndpointAPI` | Path | DataSource iOS | DTO iOS |
|---|---|---|---|
| `.login` | `POST /v1/auth/login` | `AuthAPIDataSource` | `SessionResponseDTO` |
| `.register` | `POST /v1/auth/register` | `AuthAPIDataSource` | `SessionResponseDTO` |
| `.googleSignIn` | `POST /v1/auth/google` | `AuthAPIDataSource` | `SessionResponseDTO` |
| `.banners` | `GET /v1/banners` | `CatalogAPIDataSource` | `BannerListResponseDTO` |
| `.categories` | `GET /v1/categories` | `CatalogAPIDataSource` | `CategoryListResponseDTO` |
| `.products` | `GET /v1/products` | `CatalogAPIDataSource` | `ProductListResponseDTO` |
| `.popupPromotion` | `GET /v1/promotions/popup` | `CatalogAPIDataSource` | `PromoPopupResponseDTO` |
| `.orders` | `GET /v1/orders` | `OrderAPIDataSource` | `OrderListResponseDTO` |
| `.orderDetail(id:)` | `GET /v1/orders/{id}` | `OrderAPIDataSource` | `OrderDetailResponseDTO` |
| `.rateOrder` | `POST /v1/orders/{id}/rating` | `OrderAPIDataSource` | `OrderDetailResponseDTO` |
| `.createOrder` | `POST /v1/orders` | `CheckoutAPIDataSource` | `PlacedOrderResponseDTO` |
| `.checkout` | `POST /v1/checkout` | `CheckoutAPIDataSource` | `CheckoutResponseDTO` |
| `.stores(lat:lng:)` | `GET /v1/stores` | `CatalogAPIDataSource` | `StoreListResponseDTO` |
| `.payment` · `.payments` · `.cancelPayment` | `/v1/payments[...]` | `PaymentAPIDataSource` | `PaymentResponseDTO` / `PaymentListResponseDTO` |
| `.registerDevice` · `.unregisterDevice` | `PUT /v1/me/devices` · `POST /v1/devices/unregister` | `PushRegistrar` (App) | — |
| `.refreshToken` | `POST /v1/auth/refresh` | `TokenRefresher` (NetworkManager, otomatis saat 401) | — |
| `.profile` | `GET /v1/me` | `ProfileAPIDataSource` | `ProfileResponseDTO` |
| `.updateProfile` | `PATCH /v1/me` | `ProfileAPIDataSource` | `ProfileResponseDTO` |
| `.addresses` · `.createAddress` · `.updateAddress` · `.deleteAddress` | `/v1/me/addresses[/{id}]` | `ProfileAPIDataSource` | `AddressListResponseDTO` / `AddressResponseDTO` |
| `.paymentMethods` · `.addEWallet` · `.setDefaultPaymentMethod` · `.deletePaymentMethod` | `/v1/me/payment-methods[...]` | `ProfileAPIDataSource` | `PaymentOverviewResponseDTO` |
| `.helpCenter(query:)` | `GET /v1/help?q=` | `ProfileAPIDataSource` | `HelpCenterResponseDTO` |
| `.legalDocument(slug:)` | `GET /v1/legal/{slug}` | `ProfileAPIDataSource` | `LegalDocumentResponseDTO` |
| *(belum ada)* | `GET /v1/home` | `HomeAPIDataSource` (fase 1b) | `HomeResponseDTO` |
| *(belum ada)* | `GET /v1/app-config` | `AppConfigAPIDataSource` (fase 1b) | `AppConfigResponseDTO` |
| *(belum ada)* | `GET /v1/promotions/featured` | `ProfileAPIDataSource` (fase 3) | `FeaturedPromotionDTO` |

5. Yang masih perlu ditambah di iOS: `EndpointAPI` case untuk `home`, `appConfig`, `quote`, `featuredPromotion`, dan `favorites`; lalu mengganti data hardcoded di [§4.1](#41-status-data-per-screen-dari-api-atau-masih-di-aplikasi).
