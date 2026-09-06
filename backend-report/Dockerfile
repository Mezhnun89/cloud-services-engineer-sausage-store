FROM golang:1.26-alpine3.23 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go test ./... && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /report .
FROM alpine:3.23
RUN apk add --no-cache ca-certificates && addgroup -S app && adduser -S -G app -u 10001 app
COPY --from=builder /report /app/report
USER 10001
EXPOSE 8080
ENTRYPOINT ["/app/report"]
