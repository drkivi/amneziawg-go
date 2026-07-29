ARG GOLANG_VERSION=1.26.5
ARG ALPINE_VERSION=3.24.1

FROM golang:${GOLANG_VERSION} as awg
COPY . /awg
WORKDIR /awg
RUN go mod download && \
    go mod verify && \
    go build -ldflags '-linkmode external -extldflags "-fno-PIC -static"' -v -o /usr/bin

# No alpine-3.24 zip is published under amneziawg-tools releases (only 3.19/ubuntu-22.04/windows),
# so build from source instead of a prebuilt zip to avoid a musl ABI mismatch.
# AWGTOOLS_COMMIT corresponds to release v1.0.20260618-2, the latest as of 2026-07-29.
FROM alpine:${ALPINE_VERSION} as tools
ARG AWGTOOLS_COMMIT="61e741780e8465a67a7d7fb6cffe14a8a15d624a"

RUN apk add --no-cache git build-base linux-headers && \
    git clone https://github.com/amnezia-vpn/amneziawg-tools.git /amneziawg-tools && \
    cd /amneziawg-tools && git checkout ${AWGTOOLS_COMMIT} && \
    cd src && make

FROM alpine:${ALPINE_VERSION}

RUN apk --no-cache add iproute2 iptables bash
COPY --from=tools /amneziawg-tools/src/wg /usr/bin/awg
COPY --from=tools /amneziawg-tools/src/wg-quick/linux.bash /usr/bin/awg-quick
RUN chmod +x /usr/bin/awg /usr/bin/awg-quick && \
    ln -s /usr/bin/awg /usr/bin/wg && \
    ln -s /usr/bin/awg-quick /usr/bin/wg-quick
COPY --from=awg /usr/bin/amneziawg-go /usr/bin/amneziawg-go
