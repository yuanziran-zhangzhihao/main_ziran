FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bc \
        bison \
        build-essential \
        busybox-static \
        ca-certificates \
        cpio \
        flex \
        gcc \
        gzip \
        kmod \
        libelf-dev \
        linux-headers-generic \
        linux-image-generic \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY docker/build.sh /usr/local/bin/challenge-build
RUN chmod 0755 /usr/local/bin/challenge-build

CMD ["/usr/local/bin/challenge-build"]
