# REST API for iNote

> Laravel11

## Guide

Requirement:

-   PHP (version 8.2 - 8.4)
-   xampp (sudah termasuk MySQL)

Tutorial:

-   Clone repository
-   Install composer

```bash
composer install
```

-   Copy file `.env.example` pada file baru `.env` pada root project
-   (Optional) Set konfigurasi pada `.env` menyesuaikan MySQL local
-   Pastikan sudah start Apache dan MySQL pada xampp
-   Jalankan commands berikut

```bash
php artisan key:generate
php artisan migrate
php artisan serve
```
