-- AlterTable
ALTER TABLE "procedimientos" ADD COLUMN "observaciones" TEXT;

-- AlterTable
ALTER TABLE "solicitudes_trabajo" ADD COLUMN "calificacion" VARCHAR(20);
ALTER TABLE "solicitudes_trabajo" ADD COLUMN "observaciones" TEXT;
