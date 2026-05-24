ARG BUILD_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-22.04

FROM ${BUILD_IMAGE} AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY . /work
RUN make runtime

FROM scratch

COPY --from=builder /work/runtime/ /

WORKDIR /home/ctf
EXPOSE 8000
ENTRYPOINT ["/app/launcher"]
