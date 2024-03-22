# Start by building the application.
FROM golang:1.20.5-bullseye as build

# build libsodium (dep of libzmq)
WORKDIR /build
RUN wget https://github.com/jedisct1/libsodium/releases/download/1.0.19-RELEASE/libsodium-1.0.19.tar.gz
RUN tar -xzvf libsodium-1.0.19.tar.gz
WORKDIR /build/libsodium-stable
RUN ./configure --disable-shared --enable-static
RUN make -j`nproc`
RUN make install

# build libzmq (dep of zmq datastore)
WORKDIR /build
RUN wget https://github.com/zeromq/libzmq/releases/download/v4.3.4/zeromq-4.3.4.tar.gz
RUN tar -xvf zeromq-4.3.4.tar.gz
WORKDIR /build/zeromq-4.3.4
RUN ./configure --enable-static --disable-shared --disable-Werror
RUN make -j`nproc`
RUN make install

WORKDIR /go/src/fleet-telemetry

COPY . .
ENV CGO_ENABLED=1
ENV CGO_LDFLAGS="-lstdc++"

RUN make

# hadolint ignore=DL3006
FROM gcr.io/distroless/cc-debian11
# COPY --from=busybox:1.35.0-uclibc /bin/sh /bin/sh

WORKDIR /
COPY --from=build /go/bin/fleet-telemetry /

COPY test/integration/test-certs/ /etc/tesla/certs/server/ 
COPY test/integration/config.json /etc/tesla/
COPY test/integration/config.json /etc/fleet-telemetry/

CMD ["/fleet-telemetry", "-config", "/etc/fleet-telemetry/config.json"]
