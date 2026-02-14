log_info "Installing cert-manager..."

helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace "$CERTMANAGER_NAMESPACE" \
    --create-namespace \
    --version "$CERTMANAGER_CHART_VERSION" \
    --set crds.enabled=true \
    --wait

log_info "Configuring Cloudflare API token secret..."
kubectl create secret generic cloudflare-api-token \
    --namespace "$CERTMANAGER_NAMESPACE" \
    --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -

log_info "Applying ClusterIssuer..."
envsubst '$ACME_EMAIL' <"${SCRIPT_DIR}/resources/cluster-issuer-prod.yml.tpl" | kubectl apply -f -

log_success "cert-manager and ClusterIssuer configured"
