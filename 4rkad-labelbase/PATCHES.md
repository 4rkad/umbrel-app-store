# Labelbase — 4rkad patches

The image shipped by this app is **not** the upstream `labelbase/django`
image. It is built from [`4rkad/labelbase-django`](https://github.com/4rkad/labelbase-django),
which is a fork of [`Labelbase/Labelbase`](https://github.com/Labelbase/Labelbase)
with a small patch set required to run Labelbase unattended inside Umbrel.

Published image: `ghcr.io/4rkad/labelbase-django:<version>-4rkad.<N>`
(multi-arch: `linux/amd64`, `linux/arm64`).

Each tag `v*-4rkad*` on the fork triggers a GitHub Actions workflow
that builds both architectures with `docker buildx` and pushes to
the registry above.

## Patch set

### 1. `django/Dockerfile` — run as uid 1000

Upstream image runs as root. Umbrel bind-mounts `media/`, `static/`,
`config.ini` and `labelbase.log` from the host data dir, which is
owned by uid 1000. Without this patch Django can't write to its own
data directory.

```
RUN chown -R 1000:1000 /app
USER 1000:1000
```

### 2. `django/labellabor/settings.py` — set `MEDIA_ROOT`

Upstream `settings.py` never defines `MEDIA_ROOT`, so Django falls
back to `''` and `FileField.upload_to` writes to `/app/<uuid>`. Inside
the container that path is root-owned, which made the Sparrow/JSONL
label import return HTTP 500. Patch appends:

```python
import os
MEDIA_ROOT = os.path.join(BASE_DIR, 'media/')
MEDIA_URL = '/media/'
```

so uploads land inside `/app/media/`, which is the writable bind mount.

### 3. `django/userprofile/models.py` — read Umbrel env on Profile creation

Upstream defaults for `Profile.mempool_endpoint`, `electrum_hostname`
and `electrum_ports` are public servers (`mempool.space`,
`electrum.emzy.de`). On Umbrel we want new users to default to the
host's own Electrs and Mempool apps. Patch swaps the string defaults
for callable defaults that read `UMBREL_ELECTRUM_HOSTNAME`,
`UMBREL_ELECTRUM_PORTS` and `UMBREL_MEMPOOL_ENDPOINT` from the
environment (compose injects these from `APP_ELECTRS_NODE_IP`,
`APP_MEMPOOL_IP:APP_MEMPOOL_PORT`).

### 4. `django/run.sh` + `django/umbrel_update_profile.py` — migrate existing Profiles

Callable defaults only affect rows created *after* this release.
`umbrel_update_profile.py` is a one-shot script added to `run.sh` that
walks every existing `Profile` row and, if its URL still matches the
upstream default (`https://mempool.space`, `electrum.emzy.de:s50002`),
rewrites it to the Umbrel values. Users who already customised their
endpoints are left alone.

## Not patched (upstream quirks we live with)

- `python manage.py makemigrations --noinput` in `run.sh` throws a
  PermissionError against `site-packages` because we run as uid 1000.
  Non-fatal — `migrate` still runs correctly right after.

- Gunicorn's `/.gunicorn` control socket warning is cosmetic and
  unrelated to the `--reload` mode upstream ships.
