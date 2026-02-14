if command_exists helm; then
    log_warn "Helm is already installed, skipping install..."
else
    log_info "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_success "Helm installed"
fi

log_info "Adding Helm repositories..."
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
helm repo update

log_success "Helm repositories configured"
