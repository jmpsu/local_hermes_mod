# local_hermes_mod

Portable Local + Edge/Cloud Infrastructure for a Privacy-First AI Ecosystem.

## Architecture

- **Local Compute Node**: Ubuntu Linux (x86_64), Docker Engine, NVIDIA Container Toolkit, vLLM Engine (Qwen/Qwen2.5-32B-Instruct-AWQ or hardware-bounded alternative)
- **Public Gateway Node**: Contabo VPS, Nginx Reverse Proxy (500MB payload), Open WebUI, Qdrant Vector DB
- **Network & Storage**: Cloudflare Tunnels, Cloudflare Edge Rules, Amazon S3 backups

## Activation

```bash
git clone git@github.com:jmpsu/local_hermes_mod.git
cd local_hermes_mod
chmod +x deploy.sh
./deploy.sh
```

## Endpoints (post-deployment)

| Service | URL | Backend |
|---------|-----|---------|
| Landing page | `https://joeysvault.app/` | `/var/www/joeysvault_app/index.html` |
| AI Interface | `https://joeysvault.app/ai/` | `http://127.0.0.1:8080` (Open WebUI) |
| Jellyfin Media | `https://joeysvault.app/media/` | `http://127.0.0.1:8096` (Jellyfin) |

## Landing Page

`https://joeysvault.app` is now a standalone HTML page (`templates/index.template`):

- Full-screen looping astrophotography timelapse background (YouTube `XrQwK9w2OLQ`)
- Two centered links in **Ubuntu 20px** font: **AI** → `/ai/` and **Media** → `/media/`
- Nothing else — no nav bar, no login form, no chrome

The old behaviour of the root URL proxying directly to Jellyfin is replaced by `/media/`.

---

## Cloudflare Tunnel Setup

The tunnel currently sends `joeysvault.app` traffic directly to Jellyfin on port 8096.
**You must update it to point to nginx on port 80** so nginx can route `/`, `/ai/`, and `/media/` correctly.

### Step-by-step — run these on the Contabo VPS

```bash
# 1. SSH in
ssh contabo

# 2. Find your tunnel ID
sudo cloudflared tunnel list

# 3. Rewrite /etc/cloudflared/config.yml
#    Replace <YOUR_TUNNEL_ID> with the ID from step 2
sudo tee /etc/cloudflared/config.yml > /dev/null <<'EOF'
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /root/.cloudflared/<YOUR_TUNNEL_ID>.json
ingress:
  - hostname: joeysvault.app
    service: http://localhost:80
  - hostname: www.joeysvault.app
    service: http://localhost:80
  - service: http_status:404
EOF

# 4. Validate the new config
sudo cloudflared tunnel ingress validate

# 5. Restart the tunnel
sudo systemctl restart cloudflared

# 6. Ensure DNS CNAMEs exist in Cloudflare (idempotent — safe to re-run)
sudo cloudflared tunnel route dns <YOUR_TUNNEL_ID> joeysvault.app
sudo cloudflared tunnel route dns <YOUR_TUNNEL_ID> www.joeysvault.app
```

After these steps nginx handles all requests and routes them as:

```
/          → landing page (timelapse + AI / Media links)
/ai/       → http://127.0.0.1:8080   (Open WebUI)
/media/    → http://127.0.0.1:8096   (Jellyfin)
```

### Verifying /ai/ is live

Open WebUI must be running and bound to `127.0.0.1:8080` on the VPS:

```bash
# Check
ss -tlnp | grep 8080

# Start if missing
docker run -d --name open-webui \
  -p 127.0.0.1:8080:8080 \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

---

## File Structure

```
local_hermes_mod/
├── .gitignore
├── deploy.sh
├── README.md
├── templates/
│   ├── docker-compose.local.template
│   ├── docker-compose.vps.template
│   ├── nginx.template          ← landing page root + /ai/ + /media/ blocks
│   ├── index.template          ← fullscreen timelapse landing page HTML
│   └── s3-sync.template.sh
└── core/                       ← generated at runtime, git-ignored
```

## Prerequisites

- Local: x86_64 Ubuntu, NVIDIA GPU (driver >= 535), Docker with NVIDIA runtime, 30GB+ free cache space
- VPS: Contabo with Docker and Nginx installed, SSH alias `contabo` configured in `~/.ssh/config`
- Credentials: Cloudflare Tunnel token, AWS S3 credentials, HuggingFace token (optional)
