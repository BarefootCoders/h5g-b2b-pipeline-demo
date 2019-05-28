"resource" "google_storage_bucket" "default-berlinsky-h5g-demo-prod" {
  "project" = "${local.prod_project_id}"

  "name" = "default-assets-berlinsky-h5g-demo-prod"

  "location" = "US"
}

"resource" "google_storage_bucket" "default-berlinsky-h5g-demo-nonprod" {
  "project" = "${local.nonprod_project_id}"

  "name" = "default-assets-berlinsky-h5g-demo-nonprod"

  "location" = "US"
}

"resource" "google_storage_bucket_object" "default-index-berlinsky-h5g-demo-prod" {
  "bucket" = "${google_storage_bucket.default-berlinsky-h5g-demo-prod.name}"

  "name" = "index.html"

  "content" = "<html></html>"
}

"resource" "google_storage_bucket_object" "default-index-berlinsky-h5g-demo-nonprod" {
  "bucket" = "${google_storage_bucket.default-berlinsky-h5g-demo-nonprod.name}"

  "name" = "index.html"

  "content" = "<html></html>"
}

"resource" "google_storage_default_object_access_control" "default-index-berlinsky-h5g-demo-prod" {
  "provider" = "google-beta"

  "bucket" = "${google_storage_bucket.default-berlinsky-h5g-demo-prod.name}"

  "role" = "READER"

  "entity" = "allUsers"
}

"resource" "google_storage_default_object_access_control" "default-index-berlinsky-h5g-demo-nonprod" {
  "provider" = "google-beta"

  "bucket" = "${google_storage_bucket.default-berlinsky-h5g-demo-nonprod.name}"

  "role" = "READER"

  "entity" = "allUsers"
}

"resource" "google_compute_backend_bucket" "default-berlinsky-h5g-demo-prod" {
  "lifecycle" = {
    "create_before_destroy" = true
  }

  "project" = "${local.prod_project_id}"

  "name" = "default-assets-berlinsky-h5g-demo-prod"

  "description" = "Contains default asset resources"

  "bucket_name" = "${google_storage_bucket.default-berlinsky-h5g-demo-prod.name}"

  "enable_cdn" = false
}

"resource" "google_compute_backend_bucket" "default-berlinsky-h5g-demo-nonprod" {
  "lifecycle" = {
    "create_before_destroy" = true
  }

  "project" = "${local.nonprod_project_id}"

  "name" = "default-assets-berlinsky-h5g-demo-nonprod"

  "description" = "Contains default asset resources"

  "bucket_name" = "${google_storage_bucket.default-berlinsky-h5g-demo-nonprod.name}"

  "enable_cdn" = false
}

"resource" "google_project_service" "compute-prod" {
  "project" = "berlinsky-h5g-demo-prod"

  "service" = "compute.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "iam-prod" {
  "project" = "${google_project_service.compute-prod.project}"

  "service" = "iam.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "cloudresourcemanager-prod" {
  "project" = "${google_project_service.iam-prod.project}"

  "service" = "cloudresourcemanager.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "compute-nonprod" {
  "project" = "berlinsky-h5g-demo-nonprod"

  "service" = "compute.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "iam-nonprod" {
  "project" = "${google_project_service.compute-nonprod.project}"

  "service" = "iam.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "cloudresourcemanager-nonprod" {
  "project" = "${google_project_service.iam-nonprod.project}"

  "service" = "cloudresourcemanager.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "tls_private_key" "stub-qa-integrations" {
  "algorithm" = "RSA"
}

"resource" "tls_self_signed_cert" "stub-qa-integrations" {
  "key_algorithm" = "${tls_private_key.stub-qa-integrations.algorithm}"

  "private_key_pem" = "${tls_private_key.stub-qa-integrations.private_key_pem}"

  "validity_period_hours" = 87600

  "allowed_uses" = ["key_encipherment", "digital_signature", "server_auth"]

  "dns_names" = ["*.qa.demo.h5g.clients.barefootcoders.com"]

  "subject" = {
    "common_name" = "new_deployment_stub_cert"

    "organization" = "High5 Games"
  }
}

"resource" "google_compute_ssl_certificate" "stub-qa-integrations" {
  "project" = "${local.nonprod_project_id}"

  "name_prefix" = "qa-certificate-"

  "private_key" = "${tls_private_key.stub-qa-integrations.private_key_pem}"

  "certificate" = "${tls_self_signed_cert.stub-qa-integrations.cert_pem}"

  "lifecycle" = {
    "create_before_destroy" = true
  }
}

"resource" "google_compute_ssl_policy" "qa" {
  "project" = "${local.nonprod_project_id}"

  "name" = "h5g-qa"

  "profile" = "MODERN"

  "min_tls_version" = "TLS_1_2"
}

"resource" "google_compute_global_address" "qa-integrations" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-integrations"
}

"resource" "google_dns_record_set" "qa-integrations" {
  "project" = "berlinsky-h5g-demo-dns"

  "name" = "*.qa.demo.h5g.clients.barefootcoders.com."

  "type" = "A"

  "ttl" = 300

  "managed_zone" = "berlinsky-h5g-demo-dns-zone"

  "rrdatas" = ["${google_compute_global_address.qa-integrations.address}"]
}

"resource" "google_compute_target_http_proxy" "qa-integrations" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-integrations"

  "url_map" = "${google_compute_url_map.qa-integrations.self_link}"
}

"resource" "google_compute_target_https_proxy" "qa-integrations" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-integrations"

  "url_map" = "${google_compute_url_map.qa-integrations.self_link}"

  "ssl_certificates" = ["${google_compute_ssl_certificate.stub-qa-integrations.self_link}"]

  "ssl_policy" = "${google_compute_ssl_policy.qa.self_link}"
}

"resource" "google_compute_global_forwarding_rule" "qa-integrations-http" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-integrations-http"

  "target" = "${google_compute_target_http_proxy.qa-integrations.self_link}"

  "ip_address" = "${google_compute_global_address.qa-integrations.address}"

  "port_range" = "80"
}

"resource" "google_compute_global_forwarding_rule" "qa-integrations-https" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-integrations-https"

  "target" = "${google_compute_target_https_proxy.qa-integrations.self_link}"

  "ip_address" = "${google_compute_global_address.qa-integrations.address}"

  "port_range" = "443"
}

"resource" "google_compute_url_map" "qa-integrations" {
  "project" = "${local.nonprod_project_id}"

  "default_service" = "${google_compute_backend_bucket.default-berlinsky-h5g-demo-nonprod.self_link}"

  "description" = "QA - Integrations - H5G B2B Pipeline"

  "host_rule" = {
    "hosts" = ["nyx.nj.qa.demo.h5g.clients.barefootcoders.com"]

    "path_matcher" = "nyx-nj"
  }

  "host_rule" = {
    "hosts" = ["pp.gib.qa.demo.h5g.clients.barefootcoders.com"]

    "path_matcher" = "pp-gib"
  }

  "name" = "qa-integrations"

  "path_matcher" = {
    "default_service" = "${google_compute_backend_bucket.default-berlinsky-h5g-demo-nonprod.self_link}"

    "name" = "nyx-nj"

    "path_rule" = {
      "paths" = ["/*"]

      "service" = "${module.integration-nyx-nj-nyx-nj-int-1-0-0-nonprod.google_backend_bucket_self_link}"
    }

    "path_rule" = {
      "paths" = ["/config/*"]

      "service" = "${module.integration-nyx-nj-config-nonprod.google_backend_bucket_self_link}"
    }
  }

  "path_matcher" = {
    "default_service" = "${google_compute_backend_bucket.default-berlinsky-h5g-demo-nonprod.self_link}"

    "name" = "pp-gib"

    "path_rule" = {
      "paths" = ["/*"]

      "service" = "${module.integration-pp-gib-gib-pp-int-1-0-0-nonprod.google_backend_bucket_self_link}"
    }

    "path_rule" = {
      "paths" = ["/config/*"]

      "service" = "${module.integration-pp-gib-config-nonprod.google_backend_bucket_self_link}"
    }
  }
}

"module" "game-gg-nyx-nj-1-0-0-prod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "gg"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "archived" = false

  "project_id" = "${local.prod_project_id}"

  "production" = true

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "game-gg-nyx-nj-1-0-0-nonprod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "gg"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "game-sotf-nyx-nj-1-0-0-prod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "sotf"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "archived" = false

  "project_id" = "${local.prod_project_id}"

  "production" = true

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "game-sotf-nyx-nj-1-0-0-nonprod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "sotf"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "game-gg-pp-gib-1-0-0-prod" {
  "bucket_location" = "EU"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "gg"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "archived" = false

  "project_id" = "${local.prod_project_id}"

  "production" = true

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "game-gg-pp-gib-1-0-0-nonprod" {
  "bucket_location" = "EU"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "gg"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "game-sotf-pp-gib-1-0-0-prod" {
  "bucket_location" = "EU"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "sotf"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "archived" = false

  "project_id" = "${local.prod_project_id}"

  "production" = true

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "game-sotf-pp-gib-1-0-0-nonprod" {
  "bucket_location" = "EU"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "sotf"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "game"
}

"module" "integration-nyx-nj-nyx-nj-int-1-0-0-prod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "nyx-nj-int"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "archived" = false

  "project_id" = "${local.prod_project_id}"

  "production" = true

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "integration"
}

"module" "integration-nyx-nj-nyx-nj-int-1-0-0-nonprod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "nyx-nj-int"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "integration"
}

"module" "integration-nyx-nj-config-prod" {
  "bucket_location" = "US"

  "project_id" = "${local.prod_project_id}"

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "production" = true

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-config-assets-frontend.git"

  "credentials_bucket" = "h5g-demo-config-manager-credentials"

  "credentials_path_prefix" = "credentials/prod/"
}

"module" "integration-nyx-nj-config-nonprod" {
  "bucket_location" = "US"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-config-assets-frontend.git"

  "credentials_bucket" = "h5g-demo-config-manager-credentials"

  "credentials_path_prefix" = "credentials/non_prod/"

  "production" = false
}

"module" "integration-pp-gib-gib-pp-int-1-0-0-prod" {
  "bucket_location" = "EU"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "gib-pp-int"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "archived" = false

  "project_id" = "${local.prod_project_id}"

  "production" = true

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "integration"
}

"module" "integration-pp-gib-gib-pp-int-1-0-0-nonprod" {
  "bucket_location" = "EU"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "gib-pp-int"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"

  "type" = "integration"
}

"module" "integration-pp-gib-config-prod" {
  "bucket_location" = "EU"

  "project_id" = "${local.prod_project_id}"

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "production" = true

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-config-assets-frontend.git"

  "credentials_bucket" = "h5g-demo-config-manager-credentials"

  "credentials_path_prefix" = "credentials/prod/"
}

"module" "integration-pp-gib-config-nonprod" {
  "bucket_location" = "EU"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "pp"

  "jurisdiction" = "gib"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-config-assets-frontend.git"

  "credentials_bucket" = "h5g-demo-config-manager-credentials"

  "credentials_path_prefix" = "credentials/non_prod/"

  "production" = false
}

"provider" "google" {}

"provider" "google-beta" {}

"terraform" "backend" "gcs" {
  "bucket" = "berlinsky-h5g-demo-tfstate"

  "prefix" = "tfstate"
}

"locals" = {
  "nonprod_project_id" = "${google_project_service.cloudresourcemanager-nonprod.project}"

  "prod_project_id" = "${google_project_service.cloudresourcemanager-prod.project}"
}