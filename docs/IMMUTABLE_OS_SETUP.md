# Skycom on Immutable OS (Distrobox + Docker + VS Code)

> **Scope**: generic Immutable OS (Bazzite, Silverblue, Bluefin, Aurora) with Bazzite callouts.
> Distrobox container: Ubuntu 22.04. Ruby 3.4.3 via **rbenv**. Follows `COMMANDS.md` + `docker-compose.yml`.

## 0. Why Distrobox

Immutable OS keeps `/usr` read-only — you cannot `dnf install ruby postgres` on the host.
All Skycom development happens **inside a Distrobox container**:

- Host stays clean (only Distrobox + exported VS Code launcher).
- Container holds Ruby, Docker, system libs, gems.
- `$HOME` is shared — the repo cloned on the host is visible in-box at the same path.
- Docker runs nested (container-in-container), so the `vfs` storage-driver fix in §3 is mandatory.

## 1. Prerequisites (host)

| Host | What to check |
|------|---------------|
| Bazzite | Distrobox is preinstalled. Verify with `distrobox --version`. |
| Silverblue / Bluefin / Aurora | Install Distrobox first (`rpm-ostree install distrobox` + reboot, or `brew install distrobox`). |
| All | Hardware virtualization enabled; ~20 GB free disk (images + gems + postgres data). |

No host Ruby, Postgres, or Redis needed — everything lives in the box + `docker compose`.

## 2. Part A — Container + Docker + VS Code

Run these on the **host**. This is the provided Bazzite guide, preserved verbatim with notes.

### 2.1 Remove existing Distrobox (if any)

```bash
distrobox stop dev
distrobox rm -f dev
```

### 2.2 Create new Distrobox with Ubuntu 22.04

```bash
distrobox create \
  --root \
  --image ubuntu:22.04 \
  --name dev \
  --init \
  --unshare-all \
  --additional-packages "systemd libpam-systemd" \
  --yes
```

Notes:

- `--init` + `systemd` is what lets `systemctl enable docker` work inside the box.
- `--root` matches the rest of this guide (`distrobox enter --root dev`). Rootless also works but then drop `sudo` and fix socket paths — not covered here.

### 2.3 Enter the container

```bash
distrobox enter --root dev
```

All steps from here (§2.4–§4) run **inside the box**.

### 2.4 Install Docker

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

Exit and re-enter for the group change to take effect:

```bash
exit
distrobox enter --root dev
```

### 2.5 Fix Docker storage driver (required for nested containers)

Overlayfs does not nest reliably, so force `vfs`:

```bash
sudo systemctl stop docker
sudo mkdir -p /etc/docker
echo '{
  "storage-driver": "vfs"
}' | sudo tee /etc/docker/daemon.json
sudo rm -rf /var/lib/docker/*
sudo systemctl start docker
```

> Warning: `rm -rf /var/lib/docker/*` wipes images in the box. Only run it right after creating the box.

### 2.6 Verify Docker

```bash
systemctl status docker
docker run hello-world
```

### 2.7 Install VS Code

```bash
sudo apt update
sudo apt install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt update
sudo apt install -y code
```

### 2.8 Export VS Code to host

```bash
distrobox-export --app code
```

- Always enter the container with: `distrobox enter --root dev`
- Docker starts automatically when the container starts (`systemctl enable docker` + `--init`).
- VS Code appears in the host application menu shortly after export.

## 3. Part B — Skycom inside the box

All commands below run **inside** `distrobox enter --root dev`.

### 3.1 Locate the repo (do not double-clone)

Distrobox shares `$HOME`, so a host clone is already visible in-box at the same path:

```bash
ls ~/Documents/skycom/docker-compose.yml
cd ~/Documents/skycom
```

If the repo is not there yet, clone it once (host or box — same filesystem):

```bash
git clone <skycom-remote-url> ~/Documents/skycom
cd ~/Documents/skycom
```

### 3.2 System dependencies

Runtime + build deps from `Dockerfile` (plus headers needed to compile Ruby 3.4.3):

```bash
sudo apt update
sudo apt install -y git curl build-essential pkg-config \
  libssl-dev zlib1g-dev libreadline-dev libyaml-dev \
  libsqlite3-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev \
  libpq-dev libjemalloc2 imagemagick postgresql-client \
  chromium chromium-driver
```

`chromium` covers `selenium-webdriver` system tests (`Gemfile` `:test` group).

### 3.3 Ruby 3.4.3 via rbenv

`.ruby-version` and `Dockerfile` both pin `3.4.3` — Ubuntu 22.04's apt ruby is too old for Rails 8, so use rbenv:

```bash
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
exec $SHELL
rbenv install 3.4.3
rbenv global 3.4.3
ruby -v   # => ruby 3.4.3
gem install bundler foreman
```

`foreman` is required by `bin/dev` (`Procfile.dev`: web + css + job).

### 3.4 Bundle install

```bash
cd ~/Documents/skycom
bundle install
```

### 3.5 Master key

Docker compose needs the Rails master key (see `COMMANDS.md`, `docker-compose.yml`):

```bash
ls config/master.key   # must exist; never commit it
export RAILS_MASTER_KEY=$(cat config/master.key)
```

Prefix every `docker compose` invocation with `RAILS_MASTER_KEY=$(cat config/master.key)` (shown below) or keep the export in the current shell.

### 3.6 Start infrastructure

```bash
RAILS_MASTER_KEY=$(cat config/master.key) docker compose up -d
docker compose ps
```

What comes up (`docker-compose.yml`):

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| postgres | `postgres:18.3` | 5432 | primary + queue DB (`config/database.yml`) |
| redis (valkey) | `valkey/valkey:9.1-alpine` | 6379 | Kredis counters, cache pub/sub (`config/redis/shared.yml`) |
| meilisearch | `getmeili/meilisearch:v1.53.1` | 7700 | dynamic search (`docs/MEILISEARCH.md`) |
| websocket | `centrifugo/centrifugo:v5` | 8000 | realtime (`docs/WEBSOCKET.md`) |
| minio | `minio/minio:latest` | 9000/9001 | S3-compatible storage + console |
| mock-api | `golang:1.22-alpine` | 4000 | mock bank gateway (`docs/MOCK_API.md`) |
| openobserve | `openobserve/openobserve:latest` | 5080 | logs/metrics |

The compose file already carries `:z` volume flags — keep them (SELinux on Atomic hosts).

### 3.7 Prepare DB and start Rails

```bash
bin/setup                 # bundle check + bin/rails db:prepare + log/tmp clear
bin/dev                   # web (Puma :3000) + css (tailwind watch) + job (solid queue)
```

`bin/setup` ends by exec'ing `bin/dev` unless passed `--skip-server`.

Seed with sample data when needed:

```bash
bin/rails db:seed   # Seed::ApplicationService (see docs/INIT_AND_ENRICH.md)
```

### 3.8 Verify

```bash
curl -f http://localhost:3000/up            # Rails health (or open http://localhost:3000)
curl -f http://localhost:7700/health        # Meilisearch
curl -f http://localhost:8000/health        # Centrifugo
curl -f http://localhost:4000/api/v1/ping   # Mock API
```

Browser checks: Rails `http://localhost:3000`, MinIO console `http://localhost:9001` (minioadmin/minioadmin), OpenObserve `http://localhost:5080`.

## 4. VS Code workflow

- Launch the exported **VS Code** from the host app menu, then File → Open Folder → `/var/home/<you>/Documents/skycom` (same path as `~/Documents/skycom` in-box).
- Recommended extensions (install inside VS Code): Ruby LSP, Tailwind CSS IntelliSense, EditorConfig.
- Editing credentials from the box (per `COMMANDS.md`):

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

If `code` is not on PATH in-box, run `distrobox-export --app code` again or use `EDITOR=nano`.

## 5. Daily workflow

```bash
distrobox enter --root dev
cd ~/Documents/skycom
RAILS_MASTER_KEY=$(cat config/master.key) docker compose up -d
bin/dev
```

- Run git inside the box so SSH/GPG and line endings stay consistent.
- Host ports are shared with the box — open `http://localhost:3000` in the host browser.
- Stop infra when done: `docker compose stop` (keeps data volumes).

## 6. Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `docker: permission denied` | Group change not applied → `exit`, then `distrobox enter --root dev` again (§2.4). |
| Docker fails to start / overlay errors | `vfs` fix missing → redo §2.5, check `/etc/docker/daemon.json`. |
| `connection refused` on `:4000` | Mock API container down → `docker compose restart mock-api` (`docs/MOCK_API.md` §8). |
| `connection refused` on `:7700` | Meilisearch down → `docker compose up -d meilisearch` (`docs/MEILISEARCH.md` §10). |
| `RAILS_MASTER_KEY` / credentials error | `config/master.key` missing or env prefix forgotten → redo §3.5. |
| Port conflict (`:5432`, `:6379`) | A host-level postgres/redis is running → stop the host service or remap ports. |
| `tmp/pids/server.pid` stale | Normally auto-removed by the compose `web` command; else `rm -f tmp/pids/server.pid`. |
| SELinux denials on volumes | Ensure `:z` flags intact in `docker-compose.yml`; never remove them on Atomic hosts. |
| RSpec suite DB | Use `docker-compose.rspec-test.yml` per `COMMANDS.md:10`, not the dev compose file. |
| Seed run | Use `docker-compose.seed-test.yml` per `COMMANDS.md:8`. |

## 7. File Reference

| File | Why it matters here |
|------|---------------------|
| `docker-compose.yml` | All infra services, ports, `RAILS_MASTER_KEY` wiring |
| `docker-compose.rspec-test.yml` / `docker-compose.seed-test.yml` | Test + seed compose variants (`COMMANDS.md:8-10`) |
| `Dockerfile` | `RUBY_VERSION=3.4.3`, apt deps mirrored in §3.2 |
| `.ruby-version` | Ruby pin consumed by rbenv |
| `Gemfile` | Rails 8.0.4, pg/sqlite, selenium (needs chromium) |
| `config/database.yml` | pg primary/queue (needs postgres :5432), sqlite cache/cable |
| `config/redis/shared.yml` | Redis URL default `redis://127.0.0.1:6379/0` |
| `config/initializers/meilisearch.rb` | Host default `http://localhost:7700` |
| `Procfile.dev` / `bin/dev` | foreman web + css + job |
| `bin/setup` | bundle + `db:prepare` entry point |
| `COMMANDS.md` | canonical compose + credentials commands |
| `docs/MOCK_API.md` §8 | mock-api troubleshooting |
| `docs/MEILISEARCH.md` §10 | meilisearch pitfalls |
| `docs/INIT_AND_ENRICH.md` | what `db:seed` creates |

---

*End of document*
