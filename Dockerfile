ARG CARGO_HOME=/cargo/
ARG BASE_IMAGE_TAG=1.86.0-slim-bullseye
ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM "rust:${BASE_IMAGE_TAG}" AS base
FROM base AS helper
FROM helper AS etcbuilder
RUN mkdir /etc_files && \
  touch /etc_files/passwd && \
  touch /etc_files/group

FROM helper AS srcfetcher
ARG RUSTIC_VERSION="main"
RUN apt-get update && apt-get -y install git
WORKDIR /src/
RUN git clone https://github.com/rustic-rs/rustic.git && git -C /src/rustic/ checkout "${RUSTIC_VERSION}"

FROM helper AS cratefetcher
COPY --from=srcfetcher /src/rustic/Cargo.toml /src/rustic/Cargo.lock /src/
ARG CARGO_HOME
ENV CARGO_HOME="${CARGO_HOME}"
WORKDIR /src/
RUN mkdir -pv "${CARGO_HOME}" && cargo fetch --verbose

FROM base AS appbuilder
ARG TARGETPLATFORM
ARG CARGO_HOME
ENV CARGO_HOME="${CARGO_HOME}"
WORKDIR /src/
COPY --from=cratefetcher "${CARGO_HOME}" "${CARGO_HOME}"
COPY --from=srcfetcher /src/rustic /src/
COPY build.sh .
RUN chmod +x build.sh && ./build.sh

FROM scratch
COPY --from=etcbuilder /etc_files/ /etc/
COPY --from=appbuilder "/rustic" /
ENTRYPOINT ["/rustic"]
