FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app
RUN make

EXPOSE 8080
CMD ["./routerd"]
