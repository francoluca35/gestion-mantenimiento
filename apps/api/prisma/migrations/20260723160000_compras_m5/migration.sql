-- M5 Compras: proveedores + órdenes de compra

DO $$ BEGIN
	CREATE TYPE "EstadoOrdenCompra" AS ENUM ('solicitada', 'autorizada', 'no_autorizada', 'anulada', 'recibida');
EXCEPTION
	WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS "proveedores" (
	"id" UUID NOT NULL,
	"sucursal_id" UUID NOT NULL,
	"nombre" VARCHAR(200) NOT NULL,
	"cuit" VARCHAR(20),
	"contacto" VARCHAR(200),
	"telefono" VARCHAR(50),
	"email" VARCHAR(100),
	"calificacion" DECIMAL(3,1),
	"activo" BOOLEAN NOT NULL DEFAULT true,
	"created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT "proveedores_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "ordenes_compra" (
	"id" UUID NOT NULL,
	"numero" INTEGER NOT NULL,
	"sucursal_id" UUID NOT NULL,
	"proveedor_id" UUID NOT NULL,
	"estado" "EstadoOrdenCompra" NOT NULL DEFAULT 'solicitada',
	"monto_total" DECIMAL(15,2) NOT NULL DEFAULT 0,
	"creado_por_id" UUID,
	"autorizado_por_id" UUID,
	"fecha_solicitud" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"fecha_autorizacion" TIMESTAMPTZ(6),
	"notas" TEXT,
	"created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT "ordenes_compra_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "ordenes_compra_detalle" (
	"id" UUID NOT NULL,
	"orden_compra_id" UUID NOT NULL,
	"material_id" UUID NOT NULL,
	"cantidad" DECIMAL(10,2) NOT NULL,
	"precio_unitario" DECIMAL(15,2) NOT NULL,
	CONSTRAINT "ordenes_compra_detalle_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "proveedores_sucursal_id_activo_idx" ON "proveedores"("sucursal_id", "activo");
CREATE INDEX IF NOT EXISTS "proveedores_sucursal_id_nombre_idx" ON "proveedores"("sucursal_id", "nombre");
CREATE UNIQUE INDEX IF NOT EXISTS "ordenes_compra_sucursal_id_numero_key" ON "ordenes_compra"("sucursal_id", "numero");
CREATE INDEX IF NOT EXISTS "ordenes_compra_sucursal_id_estado_idx" ON "ordenes_compra"("sucursal_id", "estado");
CREATE INDEX IF NOT EXISTS "ordenes_compra_proveedor_id_idx" ON "ordenes_compra"("proveedor_id");
CREATE INDEX IF NOT EXISTS "ordenes_compra_detalle_orden_compra_id_idx" ON "ordenes_compra_detalle"("orden_compra_id");
CREATE INDEX IF NOT EXISTS "ordenes_compra_detalle_material_id_idx" ON "ordenes_compra_detalle"("material_id");

DO $$ BEGIN
	ALTER TABLE "proveedores" ADD CONSTRAINT "proveedores_sucursal_id_fkey"
		FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
	ALTER TABLE "ordenes_compra" ADD CONSTRAINT "ordenes_compra_sucursal_id_fkey"
		FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
	ALTER TABLE "ordenes_compra" ADD CONSTRAINT "ordenes_compra_proveedor_id_fkey"
		FOREIGN KEY ("proveedor_id") REFERENCES "proveedores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
	ALTER TABLE "ordenes_compra" ADD CONSTRAINT "ordenes_compra_creado_por_id_fkey"
		FOREIGN KEY ("creado_por_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
	ALTER TABLE "ordenes_compra" ADD CONSTRAINT "ordenes_compra_autorizado_por_id_fkey"
		FOREIGN KEY ("autorizado_por_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
	ALTER TABLE "ordenes_compra_detalle" ADD CONSTRAINT "ordenes_compra_detalle_orden_compra_id_fkey"
		FOREIGN KEY ("orden_compra_id") REFERENCES "ordenes_compra"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
	ALTER TABLE "ordenes_compra_detalle" ADD CONSTRAINT "ordenes_compra_detalle_material_id_fkey"
		FOREIGN KEY ("material_id") REFERENCES "materiales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;
