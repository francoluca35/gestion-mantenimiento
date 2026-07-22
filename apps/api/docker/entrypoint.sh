#!/bin/sh
set -eu

echo "[entrypoint] waiting for database..."
i=0
until npx prisma migrate deploy >/tmp/migrate.log 2>&1; do
	i=$((i + 1))
	if [ "$i" -ge 30 ]; then
		echo "[entrypoint] migrate failed after retries:"
		cat /tmp/migrate.log
		exit 1
	fi
	echo "[entrypoint] DB not ready (attempt $i/30), retrying in 2s..."
	sleep 2
done
echo "[entrypoint] migrations OK"

if [ "${SEED_ON_START:-false}" = "true" ]; then
	echo "[entrypoint] SEED_ON_START=true — seeding..."
	# Seed requires ts-node; prefer external seed job. Skip gracefully if unavailable.
	if command -v npx >/dev/null 2>&1 && [ -f prisma/seed.ts ]; then
		npx prisma db seed || echo "[entrypoint] seed skipped/failed (non-fatal)"
	else
		echo "[entrypoint] seed tools missing — run scripts/seed-demo.ps1"
	fi
fi

echo "[entrypoint] starting API..."
exec "$@"
