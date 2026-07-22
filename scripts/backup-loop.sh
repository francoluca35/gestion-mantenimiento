#!/bin/sh
set -eu

KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
HOUR_UTC="${BACKUP_HOUR_UTC:-5}"
DB_USER="${POSTGRES_USER:-sika}"
DB_NAME="${POSTGRES_DB:-gestion_mantenimiento}"

echo "[backup] started — daily at ${HOUR_UTC}:00 UTC, keep ${KEEP_DAYS} days"

do_backup() {
	stamp=$(date -u +%Y%m%d-%H%M%S)
	file="gestion_mantenimiento-${stamp}.sql.gz"
	echo "[backup] dumping → /backups/${file}"
	pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner --format=plain \
		| gzip -c > "/backups/${file}"
	size=$(wc -c < "/backups/${file}" | tr -d ' ')
	if [ "$size" -lt 100 ]; then
		echo "[backup] ERROR: dump too small (${size} bytes)"
		rm -f "/backups/${file}"
		return 1
	fi
	echo "[backup] OK (${size} bytes)"
	find /backups -name 'gestion_mantenimiento-*.sql.gz' -mtime +"${KEEP_DAYS}" -delete 2>/dev/null || true
}

# Primera corrida a los ~2 minutos (smoke)
sleep 120
do_backup || true

while true; do
	# Esperar hasta la próxima hora UTC objetivo
	now_h=$(date -u +%H)
	now_m=$(date -u +%M)
	now_s=$(date -u +%S)
	# segundos hasta HOUR_UTC:00:00
	cur_secs=$((10#$now_h * 3600 + 10#$now_m * 60 + 10#$now_s))
	tgt_secs=$((10#$HOUR_UTC * 3600))
	if [ "$cur_secs" -ge "$tgt_secs" ]; then
		wait_secs=$((86400 - cur_secs + tgt_secs))
	else
		wait_secs=$((tgt_secs - cur_secs))
	fi
	echo "[backup] next run in ${wait_secs}s"
	sleep "$wait_secs"
	do_backup || true
done
