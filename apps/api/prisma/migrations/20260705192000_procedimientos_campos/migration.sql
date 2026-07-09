-- AlterEnum
ALTER TYPE "TipoMantenimiento" ADD VALUE IF NOT EXISTS 'preventivo_no_periodico';

-- CreateEnum
CREATE TYPE "CriterioProgramacion" AS ENUM ('fecha_inicio', 'fecha_finalizacion');

-- AlterTable
ALTER TABLE "procedimientos" ADD COLUMN "codigo" SERIAL;
ALTER TABLE "procedimientos" ADD COLUMN "sector_responsable_id" UUID;
ALTER TABLE "procedimientos" ADD COLUMN "criterio_programacion" "CriterioProgramacion";
ALTER TABLE "procedimientos" ADD COLUMN "tolerancia" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "procedimientos" ADD COLUMN "cant_operarios" INTEGER;
ALTER TABLE "procedimientos" ADD COLUMN "indisponibilidad_estimada" INTEGER;
ALTER TABLE "procedimientos" ADD COLUMN "costo_estimado" DECIMAL(15,2);

-- CreateIndex
CREATE UNIQUE INDEX "procedimientos_codigo_key" ON "procedimientos"("codigo");

-- Set sequence start at 1000
SELECT setval(pg_get_serial_sequence('procedimientos', 'codigo'), 999, false);

-- AddForeignKey
ALTER TABLE "procedimientos" ADD CONSTRAINT "procedimientos_sector_responsable_id_fkey" FOREIGN KEY ("sector_responsable_id") REFERENCES "ubicaciones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
