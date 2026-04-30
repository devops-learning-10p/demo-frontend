FROM node:14-alpine AS builder

WORKDIR /app

ENV NPM_CONFIG_LOGLEVEL=error

COPY package*.json ./
RUN npm install --legacy-peer-deps --no-audit --no-fund

COPY . .
RUN npm run build -- --prod --output-path=dist/kanban-ui

FROM nginx:alpine

# Создаём пользователя
RUN addgroup -g 1001 -S nginxuser && \
    adduser -u 1001 -S nginxuser -G nginxuser

# Создаём все необходимые директории и выставляем права
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx /run && \
    chown -R nginxuser:nginxuser /var/cache/nginx /var/run /var/log/nginx /run && \
    chown -R nginxuser:nginxuser /etc/nginx /usr/share/nginx/html

# Копируем конфиг и статику
COPY default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist/kanban-ui /usr/share/nginx/html

# Убираем директиву user из основного конфига nginx (она не нужна при non-root)
RUN sed -i 's/^user[[:space:]]\+nginx;/#user nginx;/' /etc/nginx/nginx.conf

# Переключаемся на non-root пользователя
USER nginxuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]