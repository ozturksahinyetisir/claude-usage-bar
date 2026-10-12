#!/bin/bash
# Kullanım: write.sh <5 saatlik yüzde> <5 saatlik sıfırlanma ISO> <haftalık yüzde> <haftalık sıfırlanma ISO>
# Menü çubuğu uygulamasının okuduğu ~/.claude-usage-bar/usage.json dosyasını güvenle (atomik) yazar.
set -e
f="$1"; fr="$2"; w="$3"; wr="$4"
[[ "$f" =~ ^[0-9]{1,3}$ && "$w" =~ ^[0-9]{1,3}$ ]] || { echo "geçersiz yüzde" >&2; exit 1; }
iso='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z$'
[[ "$fr" =~ $iso && "$wr" =~ $iso ]] || { echo "geçersiz tarih" >&2; exit 1; }
d="$HOME/.claude-usage-bar"; mkdir -p "$d"
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '{"updatedAt":"%s","fiveHour":{"percent":%s,"resetsAt":"%s"},"weekly":{"percent":%s,"resetsAt":"%s"}}\n' "$now" "$f" "$fr" "$w" "$wr" > "$d/usage.json.tmp"
mv "$d/usage.json.tmp" "$d/usage.json"
echo "yazıldı: 5s %$f, hf %$w ($now)"
