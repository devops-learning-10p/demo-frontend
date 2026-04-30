# Stage 1: Build
FROM node:14-alpine AS builder

WORKDIR /app

# Копируем package.json и package-lock.json
COPY package*.json ./

# Используем npm install вместо npm ci (для старых lock-файлов)
RUN npm install --legacy-peer-deps

# Копируем исходники
COPY . .

# Сборка продакшн-версии (исправлено для Angular 7)
RUN npm run build -- --prod --output-path=dist/kanban-ui

# Stage 2: Nginx
FROM nginx:alpine

# Копируем конфиг nginx
COPY default.conf /etc/nginx/conf.d/default.conf

# Копируем собранное приложение (путь может отличаться)
COPY --from=builder /app/dist/kanban-ui /usr/share/nginx/html

# Non-root user для nginx (синтаксис Alpine)
RUN addgroup -g 1001 -S nginxuser && \
    adduser -u 1001 -S nginxuser -G nginxuser && \
    chown -R nginxuser:nginxuser /usr/share/nginx/html /etc/nginx/conf.d

USER nginxuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]