## **GAME ASSET MANAGER**

Studio Game "gamelove" membutuhkan alat bantu CLI untuk mengelola ribuan aset (gambar, suara, model 3D) yang tersimpan di folder `assets/`. Kamu sebagai *Tools Engineer* ditugaskan membangun `script.sh` untuk memastikan sinkronisasi data antara folder fisik dan database metadata `metadata.csv`.

---

### **A. Fitur SINKRONISASI (SYNC)**

Buatlah fungsi `sync` yang bertugas menjaga konsistensi antara folder `assets/` dan `metadata.csv`.

1. **Detect New Files:** Jika ada file baru di folder yang belum terdaftar di CSV, tambahkan baris baru dengan format: `filename,size,extension,created_at`.
2. **Clean Up:** Jika ada entri di CSV yang file fisiknya sudah dihapus dari folder, hapus baris tersebut dari database.

### **B. Fitur MONITORING (LIST & STATS)**

Buatlah fungsi untuk memantau penggunaan "budget" memori aset game.

1. **List:** Tampilkan isi database dalam bentuk tabel. Dukung argumen `--sort=name` (alfabet), `--sort=size` (ukuran), dan filter `--ext=<extension>` (misal hanya menampilkan aset `.png`).
2. **Asset Statistics:** Tampilkan ringkasan data yang mencakup:
* Total jumlah aset dan total ukuran (dalam bytes).
* Rata-rata ukuran aset untuk estimasi beban *loading*.
* Identifikasi aset terbesar (untuk optimasi) dan terkecil.
* Rekapitulasi jumlah file berdasarkan jenis ekstensi (misal: Berapa banyak `.wav`, `.png`, dll).

### **C. Fitur MANAJEMEN ASET (CREATE & DELETE)**

Buatlah fungsi untuk memanipulasi aset langsung melalui script.

1. **Mock Asset Creation:** Fungsi `create <filename> <size>` akan menghasilkan file *dummy* di folder `assets/` dengan ukuran tertentu dan otomatis mendaftarkannya ke database.
2. **Asset Removal:** Fungsi `delete <filename>` akan menghapus file fisik dari folder dan menghapus entri datanya dari database secara permanen.
3. **Validation:** Pastikan ada validasi jika file sudah ada (saat create) atau file tidak ditemukan (saat delete).

### **D. Fitur OTOMASI (AUTOSYNC)**

Guna memastikan database selalu *up-to-date* saat tim Artist sedang bekerja:

1. Buat fungsi `autosync` yang secara otomatis menjalankan perintah `sync` agar berjalan secara otomatis setiap **5 menit** menggunakan crontab.

### **E. SISTEM LOGGING (LOG)**

Bangun sistem pencatatan aktivitas yang terpusat untuk keperluan audit:

1. Buat fungsi khusus logging yang menerima parameter `LEVEL`, `COMMAND`, dan `MESSAGE`.
2. Format log harus seragam: `[YYYY-MM-DD HH:MM:SS] [LEVEL] [COMMAND] message`.
3. Pastikan setiap keberhasilan (INFO) maupun kegagalan sistem atau validasi (ERROR) tercatat dengan rapi di `activity.log`.
