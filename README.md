# ArgoCD Bootstrap

Bootstrap script for setting up K3s with ArgoCD, cert-manager, and Let's Encrypt (Cloudflare DNS-01) on a single server. Supports both local execution (with `sudo`) and remote execution over SSH.

## Prerequisites

- A Linux server (Debian/Ubuntu)
- A Cloudflare-managed domain
- A Cloudflare API token with DNS edit permissions
- For remote mode: passwordless SSH key access to the target server
- [direnv](https://direnv.net/) (recommended) for managing secrets via `.envrc`

## Configuration

### Secrets (`.envrc`)

Copy `.envrc.example` to `.envrc` and fill in your values:

```bash
cp .envrc.example .envrc
```

```bash
export CLOUDFLARE_API_TOKEN=""   # Cloudflare API token with DNS edit permissions
export DOMAIN="argocd.example.com"
export ACME_EMAIL="your-email@example.com"
```

Then allow direnv to load it:

```bash
direnv allow
```

`.envrc` is gitignored and will never be committed.

### Versions (`config.env`)

Edit `config.env` to pin chart versions:

```bash
export ARGOCD_NAMESPACE="argocd"
export ARGOCD_CHART_VERSION="9.4.3"
export CERTMANAGER_NAMESPACE="cert-manager"
export CERTMANAGER_CHART_VERSION="v1.19.3"
```

## Usage

### Local mode

Run all tasks on the current machine (requires root):

```bash
sudo CLOUDFLARE_API_TOKEN=<your-token> ./run.sh
```

Run a specific task:

```bash
sudo CLOUDFLARE_API_TOKEN=<your-token> ./run.sh --task <task-name>
```

### Remote mode

Run all tasks on a remote server over SSH (`--user` is required):

```bash
CLOUDFLARE_API_TOKEN=<your-token> ./run.sh --server 192.168.1.10 --user ubuntu
```

Run a specific task remotely:

```bash
CLOUDFLARE_API_TOKEN=<your-token> ./run.sh --server 192.168.1.10 --user ubuntu --task argocd
```

In remote mode, k3s is installed on the target server over SSH. The kubeconfig is fetched from the remote server and patched to use the server's IP, so all subsequent `helm` and `kubectl` commands run locally against the remote cluster.

### Options

| Flag | Description |
|------|-------------|
| `--server <IP>` | Target remote server IP (SSH mode) |
| `--user <user>` | SSH user for remote server (required with `--server`) |
| `--task <name>` | Run a specific task only |

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
