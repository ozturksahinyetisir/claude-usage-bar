# Changelog / Değişiklik günlüğü

## 0.3 — Resmî veri güvenilirliği / Official-data reliability

**Sorun / Problem**
- 🇹🇷 Menü çubuğu `%78` gösteriyor, Claude'un kendi göstergesi `%24` diyordu. Sebep: zamanlanmış görev, bir `Bash` komutu için onay beklerken takılmıştı. Onay penceresi hiç çıkmadığı için tur bitmedi, takılı tur varken yenisi başlamadı, `usage.json` bir gün boyunca güncellenmedi ve uygulama **yerel token tahminine** düştü.
- 🇬🇧 The bar showed `78%` while Claude's own indicator said `24%`. The scheduled task had hung waiting for approval of a `Bash` command. No approval prompt ever appeared, so the run never finished, no new run could start, `usage.json` went stale for a day and the app fell back to the **local token estimate**.

**Düzeltmeler / Fixes**
- `scripts/write-usage.sh`: tek amaçlı betik. Yalnızca iki yüzde + iki ISO tarih kabul eder, girdiyi doğrular, başka hiçbir şeyi çalıştırmaz, `usage.json`'u atomik yazar. / Single-purpose script: accepts only two percentages + two ISO dates, validates input, runs nothing else, writes `usage.json` atomically.
- Görev istemi bu betiği çağıracak şekilde sadeleştirildi (JSON üretme, `mv`, tarih hesabı yok). / The task prompt now just calls the script.
- İzin, `~/.claude/settings.json` içinde yalnızca bu betik için önceden verilir; onay penceresi gerekmez. / The permission is granted up front for this script only; no prompt needed.
- Menü: veri eskiyince `⚠ Resmî veri N saat önce güncellendi; yerel tahmin gösteriliyor (~)` uyarısı. Yanlış rakam sessizce gösterilmez. / Menu: a `⚠ official data is N hours old; showing local estimate (~)` warning when data goes stale.
- Yerel tahmin %100'de sınırlandı (önceden %141 gösterebiliyordu). / Local estimate is capped at 100% (it could show 141%).
- README: **Sorun giderme / Troubleshooting** bölümü eklendi. / Added a Troubleshooting section.

**Doğrulama / Verification**
- Elle başlatılan tur ve ardından zamanlayıcının kendi başlattığı tur, izin sormadan `usage.json`'u yazdı (15:10 → %28, 15:16 → %29). / A manual run and the next scheduler-started run both wrote `usage.json` without any prompt.

## 0.2
- Resmî yüzde için `usage.json` kaynağı ve yerel tahmine geri dönüş. / `usage.json` source for official percentages with local-estimate fallback.

## 0.1
- İlk sürüm: yerel Claude Code kayıtlarından 5 saatlik ve günlük tahmin. / First release: 5-hour and daily estimate from local Claude Code logs.
