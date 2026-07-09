-- CreateTable
CREATE TABLE "motivos_ot_pendiente" (
    "id" UUID NOT NULL,
    "sucursal_id" UUID NOT NULL,
    "codigo" VARCHAR(30) NOT NULL,
    "descripcion" VARCHAR(200) NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "orden" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "motivos_ot_pendiente_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "ordenes_trabajo" ADD COLUMN "motivo_pendiente_id" UUID;

-- CreateIndex
CREATE INDEX "motivos_ot_pendiente_sucursal_id_activo_idx" ON "motivos_ot_pendiente"("sucursal_id", "activo");

-- CreateIndex
CREATE UNIQUE INDEX "motivos_ot_pendiente_sucursal_id_codigo_key" ON "motivos_ot_pendiente"("sucursal_id", "codigo");

-- AddForeignKey
ALTER TABLE "motivos_ot_pendiente" ADD CONSTRAINT "motivos_ot_pendiente_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_motivo_pendiente_id_fkey" FOREIGN KEY ("motivo_pendiente_id") REFERENCES "motivos_ot_pendiente"("id") ON DELETE SET NULL ON UPDATE CASCADE;
