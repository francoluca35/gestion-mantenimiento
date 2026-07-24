-- DropForeignKey
ALTER TABLE "equipo_documentos" DROP CONSTRAINT "equipo_documentos_creador_id_fkey";

-- DropForeignKey
ALTER TABLE "equipo_documentos" DROP CONSTRAINT "equipo_documentos_equipo_id_fkey";

-- DropForeignKey
ALTER TABLE "equipo_documentos" DROP CONSTRAINT "equipo_documentos_sucursal_id_fkey";

-- AlterTable
ALTER TABLE "equipo_documentos" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "ordenes_trabajo" ADD COLUMN     "ot_origen_id" UUID;

-- CreateTable
CREATE TABLE "password_reset_tokens" (
    "id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "codigo_hash" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "usado" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "password_reset_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "procedimiento_versiones" (
    "id" UUID NOT NULL,
    "procedimiento_id" UUID NOT NULL,
    "version" INTEGER NOT NULL,
    "snapshot" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by_id" UUID,

    CONSTRAINT "procedimiento_versiones_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "password_reset_tokens_usuario_id_usado_idx" ON "password_reset_tokens"("usuario_id", "usado");

-- CreateIndex
CREATE INDEX "procedimiento_versiones_procedimiento_id_created_at_idx" ON "procedimiento_versiones"("procedimiento_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "procedimiento_versiones_procedimiento_id_version_key" ON "procedimiento_versiones"("procedimiento_id", "version");

-- CreateIndex
CREATE INDEX "ordenes_trabajo_ot_origen_id_idx" ON "ordenes_trabajo"("ot_origen_id");

-- AddForeignKey
ALTER TABLE "password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipo_documentos" ADD CONSTRAINT "equipo_documentos_equipo_id_fkey" FOREIGN KEY ("equipo_id") REFERENCES "equipos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipo_documentos" ADD CONSTRAINT "equipo_documentos_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipo_documentos" ADD CONSTRAINT "equipo_documentos_creador_id_fkey" FOREIGN KEY ("creador_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "procedimiento_versiones" ADD CONSTRAINT "procedimiento_versiones_procedimiento_id_fkey" FOREIGN KEY ("procedimiento_id") REFERENCES "procedimientos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_ot_origen_id_fkey" FOREIGN KEY ("ot_origen_id") REFERENCES "ordenes_trabajo"("id") ON DELETE SET NULL ON UPDATE CASCADE;
