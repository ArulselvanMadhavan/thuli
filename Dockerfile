# syntax=docker/dockerfile:1

ARG FUTHARK_VERSION=0.26.4

FROM debian:bookworm-slim

ARG FUTHARK_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gcc \
    libc6-dev \
    libtinfo6 \
    make \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
    "https://github.com/diku-dk/futhark/releases/download/v${FUTHARK_VERSION}/futhark-${FUTHARK_VERSION}-linux-x86_64.tar.xz" \
    | tar -xJ -C /usr/local/bin --strip-components=2 \
      "futhark-${FUTHARK_VERSION}-linux-x86_64/bin/futhark"

WORKDIR /app
COPY . .

CMD ["/bin/bash"]
