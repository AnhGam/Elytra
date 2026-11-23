#!/usr/bin/env bash
set -euo pipefail
# Gốc repo (chứa thư mục supabase/ đã link): mọi lệnh CLI chạy với --workdir này, kể cả khi đang cd vào thư mục tạm
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Sao lưu lược đồ + dữ liệu DB Elytra (kèm auth) vào bucket Storage riêng tư db-backups.
# Yêu cầu: Supabase CLI đã `link`, Docker đang chạy, có biến SUPABASE_ACCESS_TOKEN (hoặc đã `supabase login`).
# Cách chạy: bash supabase/scripts/backup_db.sh
# Chính sách lưu trữ: giữ 8 bản sao lưu mới nhất, tự xóa các bản cũ hơn.

SB="${SUPABASE_CLI:-npx --no-install supabase} --workdir $ROOT"
# Lệnh storage của CLI 2.x bắt buộc --experimental (đã thử thật 23/11/2026); cp cần đường dẫn tương đối trên Windows
SBX="$SB --experimental"
STAMP=$(date -u +%Y-%m-%d_%H%M)
KEEP=8
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

$SB db dump --linked -f "$TMP/schema.sql"
$SB db dump --linked --data-only -f "$TMP/data.sql"
$SB db dump --linked --data-only -s auth -f "$TMP/auth_data.sql"

gzip -9 "$TMP/schema.sql" "$TMP/data.sql" "$TMP/auth_data.sql"

cd "$TMP"
for f in *.gz; do
  $SBX storage cp --linked "$f" "ss:///db-backups/$STAMP/$f"
done
cd - >/dev/null

LS_OUT=$($SBX storage ls --linked ss:///db-backups/)
DIRS=$(printf '%s\n' "$LS_OUT" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}' | sort -u || true)
COUNT=$(printf '%s\n' "$DIRS" | grep -c . || true)
if [ "$COUNT" -gt "$KEEP" ]; then
  DEL_COUNT=$((COUNT - KEEP))
  for OLD in $(printf '%s\n' "$DIRS" | head -n "$DEL_COUNT"); do
    $SBX storage rm -r --yes --linked "ss:///db-backups/$OLD"
  done
fi

SUMMARY=$(for f in "$TMP"/*.gz; do printf '%s %s, ' "$(basename "$f")" "$(du -h "$f" | cut -f1)"; done)
echo "Sao lưu xong: db-backups/$STAMP (${SUMMARY%, })"
