# Deploy Cert-manager in GKE

## Example configuration

Terraform code

Variable "environment_dir" should be pointed to the directory where the helm values files located

```bash
module "cert_manager" {
  depends_on = [
    module.gke
  ]
  source  = "git::https://github.com/tf-modules-gcp/terraform-gcp-gke-cert-manager.git//modules/cert-manager?ref=0.0.1"
  environment_dir = var.environment_dir
  sa_sufix        = var.gke.cluster.name
  gke_project_id  = var.gcp.gke_project_id
  dns_project_id  = var.gcp.dns_project_id
  helm_config     = {
    namespace = "cert-manager"
    chart = {
      repository  = "https://charts.jetstack.io"
      version     = "1.13.2"
      values_file = "helm_values_cert_manager.yml"
    }
  }
  clusterIssuers  = {
    letsencrypt-prod = {
      acmeServer: "https://acme-v02.api.letsencrypt.org/directory",
      dnsZone: "example.com",
      privateKeySecretRefName: "letsencrypt-prod",
      project: "gcp-project-id"
    }
  }
}
```

Helm chart values file: helm_values_cert_manager.yml

```yaml
---
cainjector:
  tolerations: &id001
  - effect: NoSchedule
    key: kubernetes.io/arch
    operator: Equal
    value: arm64
ingressShim:
  defaultIssuerKind: ClusterIssuer
  defaultIssuerName: letsencrypt-prod
installCRDs: true
startupapicheck:
  tolerations: *id001
tolerations: *id001
webhook:
  tolerations: *id001
```
