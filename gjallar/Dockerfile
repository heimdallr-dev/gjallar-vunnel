# Gjallar's self-hosted Grype DB builder: Vunnel (built from this fork's own
# source) + grype-db, pinned and checksum-verified. Output is a directory you
# serve over HTTP and point Grype at (GRYPE_DB_UPDATE_URL / grypeDB.updateUrl).
# docker build -f gjallar/Dockerfile -t gjallar-vunnel .
FROM python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS wheel
ARG VUNNEL_VERSION=0.68.0
WORKDIR /src
COPY . .
# Version from the pinned tag, not from git metadata (deterministic, no .git needed).
RUN UV_DYNAMIC_VERSIONING_BYPASS=${VUNNEL_VERSION} pip wheel --no-deps -w /dist .

FROM python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39
ARG GRYPE_DB_VERSION=0.55.0
ARG TARGETARCH
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN set -eux; apt-get update; apt-get install -y --no-install-recommends git curl ca-certificates zstd; rm -rf /var/lib/apt/lists/*; \
    cd /tmp; f="grype-db_${GRYPE_DB_VERSION}_linux_${TARGETARCH}.tar.gz"; base="https://github.com/anchore/grype-db/releases/download/v${GRYPE_DB_VERSION}"; \
    curl -sSfLO "$base/$f"; curl -sSfL "$base/grype-db_${GRYPE_DB_VERSION}_checksums.txt" | grep " ${f}\$" | sha256sum -c -; \
    tar -xzf "$f" -C /usr/local/bin grype-db; rm "$f"; \
    git config --system safe.directory '*'; useradd -u 65532 -m builder
COPY --from=wheel /dist /dist
RUN pip install --no-cache-dir /dist/vunnel-*.whl && vunnel --version && grype-db version
COPY gjallar/build-db.sh /usr/local/bin/build-db
USER 65532
WORKDIR /data
ENTRYPOINT ["build-db"]
LABEL org.opencontainers.image.source="https://github.com/heimdallr-dev/gjallar-vunnel" \
      org.opencontainers.image.description="Self-hosted Grype vulnerability DB builder (Vunnel + grype-db) for Gjallar" \
      org.opencontainers.image.licenses="Apache-2.0"
