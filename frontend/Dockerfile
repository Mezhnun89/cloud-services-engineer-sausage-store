FROM node:22-alpine AS builder
WORKDIR /src
COPY package*.json ./
RUN npm ci --legacy-peer-deps --ignore-scripts
COPY . .
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build -- --configuration=production
FROM nginx:1.28-alpine
COPY --from=builder /src/dist/frontend /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
USER 101
EXPOSE 8080
ENTRYPOINT ["nginx", "-e", "/dev/stderr", "-g", "daemon off;"]
