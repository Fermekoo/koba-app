# Build Stage
FROM golang:1.22-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /bin/app main.go

# Run Stage
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /
COPY --from=builder /bin/app /bin/app

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/bin/app"]
