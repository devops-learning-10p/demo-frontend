# Stage 1: Build Angular
FROM node:16-alpine AS builder

WORKDIR /app

# Копируем package.json и package-lock.json
COPY package*.json ./

# Устанавливаем зависимости
RUN npm ci --legacy-peer-deps

# Копируем исходники
COPY . .

# Сборка продакшн-версии
RUN npm run build -- --prod

# Stage 2: Nginx для отдачи статики
FROM nginx:alpine

# Копируем существующий конфиг (не создаём новый!)
COPY default.conf /etc/nginx/conf.d/default.conf

# Копируем собранное приложение
COPY --from=builder /app/dist/kanban-ui /usr/share/nginx/html

# Non-root user для nginx
RUN addgroup -g 1001 -S nginxuser && \
    adduser -u 1001 -S nginxuser -G nginxuser && \
    chown -R nginxuser:nginxuser /usr/share/nginx/html /etc/nginx/conf.d

USER nginxuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]