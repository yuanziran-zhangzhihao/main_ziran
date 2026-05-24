ARG BUILD_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-22.04

FROM ${BUILD_IMAGE} AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY Makefile routerd.c ./
RUN make clean \
    && make STATIC=1

FROM scratch

WORKDIR /app
COPY --from=builder /src/routerd /app/routerd

EXPOSE 8080
CMD ["/app/routerd"]
