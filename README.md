# CLI File Database Manager 

## Tujuan

Praktikan diminta membuat sistem mini file database manager berbasis Bash untuk menyimpan metadata file dari satu directory tertentu ke dalam format CSV, menyediakan fitur manipulasi data, pengecekan integritas file, logging aktivitas, serta otomatisasi menggunakan crontab.

Fokus utama:

* Shell scripting
* CLI parsing
* File I/O
* Text processing (awk/sed)
* Sorting dan aggregation
* Logging
* Cron automation
* State management sederhana

---

# Struktur Sistem

Script utama:

```id="z9m2cx"
filedb.sh
```

Database:

```id="c0q8ad"
filedb.csv
```

Log aktivitas:

```id="p3v1kw"
activity.log
```

File konfigurasi:

```id="t7n4sj"
filedb.conf
```

---

# Konsep Working Directory

Sistem hanya bekerja pada satu directory aktif yang ditentukan saat `init`.

Saat menjalankan:

```bash id="a6x1lp"
./filedb.sh init <directory>
```

Script harus:

1. Memvalidasi bahwa directory ada.
2. Mengambil absolute path directory tersebut.
3. Menyimpan path tersebut ke `filedb.conf` dengan format:

```id="m2r8ye"
WORKDIR=/absolute/path/to/directory
```

Semua command selain `init` wajib membaca WORKDIR dari `filedb.conf`.

Jika `filedb.conf` tidak ada, tampilkan error:

```id="g5k2hz"
Database not initialized.
```

---

# Format Database (filedb.csv)

Delimiter: `,`
Tidak menggunakan header.

Format per baris:

```id="b8w6nf"
filename,size,extension,created_at,tag
```

Keterangan:

* filename → nama file saja (tanpa path)
* size → ukuran dalam byte
* extension → lowercase, jika tidak ada isi `none`
* created_at → format `YYYY-MM-DD_HH:MM:SS`
* tag → string tanpa koma

Contoh:

```id="r1y9lo"
report.pdf,1200,pdf,2026-02-26_14:30:00,important
notes.txt,500,txt,2026-02-26_14:32:11,untagged
```

Semua file yang dicatat harus berada di WORKDIR.

---

# Format Logging (activity.log)

Format:

```id="e4u7tn"
[YYYY-MM-DD HH:MM:SS] [LEVEL] [COMMAND] message
```

LEVEL:

* INFO
* WARNING
* ERROR

Contoh:

```id="h9q2dc"
[2026-02-26 14:32:10] [INFO] [INIT] Initialized database from folder docs
[2026-02-26 14:35:01] [ERROR] [ADD] File report.pdf already exists
[2026-02-26 15:01:00] [WARNING] [CHECK] File report.pdf missing
```

Semua command kecuali `list` tetap harus tercatat di log.

---

# Fitur yang Harus Diimplementasikan

## 1. init

```bash id="k3d8op"
./filedb.sh init <directory>
```

Fungsi:

* Menghapus dan membuat ulang `filedb.csv`
* Menyimpan WORKDIR ke `filedb.conf`
* Scan semua file dalam directory (non-recursive)
* Tambahkan semua file ke database
* Default tag: `untagged`

Ketentuan:

* `init` selalu bersifat destruktif (reset database)
* Jika directory kosong, tetap buat database kosong
* Semua aktivitas dicatat ke log

---

## 2. add

```bash id="v6t1bn"
./filedb.sh add <filename> <tag>
```

Ketentuan:

* File harus berada di WORKDIR
* User hanya mengetik nama file (tanpa path)
* Script otomatis mengakses `$WORKDIR/<filename>`

Validasi:

* Database harus sudah ada
* File harus ada di WORKDIR
* Tidak boleh duplicate filename
* Tag tidak boleh kosong

---

## 3. tag

```bash id="y2m5rf"
./filedb.sh tag <filename> <newtag>
```

Fungsi:

* Mengubah kolom tag pada file tertentu saja
* Tidak boleh mengubah baris lain
* Gunakan mekanisme rewrite aman (temporary file kemudian replace)

Jika filename tidak ditemukan di database → ERROR.

---

## 4. list

```bash id="q8w3je"
./filedb.sh list [--sort=name|size] [--tag=value] [--ext=value]
```

Fungsi:

* Menampilkan isi database
* Maksimal satu filter dan satu sort option

Sorting:

* name → ascending alphabet
* size → ascending numeric

Filtering:

* Berdasarkan tag
* Berdasarkan extension

Jika database belum ada → ERROR.

---

## 5. stats

```bash id="n5u4ci"
./filedb.sh stats
```

Menampilkan:

* Total files
* Total size (bytes)
* Average size
* Extension paling banyak
* Tag paling sering

Jika database kosong:

* Total files = 0
* Tidak boleh terjadi crash atau pembagian dengan nol

---

## 6. check

```bash id="x7l2sd"
./filedb.sh check
```

Fungsi:

* Membaca seluruh file di database
* Memeriksa apakah setiap file masih ada di WORKDIR
* Jika file tidak ada:

  * Tampilkan di terminal
  * Catat sebagai WARNING di log

Jika semua file tersedia, catat INFO di log.

---

## 7. schedule

```bash id="w1r9pk"
./filedb.sh schedule <interval_minutes>
```

Fungsi:

* Menambahkan cron job untuk menjalankan:

```id="z3n6ut"
*/X * * * * /absolute/path/filedb.sh check >> activity.log
```

Ketentuan:

* Tidak boleh menghapus cron entry lain
* Tidak boleh menambahkan entry duplikat
* Harus menggunakan absolute path ke script
* Interval harus berupa angka valid

---

# Error Handling Wajib

Script harus:

* Menolak command tidak dikenal
* Menolak argumen kurang
* Menolak menjalankan command selain `init` jika database belum dibuat
* Tidak boleh crash
* Semua error harus dicatat di log

---

# Implementasi yang Wajib Ada

Script harus menggunakan:

* CLI parsing (`case`)
* Function
* Looping (scan directory dan scan CSV)
* Conditional (`if/else`)
* File I/O (read dan write file)
* Text processing (`awk`, `sed`, `grep`, `cut`)
* Sorting (`sort`)
* Aggregation (sum, count, average)
* Cron automation
* Logging system terpusat

---

# Batasan

* Hanya boleh menggunakan Bash
* Tidak boleh menggunakan bahasa lain
* Tidak boleh menggunakan database eksternal
* Hanya boleh menggunakan utilitas dasar Linux (awk, sed, grep, sort, cut, wc, date, stat)
* Nama file dan tag tidak boleh mengandung koma
