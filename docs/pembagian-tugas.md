# Pembagian Tugas Proyek Forgejo

Ganti `[Nama]` dengan nama anggota.

| No | Anggota | Tugas teknis | Bagian laporan/slide | Bicara |
|---|---|---|---|---|
| 1 | [Nama] | Server dan domain: IP statis, port NSG (22, 80, 443, 2222), akses SSH semua anggota, domain/DNS | Prasyarat dan persiapan server | Persiapan server |
| 2 | [Nama] | Instalasi: Docker, `.env`, `docker-compose.yml`, Forgejo + PostgreSQL, akun admin | Instalasi (Docker dan Forgejo) | Instalasi aplikasi |
| 3 | [Nama] | Nginx, HTTPS, batas upload, tutup registrasi, login Google (opsional) | Instalasi (Nginx dan HTTPS) + Konfigurasi | Reverse proxy, HTTPS, konfigurasi |
| 4 | [Nama] | Backup, cron, uji restore, `install.sh` | Maintenance dan Otomatisasi | Maintenance dan otomatisasi |
| 5 | [Nama] | Data dummy (akun, repo, issue, PR, wiki), screenshot | Cara Pemakaian dan slide demo | Fitur dan demo |

## Tugas tambahan tiap anggota

| Anggota | Bagian Pembahasan |
|---|---|
| 1 | Perbandingan dengan GitHub |
| 2 | Perbandingan dengan GitLab |
| 3 | Perbandingan dengan Gitea |
| 4 | Kelebihan Forgejo |
| 5 | Kekurangan Forgejo dan kesimpulan |

Referensi: tiap anggota mencatat sumber dari bagiannya sendiri.

## Urutan kerja

```
1 (server siap) -> 2 (Forgejo jalan) -> 3 (HTTPS aktif) -> 4 dan 5 bersamaan
```

Sambil menunggu, semua anggota membuat SSH key, mencoba Forgejo di laptop (Docker), dan menulis bagian laporannya.

## Aturan

- Kabari grup sebelum dan sesudah mengerjakan server.
- Satu orang saja yang mengubah konfigurasi server dalam satu waktu.
- Hanya kirim kunci publik (`.pub`). Kunci privat dan password jangan dibagikan.
- Uji restore (anggota 4) dilakukan setelah screenshot (anggota 5) selesai.
- Dikerjakan bersama: baca ulang laporan, rapikan PPT, latihan presentasi minimal 2 kali, cek akses dari luar jaringan sehari sebelum tampil.
