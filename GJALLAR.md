# gjallar-vunnel

A fork of [anchore/vunnel](https://github.com/anchore/vunnel) (Apache-2.0,
Copyright Anchore, Inc.) used by [Gjallar](https://github.com/heimdallr-dev/gjallar)
to **build the Grype vulnerability database yourself**, from public sources, on
your own infrastructure. Nothing about your images leaves your network: Vunnel
only downloads public advisory feeds, and Grype reads the result from your
own HTTP server.

Upstream code is unchanged; this fork adds only `gjallar/`:

| File | What it does |
|---|---|
| `gjallar/Dockerfile` | Image with Vunnel built from this fork's source and `grype-db` (pinned, checksum-verified), non-root |
| `gjallar/build-db.sh` | Runs the providers, builds and packages a Grype v6 DB, writes `databases/v6/latest.json` |
| `.github/workflows/gjallar-image.yml` | Builds, signs (Sigstore) and attests the image |

## Use it

```bash
docker build -f gjallar/Dockerfile -t gjallar-vunnel .
docker run --rm -e PROVIDERS="alpine debian ubuntu github" -e NVD_API_KEY=... -v $PWD/data:/data gjallar-vunnel
# serve ./data/out over HTTP, then:
GRYPE_DB_UPDATE_URL=http://<host>/databases grype db update
```

In the Gjallar Helm chart: `cronjobs.vunnel.enabled=true` runs this image on a
schedule; set `grypeDB.updateUrl` to wherever you serve the output.

Verified 2026-11-22: provider `alpine` → DB schema v6.1.10 → `grype db update`
from a local HTTP server → status valid.

## Stay in sync with upstream

```bash
git remote add upstream https://github.com/anchore/vunnel.git
git fetch upstream --tags
git rebase <new-upstream-tag>      # gjallar/ never conflicts with upstream files
```
Bump `VUNNEL_VERSION` in `gjallar/Dockerfile` to the new tag.

## Licence and credit

Vunnel is © Anchore, Inc., licensed under Apache-2.0 (see `LICENSE`,
`COPYRIGHT`, `CONTRIBUTORS.md`). The Gjallar additions are Apache-2.0 too.
Report Vunnel bugs upstream; report issues with `gjallar/` here.
