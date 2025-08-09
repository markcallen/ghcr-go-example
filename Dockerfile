# syntax=docker/dockerfile:1.6

########################################
# Builder
########################################
FROM golang:1.22-alpine AS builder
WORKDIR /src

# Build args for metadata
ARG GIT_SHA=unknown
ARG VERSION=dev
ARG BUILD_DATE=unknown

RUN apk add --no-cache ca-certificates upx

# Pre-cache modules
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

# Copy source
COPY . .

# Build static binary with build metadata
RUN --mount=type=cache,target=/go/pkg/mod CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-s -w -X 'main.version=${VERSION}' -X 'main.commitSHA=${GIT_SHA}' -X 'main.buildDate=${BUILD_DATE}'" -o /out/app ./cmd/app

# Optional: compress for tiny binaries
RUN upx -q /out/app || true

########################################
# Runtime
########################################
FROM gcr.io/distroless/static:nonroot

# OCI labels for traceability
ARG GIT_SHA=unknown
ARG VERSION=dev
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="everyday-devops-go-app" org.opencontainers.image.revision="${GIT_SHA}" org.opencontainers.image.version="${VERSION}" org.opencontainers.image.created="${BUILD_DATE}"

WORKDIR /app
COPY --from=builder /out/app /app/app

USER nonroot:nonroot

EXPOSE 8080
ENTRYPOINT ["/app/app"]
