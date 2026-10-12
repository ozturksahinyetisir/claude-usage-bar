# Resmî yüzdeyi güncelleyen zamanlanmış görev / Scheduled task prompt

## 1. Betiği kur / Install the helper script

```bash
mkdir -p ~/.claude-usage-bar
cp scripts/write-usage.sh ~/.claude-usage-bar/write.sh
chmod +x ~/.claude-usage-bar/write.sh
```

Betik yalnızca dört değer kabul eder (iki yüzde, iki ISO tarih), başka hiçbir şeyi çalıştırmaz ve
`~/.claude-usage-bar/usage.json` dosyasını atomik olarak yazar.
The script only accepts four values (two percentages, two ISO dates), runs nothing else and writes the file atomically.

## 2. Görevi oluştur / Create the task

Claude masaüstü uygulamasında **Scheduled** bölümünden yeni görev oluştur, zamanlamayı `*/5 * * * *` (5 dakikada bir) yap ve aşağıdaki metni prompt olarak yapıştır.
Create a new task in the Claude desktop app's **Scheduled** section, schedule `*/5 * * * *`, and paste the text below as the prompt.

```
Çok kısa ve hızlı bir iş; başka hiçbir şey yapma, açıklama yazma, dosya okuma/arama yapma.

1. Gerekirse ToolSearch ile "select:mcp__ccd_session_mgmt__get_usage" çalıştırıp aracı yükle, sonra mcp__ccd_session_mgmt__get_usage aracını argümansız çağır.
2. Sonuçtaki plan.windows listesinden label'ı "5-hour limit" olanın percentUsed ve resetsAt değerlerini, label'ı "Weekly · all models" olanın percentUsed ve resetsAt değerlerini al. plan.status "ok" değilse hiçbir şey yazma, sadece "okunamadı" de ve bitir.
3. Tek bir Bash komutu çalıştır (başka hiçbir komut çalıştırma):
   ~/.claude-usage-bar/write.sh <5 saatlik percentUsed tam sayı> <5 saatlik resetsAt aynen> <haftalık percentUsed tam sayı> <haftalık resetsAt aynen>
   Örnek: ~/.claude-usage-bar/write.sh 24 2026-10-12T19:19:59.664Z 20 2026-10-15T01:59:59.665Z
   Betik dosyayı kendisi atomik olarak yazar; sen JSON üretme, tarih hesaplama, mv ya da başka komut kullanma.
4. Betiğin ürettiği tek satırlık çıktıyı yaz ve bitir.
```

## 3. İzni bir kez ver / Approve once

Görevi **Run now** ile bir kez çalıştır. Araç izni sorulduğunda `~/.claude-usage-bar/write.sh` komutu için **"Always allow"** (her zaman izin ver) seç.
Böylece sonraki turlar sormadan çalışır. İzin yalnızca bu betiğe verilir, genel `Bash` izni değildir.
Run the task once with **Run now**. When asked, choose **"Always allow"** for the `~/.claude-usage-bar/write.sh` command so later runs don't pause. The permission covers this script only, not general `Bash`.

> Not: Tur takılı kalırsa (izin beklerken) sonraki turlar başlamaz ve uygulama `~` ile işaretli yerel tahmine düşer.
> Note: if a run hangs waiting for approval, later runs won't start and the app falls back to the `~` local estimate.

Tüm bunlar senin kendi Claude hesabınla, kendi bilgisayarında çalışır. Hiçbir anahtar (key/token) girmen gerekmez.
