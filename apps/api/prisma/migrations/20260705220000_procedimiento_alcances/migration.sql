-- CreateEnum
CREATE TYPE "TipoAlcanceProcedimiento" AS ENUM ('ubicacion', 'planta');

-- CreateTable
CREATE TABLE "procedimiento_alcances" (
    "id" UUID NOT NULL,
    "procedimiento_id" UUID NOT NULL,
    "tipo" "TipoAlcanceProcedimiento" NOT NULL,
    "ubicacion_id" UUID,
    "sucursal_alcance_id" UUID,
    "estado" "EstadoProcedimientoEquipo" NOT NULL DEFAULT 'activo',
    "fecha_asociacion" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ultima_emision" DATE,

    CONSTRAINT "procedimiento_alcances_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "procedimiento_alcances_procedimiento_id_ubicacion_id_key" ON "procedimiento_alcances"("procedimiento_id", "ubicacion_id");

-- CreateIndex
CREATE UNIQUE INDEX "procedimiento_alcances_procedimiento_id_sucursal_alcance_id_key" ON "procedimiento_alcances"("procedimiento_id", "sucursal_alcance_id");

-- AddForeignKey
ALTER TABLE "procedimiento_alcances" ADD CONSTRAINT "procedimiento_alcances_procedimiento_id_fkey" FOREIGN KEY ("procedimiento_id") REFERENCES "procedimientos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "procedimiento_alcances" ADD CONSTRAINT "procedimiento_alcances_ubicacion_id_fkey" FOREIGN KEY ("ubicacion_id") REFERENCES "ubicaciones"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "procedimiento_alcances" ADD CONSTRAINT "procedimiento_alcances_sucursal_alcance_id_fkey" FOREIGN KEY ("sucursal_alcance_id") REFERENCES "sucursales"("id") ON DELETE SET NULL ON UPDATE CASCADE;
