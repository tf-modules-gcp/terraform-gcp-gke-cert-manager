resource "random_string" "cert_manager_service_account_suffix" {
  upper   = false
  lower   = true
  special = false
  length  = 4
}
resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "tf-gke-${substr(var.sa_sufix, 0, min(15, length(var.sa_sufix)))}-${random_string.cert_manager_service_account_suffix.result}"
  display_name = format("Service account for Cert-manager %s", var.sa_sufix)
  description  = format("Service account for Cert-manager %s", var.sa_sufix)
}

resource "google_project_iam_member" "iam_member" {
  depends_on = [google_service_account.service_account]
  project    = var.project_id
  role       = "roles/dns.admin"
  member     = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_service_account_iam_member" "workloadIdentityUser" {
  depends_on = [
    google_project_iam_member.iam_member,
    helm_release.cert_manager
  ]
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = format("serviceAccount:%s.svc.id.goog[%s/%s]", var.project_id, kubernetes_namespace.cert_manager.id, lookup(lookup(yamldecode(helm_release.cert_manager.values[0]), "serviceAccount", {}), "name", "cert-manager"))
}
