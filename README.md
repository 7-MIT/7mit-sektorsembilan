# Sektor Sembilan

Gim tembak 3D (FPS) berbasis browser dalam satu file HTML (Three.js r128 dari CDN, tanpa aset lain).

## Fitur
- 4 senjata + karambit, 11 peta, mode Bertahan, Tim vs Tim (sistem pangkat), Multiplayer FFA dan Duel 1v1 (butuh claude.ai)
- Koin, spin skin, skin Mitos berefek khusus
- Pengaturan: bahasa (Indonesia/English), sensitivitas (umum, vertikal, scope, sniper, sentuh), FOV, grafik, garis bidik

## Menjalankan
Buka `index.html` di browser, atau aktifkan GitHub Pages dari branch `main`.
Simpan progres ke akun dan multiplayer online hanya jalan di dalam claude.ai; di luar itu progres tersimpan di browser.

## Server Fathan (multiplayer)

Online play uses a Supabase project ("Server Fathan"): realtime broadcast channels for gameplay,
tables `s9_rooms`, `s9_scores`, `s9_chat` for the lobby, leaderboard and lobby chat.
The schema is in `server/schema.sql` (writes go through validated RPC functions, tables are read-only for anon).
If the server is unreachable the game falls back to the claude.ai room transport.
