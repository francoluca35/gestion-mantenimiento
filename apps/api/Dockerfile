# Build desde la raíz del monorepo:
#   docker build -f apps/api/Dockerfile -t sika-api .
FROM node:22-bookworm-slim AS deps
WORKDIR /app
COPY apps/api/package.json apps/api/package-lock.json ./
RUN npm ci

FROM node:22-bookworm-slim AS build
WORKDIR /app
RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*
COPY --from=deps /app/node_modules ./node_modules
COPY apps/api/ ./
RUN npx prisma generate && npm run build

# One-shot seed image (incluye ts-node / prisma)
FROM build AS seed
WORKDIR /app
ENV NODE_ENV=production
CMD ["npx", "prisma", "db", "seed"]

FROM node:22-bookworm-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV API_PORT=3000

RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl ca-certificates curl \
	&& rm -rf /var/lib/apt/lists/* \
	&& groupadd --system --gid 1001 nestjs \
	&& useradd --system --uid 1001 --gid nestjs nestjs \
	&& mkdir -p /app/storage /app/backups \
	&& chown -R nestjs:nestjs /app

# Dependencias de producción + Prisma CLI (migrate deploy)
COPY --from=deps /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev \
	&& npm install prisma@5.22.0 --no-save --omit=dev \
	&& npm cache clean --force

COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma/client ./node_modules/@prisma/client
COPY apps/api/docker/entrypoint.sh /entrypoint.sh

# sed quita CRLF por si el checkout de Windows convirtió los finales de línea
RUN sed -i 's/\r$//' /entrypoint.sh \
	&& chmod +x /entrypoint.sh \
	&& chown -R nestjs:nestjs /app

USER nestjs
EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=45s --retries=5 \
	CMD curl -fsS "http://127.0.0.1:${API_PORT:-3000}/v1/health" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "dist/src/main.js"]
