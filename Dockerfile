ARG CARGO_HOME=/cargo/
ARG BUILD_IMAGE="rust:1.96.0-slim-bullseye"
ARG BUILDPLATFORM
FROM --platform="${BUILDPLATFORM}" "${BUILD_IMAGE}" AS base
FROM base AS builder
FROM base AS helper

FROM helper AS srcfetcher
ARG RUSTIC_REPO="https://github.com/rustic-rs/rustic.git"
ARG RUSTIC_VERSION="main"
RUN apt-get update && apt-get -y install git
WORKDIR /src/
RUN git clone "${RUSTIC_REPO}" && git -C /src/rustic/ checkout "${RUSTIC_VERSION}"

FROM helper AS cratefetcher
COPY --from=srcfetcher /src/rustic/Cargo.toml /src/rustic/Cargo.lock /src/
ARG CARGO_HOME
ENV CARGO_HOME="${CARGO_HOME}"
WORKDIR /src/
RUN mkdir -pv "${CARGO_HOME}" && cargo fetch --verbose

FROM builder AS appbuilder
ARG TARGETPLATFORM
ARG CARGO_HOME
ENV CARGO_HOME="${CARGO_HOME}"
WORKDIR /src/
COPY --from=cratefetcher "${CARGO_HOME}" "${CARGO_HOME}"
COPY --from=srcfetcher /src/rustic /src/
COPY build.sh .
RUN chmod +x build.sh && ./build.sh

FROM scratch
COPY --from=appbuilder "/rustic" /
ENTRYPOINT ["/rustic"]
