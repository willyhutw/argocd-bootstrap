if [[ -n "${SERVER_IP:-}" ]]; then
    if ssh "${SERVER_USER}@${SERVER_IP}" 'command -v kubectl &>/dev/null && sudo kubectl get nodes &>/dev/null' 2>/dev/null; then
        log_warn "K3s already installed on ${SERVER_IP}, skipping..."
    else
        log_info "Installing K3s on ${SERVER_IP}..."
        ssh "${SERVER_USER}@${SERVER_IP}" 'curl -sfL https://get.k3s.io | sudo sh -'
        log_info "Waiting for K3s to be ready on ${SERVER_IP}..."
        sleep 10
        until ssh "${SERVER_USER}@${SERVER_IP}" 'sudo kubectl get nodes &>/dev/null'; do
            sleep 5
        done
        log_success "K3s installed on ${SERVER_IP}"
    fi
    # Fetch and patch kubeconfig for local use
    mkdir -p "$(dirname "${LOCAL_KUBECONFIG}")"
    ssh "${SERVER_USER}@${SERVER_IP}" 'sudo cat /etc/rancher/k3s/k3s.yaml' \
        | sed "s|https://127.0.0.1:6443|https://${SERVER_IP}:6443|g" \
        > "${LOCAL_KUBECONFIG}"
    chmod 600 "${LOCAL_KUBECONFIG}"
    export KUBECONFIG="${LOCAL_KUBECONFIG}"
    log_info "Remote kubeconfig saved to ${LOCAL_KUBECONFIG}"
    return 0
fi

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
cp /etc/rancher/k3s/k3s.yaml "$KUBE_DIR/k3s"

if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$KUBE_DIR"
fi

chmod 600 "$KUBE_DIR/k3s"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

log_success "K3s installed"
