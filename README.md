# ArgoCD Bootstrap

Bootstrap script for setting up K3s with ArgoCD, cert-manager, and Let's Encrypt (Cloudflare DNS-01) on a single server.

## Prerequisites

- A Linux server (Debian/Ubuntu)
- A Cloudflare-managed domain
- A Cloudflare API token with DNS edit permissions

## Configuration

Edit `config.env` with your settings:

```bash
export DOMAIN="argocd.example.com"
export ACME_EMAIL="your-email@example.com"
export ARGOCD_NAMESPACE="argocd"
export ARGOCD_CHART_VERSION="9.3.7"
export CERTMANAGER_NAMESPACE="cert-manager"
export CERTMANAGER_CHART_VERSION="v1.17.2"
```

## Usage

Run all tasks:

```bash
sudo CLOUDFLARE_API_TOKEN=<your-token> ./run.sh
```

Run a specific task:

```bash
sudo CLOUDFLARE_API_TOKEN=<your-token> ./run.sh --task <task-name>
```

Available tasks: `k3s`, `helm`, `cert-manager`, `argocd`

## Tasks

| Task | Description |
|------|-------------|
| `k3s` | Install K3s and configure kubeconfig |
| `helm` | Install Helm and add chart repositories |
| `cert-manager` | Install cert-manager, configure Cloudflare secret and ClusterIssuer |
| `argocd` | Install ArgoCD, create Ingress with TLS, wait for certificate |

## Project Structure

```
argocd-bootstrap/
├── config.env              # Configuration (domain, versions, etc.)
├── run.sh                  # Entry point
├── tasks/
│   ├── k3s.sh
│   ├── helm.sh
│   ├── cert-manager.sh
│   └── argocd.sh
└── resources/
    ├── cluster-issuer-prod.yml.tpl
    └── argocd-ingress.yml.tpl
```
