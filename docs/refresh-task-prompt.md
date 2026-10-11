# Resmî yüzdeyi güncelleyen zamanlanmış görev / Scheduled task prompt

Claude masaüstü uygulamasında **Scheduled** bölümünden yeni görev oluştur,
zamanlamayı `*/5 * * * *` (5 dakikada bir) yap ve aşağıdaki metni prompt olarak yapıştır.
Create a new task in the Claude desktop app's **Scheduled** section, schedule `*/5 * * * *`,
and paste the text below as the prompt.

```
Çok kısa ve hızlı bir iş; başka hiçbir şey yapma, açıklama yazma, dosya okuma/arama yapma.

1. Gerekirse ToolSearch ile "select:mcp__ccd_session_mgmt__get_usage" çalıştırıp aracı yükle, sonra mcp__ccd_session_mgmt__get_usage aracını argümansız çağır.
2. Sonuçtaki plan.windows listesinden label'ı "5-hour limit" olanın percentUsed ve resetsAt değerlerini, label'ı "Weekly · all models" olanın percentUsed ve resetsAt değerlerini al. plan.status "ok" değilse hiçbir dosya yazma, sadece "okunamadı" de ve bitir.
3. Bash ile ~/.claude-usage-bar/usage.json dosyasını yaz (updatedAt şu anki UTC zamanı, `date -u +%Y-%m-%dT%H:%M:%SZ`). İçerik tek satır JSON:
   {"updatedAt":"<şimdi>","fiveHour":{"percent":<sayı>,"resetsAt":"<resetsAt>"},"weekly":{"percent":<sayı>,"resetsAt":"<resetsAt>"}}
   percent tam sayı olmalı. Önce geçici dosyaya yaz, sonra mv ile yerine koy.
4. Tek satırlık "güncellendi: 5s %X, hf %Y" yaz ve bitir.
```

Tüm bunlar senin kendi Claude hesabınla, kendi bilgisayarında çalışır. Hiçbir anahtar (key/token) girmen gerekmez.
