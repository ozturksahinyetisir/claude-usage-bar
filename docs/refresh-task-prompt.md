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

## 3. Betiğe izni ver / Allow the script

Zamanlanmış görevler kimse başında değilken çalışır. Araç izni gerektiğinde **onay penceresi çıkmayabilir** ve tur sonsuza dek bekler
(ayrıntı: README → Sorun giderme). Bu yüzden izni önceden, yalnızca bu betik için ver.
Scheduled tasks run unattended. When a tool needs approval, **no prompt may ever appear** and the run waits forever
(see README → Troubleshooting). So grant the permission up front, for this script only.

`~/.claude/settings.json` dosyasına şunu ekle (dosya yoksa oluştur; varsa yalnızca `permissions.allow` listesine satırı ekle):
Add this to `~/.claude/settings.json` (create it if missing; if it exists, only add the line to `permissions.allow`):

```json
{
  "permissions": {
    "allow": [
      "Bash(~/.claude-usage-bar/write.sh:*)"
    ]
  }
}
```

Mevcut ayarlarını bozmadan eklemek için tek komut / one command that keeps your existing settings:

```bash
python3 - <<'PY'
import json, os
p = os.path.expanduser('~/.claude/settings.json')
d = json.load(open(p)) if os.path.exists(p) else {}
allow = d.setdefault('permissions', {}).setdefault('allow', [])
rule = 'Bash(~/.claude-usage-bar/write.sh:*)'
if rule not in allow: allow.append(rule)
json.dump(d, open(p, 'w'), indent=2); open(p, 'a').write('\n')
print('tamam:', rule)
PY
```

İzin yalnızca bu betiğe verilir (genel `Bash` izni değildir). Betik dört değer kabul eder ve başka hiçbir şeyi çalıştırmaz.
The permission covers this script only (not general `Bash`). The script accepts four values and runs nothing else.

Sonra görevi bir kez **Run now** ile çalıştır ve `~/.claude-usage-bar/usage.json` dosyasının güncellendiğini doğrula.
Then run the task once with **Run now** and check that `~/.claude-usage-bar/usage.json` is updated.

Tüm bunlar senin kendi Claude hesabınla, kendi bilgisayarında çalışır. Hiçbir anahtar (key/token) girmen gerekmez.
