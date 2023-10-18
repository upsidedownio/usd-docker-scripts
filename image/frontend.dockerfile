# Build environment
FROM node:18 as builder
ARG BUILD_STREAM=dev
#ENV PATH /app/node_modules/.bin:$PATH
COPY .. /app
WORKDIR /app
RUN npm ci
RUN npm run build:libs
RUN npm run build:frontend

# Production environment
FROM nginx:1.19
COPY --from=builder /app/apps/salkka_frontend/dist /usr/share/nginx/html
COPY --from=builder /app/apps/salkka_frontend/nginx.conf /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
