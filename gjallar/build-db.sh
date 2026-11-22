#!/bin/sh
# Build a Grype v6 vulnerability DB from public sources, entirely on your side.
#   PROVIDERS   space-separated Vunnel providers (default below)
#   OUT         output folder to serve over HTTP (default /data/out)
#   NVD_API_KEY optional, much faster NVD downloads
# Result: $OUT/databases/v6/latest.json + the archive it names. Serve $OUT and
# set GRYPE_DB_UPDATE_URL=http(s)://<host>/databases (grypeDB.updateUrl in the chart).
set -eu
PROVIDERS=${PROVIDERS:-"nvd alpine debian ubuntu rhel github"}
OUT=${OUT:-/data/out}
cd /data
for p in $PROVIDERS; do
  echo "==> vunnel run $p"
  vunnel run "$p"
done
# grype-db reads the providers Vunnel wrote under ./data/<provider>.
cfg=/tmp/grype-db.yaml
{ echo "provider:"; echo "  root: /data/data"; echo "  configs:"; for p in $PROVIDERS; do echo "    - name: $p"; done; } > "$cfg"
grype-db build -c "$cfg" --dir /data/build
grype-db package -c "$cfg" --dir /data/build
archive=$(ls -t /data/build/*.tar.* | head -1)
name=$(basename "$archive")
mkdir -p "$OUT/databases/v6"
cp "$archive" "$OUT/databases/v6/$name"
# The index Grype v6 reads: what to download and how to verify it.
schema=$(echo "$name" | sed -n 's/^vulnerability-db_\(v[0-9.]*\)_.*/\1/p')
sum=$(sha256sum "$archive" | cut -d' ' -f1)
cat > "$OUT/databases/v6/latest.json.tmp" <<JSON
{
 "status": "active",
 "schemaVersion": "${schema}",
 "built": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
 "path": "${name}",
 "checksum": "sha256:${sum}"
}
JSON
mv "$OUT/databases/v6/latest.json.tmp" "$OUT/databases/v6/latest.json"
ls -la "$OUT/databases/v6"
