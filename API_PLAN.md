# API Plan: TryTuist Backend (Go + PostgreSQL)

Rencana backend untuk aplikasi iOS **TryTuist** (pesan makanan & minuman). Dokumen ini adalah **kontrak** antara iOS dan backend. Semua nama field dan bentuk JSON di sini sudah sama persis dengan DTO di aplikasi, jadi begitu backend jadi, iOS cukup mengganti `USE_MOCK_DATA = NO`.

> Backend dibuat di direktori/repo terpisah, misalnya `~/Documents/Backend/trytuist-api`.

---

## Daftar isi

1. [Ringkasan & stack](#1-ringkasan--stack)
2. [Environment](#2-environment)
3. [Konvensi API](#3-konvensi-api)
4. [Daftar endpoint](#4-daftar-endpoint)
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
| 17 | `PATCH` | `/v1/me` | 🔒 | 3 | Profil → Ubah |
| 18 | `GET`/`POST` | `/v1/me/addresses` | 🔒 | 3 | Profil → Alamat Pengiriman, header "Antar ke" |
| 19 | `PATCH`/`DELETE` | `/v1/me/addresses/{id}` | 🔒 | 3 | |
| 20 | `GET` | `/v1/me/favorites` | 🔒 | 3 | Profil → Menu Favorit |
| 21 | `PUT`/`DELETE` | `/v1/me/favorites/{product_id}` | 🔒 | 3 | Detail produk → ❤️ |
| 22 | `GET` | `/v1/me/vouchers` | 🔒 | 3 | Profil → Voucher |
| 23 | `GET` | `/v1/stores` | | 3 | Pilih outlet terdekat |

Endpoint yang **sudah terdaftar di `EndpointAPI.swift`**: 2, 3, 6, 7, 8, 12, 16.

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
- `tags` saat ini: `best_seller`. Tag lain (`new`, `spicy`) boleh ditambah; iOS mengabaikan yang tidak dikenal.
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

Body: sama dengan quote, ditambah `"payment_method": "COD" | "QRIS" | "EWALLET"` dan `"note"` opsional.

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
    "payment_method": "COD",
    "created_at": "2026-10-17T14:30:00+07:00",
    "items": [ ]
  }
}
```

### 5.12 `GET /v1/orders` 🔒

Query: `status` (opsional, bisa koma: `PENDING,PROCESSING`), `page`, `limit`. Urut `created_at DESC`.

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
      "status": "PENDING"
    }
  ],
  "meta": { "page": 1, "limit": 20, "total": 1 }
}
```

- `product_name`: nama item pertama, ditambah ` +N lainnya` bila lebih dari satu item.
- `qty`: total kuantitas semua item.
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

`PATCH` menerima `name`, `phone`, `avatar_url` (sebagian saja boleh).

### 5.17 Alamat · Favorit · Voucher · Outlet (fase 3)

| Endpoint | Body / Response `data` |
|---|---|
| `GET /v1/me/addresses` | `[{ "id", "label", "recipient", "phone", "address", "notes", "lat", "lng", "is_default" }]` |
| `POST /v1/me/addresses` | body = objek di atas tanpa `id` → `201` + objek |
| `PATCH/DELETE /v1/me/addresses/{id}` | sebagian field / `data: null` |
| `GET /v1/me/favorites` | `[ProductDTO]` (bentuk sama dengan 5.8) |
| `PUT/DELETE /v1/me/favorites/{product_id}` | `data: null` (idempotent) |
| `GET /v1/me/vouchers` | `[{ "code", "title", "description", "discount_type": "PERCENT"\|"FIXED", "discount_value", "min_subtotal", "max_discount", "ends_at" }]` |
| `GET /v1/stores?lat=&lng=` | `[{ "id", "name", "address", "lat", "lng", "is_open", "distance_km" }]` |

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
    password_hash  TEXT        NOT NULL,
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
    is_open   BOOLEAN          NOT NULL DEFAULT TRUE
);

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
    categories ||--o{ products : groups
    products ||--o{ product_options : has
    products ||--o{ order_items : "dipesan di"
    stores ||--o{ orders : fulfils
    orders ||--|{ order_items : contains
    orders ||--o{ order_status_history : tracks
    orders ||--o| order_ratings : rated
    vouchers ||--o{ orders : "dipakai di"
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
| Produk habis | `is_available = false` → 422 `PRODUCT_UNAVAILABLE` | `CartError.productUnavailable` |
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
│   ├── user/                       # me, addresses, favorites, vouchers
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
INSERT INTO stores (id, name, address, lat, lng) VALUES
  ('ST01', 'Gandaria City', 'Jl. Sultan Iskandar Muda, Jakarta Selatan', -6.2443, 106.7834),
  ('ST02', 'Kemang Utara', 'Jl. Kemang Utara Raya, Jakarta Selatan', -6.2608, 106.8133);

-- Akun demo (password: 12345678 & password123) — hash dibuat dengan bcrypt saat seeding:
--   go run ./cmd/seed  (atau isi password_hash dengan hasil bcrypt.GenerateFromPassword)
-- kholis@gmail.com / 12345678, demo@trytuist.com / password123  (sama dengan AuthMockDataSource)
```

---

## 10. Roadmap & checklist

**Fase 1: Auth + Katalog** (cukup untuk login dan Beranda/Menu tanpa mock)

- [ ] Init repo, `go mod init`, docker-compose Postgres, `Makefile`
- [ ] `config`, `httpx` (envelope, error), middleware RequestID/Logger/Recover/APIKey
- [ ] Migrasi `0001_init` + seed
- [ ] `GET /healthz`
- [ ] `POST /v1/auth/register`, `/login`, `/refresh`, `/logout` (JWT + refresh token rotation)
- [ ] `GET /v1/banners`, `/v1/categories`, `/v1/products`, `/v1/products/{id}`
- [ ] Test: unit service + integration test handler (Postgres via `testcontainers-go` atau DB test lokal)
- [ ] iOS: `USE_MOCK_DATA = NO` di Dev → login & katalog jalan dari API

**Fase 2: Checkout & Pesanan**

- [ ] `POST /v1/orders/quote`, `POST /v1/orders` (transaksi + idempotency)
- [ ] `GET /v1/orders`, `/v1/orders/{id}`, `POST /v1/orders/{id}/cancel`
- [ ] iOS: `CartAPIRepository` (checkout via API, keranjang tetap lokal) + tab Pesanan dari API

**Fase 3: Profil & fitur tambahan**

- [ ] `GET/PATCH /v1/me`, alamat, favorit, voucher, outlet, rating
- [ ] Push notification status pesanan (FCM) memakai `users.fcm_token`

**Siap staging/prod**

- [ ] Dockerfile multi-stage (`distroless`), deploy (Fly.io / Railway / VPS + Nginx)
- [ ] HTTPS, `API_KEYS` & `JWT_SECRET` dari secret manager, `LOG_LEVEL=info`
- [ ] Backup harian Postgres prod, migrasi dijalankan di pipeline CI sebelum deploy
- [ ] Rate limit login, timeout request 30 detik, batas ukuran body 1 MB

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
| `.banners` | `GET /v1/banners` | `CatalogAPIDataSource` | `BannerListResponseDTO` |
| `.categories` | `GET /v1/categories` | `CatalogAPIDataSource` | `CategoryListResponseDTO` |
| `.products` | `GET /v1/products` | `CatalogAPIDataSource` | `ProductListResponseDTO` |
| `.orders` | `GET /v1/orders` | `OrderAPIDataSource` | `OrderListResponseDTO` |
| `.profile` | `GET /v1/me` | (belum dipakai) | (fase 3) |

5. Yang masih perlu ditambah di iOS saat fase 2–3 sudah ada: `EndpointAPI` case untuk `quote`, `createOrder`, `refresh`, dan `me`; refresh token otomatis saat 401 `TOKEN_EXPIRED`; dan `CartAPIRepository`.
