ARG GOLANG_VERSION=1.26.6
ARG ALPINE_VERSION=3.24.1

FROM golang:${GOLANG_VERSION} as awg
COPY . /awg
WORKDIR /awg
RUN go mod download && \
    go mod verify && \
    go build -ldflags '-linkmode external -extldflags "-fno-PIC -static"' -v -o /usr/bin

FROM alpine:${ALPINE_VERSION} as tools
ARG AWGTOOLS_COMMIT="ee0f0a9aa34ff0a0da4b3433b9512781cfe02843"

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
