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

### 4. Export modal passphrase ID collision

Both `ExportLabelsForm` (`labelbase/forms.py`) and `BackupFileForm`
(`importer/forms.py`) define a `passphrase` field, so Django rendered
both modals with `<input id="id_passphrase">` on the same page.
jQuery's `$("#id_passphrase")` in the export modal hit the (hidden)
import modal's input, leaving the visible export passphrase field
greyed out and forcing silent plaintext `.jsonl` downloads. Patch the
`labelbaseform_export` template tag with `form.auto_id = 'id_export_%s'`
and update the six selectors in `_modal_exportLabelbaseModal.html`.
POST field names are untouched, so `ExportLabelsView` still reads
`request.POST['passphrase']` directly.

### 5. `django/templates/_base.html` — honor `use_treemap` toggle

The sidebar renders a "Tree Map" link inside each labelbase. Upstream
wraps the sibling "Fiat Finances" and "Hashtags" links in
`{% if request.user.profile.use_* %}` guards, but forgot the one for
Tree Map — so the link showed up even when the user disabled the
extension under Profile → Extensions. Adding the matching guard makes
the toggle do what the UI promises.

### 6. `django/labellabor/views.py` — accept canonical xpub/tpub for BIP-49/84

`BitcoinAddressDatatableView.initialize_addresses()` originally matched
`(derivation, SLIP-132 prefix)` with a six-branch `if/elif`. A canonical
`xpub`/`tpub` (the form exported by Bitcoin Core, Sparrow's default and
Specter) paired with BIP-49 or BIP-84 didn't match any branch, every
iteration hit `continue`, and the address table rendered empty with no
error. The prefix now only decides mainnet vs testnet (`t/u/v` →
testnet); the derivation path decides the script type. Verified against
the official BIP-84 test vector.

### 7. `django/run.sh` + `django/umbrel_update_profile.py` — migrate existing Profiles

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
