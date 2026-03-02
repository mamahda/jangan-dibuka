## GAME ASSET MANAGER

Studio Game "gamelove" membutuhkan alat bantu CLI untuk mengelola ribuan aset (gambar, suara, model 3D) yang tersimpan di folder `assets/`. Kamu sebagai *Tools Engineer* ditugaskan membangun `script.sh` untuk memastikan sinkronisasi data antara folder fisik dan database metadata `metadata.csv`.

---

## A. Fitur Sinkronisasi (SYNC)

Fungsi `sync` menjaga konsistensi antara folder `assets/` dan `metadata.csv`.

1. **Detect New Files**
   Jika ada file baru di folder yang belum terdaftar di CSV, tambahkan baris baru dengan format:
   `filename,size,extension,created_at`.

2. **Clean Up**
   Jika ada entri di CSV yang file fisiknya sudah dihapus dari folder, hapus baris tersebut dari database.

---

## B. Fitur Monitoring (LIST & STATS)

### 1. List

Menampilkan isi database dalam bentuk tabel dengan dukungan:

* `--sort=name` → urut alfabet
* `--sort=size` → urut berdasarkan ukuran
* `--ext=<extension>` → filter berdasarkan ekstensi (misalnya `.png`)

### 2. Asset Statistics

Menampilkan ringkasan data:

* Total jumlah aset
* Total ukuran (bytes)
* Rata-rata ukuran aset
* Aset terbesar dan terkecil
* Jumlah file berdasarkan ekstensi

---

## C. Fitur Manajemen Aset (CREATE & DELETE)

### 1. Mock Asset Creation

Perintah:

```
create <filename> <size>
```

* Membuat file dummy di folder `assets/`
* Otomatis menambahkan metadata ke database

### 2. Asset Removal

Perintah:

```
delete <filename>
```

* Menghapus file fisik
* Menghapus entri metadata dari database

### 3. Validation

* Validasi jika file sudah ada saat `create`
* Validasi jika file tidak ditemukan saat `delete`

---

## D. Fitur Otomasi (AUTOSYNC)

Fungsi `autosync` akan menjalankan perintah `sync` setiap 5 menit menggunakan `crontab`.

---

## E. Sistem Logging (LOG)

Sistem logging mencatat seluruh aktivitas ke dalam `activity.log`.

### Format Log

```
[YYYY-MM-DD HH:MM:SS] [LEVEL] [COMMAND] message
```

---

### SYSTEM

```
[YYYY-MM-DD HH:MM:SS] [ERROR] [SYSTEM] Missing components (assets/, metadata.csv, activity.log, or crontabs)
```

---

### SYNC

**File baru terdeteksi**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [SYNC] Added new file <filename>
```

**File hilang dibersihkan dari database**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [SYNC] Removed missing file <filename> from database
```

---

### LIST

**Berhasil menampilkan database**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [LIST] Displayed database content
```

**Hasil filter kosong**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [LIST] Query returned empty result
```

---

### STATS

**Statistik berhasil dibuat**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [STATS] Generated statistics
```

**Database kosong**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [STATS] Accessed empty database
```

---

### CREATE

**Argumen kurang**

```
[YYYY-MM-DD HH:MM:SS] [ERROR] [CREATE] Missing arguments
```

**Size tidak valid**

```
[YYYY-MM-DD HH:MM:SS] [ERROR] [CREATE] Invalid size: <size>
```

**File sudah ada**

```
[YYYY-MM-DD HH:MM:SS] [ERROR] [CREATE] File <filename> already exists
```

**File berhasil dibuat**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [CREATE] Created file <filename> (<size> bytes)
```

---

### DELETE

**Tidak ada filename**

```
[YYYY-MM-DD HH:MM:SS] [ERROR] [DELETE] No filename provided
```

**File tidak ditemukan**

```
[YYYY-MM-DD HH:MM:SS] [ERROR] [DELETE] <filename> not found
```

**File berhasil dihapus**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [DELETE] Deleted <filename>
```

---

### AUTOSYNC

**Autosync berhasil dipasang**

```
[YYYY-MM-DD HH:MM:SS] [INFO] [AUTOSYNC] Installed autosync every 5 minutes
```
