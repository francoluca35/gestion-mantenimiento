-- AlterTable
ALTER TABLE "sucursales" ADD COLUMN IF NOT EXISTS "logo_key" VARCHAR(500);
ALTER TABLE "sucursales" ADD COLUMN IF NOT EXISTS "logo_url" VARCHAR(800);
