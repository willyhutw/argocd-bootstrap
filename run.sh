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
    echo "Usage: $0 [--server <IP>] [--user <user>] [--task <k3s|helm|cert-manager|argocd>]"
    echo ""
    echo "Options:"
    echo "  --server <IP>    Target remote server IP (bootstraps over SSH instead of locally)"
    echo "  --user <user>    SSH user for remote server (required with --server)"
    echo "  --task <name>    Run a specific task only"
    echo ""
    echo "Run without --task to execute all tasks sequentially."
    echo ""
    echo "Examples:"
    echo "  sudo $0                                    # Run all tasks locally"
    echo "  sudo $0 --task k3s                        # Install K3s only (local)"
    echo "  $0 --server 192.168.1.10                  # Run all tasks on remote server"
    echo "  $0 --server 192.168.1.10 --user ubuntu    # Remote with custom SSH user"
    echo "  $0 --server 192.168.1.10 --task argocd    # Remote, single task"
    exit 1
}

# ============== PRE-FLIGHT CHECKS ==============
preflight_checks() {
    log_info "Running pre-flight checks..."

    if [[ -n "$SERVER_IP" ]]; then
        log_info "Remote mode: checking SSH connectivity to ${SERVER_USER}@${SERVER_IP}..."
        if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${SERVER_USER}@${SERVER_IP}" exit 2>/dev/null; then
            log_error "Cannot connect to ${SERVER_USER}@${SERVER_IP} via SSH. Ensure key-based auth is configured."
        fi
    else
        if [[ $EUID -ne 0 ]]; then
            log_error "This script must be run as root or with sudo (or use --server for remote mode)"
        fi
    fi

    if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        log_error "CLOUDFLARE_API_TOKEN is not set. Export it before running."
    fi

    if [[ -z "${ACME_EMAIL:-}" ]]; then
        log_error "ACME_EMAIL is not set. Add it to .envrc."
    fi

    log_success "Pre-flight checks passed"
}

# ============== REMOTE KUBECONFIG ==============
setup_remote_kubeconfig() {
    mkdir -p "$(dirname "${LOCAL_KUBECONFIG}")"
    ssh "${SERVER_USER}@${SERVER_IP}" 'sudo cat /etc/rancher/k3s/k3s.yaml' \
        | sed "s|https://127.0.0.1:6443|https://${SERVER_IP}:6443|g" \
        > "${LOCAL_KUBECONFIG}"
    chmod 600 "${LOCAL_KUBECONFIG}"
    export KUBECONFIG="${LOCAL_KUBECONFIG}"
    log_info "Remote kubeconfig saved to ${LOCAL_KUBECONFIG}"
}

# ============== MAIN ==============
TASKS=(k3s helm cert-manager argocd)

SERVER_IP=""
SERVER_USER=""
TASK=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)   usage ;;
        --server)    SERVER_IP="$2";   shift 2 ;;
        --user)      SERVER_USER="$2"; shift 2 ;;
        --task)      TASK="$2";        shift 2 ;;
        *)           echo "Unknown argument: $1"; usage ;;
    esac
done

if [[ -n "$SERVER_IP" && -z "$SERVER_USER" ]]; then
    echo "Error: --user is required when --server is specified"
    usage
fi

export SERVER_IP SERVER_USER

preflight_checks

if [[ -n "$TASK" ]]; then
    if [[ ! -f "${SCRIPT_DIR}/tasks/${TASK}.sh" ]]; then
        log_error "Task '${TASK}' not found"
    fi
    # For non-k3s tasks in remote mode, fetch kubeconfig upfront
    if [[ -n "$SERVER_IP" && "$TASK" != "k3s" ]]; then
        setup_remote_kubeconfig
    elif [[ -z "$SERVER_IP" ]]; then
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    fi
    source "${SCRIPT_DIR}/tasks/${TASK}.sh"
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
