-- CreateEnum
CREATE TYPE "TipoMantenimiento" AS ENUM ('preventivo', 'predictivo', 'correctivo', 'mejora');

-- CreateEnum
CREATE TYPE "EstadoOt" AS ENUM ('necesaria_de_emitir', 'pendiente', 'pendiente_panol', 'en_ejecucion', 'realizada', 'anulada');

-- CreateEnum
CREATE TYPE "PrioridadOt" AS ENUM ('baja', 'media', 'alta', 'urgente');

-- CreateEnum
CREATE TYPE "PeriodicidadTipo" AS ENUM ('tiempo', 'contador');

-- CreateEnum
CREATE TYPE "EstadoProcedimientoEquipo" AS ENUM ('activo', 'suspendido', 'baja');

-- CreateEnum
CREATE TYPE "EstadoSolicitudTrabajo" AS ENUM ('pendiente', 'conformada', 'rechazada');

-- AlterTable
ALTER TABLE "lecturas" ADD COLUMN     "ot_id" UUID;

-- CreateTable
CREATE TABLE "procedimientos" (
    "id" UUID NOT NULL,
    "sucursal_id" UUID NOT NULL,
    "nombre" VARCHAR(200) NOT NULL,
    "tipo" "TipoMantenimiento" NOT NULL,
    "descripcion" TEXT,
    "planilla_lecturas" JSONB NOT NULL DEFAULT '[]',
    "periodicidad_tipo" "PeriodicidadTipo",
    "periodicidad_valor" INTEGER,
    "duracion_estimada" INTEGER,
    "hs_hombre" DECIMAL(8,2),
    "version_actual" INTEGER NOT NULL DEFAULT 1,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "procedimientos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "procedimiento_equipos" (
    "id" UUID NOT NULL,
    "procedimiento_id" UUID NOT NULL,
    "equipo_id" UUID NOT NULL,
    "estado" "EstadoProcedimientoEquipo" NOT NULL DEFAULT 'activo',
    "fecha_asociacion" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ultima_emision" DATE,

    CONSTRAINT "procedimiento_equipos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ordenes_trabajo" (
    "id" UUID NOT NULL,
    "numero" SERIAL NOT NULL,
    "sucursal_id" UUID NOT NULL,
    "ubicacion_id" UUID NOT NULL,
    "equipo_id" UUID NOT NULL,
    "procedimiento_id" UUID,
    "tipo" "TipoMantenimiento" NOT NULL,
    "estado" "EstadoOt" NOT NULL DEFAULT 'pendiente',
    "tecnico_asignado_id" UUID,
    "creador_id" UUID,
    "fecha_programacion" DATE NOT NULL,
    "fecha_ejecucion" DATE,
    "tolerancia" INTEGER NOT NULL DEFAULT 0,
    "prioridad" "PrioridadOt" NOT NULL DEFAULT 'media',
    "comentarios" TEXT,
    "novedades_fuera_de_programa" TEXT,
    "checklist_completado" JSONB NOT NULL DEFAULT '[]',
    "firma_digital" TEXT,
    "fotos" JSONB NOT NULL DEFAULT '[]',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "ordenes_trabajo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ot_estado_historial" (
    "id" UUID NOT NULL,
    "ot_id" UUID NOT NULL,
    "estado" "EstadoOt" NOT NULL,
    "usuario_id" UUID,
    "comentario" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ot_estado_historial_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "solicitudes_trabajo" (
    "id" UUID NOT NULL,
    "sucursal_id" UUID NOT NULL,
    "solicitante" VARCHAR(200) NOT NULL,
    "descripcion" TEXT NOT NULL,
    "urgente" BOOLEAN NOT NULL DEFAULT false,
    "estado" "EstadoSolicitudTrabajo" NOT NULL DEFAULT 'pendiente',
    "ot_generada_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "solicitudes_trabajo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "historial_equipo" (
    "id" UUID NOT NULL,
    "equipo_id" UUID NOT NULL,
    "ot_id" UUID,
    "tipo_evento" VARCHAR(50) NOT NULL,
    "descripcion" TEXT NOT NULL,
    "fecha" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_id" UUID,

    CONSTRAINT "historial_equipo_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "procedimientos_sucursal_id_activo_idx" ON "procedimientos"("sucursal_id", "activo");

-- CreateIndex
CREATE UNIQUE INDEX "procedimiento_equipos_procedimiento_id_equipo_id_key" ON "procedimiento_equipos"("procedimiento_id", "equipo_id");

-- CreateIndex
CREATE UNIQUE INDEX "ordenes_trabajo_numero_key" ON "ordenes_trabajo"("numero");

-- CreateIndex
CREATE INDEX "ordenes_trabajo_sucursal_id_estado_idx" ON "ordenes_trabajo"("sucursal_id", "estado");

-- CreateIndex
CREATE INDEX "ordenes_trabajo_tecnico_asignado_id_estado_idx" ON "ordenes_trabajo"("tecnico_asignado_id", "estado");

-- CreateIndex
CREATE INDEX "ordenes_trabajo_equipo_id_idx" ON "ordenes_trabajo"("equipo_id");

-- CreateIndex
CREATE INDEX "ot_estado_historial_ot_id_created_at_idx" ON "ot_estado_historial"("ot_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "solicitudes_trabajo_ot_generada_id_key" ON "solicitudes_trabajo"("ot_generada_id");

-- CreateIndex
CREATE INDEX "solicitudes_trabajo_sucursal_id_estado_idx" ON "solicitudes_trabajo"("sucursal_id", "estado");

-- CreateIndex
CREATE INDEX "historial_equipo_equipo_id_fecha_idx" ON "historial_equipo"("equipo_id", "fecha");

-- AddForeignKey
ALTER TABLE "lecturas" ADD CONSTRAINT "lecturas_ot_id_fkey" FOREIGN KEY ("ot_id") REFERENCES "ordenes_trabajo"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "procedimientos" ADD CONSTRAINT "procedimientos_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "procedimiento_equipos" ADD CONSTRAINT "procedimiento_equipos_procedimiento_id_fkey" FOREIGN KEY ("procedimiento_id") REFERENCES "procedimientos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "procedimiento_equipos" ADD CONSTRAINT "procedimiento_equipos_equipo_id_fkey" FOREIGN KEY ("equipo_id") REFERENCES "equipos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_ubicacion_id_fkey" FOREIGN KEY ("ubicacion_id") REFERENCES "ubicaciones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_equipo_id_fkey" FOREIGN KEY ("equipo_id") REFERENCES "equipos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_procedimiento_id_fkey" FOREIGN KEY ("procedimiento_id") REFERENCES "procedimientos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_tecnico_asignado_id_fkey" FOREIGN KEY ("tecnico_asignado_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordenes_trabajo" ADD CONSTRAINT "ordenes_trabajo_creador_id_fkey" FOREIGN KEY ("creador_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ot_estado_historial" ADD CONSTRAINT "ot_estado_historial_ot_id_fkey" FOREIGN KEY ("ot_id") REFERENCES "ordenes_trabajo"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ot_estado_historial" ADD CONSTRAINT "ot_estado_historial_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_trabajo" ADD CONSTRAINT "solicitudes_trabajo_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitudes_trabajo" ADD CONSTRAINT "solicitudes_trabajo_ot_generada_id_fkey" FOREIGN KEY ("ot_generada_id") REFERENCES "ordenes_trabajo"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historial_equipo" ADD CONSTRAINT "historial_equipo_equipo_id_fkey" FOREIGN KEY ("equipo_id") REFERENCES "equipos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historial_equipo" ADD CONSTRAINT "historial_equipo_ot_id_fkey" FOREIGN KEY ("ot_id") REFERENCES "ordenes_trabajo"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historial_equipo" ADD CONSTRAINT "historial_equipo_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
