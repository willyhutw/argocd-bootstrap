if command_exists kubectl && kubectl get nodes &>/dev/null; then
    log_warn "K3s is already installed, skipping..."
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    return 0
fi

log_info "Installing K3s..."
curl -sfL https://get.k3s.io | sh -

log_info "Waiting for K3s to be ready..."
sleep 10
until kubectl get nodes &>/dev/null; do
    sleep 5
done

# Setup kubeconfig for non-root user
SUDO_USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
KUBE_DIR="$SUDO_USER_HOME/.kube"

mkdir -p "$KUBE_DIR"
cp /etc/rancher/k3s/k3s.yaml "$KUBE_DIR/config"

if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$KUBE_DIR"
fi

chmod 600 "$KUBE_DIR/config"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

log_success "K3s installed"
