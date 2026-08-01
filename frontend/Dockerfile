# ── Stage 1: dependency installer ─────────────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

# Copy lockfiles first to maximise layer cache reuse
COPY package.json package-lock.json* ./
RUN npm ci --ignore-scripts


# ── Stage 2: build ────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Receive build-time API URL (can be overridden via docker-compose build args)
ARG NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Copy deps from previous stage
COPY --from=deps /app/node_modules ./node_modules

# Copy all source files
COPY . .

# Build the Next.js production bundle
RUN npm run build


# ── Stage 3: production runner ────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy only what Next.js needs to run
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

# Health check — verifies the Next.js server responds
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD wget -qO- http://localhost:3000/ || exit 1

CMD ["node", "server.js"]
