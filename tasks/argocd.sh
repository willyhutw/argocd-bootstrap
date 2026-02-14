log_info "Installing ArgoCD..."

helm upgrade --install argocd argo/argo-cd \
    --namespace "$ARGOCD_NAMESPACE" \
    --create-namespace \
    --version "$ARGOCD_CHART_VERSION" \
    --set 'configs.params.server\.insecure=true' \
    --wait --timeout 5m

log_info "Creating ArgoCD Ingress with TLS..."
envsubst '$DOMAIN $ARGOCD_NAMESPACE' <"${SCRIPT_DIR}/resources/argocd-ingress.yml.tpl" | kubectl apply -f -

log_info "Waiting for TLS certificate to be issued..."
attempt=0
while [[ $attempt -lt 60 ]]; do
    ready=$(kubectl get certificate argocd-tls -n "$ARGOCD_NAMESPACE" \
        -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
    if [[ "$ready" == "True" ]]; then
        log_success "TLS certificate issued"
        break
    fi
    attempt=$((attempt + 1))
    echo -n "."
    sleep 5
done
echo ""

if [[ "$ready" != "True" ]]; then
    log_warn "Certificate not ready yet. Check: kubectl describe certificate argocd-tls -n $ARGOCD_NAMESPACE"
fi

# Print summary
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n "$ARGOCD_NAMESPACE" \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "N/A")
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "=========================================="
echo -e "${GREEN}  ArgoCD Bootstrap Complete!${NC}"
echo "=========================================="
echo ""
echo "  ArgoCD URL:      https://$DOMAIN"
echo "  Username:        admin"
echo "  Password:        $ARGOCD_PASSWORD"
echo "  Node IP:         $NODE_IP"
echo ""
echo "  DNS: Add A record '$DOMAIN' -> $NODE_IP (Proxy OFF)"
echo ""
echo "=========================================="
