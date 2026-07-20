-- CreateEnum
CREATE TYPE "TipoMovimientoStock" AS ENUM ('entrada', 'salida', 'reserva', 'devolucion', 'transferencia');

-- CreateEnum
CREATE TYPE "EstadoSolicitudMaterial" AS ENUM ('pendiente', 'aprobado', 'rechazado');

-- CreateTable
CREATE TABLE "unidades" (
    "id" UUID NOT NULL,
    "codigo" VARCHAR(20) NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "unidades_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "panoles" (
    "id" UUID NOT NULL,
    "sucursal_id" UUID NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "panoles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "materiales" (
    "id" UUID NOT NULL,
    "codigo" VARCHAR(50) NOT NULL,
    "nombre" VARCHAR(200) NOT NULL,
    "marca" VARCHAR(100),
    "unidad_id" UUID NOT NULL,
    "precio_actual" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "materiales_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_items" (
    "id" UUID NOT NULL,
    "panol_id" UUID NOT NULL,
    "material_id" UUID NOT NULL,
    "cantidad_actual" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "cantidad_minima" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "cantidad_reservada" DECIMAL(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT "stock_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "movimientos_stock" (
    "id" UUID NOT NULL,
    "panol_id" UUID NOT NULL,
    "material_id" UUID NOT NULL,
    "tipo" "TipoMovimientoStock" NOT NULL,
    "cantidad" DECIMAL(10,2) NOT NULL,
    "ot_id" UUID,
    "usuario_id" UUID,
    "fecha" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "origen" VARCHAR(50),
    "notas" TEXT,

    CONSTRAINT "movimientos_stock_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "solicitudes_material" (
    "id" UUID NOT NULL,
    "ot_id" UUID NOT NULL,
    "panol_id" UUID NOT NULL,
    "material_id" UUID NOT NULL,
    "cantidad_solicitada" DECIMAL(10,2) NOT NULL,
    "estado" "EstadoSolicitudMaterial" NOT NULL DEFAULT 'pendiente',
    "solicitante_id" UUID,
    "panolero_id" UUID,
    "fecha_solicitud" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fecha_resolucion" TIMESTAMPTZ(6),
    "motivo_rechazo" TEXT,

    CONSTRAINT "solicitudes_material_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "unidades_codigo_key" ON "unidades"("codigo");

-- CreateIndex
CREATE INDEX "panoles_sucursal_id_activo_idx" ON "panoles"("sucursal_id", "activo");

-- CreateIndex
CREATE UNIQUE INDEX "materiales_codigo_key" ON "materiales"("codigo");

-- CreateIndex
CREATE INDEX "materiales_activo_nombre_idx" ON "materiales"("activo", "nombre");

-- CreateIndex
CREATE INDEX "stock_items_material_id_idx" ON "stock_items"("material_id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_items_panol_id_material_id_key" ON "stock_items"("panol_id", "material_id");

-- CreateIndex
CREATE INDEX "movimientos_stock_panol_id_fecha_idx" ON "movimientos_stock"("panol_id", "fecha");

-- CreateIndex
CREATE INDEX "movimientos_stock_material_id_fecha_idx" ON "movimientos_stock"("material_id", "fecha");

-- CreateIndex
CREATE INDEX "movimientos_stock_ot_id_idx" ON "movimientos_stock"("ot_id");

-- CreateIndex
CREATE INDEX "solicitudes_material_ot_id_estado_idx" ON "solicitudes_material"("ot_id", "estado");

-- CreateIndex
CREATE INDEX "solicitudes_material_panol_id_estado_idx" ON "solicitudes_material"("panol_id", "estado");

-- CreateIndex
CREATE INDEX "solicitudes_material_estado_fecha_solicitud_idx" ON "solicitudes_material"("estado", "fecha_solicitud");

-- AddForeignKey
ALTER TABLE "panoles" ADD CONSTRAINT "panoles_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "materiales" ADD CONSTRAINT "materiales_unidad_id_fkey" FOREIGN KEY ("unidad_id") REFERENCES "unidades"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_items" ADD CONSTRAINT "stock_items_panol_id_fkey" FOREIGN KEY ("panol_id") REFERENCES "panoles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_items" ADD CONSTRAINT "stock_items_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "materiales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos_stock" ADD CONSTRAINT "movimientos_stock_panol_id_fkey" FOREIGN KEY ("panol_id") REFERENCES "panoles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos_stock" ADD CONSTRAINT "movimientos_stock_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "materiales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos_stock" ADD CONSTRAINT "movimientos_stock_ot_id_fkey" FOREIGN KEY ("ot_id") REFERENCES "ordenes_trabajo"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movimientos_stock" ADD CONSTRAINT "movimientos_stock_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_material" ADD CONSTRAINT "solicitudes_material_ot_id_fkey" FOREIGN KEY ("ot_id") REFERENCES "ordenes_trabajo"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_material" ADD CONSTRAINT "solicitudes_material_panol_id_fkey" FOREIGN KEY ("panol_id") REFERENCES "panoles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_material" ADD CONSTRAINT "solicitudes_material_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "materiales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_material" ADD CONSTRAINT "solicitudes_material_solicitante_id_fkey" FOREIGN KEY ("solicitante_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_material" ADD CONSTRAINT "solicitudes_material_panolero_id_fkey" FOREIGN KEY ("panolero_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
