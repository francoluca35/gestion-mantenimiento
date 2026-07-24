-- Preparación OT: lectura obligatoria + decisión materiales + pedidos vinculados
DO $$ BEGIN
	CREATE TYPE "DecisionMaterialesOt" AS ENUM ('pendiente', 'no_necesita', 'necesita');
EXCEPTION
	WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "ordenes_trabajo"
	ADD COLUMN IF NOT EXISTS "lectura_registrada_at" TIMESTAMPTZ(6),
	ADD COLUMN IF NOT EXISTS "decision_materiales" "DecisionMaterialesOt" NOT NULL DEFAULT 'pendiente',
	ADD COLUMN IF NOT EXISTS "materiales_texto_libre" TEXT;

ALTER TABLE "pedidos_stock"
	ADD COLUMN IF NOT EXISTS "ot_id" UUID;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint WHERE conname = 'pedidos_stock_ot_id_fkey'
	) THEN
		ALTER TABLE "pedidos_stock"
			ADD CONSTRAINT "pedidos_stock_ot_id_fkey"
			FOREIGN KEY ("ot_id") REFERENCES "ordenes_trabajo"("id")
			ON DELETE SET NULL ON UPDATE CASCADE;
	END IF;
END $$;

CREATE INDEX IF NOT EXISTS "pedidos_stock_ot_id_idx" ON "pedidos_stock"("ot_id");
