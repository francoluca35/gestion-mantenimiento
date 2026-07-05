-- Esquemas base al levantar PostgreSQL por primera vez
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;

-- Extensiones útiles
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
