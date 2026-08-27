# Cloudflare Tunnel Ingress — Source of Truth

This file is the **authoritative record** of what each Cloudflare Tunnel
routes to. It exists because tunnel ingress rules live in Cloudflare's
dashboard/API, not in this repo — `deploy.sh` and the nginx templates here
cannot see or manage them. When ingress rules and this repo's nginx config
disagree, requests 404/502 in ways that are invisible from the VPS or from
`git diff`. Keep this file updated whenever tunnel ingress changes, and check
it before editing `templates/nginx.template` or `deploy.sh`.

Last verified: 2026-08-27 (see full audit in project history — "joeysvault.app
Complete Technical Inventory").

## Tunnel 1: `joeysvault` (runs on the Contabo VPS)

| Property | Value |
|---|---|
| Tunnel ID | `52cb5b6d-a3a6-4b9a-8c24-6f12c42fee5c` |
| CNAME target | `52cb5b6d-a3a6-4b9a-8c24-6f12c42fee5c.cfargotunnel.com` |
| Runs on | Contabo VPS, `cloudflared` systemd service |
| Managed | Remotely (dashboard/API) — no local `config.yml` |

Ingress rules, evaluated top to bottom:

| # | Hostname | Service | TLS Verify | Origin |
|---|---|---|---|---|
| 1 | `joeysvault.app` | `https://localhost:443` | **skipped** (`noTLSVerify: true`) | nginx |
| 2 | `www.joeysvault.app` | `https://localhost:443` | **skipped** | nginx |
| 3 | `torrent.joeysvault.app` | `https://localhost:443` | **skipped** | nginx |
| 4 | `ha.joeysvault.app` | `http://localhost:8123` | n/a | Home Assistant |
| 5 | `project.joeysvault.app` | `http://127.0.0.1:8090` | n/a | (unlabeled service) |
| 6 | `ai.joeysvault.app` | `http://localhost:18080` | n/a | Open WebUI (direct, **not** via nginx) |
| 7 | `jellyfin.joeysvault.app` | `http://localhost:8096` | n/a | Jellyfin (direct, **not** via nginx) |
| 8 | catch-all | `http_status:404` | n/a | — |

**Why `noTLSVerify: true` is needed:** the origin cert at
`/etc/letsencrypt/live/jellyfin.joeysvault.app/` is issued for
`jellyfin.joeysvault.app`, but nginx serves `joeysvault.app`, `www`, and
`torrent` over that same cert. The hostname mismatch would otherwise fail
origin TLS validation. The correct long-term fix is a SAN cert covering all
proxied hostnames (or per-host certs); until then, do not remove
`noTLSVerify` from rules 1–3 without fixing the cert first.

**Why `ai` and `jellyfin` bypass nginx:** these route straight from the
tunnel to the backing service's port. `templates/nginx.template` has **no**
`/ai/` or `/media/`-equivalent block for these — `/media/` in nginx is a
*separate*, still-active proxy path to Jellyfin (`joeysvault.app/media/`),
distinct from the direct `jellyfin.joeysvault.app` route above. Both work
concurrently; don't assume removing one path removes access to Jellyfin.

## Tunnel 2: `embiz-laptop-ollama` (runs on the local laptop)

| Property | Value |
|---|---|
| Tunnel ID | `c7a370e0-025f-4f29-a123-79b071acc995` |
| CNAME target | `c7a370e0-025f-4f29-a123-79b071acc995.cfargotunnel.com` |
| Runs on | Local laptop, `cloudflared` |
| Managed | Remotely (dashboard/API) |

| # | Hostname | Service | Origin |
|---|---|---|---|
| 1 | `llm.joeysvault.app` | `http://127.0.0.1:11435` | `reasonix-ollama-native-proxy.py` (OpenAI-compatible API in front of local Ollama, `qwen3:8b`) |
| 2 | catch-all | `http_status:404` | — |

`llm.jupiterembroideryco.com.joeysvault.app` has a DNS CNAME to this tunnel
but no matching ingress rule — it hits the catch-all 404. This is dead DNS,
not a bug to fix by adding a rule; delete the DNS record if it's confirmed
unused.

## DNS → Tunnel map

All hostnames below are CNAMEs to one of the two tunnel targets above,
proxied (orange-clouded) through Cloudflare:

| Hostname | → Tunnel |
|---|---|
| `joeysvault.app`, `www`, `torrent`, `ha`, `project`, `ai`, `jellyfin`, `ssh` | `joeysvault` (VPS) |
| `llm`, `llm.jupiterembroideryco.com` (dead) | `embiz-laptop-ollama` (laptop) |
| `panel` | Cloudflare Pages (`joeysvault-panel.pages.dev`), not a tunnel |

## Known drift risk

`deploy.sh` and `templates/nginx.template` only ever manage the **nginx**
side of this system. Nothing in this repo can create, edit, or read tunnel
ingress rules — that must be done via `cloudflared tunnel ingress` /
the Cloudflare API/dashboard. Before changing what a `*.joeysvault.app`
hostname does:

1. Check this file for which tunnel + rule currently owns that hostname.
2. If the change is nginx-side (e.g. adjusting `/media/`), edit
   `templates/nginx.template` and re-run `deploy.sh`.
3. If the change is tunnel-side (e.g. pointing a hostname at a different
   port/service), update the tunnel ingress via the Cloudflare dashboard/API,
   **then update this file in the same change** so it stays accurate.
