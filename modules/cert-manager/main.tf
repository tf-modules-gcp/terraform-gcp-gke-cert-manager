resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = var.helm_config.namespace
  }
}
resource "helm_release" "cert_manager" {
  depends_on = [
    kubernetes_namespace.cert_manager,
    google_project_iam_member.iam_member
  ]
  chart      = "cert-manager"
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = var.helm_config.chart.repository
  version    = var.helm_config.chart.version
  timeout    = 600
  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = google_service_account.service_account.email
    type  = "string"
  }

  values = [for s in var.helm_config.chart.values_files : file("${local.environment_dir}/${s}")]
}

resource "kubectl_manifest" "cert-manager-cluster-issuer" {
  depends_on      = [
    helm_release.cert_manager
  ]
  for_each = var.clusterIssuers
  validate_schema = false
  yaml_body = templatefile("${path.module}/manifests/cert-manager-cluster-issuer.tmpl.yml", {
    clusterIssueName        = each.key
    acmeServer              = each.value.acmeServer
    privateKeySecretRefName = each.value.privateKeySecretRefName
    dnsZone                 = each.value.dnsZone
    project                 = each.value.project
  })
}