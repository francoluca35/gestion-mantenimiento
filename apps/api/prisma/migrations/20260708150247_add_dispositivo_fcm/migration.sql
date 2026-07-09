-- CreateTable
CREATE TABLE "dispositivos_fcm" (
    "id" UUID NOT NULL,
    "token" VARCHAR(500) NOT NULL,
    "usuario_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "dispositivos_fcm_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "dispositivos_fcm_token_key" ON "dispositivos_fcm"("token");

-- CreateIndex
CREATE INDEX "dispositivos_fcm_usuario_id_idx" ON "dispositivos_fcm"("usuario_id");

-- AddForeignKey
ALTER TABLE "dispositivos_fcm" ADD CONSTRAINT "dispositivos_fcm_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
