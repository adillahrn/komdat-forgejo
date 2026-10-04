# Alur Kerja Tim

Satu repositori dipakai bersama. Supaya tidak saling menimpa, tiap anggota bekerja di **branch sendiri**, lalu membuka **pull request**.

## Langkah kerja

```bash
# 1. Ambil repo (sekali saja)
git clone https://github.com/USERNAME/projek-forgejo.git
cd projek-forgejo

# 2. Selalu update sebelum mulai menulis
git checkout main
git pull

# 3. Buat branch untuk bagianmu
git checkout -b bagian-instalasi

# 4. Edit file, lalu simpan perubahan
git add .
git commit -m "tambah langkah instalasi Docker"

# 5. Kirim ke GitHub
git push origin bagian-instalasi
```

Setelah itu buka **Pull Request** di GitHub, minta satu anggota lain untuk membaca, lalu **Merge**.

## Aturan

1. Satu orang satu bagian. Jangan mengedit bagian orang lain tanpa memberi tahu.
2. Nama branch menjelaskan isinya, misalnya `bagian-server`, `bagian-https`, `bagian-backup`, `bagian-demo`, `bagian-pembahasan`.
3. Pesan commit singkat dan jelas.
4. Screenshot disimpan di folder `img/` dengan nama berurutan (`01-halaman-utama.png`, `02-buat-repo.png`, dst.) dan dipanggil di laporan dengan `![deskripsi](img/nama-file.png)`.
5. Tulis langkah dari pengalaman sendiri, termasuk error yang muncul dan cara memperbaikinya.

## Jangan pernah di-commit

- Password, token, dan isi file `.env` yang asli
- Kunci privat SSH (`id_ed25519`, `*.pem`)
- Subscription ID atau kredensial cloud
- Screenshot yang menampilkan hal-hal di atas (tutup dulu bagian rahasianya)

File `.gitignore` sudah menolak `.env` dan `*.pem`, tapi tetap periksa sebelum push:

```bash
git status
git diff --staged
```

## Jika sudah terlanjur meng-commit rahasia

Anggap rahasia itu **sudah bocor**: ganti password atau kunci yang terkena, lalu beri tahu anggota lain. Menghapus commit saja tidak cukup karena riwayatnya masih tersimpan.

## Checklist sebelum dikumpulkan

- [ ] Semua penanda `[ISI: ...]` sudah diganti
- [ ] Domain di laporan sama dengan yang benar-benar aktif
- [ ] Semua screenshot muncul di halaman repo
- [ ] Tabel perbandingan sudah diverifikasi ulang
- [ ] Referensi lengkap
- [ ] Tidak ada password, token, atau isi `.env` di repo
