FROM node:14-alpine AS builder

WORKDIR /app

ENV NPM_CONFIG_LOGLEVEL=error

COPY package*.json ./
RUN npm install --legacy-peer-deps --no-audit --no-fund

COPY . .
RUN npm run build -- --prod --output-path=dist/kanban-ui

FROM nginx:alpine

# Создаём пользователя и группу
RUN addgroup -g 1001 -S nginxuser && \
    adduser -u 1001 -S nginxuser -G nginxuser

# Создаём необходимые директории и выставляем права
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx && \
    chown -R nginxuser:nginxuser /var/cache/nginx /var/run /var/log/nginx && \
    chown -R nginxuser:nginxuser /etc/nginx /usr/share/nginx/html

# Копируем конфиг и статику
COPY default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist/kanban-ui /usr/share/nginx/html

# Убеждаемся, что все файлы принадлежат nginxuser
RUN chown -R nginxuser:nginxuser /usr/share/nginx/html /etc/nginx/conf.d

# Переключаемся на non-root пользователя
USER nginxuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]