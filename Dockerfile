FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        file \
        gcc \
        make \
        python3 \
        tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY docker/build.sh /usr/local/bin/challenge-build
RUN chmod 0755 /usr/local/bin/challenge-build

CMD ["/usr/local/bin/challenge-build"]
