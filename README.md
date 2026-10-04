# Aplikasi Web "Forgejo"

> Catatan: teks bertanda `[ISI: ...]` dan `git.contoh.com` harus kamu ganti dengan data kelompokmu sendiri.

**Kelompok:** [ISI: nomor kelompok]
**Anggota:** [ISI: nama dan NIM]
**URL aplikasi:** https://git.contoh.com


## Struktur Repositori

```
projek-forgejo/
├── README.md              # laporan
├── docker-compose.yml     # Forgejo + PostgreSQL
├── .env.example           
├── nginx/forgejo.conf     # konfigurasi reverse proxy
├── scripts/
│   ├── install.sh         # instalasi otomatis dari nol
│   └── backup.sh          # backup database dan data
├── docs/                 
├── img/                   # screenshot untuk laporan
├── CONTRIBUTING.md        # alur kerja Git tim
└── .gitignore
```

## Sekilas Tentang

Forgejo adalah platform hosting kode sumber berbasis Git yang bisa dipasang sendiri (self-hosted), sehingga fungsinya mirip GitHub atau GitLab tetapi berjalan di server milik sendiri. Aplikasi ini ditulis dengan bahasa Go dan dirilis sebagai satu binary yang ringan, sehingga cocok untuk VPS berspesifikasi kecil.

Fitur utamanya: repositori Git (akses HTTPS dan SSH), issue tracker, pull request beserta code review, wiki, organisasi dan tim, package registry, serta CI/CD lewat Forgejo Actions. Forgejo merupakan hasil fork dari Gitea dan dikelola oleh komunitas nirlaba (Codeberg e.V.).

## Instalasi

### Prasyarat

- VPS dengan Ubuntu 22.04/24.04, minimal 1 vCPU dan 1 GB RAM (disarankan 2 GB)
- Domain atau subdomain yang record A-nya sudah mengarah ke IP VPS (contoh: `git.contoh.com`)
- Port 80, 443, dan 2222 terbuka di firewall
- Docker Engine dan Docker Compose plugin
- Nginx sebagai reverse proxy dan Certbot untuk sertifikat HTTPS


**Catatan untuk server di Azure for Students:** selain UFW di dalam server, port 22, 80, 443, dan 2222 juga harus dibuka di **Network Security Group** milik VM (menu Networking > Add inbound port rule). Alamat IP publik juga perlu diubah menjadi **Static** agar tidak berubah. Pada VM Ubuntu di Azure, nama user bawaan biasanya `azureuser`, jadi `~` pada perintah di bawah berarti `/home/azureuser`.

Arsitektur:

```
Pengguna --HTTPS--> Nginx (443) --> Forgejo (127.0.0.1:3000) --> PostgreSQL
Pengguna --SSH---->  Forgejo (2222, untuk git clone/push via SSH)
```

### Langkah instalasi

**1. Perbarui sistem dan pasang paket dasar**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl nginx certbot python3-certbot-nginx ufw
```

**2. Pasang Docker**

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker --version && docker compose version
```

**3. Atur firewall**

Port SSH admin tetap 22, sedangkan Git SSH milik Forgejo dipetakan ke 2222.

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80,443/tcp
sudo ufw allow 2222/tcp
sudo ufw enable
```

**4. Buat direktori kerja dan file `.env`**

```bash
mkdir -p ~/forgejo && cd ~/forgejo
cat > .env <<'EOF'
DOMAIN=git.contoh.com
POSTGRES_PASSWORD=GANTI_DENGAN_PASSWORD_KUAT
EOF
chmod 600 .env
```

**5. Buat `docker-compose.yml`**

Versi image mengikuti dokumentasi resmi Forgejo. Cek tag terbaru di https://forgejo.org/docs/latest/admin/installation/docker/ (saat laporan ini ditulis tag utamanya `15`).

```yaml
networks:
  forgejo:
    external: false

services:
  server:
    image: codeberg.org/forgejo/forgejo:15
    container_name: forgejo
    restart: always
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - FORGEJO__database__DB_TYPE=postgres
      - FORGEJO__database__HOST=db:5432
      - FORGEJO__database__NAME=forgejo
      - FORGEJO__database__USER=forgejo
      - FORGEJO__database__PASSWD=${POSTGRES_PASSWORD}
      - FORGEJO__server__DOMAIN=${DOMAIN}
      - FORGEJO__server__ROOT_URL=https://${DOMAIN}/
      - FORGEJO__server__SSH_DOMAIN=${DOMAIN}
      - FORGEJO__server__SSH_PORT=2222
      - FORGEJO__server__SSH_LISTEN_PORT=22
    networks:
      - forgejo
    volumes:
      - ./forgejo:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "127.0.0.1:3000:3000"
      - "2222:22"
    depends_on:
      - db

  db:
    image: postgres:16
    container_name: forgejo-db
    restart: always
    environment:
      - POSTGRES_USER=forgejo
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=forgejo
    networks:
      - forgejo
    volumes:
      - ./postgres:/var/lib/postgresql/data
```

**6. Jalankan container**

```bash
docker compose up -d
docker compose ps
docker compose logs -f server   # tekan Ctrl+C untuk keluar
```

**7. Konfigurasi Nginx sebagai reverse proxy**

```bash
sudo tee /etc/nginx/sites-available/forgejo >/dev/null <<'EOF'
server {
    listen 80;
    server_name git.contoh.com;

    client_max_body_size 512M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/forgejo /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

**8. Aktifkan HTTPS dengan Let's Encrypt**

```bash
sudo certbot --nginx -d git.contoh.com
```

**9. Selesaikan instalasi lewat browser**

Buka `https://git.contoh.com`, cek halaman *Initial Configuration* (nilai database dan domain sudah terisi dari environment), lalu buka bagian *Administrator Account Settings* dan buat akun admin. Klik **Install Forgejo**.

[ISI: screenshot halaman instalasi awal]

## Konfigurasi (opsional)

Konfigurasi bisa lewat environment variable dengan format `FORGEJO__bagian__KUNCI` di `docker-compose.yml`, atau langsung di file `forgejo/gitea/conf/app.ini`. Setelah mengubah, jalankan `docker compose up -d` lagi.

**Batas upload dan ukuran file**

Tambahkan di bagian `environment` pada service `server`:

```yaml
      - FORGEJO__attachment__MAX_SIZE=100        # lampiran issue/PR, satuan MB
      - FORGEJO__repository_0x2E_upload__FILE_MAX_SIZE=100   # upload file lewat web, MB
```

Bagian `[repository.upload]` di `app.ini` mengandung titik, sehingga pada environment variable titik itu ditulis `_0x2E_`.

Batas di Nginx (`client_max_body_size 512M`) harus lebih besar daripada nilai di atas, kalau tidak upload akan ditolak dengan galat 413.

**Menutup pendaftaran publik**

Supaya server tidak dipakai sembarang orang, matikan registrasi bebas dan buat akun lewat halaman admin:

```yaml
      - FORGEJO__service__DISABLE_REGISTRATION=true
```

Untuk demo, boleh dibiarkan terbuka sementara atau buat beberapa akun dummy secara manual.

**Batas memori container**

Pada VPS kecil, batasi memori agar server tidak macet:

```yaml
    deploy:
      resources:
        limits:
          memory: 768M
```

**Login dengan Google (OAuth2)**

1. Buat *OAuth client ID* di Google Cloud Console (tipe Web application). Isi *Authorized redirect URI* dengan `https://git.contoh.com/user/oauth2/google/callback`.
2. Di Forgejo, buka **Site Administration → Identity & Access → Authentication Sources → Add Authentication Source**.
3. Pilih tipe **OAuth2**, provider **OpenID Connect**, nama `google`, isi Client ID dan Client Secret, dan Auto Discovery URL `https://accounts.google.com/.well-known/openid-configuration`.

[ISI: screenshot halaman Authentication Sources, jika dikerjakan]

**Editor Markdown dan fitur lain**

Editor Markdown dengan pratinjau sudah bawaan (dipakai di README, issue, dan wiki), jadi tidak perlu plugin tambahan. Forgejo juga bisa dihubungkan dengan webhook ke layanan lain (misalnya notifikasi Discord atau Telegram) lewat menu **Settings → Webhooks** pada setiap repositori.

## Maintenance (opsional)

**Backup**

Yang perlu dicadangkan ada dua hal: dump database PostgreSQL dan folder `forgejo/` (berisi repositori Git, lampiran, dan `app.ini`).

```bash
mkdir -p ~/backup
cd ~/forgejo
docker exec forgejo-db pg_dump -U forgejo forgejo | gzip > ~/backup/forgejo-db-$(date +%F).sql.gz
sudo tar czf ~/backup/forgejo-data-$(date +%F).tar.gz forgejo
```

**Restore (garis besar)**

```bash
docker compose down
sudo tar xzf ~/backup/forgejo-data-TANGGAL.tar.gz
docker compose up -d db
gunzip -c ~/backup/forgejo-db-TANGGAL.sql.gz | docker exec -i forgejo-db psql -U forgejo forgejo
docker compose up -d
```

**Update**

Naik versi mayor (misalnya 14 ke 15) butuh pengecekan manual. Baca *release notes* dulu, buat backup, lalu ubah tag image dan jalankan:

```bash
docker compose pull
docker compose up -d
docker image prune -f
```

**Perpanjangan sertifikat HTTPS**

Certbot otomatis memasang timer perpanjangan. Uji dengan:

```bash
sudo certbot renew --dry-run
```

**Penjadwalan dengan cron**

Buka `crontab -e` dan tambahkan (backup tiap Minggu pukul 02.00 dan hapus backup yang lebih dari 30 hari):

```cron
0 2 * * 0 /home/USER/forgejo/backup.sh
30 2 * * 0 find /home/USER/backup -type f -mtime +30 -delete
```

## Otomatisasi (opsional)

Dua skrip tersedia di folder [`scripts/`](scripts/):

- [`scripts/install.sh`](scripts/install.sh): memasang paket, Docker, firewall, Forgejo + PostgreSQL, Nginx, dan HTTPS dari nol. Password database dibuat acak dan disimpan di `~/forgejo/.env`.
- [`scripts/backup.sh`](scripts/backup.sh): backup database dan folder data, lalu menghapus backup yang lebih tua dari 30 hari.

Pemakaian pada Ubuntu yang bersih (domain harus sudah mengarah ke IP server):

```bash
git clone https://github.com/USERNAME/projek-forgejo.git
cd projek-forgejo
chmod +x scripts/*.sh
./scripts/install.sh git.contoh.com admin@contoh.com
```

Backup terjadwal lewat cron:

```cron
0 2 * * 0 /home/azureuser/projek-forgejo/scripts/backup.sh
```

[ISI: hasil uji coba skrip, misalnya screenshot keluaran `install.sh`]

## Cara Pemakaian

Bagian ini diisi setelah aplikasi berjalan dan berisi data dummy. Ambil screenshot pada tiap langkah.

1. **Halaman utama dan login.** Tampilan awal Forgejo dan halaman masuk. [ISI: screenshot]
2. **Membuat akun dan organisasi.** Buat 2-3 akun dummy (misalnya `mahasiswa1`, `dosen`) dan satu organisasi (misalnya `praktikum-komdat`). [ISI: screenshot]
3. **Membuat repositori.** Klik tombol **+ → New Repository**, isi nama, deskripsi, dan centang *Initialize repository* dengan README. [ISI: screenshot]
4. **Clone dan push lewat HTTPS.**
   ```bash
   git clone https://git.contoh.com/mahasiswa1/proyek-demo.git
   cd proyek-demo
   echo "halo forgejo" > catatan.txt
   git add . && git commit -m "tambah catatan" && git push
   ```
5. **Clone dan push lewat SSH.** Tambahkan public key di **Settings → SSH/GPG Keys**, lalu:
   ```bash
   git clone ssh://git@git.contoh.com:2222/mahasiswa1/proyek-demo.git
   ```
6. **Issue dan label.** Buat beberapa issue (bug, fitur) dan beri label serta milestone. [ISI: screenshot]
7. **Pull request dan code review.** Buat branch, push, buka pull request, beri komentar, lalu merge. [ISI: screenshot]
8. **Wiki.** Aktifkan wiki repositori dan tulis satu halaman dengan Markdown. [ISI: screenshot]
9. **Halaman admin.** Tunjukkan **Site Administration** (daftar pengguna, repositori, dan konfigurasi sistem). [ISI: screenshot]

Data dummy yang disarankan: minimal 3 repositori, 5 issue, dan 2 pull request agar demo tidak terlihat kosong.

## Pembahasan

### Pendapat kami

**Kelebihan**

- Ringan. Berjalan baik di VPS 1-2 GB RAM, jauh lebih hemat daripada GitLab.
- Instalasi sederhana karena hanya butuh Docker dan sebuah database.
- Antarmukanya mirip GitHub sehingga mudah dipelajari.
- Bebas dan open source, dengan data sepenuhnya di server sendiri.
- Ada issue, pull request, wiki, dan CI/CD dalam satu aplikasi.

**Kekurangan**

- Ekosistem dan integrasi pihak ketiga lebih kecil daripada GitHub dan GitLab.
- CI/CD (Forgejo Actions) memerlukan runner terpisah dan konfigurasi tambahan.
- Fitur enterprise seperti dashboard keamanan yang lengkap tidak sebanyak GitLab.
- Tanggung jawab keamanan, backup, dan update ada pada pengelola server.
- Upgrade versi mayor perlu pengecekan manual.

### Perbandingan dengan aplikasi sejenis

Isi tabel berikut berdasarkan pengamatan kelompok dan dokumentasi resmi masing-masing aplikasi. Verifikasi ulang angka dan fitur sebelum dikumpulkan.

| Aspek | Forgejo | GitHub | GitLab (self-hosted) | Gitea |
|---|---|---|---|---|
| Model | Self-hosted, open source | Layanan cloud (SaaS) | Self-hosted atau SaaS | Self-hosted, open source |
| Kebutuhan resource | Rendah (sekitar 1 GB RAM) | Tidak perlu server sendiri | Tinggi (disarankan 4 GB RAM ke atas) | Rendah |
| Kontrol data | Penuh | Dipegang penyedia | Penuh | Penuh |
| Biaya | Gratis, hanya biaya server | Gratis dan berbayar | Edisi komunitas gratis | Gratis, hanya biaya server |
| CI/CD | Forgejo Actions (butuh runner) | GitHub Actions | GitLab CI (sangat lengkap) | Gitea Actions |
| Kemudahan instalasi | Mudah | Tidak perlu instalasi | Sedang sampai sulit | Mudah |
| Tata kelola | Dikelola komunitas nirlaba | Perusahaan (Microsoft) | Perusahaan (GitLab Inc.) | Perusahaan dan komunitas |

Kesimpulan: Forgejo cocok untuk kelompok kecil, kampus, atau individu yang ingin punya layanan Git sendiri dengan biaya rendah. Jika membutuhkan fitur DevOps dan keamanan yang sangat lengkap, GitLab lebih unggul. Jika kolaborasi dengan komunitas open source publik yang utama, GitHub tetap pilihan paling praktis.

## Referensi

- Dokumentasi instalasi Docker Forgejo: https://forgejo.org/docs/latest/admin/installation/docker/
- Dokumentasi Forgejo: https://forgejo.org/docs/latest/
- Referensi konfigurasi `app.ini`: https://forgejo.org/docs/latest/admin/config-cheat-sheet/
- Dokumentasi Docker Engine: https://docs.docker.com/engine/install/ubuntu/
- Dokumentasi Nginx reverse proxy: https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/
- Certbot: https://certbot.eff.org/
- [ISI: tambahkan sumber lain yang kamu pakai]
