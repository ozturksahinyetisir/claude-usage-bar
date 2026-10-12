# Claude Usage Bar

Claude'un **5 saatlik** ve **haftalık** kullanım yüzdesini macOS menü çubuğunda sürekli gösteren küçük bir uygulama.
Claude uygulamasındaki yuvarlak butona tekrar tekrar tıklamana gerek kalmaz.

```
5s %60 · Hf %11
```

English: [README.md](README.md)

> Resmî olmayan topluluk projesidir. Anthropic ile bağlantısı yoktur.

## Anahtar (key) gerekmez

Bu proje **hiçbir API anahtarı, token ya da parola istemez, saklamaz, okumaz.**
Ağa hiçbir şey göndermez; her şey kendi Mac'inde kalır. Herkes kendi Claude hesabıyla çalıştırır, kodda ayarlanacak bir anahtar yoktur.
Fork'layıp geliştirirsen kimlik bilgilerini asla commit etme (`.gitignore` `.env`, `*.key`, `*.pem` dosyalarını zaten dışarıda tutar).

## İki mod

| Mod | Gösterir | Gereken |
|---|---|---|
| **Tahmin** (varsayılan) | `~5s %42 · ~Gün %18`, yerel Claude Code kayıtlarından hesaplanır | Hiçbir şey. Kurunca hemen çalışır |
| **Resmî** | `5s %60 · Hf %11`, Claude'un sana gösterdiği birebir değerler | Claude masaüstü uygulaması + zamanlanmış görev (aşağıda) |

Resmî veri yoksa ya da 20 dakikadan eskiyse uygulama tahmine döner ve bunu `~` ile belli eder.

## Kurulum

Gereksinimler: macOS 13+, Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/ozturksahinyetisir/claude-usage-bar.git
cd claude-usage-bar
./build.sh
open ClaudeUsageBar.app
```

İstersen `ClaudeUsageBar.app` dosyasını `/Applications` içine taşı. İlk açılışta macOS "tanımlanamayan geliştirici" uyarısı verebilir
(uygulama ad-hoc imzalı): sağ tık → **Aç**.

### Tahmin modu

Menü → **Limitleri ayarla…** ile planının 5 saatte / günde yaklaşık kaç token izin verdiğini gir.
Anthropic bu rakamları yayımlamadığı için bu moddaki yüzdeler yaklaşıktır.

### Resmî mod (birebir yüzde)

Resmî rakamlar yalnızca Claude masaüstü uygulamasının içinden okunabildiği için, küçük bir zamanlanmış görev bunları menü çubuğu uygulamasının okuduğu bir dosyaya kopyalar:

1. Claude masaüstü uygulamasında **Scheduled** bölümünden 5 dakikada bir (`*/5 * * * *`) çalışan yeni bir görev oluştur.
2. `scripts/write-usage.sh` betiğini kur ve prompt olarak [docs/refresh-task-prompt.md](docs/refresh-task-prompt.md) içindeki metni yapıştır.
3. Betiğe `~/.claude/settings.json` içinde izin ver (tek satır, rehbere bak) ve bir kez **Run now** de.

Görev `~/.claude-usage-bar/usage.json` dosyasını yazar. Çalışması için Claude uygulamasının açık olması gerekir.
Her tur çok kısa bir oturumdur, kendi kullanımından ihmal edilebilir kadar yer. 5 dakika iyi bir dengedir; çok daha sık yaparsan ölçümün kendisi limitini yemeye başlar.

## Sorun giderme

### Çubukta `~5s %78` / "resmî veri N saat önce güncellendi" yazıyor

Uygulama **yerel tahmine** düşmüş, çünkü `~/.claude-usage-bar/usage.json` 20 dakikadan eski. Menüdeki `~` işareti ve uyarı satırı tam olarak bunu söyler. **Yenile** düğmesi çözmez: yalnızca dosyayı yeniden okur.

**Dosya neden güncellenmez?** Zamanlanmış görevin bir kabuk komutu (`write.sh`) çalıştırması gerekir. Zamanlanmış görevler kimse başında değilken çalışır ve araç izin istediğinde Claude uygulaması **hiç onay penceresi göstermeyebilir.** Tur sonsuza dek bekler ve bir tur "running" durumundayken zamanlayıcı **bir sonrakini başlatmaz.** O andan itibaren `usage.json` eskir. **Scheduled** bölümünde saatlerdir "running" kalan bir tur varsa sebep budur.

**Çözüm.**
1. Takılı turu durdur (oturumu açıp durdur).
2. Betiğe `~/.claude/settings.json` içinde önceden izin ver (hiçbir pencere gerekmez):
   ```json
   { "permissions": { "allow": ["Bash(~/.claude-usage-bar/write.sh:*)"] } }
   ```
   Tek komutluk sürümü [docs/refresh-task-prompt.md](docs/refresh-task-prompt.md#3-betiğe-izni-ver--allow-the-script) içinde.
3. **Run now** de. `usage.json` birkaç saniyede güncellenmeli, sonra yaklaşık 5 dakikada bir kendiliğinden.

Başka nedenler: Claude masaüstü uygulaması kapalı (görev açılınca çalışır) ya da Mac uyuyordu (sonraki tur telafi eder).

Neyin değiştiği için [CHANGELOG.md](CHANGELOG.md) dosyasına bak.

## Menü

Menü çubuğundaki yazıya tıkla: token sayıları, 5 saatlik pencerenin sıfırlanmasına kalan süre ve seçenekler görünür:
**Yenile**, **Limitleri ayarla…**, **Girişte başlat**, **Çık**.

## Nasıl çalışır

- Tahmin: `~/.claude/projects/**/*.jsonl` dosyalarını okur, kullanımı 5 saatlik bloklara ve günlük toplama ayırır.
- Resmî: zamanlanmış görevin yazdığı `~/.claude-usage-bar/usage.json` dosyasını okur.
- Tüm kod tek dosyada: [Sources/main.swift](Sources/main.swift).

## Gizlilik

Yalnızca yerel dosyaları okur. Ağ erişimi, analitik ve kimlik bilgisi yoktur. `usage.json` sadece yüzdeleri ve sıfırlanma zamanlarını içerir.

## Lisans

MIT
