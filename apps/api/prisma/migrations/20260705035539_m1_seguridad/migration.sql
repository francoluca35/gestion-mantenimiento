-- CreateEnum
CREATE TYPE "SupervisaSolicitudesOt" AS ENUM ('ninguna', 'de_su_sector', 'todas');

-- CreateTable
CREATE TABLE "sucursales" (
    "id" UUID NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "codigo" VARCHAR(20) NOT NULL,
    "activa" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "sucursales_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "perfiles" (
    "id" UUID NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "descripcion" TEXT,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "perfiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "derechos" (
    "id" UUID NOT NULL,
    "parent_id" UUID,
    "codigo" VARCHAR(100) NOT NULL,
    "nombre" VARCHAR(200) NOT NULL,
    "orden" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "derechos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "perfil_derechos" (
    "perfil_id" UUID NOT NULL,
    "derecho_id" UUID NOT NULL,
    "habilitado" BOOLEAN NOT NULL DEFAULT true,
    "modo_total" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "perfil_derechos_pkey" PRIMARY KEY ("perfil_id","derecho_id")
);

-- CreateTable
CREATE TABLE "usuarios" (
    "id" UUID NOT NULL,
    "nombre_usuario" VARCHAR(50) NOT NULL,
    "clave_hash" VARCHAR(255) NOT NULL,
    "email" VARCHAR(100),
    "sucursal_id" UUID,
    "sector_id" UUID,
    "perfil_id" UUID,
    "es_administrador" BOOLEAN NOT NULL DEFAULT false,
    "supervisa_sucursales" BOOLEAN NOT NULL DEFAULT false,
    "supervisa_solicitudes_ot" "SupervisaSolicitudesOt" NOT NULL DEFAULT 'ninguna',
    "supervisa_solicitudes_oc" BOOLEAN NOT NULL DEFAULT false,
    "monto_maximo_oc" DECIMAL(15,2),
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sesiones" (
    "id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "refresh_token_hash" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "revocada" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sesiones_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "sucursales_codigo_key" ON "sucursales"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "derechos_codigo_key" ON "derechos"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_nombre_usuario_key" ON "usuarios"("nombre_usuario");

-- CreateIndex
CREATE INDEX "sesiones_usuario_id_idx" ON "sesiones"("usuario_id");

-- AddForeignKey
ALTER TABLE "derechos" ADD CONSTRAINT "derechos_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "derechos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "perfil_derechos" ADD CONSTRAINT "perfil_derechos_perfil_id_fkey" FOREIGN KEY ("perfil_id") REFERENCES "perfiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "perfil_derechos" ADD CONSTRAINT "perfil_derechos_derecho_id_fkey" FOREIGN KEY ("derecho_id") REFERENCES "derechos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_sucursal_id_fkey" FOREIGN KEY ("sucursal_id") REFERENCES "sucursales"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_perfil_id_fkey" FOREIGN KEY ("perfil_id") REFERENCES "perfiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sesiones" ADD CONSTRAINT "sesiones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
