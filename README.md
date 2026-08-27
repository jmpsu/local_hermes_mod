# local_hermes_mod

Portable Local + Edge/Cloud Infrastructure for a Privacy-First AI Ecosystem.

## Architecture

- **Local Compute Node**: Ubuntu Linux (x86_64), Docker Engine, NVIDIA Container Toolkit, vLLM Engine (Qwen/Qwen2.5-32B-Instruct-AWQ or hardware-bounded alternative)
- **Public Gateway Node**: Contabo VPS, Nginx Reverse Proxy (500MB payload), Open WebUI, Qdrant Vector DB
- **Network & Storage**: Cloudflare Tunnels, Cloudflare Edge Rules, Amazon S3 backups

## Activation

```bash
# Clone repository
git clone git@github.com:YOUR_USERNAME/local_hermes_mod.git
cd local_hermes_mod

# Run the autonomous deployer
chmod +x deploy.sh
./deploy.sh
```

The deployer will:
1. Crawl and self-heal the local machine (GPU, Docker, storage)
2. Audit SSH connectivity and scan VPS for Jellyfin port
3. Prompt for domain, Cloudflare token, and AWS credentials
4. Run dry-run validation on all generated configs
5. Deploy configs to Contabo VPS and reload Nginx
6. Launch local vLLM + Cloudflare tunnel containers

## Endpoints (post-deployment)

| Service | URL |
|---------|-----|
| AI Interface | `http://YOUR_DOMAIN/ai/` |
| Jellyfin Media | `http://YOUR_DOMAIN/media/` |

## File Structure

```
local_hermes_mod/
├── .gitignore
├── deploy.sh
├── README.md
├── TUNNEL.md              ← source of truth for Cloudflare Tunnel ingress rules
├── templates/
│   ├── docker-compose.local.template
│   ├── docker-compose.vps.template
│   ├── nginx.template
│   ├── index.template
│   └── s3-sync.template.sh
└── core/                  ← generated at runtime, git-ignored
```

## Prerequisites

- Local: x86_64 Ubuntu, NVIDIA GPU (driver >= 535), Docker with NVIDIA runtime, 30GB+ free cache space
- VPS: Contabo with Docker and Nginx installed, SSH alias `contabo` configured in `~/.ssh/config`
- Credentials: Cloudflare Tunnel token, AWS S3 credentials, HuggingFace token (optional)
