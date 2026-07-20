-- AlterTable
ALTER TABLE "materiales" ADD COLUMN "uso" VARCHAR(50) NOT NULL DEFAULT 'Mantenimiento';

-- CreateEnum
CREATE TYPE "EstadoPedidoStock" AS ENUM ('pendiente', 'en_proceso', 'completado');

-- CreateTable
CREATE TABLE "pedidos_stock" (
    "id" UUID NOT NULL,
    "numero" SERIAL NOT NULL,
    "panol_id" UUID NOT NULL,
    "material_id" UUID NOT NULL,
    "cantidad" DECIMAL(10,2) NOT NULL,
    "estado" "EstadoPedidoStock" NOT NULL DEFAULT 'pendiente',
    "usuario_id" UUID,
    "notas" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "completado_at" TIMESTAMPTZ(6),

    CONSTRAINT "pedidos_stock_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "pedidos_stock_numero_key" ON "pedidos_stock"("numero");

-- CreateIndex
CREATE INDEX "pedidos_stock_panol_id_estado_idx" ON "pedidos_stock"("panol_id", "estado");

-- CreateIndex
CREATE INDEX "pedidos_stock_estado_created_at_idx" ON "pedidos_stock"("estado", "created_at");

-- AddForeignKey
ALTER TABLE "pedidos_stock" ADD CONSTRAINT "pedidos_stock_panol_id_fkey" FOREIGN KEY ("panol_id") REFERENCES "panoles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pedidos_stock" ADD CONSTRAINT "pedidos_stock_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "materiales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pedidos_stock" ADD CONSTRAINT "pedidos_stock_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
