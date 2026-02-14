#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============== HELPER FUNCTIONS ==============
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

command_exists() {
    command -v "$1" &>/dev/null
}

# ============== USAGE ==============
usage() {
    echo "Usage: sudo $0 [--task <k3s|helm|cert-manager|argocd>]"
    echo ""
    echo "Run without --task to execute all tasks sequentially."
    echo ""
    echo "Examples:"
    echo "  sudo $0                       # Run all tasks"
    echo "  sudo $0 --task k3s            # Install K3s only"
    echo "  sudo $0 --task helm           # Install Helm only"
    echo "  sudo $0 --task cert-manager   # Install cert-manager only"
    echo "  sudo $0 --task argocd         # Install ArgoCD only"
    exit 1
}

# ============== PRE-FLIGHT CHECKS ==============
preflight_checks() {
    log_info "Running pre-flight checks..."

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
    fi

    if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        log_error "CLOUDFLARE_API_TOKEN is not set. Export it before running."
    fi

    if [[ "$ACME_EMAIL" == "your-email@example.com" ]]; then
        log_error "Please set your email address in config.env"
    fi

    log_success "Pre-flight checks passed"
}

# ============== MAIN ==============
TASKS=(k3s helm cert-manager argocd)

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
fi

preflight_checks

if [[ "${1:-}" == "--task" ]]; then
    if [[ -z "${2:-}" || ! -f "${SCRIPT_DIR}/tasks/${2}.sh" ]]; then
        log_error "Task '${2:-}' not found"
    fi
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    source "${SCRIPT_DIR}/tasks/${2}.sh"
elif [[ -n "${1:-}" ]]; then
    echo "Unknown argument: $1"
    usage
else
    echo ""
    echo "=========================================="
    echo "  ArgoCD Bootstrap"
    echo "=========================================="
    echo ""
    for task in "${TASKS[@]}"; do
        source "${SCRIPT_DIR}/tasks/${task}.sh"
    done
fi
