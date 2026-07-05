-- CreateTable
CREATE TABLE "ubicaciones" (
    "id" UUID NOT NULL,
    "sucursal_id" UUID NOT NULL,
    "parent_id" UUID,
    "nombre" VARCHAR(200) NOT NULL,
    "orden" INTEGER NOT NULL DEFAULT 0,
    "activa" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "ubicaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tipos_equipo" (
    "id" UUID NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "campos_detalle" JSONB NOT NULL DEFAULT '[]',
    "campos_lectura" JSONB NOT NULL DEFAULT '[]',
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "tipos_equipo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "equipos" (
    "id" UUID NOT NULL,
    "sucursal_id" UUID NOT NULL,
    "ubicacion_id" UUID NOT NULL,
    "tipo_equipo_id" UUID NOT NULL,
    "nombre" VARCHAR(200) NOT NULL,
    "codigo" VARCHAR(50) NOT NULL,
    "detalle" JSONB NOT NULL DEFAULT '{}',
    "fuera_de_servicio" BOOLEAN NOT NULL DEFAULT false,
    "fecha_baja" DATE,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "equipos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "componentes" (
    "id" UUID NOT NULL,
    "equipo_id" UUID NOT NULL,
    "nombre" VARCHAR(200) NOT NULL,
    "codigo" VARCHAR(50),
    "detalle" JSONB,
    "activo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "componentes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lecturas" (
    "id" UUID NOT NULL,
    "equipo_id" UUID NOT NULL,
    "usuario_id" UUID,
    "tipo" VARCHAR(50) NOT NULL,
    "valor" DECIMAL(15,2) NOT NULL,
    "fecha" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notas" TEXT,

    CONSTRAINT "lecturas_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ubicaciones_sucursal_id_parent_id_idx" ON "ubicaciones"("sucursal_id", "parent_id");

-- CreateIndex
CREATE INDEX "equipos_ubicacion_id_idx" ON "equipos"("ubicacion_id");

-- CreateIndex
CREATE INDEX "equipos_sucursal_id_activo_idx" ON "equipos"("sucursal_id", "activo");

-- CreateIndex
CREATE UNIQUE INDEX "equipos_sucursal_id_codigo_key" ON "equipos"("sucursal_id", "codigo");

-- CreateIndex
CREATE INDEX "componentes_equipo_id_idx" ON "componentes"("equipo_id");

-- CreateIndex
CREATE INDEX "lecturas_equipo_id_fecha_idx" ON "lecturas"("equipo_id", "fecha");

-- AddForeignKey
ALTER TABLE "ubicaciones" ADD CONSTRAINT "ubicaciones_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ubicaciones" ADD CONSTRAINT "ubicaciones_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "ubicaciones"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipos" ADD CONSTRAINT "equipos_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipos" ADD CONSTRAINT "equipos_ubicacion_id_fkey" FOREIGN KEY ("ubicacion_id") REFERENCES "ubicaciones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipos" ADD CONSTRAINT "equipos_tipo_equipo_id_fkey" FOREIGN KEY ("tipo_equipo_id") REFERENCES "tipos_equipo"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "componentes" ADD CONSTRAINT "componentes_equipo_id_fkey" FOREIGN KEY ("equipo_id") REFERENCES "equipos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lecturas" ADD CONSTRAINT "lecturas_equipo_id_fkey" FOREIGN KEY ("equipo_id") REFERENCES "equipos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lecturas" ADD CONSTRAINT "lecturas_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
