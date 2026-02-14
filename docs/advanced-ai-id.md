# Tutorial: Integrasi & Instalasi Advanced AI (Bahasa Indonesia)

Dokumen ini menjelaskan:
1. bagaimana `advanced_bot_ai` sekarang sudah terhubung ke alur draft bot,
2. cara mengatur profilnya,
3. cara install script ke Dota 2 (Windows & macOS).

## 1) Status Integrasi di Repository

Modul AI lanjutan berada di:
- `bots/FunLib/advanced_bot_ai.lua`

Dan sudah dipakai langsung oleh sistem draft di:
- `bots/hero_selection.lua`

Integrasi yang dilakukan:
- Membaca konfigurasi dari `Customize.general.lua` (`Customize.AdvancedAI`).
- Menentukan role sesuai slot bot (pos1–pos5).
- Menentukan skill bracket (`bot_immortal_6k` / `fretbots_10k`) otomatis dari setting atau difficulty Fretbots.
- Memakai rekomendasi hero dari Advanced AI sebagai tie-breaker saat proses pick.

## 2) Cara Mengatur Profil Advanced AI

Buka file:
- `bots/Customize/general.lua`

Cari blok:

```lua
Customize.AdvancedAI = {
    Skill_Bracket = 'bot_immortal_6k',
    Reflex_Profile = '',
}
```

### Opsi yang tersedia

- `Skill_Bracket`
  - `bot_immortal_6k` → default bot (stabil/umum)
  - `fretbots_10k` → lebih agresif/lebih disiplin macro

- `Reflex_Profile`
  - `''` (kosong) → otomatis mengikuti skill bracket
  - `human` → reaksi lebih lambat
  - `pro` → reaksi cepat
  - `superhuman` → reaksi paling cepat

### Contoh setting cepat

```lua
Customize.AdvancedAI = {
    Skill_Bracket = 'fretbots_10k',
    Reflex_Profile = 'superhuman',
}
```

## 3) Cara Pakai di Dota 2 (Install)

> Penting: mainkan via **Custom Lobby** dan set server ke **Local Host**.

### A. Cara paling mudah (Workshop script helper)

#### Windows
1. Subscribe workshop item Open Hyper AI.
2. Buka folder:
   `Steam\steamapps\workshop\content\570\3246316298\Install-to-vscript`
3. Jalankan `quick-install-oha.bat`.
4. Selesai, file workshop akan di-link/copy ke folder `vscripts` Dota.

#### macOS
1. Subscribe workshop item Open Hyper AI.
2. Buka Terminal lalu masuk ke folder:
   `Steam/steamapps/workshop/content/570/3246316298/Install-to-vscript`
3. Jalankan:
   ```bash
   chmod +x quick-install-oha-mac.sh
   sudo ./quick-install-oha-mac.sh
   ```

### B. Cara manual (untuk development / edit langsung)

Copy folder project ke:

`<Steam>/steamapps/common/dota 2 beta/game/dota/scripts/vscripts/`

Struktur minimal harus seperti ini:
- `bots/`
- `game/`

Jika folder sudah benar:
1. Restart Dota 2 (atau minimal restart lobby/script load).
2. Buat custom lobby Local Host.
3. Jalankan game dan cek bot name/behavior.

## 4) Verifikasi Cepat Setelah Install

1. Pastikan bot bisa pick hero normal (tidak stuck random default Valve).
2. Ubah `Customize.AdvancedAI.Skill_Bracket` lalu main 1 game untuk cek perubahan gaya bermain.
3. Jika ada error syntax, restore file terakhir yang valid atau re-subscribe workshop item.

## 5) Catatan Kompatibilitas

- File root `bot_advanced_ai.lua` disediakan sebagai shim compatibility.
- Runtime utama menggunakan `bots/FunLib/advanced_bot_ai.lua`.
- Jadi untuk edit fitur AI lanjutan, fokus ke file di `bots/FunLib/`.

## 6) Efisiensi Item Otomatis (Power Treads / Bottle / Stick / Wand)

Sekarang bot juga ditingkatkan untuk efisiensi resource:
- Saat memakai **Bottle / Magic Stick / Magic Wand**, bot akan mencoba **switch Power Treads** terlebih dulu.
- Jika aman, bot condong switch ke **INT** dulu untuk efisiensi mana.
- Jika sedang terancam/diserang, bot condong switch ke **STR** untuk ketahanan.

> Catatan: mekanik "drop item stats lalu minum Bottle/Wand" tidak selalu stabil di semua kondisi API bot,
> jadi implementasi di repo ini memakai pendekatan aman: **PT stat switching + cast sequencing**.


## 7) Presisi Gerak Bot (Prioritas 10k MMR)

Untuk profile `fretbots_10k`, perintah gerak bot sekarang dibuat lebih efisien:
- mengurangi spam order move berulang dalam interval sangat pendek,
- menghindari perintah move ke lokasi yang terlalu dekat (order mubazir),
- mencoba menormalkan target move ke lokasi yang passable bila titik awal tidak passable.

Efeknya: respons gerak terasa lebih rapih/stabil saat teamfight, rotasi, dan kiting, terutama untuk preset 10k.



## 8) Perbaikan Koordinasi Gameplay (Chain Control, Roam, Laning)

Penyesuaian terbaru yang sudah ditambahkan:
- **Roam/Gank scoring lebih cerdas** di `mode_roam_generic.lua`:
  - mempertimbangkan estimasi kontrol tim (stun/root/fear/silence/hex) di lane target,
  - mempertimbangkan dukungan healing tim (hero-hero support healer),
  - memberi bonus keputusan roam saat power spike mid/support sudah siap.
- **Kontes rune untuk mid laner/suport** di `mode_rune_generic.lua`:
  - mid level 6+ dan resource cukup akan lebih prioritas contest power rune,
  - support pos4/5 bisa bantu secure power rune untuk mid jika kondisi cocok.
- **Laning equilibrium control** di `mode_laning_generic.lua`:
  - bot mencoba aggro control (tarik creep wave) via hero aggro timing,
  - bot mencoba hold posisi lane agar equilibrium tetap aman.

Catatan: ini adalah peningkatan bertahap menuju gameplay yang lebih “panas” dan terkoordinasi,
namun tetap mempertahankan stabilitas logic existing dari project utama.


## 9) Mapping Difficulty -> Bracket Skill (Auto)

Agar perbedaan rank rendah vs high-immortal lebih konsisten, pemetaan default sekarang:
- Difficulty `0-2`  -> `legend`
- Difficulty `3-7`  -> `bot_immortal_6k`
- Difficulty `8-10` -> `fretbots_10k`

Jika `Customize.AdvancedAI.Skill_Bracket` diisi manual, nilai manual tetap dipakai.
Jika dikosongkan, sistem akan mengikuti mapping difficulty di atas.

## 10) Pattern Farming Maksimal + Objective Utility (Outpost/Watcher/Lotus/Twin Gate)

Update terbaru pada mode farm (`mode_farm_generic.lua`) menambahkan perilaku utility saat bot sedang rotasi farming:
- bot akan opportunistic **pickup Lotus** (Lotus / Greater Lotus) jika aman,
- bot dapat **capture Watcher / Outpost** yang dekat saat tidak ada ancaman musuh di area,
- core bisa sesekali **pathing ke Lotus Pool** pada timing spawn agar resource lane/map lebih efisien,
- bot dapat mempertimbangkan **Twin Gate** untuk mempercepat rotasi ke target farm yang sangat jauh.

Khusus profil tinggi (`fretbots_10k`), radius keputusan objective dibuat sedikit lebih agresif namun tetap dibatasi safety check musuh terdekat.

## 11) Wisdom Shrine Tiap 7 Menit (Dipaksa Lebih Konsisten)

Mode rune sekarang diperketat untuk Wisdom Shrine:
- bot mulai **pre-position** sebelum spawn (jendela persiapan), bukan hanya bereaksi setelah spawn,
- prioritas pengambil Wisdom lebih condong ke **support (pos4/5)** dan hero level lebih rendah,
- di jendela Wisdom aktif, desire dinaikkan agar eksekusi lebih konsisten,
- tracking cycle 7-menit diperbaiki supaya tidak gampang miss pada transisi menit.

Tujuannya: tim bot lebih konsisten mengambil Wisdom setiap siklus 7 menit selama kondisi map masih aman.
