"resource" "google_storage_bucket" "default-rmg-assets" {
  "project" = "${local.prod_project_id}"

  "name" = "default-game-assets-rmg-assets"

  "location" = "US"
}

"resource" "google_storage_bucket" "default-rmg-assets-test" {
  "project" = "${local.nonprod_project_id}"

  "name" = "default-game-assets-rmg-assets-test"

  "location" = "US"
}

"resource" "google_storage_bucket_object" "default-index-rmg-assets" {
  "bucket" = "${google_storage_bucket.default-rmg-assets.name}"

  "name" = "index.html"

  "content" = "<html></html>"
}

"resource" "google_storage_bucket_object" "default-index-rmg-assets-test" {
  "bucket" = "${google_storage_bucket.default-rmg-assets-test.name}"

  "name" = "index.html"

  "content" = "<html></html>"
}

"resource" "google_storage_default_object_access_control" "default-index-rmg-assets" {
  "provider" = "google-beta"

  "bucket" = "${google_storage_bucket.default-rmg-assets.name}"

  "role" = "READER"

  "entity" = "allUsers"
}

"resource" "google_storage_default_object_access_control" "default-index-rmg-assets-test" {
  "provider" = "google-beta"

  "bucket" = "${google_storage_bucket.default-rmg-assets-test.name}"

  "role" = "READER"

  "entity" = "allUsers"
}

"resource" "google_compute_backend_bucket" "default-rmg-assets" {
  "lifecycle" = {
    "create_before_destroy" = true
  }

  "project" = "${local.prod_project_id}"

  "name" = "default-game-assets-rmg-assets"

  "description" = "Contains default game asset resources"

  "bucket_name" = "${google_storage_bucket.default-rmg-assets.name}"

  "enable_cdn" = false
}

"resource" "google_compute_backend_bucket" "default-rmg-assets-test" {
  "lifecycle" = {
    "create_before_destroy" = true
  }

  "project" = "${local.nonprod_project_id}"

  "name" = "default-game-assets-rmg-assets-test"

  "description" = "Contains default game asset resources"

  "bucket_name" = "${google_storage_bucket.default-rmg-assets-test.name}"

  "enable_cdn" = false
}

"resource" "google_project_service" "compute-prod" {
  "project" = "rmg-assets"

  "service" = "compute.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "cloudresourcemanager-prod" {
  "project" = "${google_project_service.compute-prod.project}"

  "service" = "cloudresourcemanager.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "compute-nonprod" {
  "project" = "rmg-assets-test"

  "service" = "compute.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "google_project_service" "cloudresourcemanager-nonprod" {
  "project" = "${google_project_service.compute-nonprod.project}"

  "service" = "cloudresourcemanager.googleapis.com"

  "disable_on_destroy" = false
}

"resource" "tls_private_key" "stub-qa" {
  "algorithm" = "RSA"
}

"resource" "tls_private_key" "stub-int-test" {
  "algorithm" = "RSA"
}

"resource" "tls_private_key" "stub-stage" {
  "algorithm" = "RSA"
}

"resource" "tls_self_signed_cert" "stub-qa" {
  "key_algorithm" = "${tls_private_key.stub-qa.algorithm}"

  "private_key_pem" = "${tls_private_key.stub-qa.private_key_pem}"

  "validity_period_hours" = 87600

  "allowed_uses" = ["key_encipherment", "digital_signature", "server_auth"]

  "dns_names" = ["*.qa.games.h5grgs.com"]

  "subject" = {
    "common_name" = "new_deployment_stub_cert"

    "organization" = "High5 Games"
  }
}

"resource" "tls_self_signed_cert" "stub-int-test" {
  "key_algorithm" = "${tls_private_key.stub-int-test.algorithm}"

  "private_key_pem" = "${tls_private_key.stub-int-test.private_key_pem}"

  "validity_period_hours" = 87600

  "allowed_uses" = ["key_encipherment", "digital_signature", "server_auth"]

  "dns_names" = ["*.int-test.games.h5grgs.com"]

  "subject" = {
    "common_name" = "new_deployment_stub_cert"

    "organization" = "High5 Games"
  }
}

"resource" "tls_self_signed_cert" "stub-stage" {
  "key_algorithm" = "${tls_private_key.stub-stage.algorithm}"

  "private_key_pem" = "${tls_private_key.stub-stage.private_key_pem}"

  "validity_period_hours" = 87600

  "allowed_uses" = ["key_encipherment", "digital_signature", "server_auth"]

  "dns_names" = ["*.stage.games.h5grgs.com"]

  "subject" = {
    "common_name" = "new_deployment_stub_cert"

    "organization" = "High5 Games"
  }
}

"resource" "google_compute_ssl_certificate" "stub-qa" {
  "project" = "${local.nonprod_project_id}"

  "name_prefix" = "qa-certificate-"

  "private_key" = "${tls_private_key.stub-qa.private_key_pem}"

  "certificate" = "${tls_self_signed_cert.stub-qa.cert_pem}"

  "lifecycle" = {
    "create_before_destroy" = true
  }
}

"resource" "google_compute_ssl_certificate" "stub-int-test" {
  "project" = "${local.nonprod_project_id}"

  "name_prefix" = "int-test-certificate-"

  "private_key" = "${tls_private_key.stub-int-test.private_key_pem}"

  "certificate" = "${tls_self_signed_cert.stub-int-test.cert_pem}"

  "lifecycle" = {
    "create_before_destroy" = true
  }
}

"resource" "google_compute_ssl_certificate" "stub-stage" {
  "project" = "${local.prod_project_id}"

  "name_prefix" = "stage-certificate-"

  "private_key" = "${tls_private_key.stub-stage.private_key_pem}"

  "certificate" = "${tls_self_signed_cert.stub-stage.cert_pem}"

  "lifecycle" = {
    "create_before_destroy" = true
  }
}

"resource" "google_compute_url_map" "qa-games" {
  "project" = "${local.nonprod_project_id}"

  "default_service" = "${google_compute_backend_bucket.default-rmg-assets-test.self_link}"

  "description" = "QA - Games - H5G B2B Pipeline"

  "host_rule" = {
    "hosts" = ["nj-nyx.qa.games.h5grgs.com"]

    "path_matcher" = "nj-nyx"
  }

  "name" = "qa-games"

  "path_matcher" = {
    "default_service" = "${google_compute_backend_bucket.default-rmg-assets-test.self_link}"

    "name" = "nj-nyx"

    "path_rule" = {
      "paths" = ["/test/*"]

      "service" = "${module.test-1-0-0-nonprod.google_backend_bucket_self_link}"
    }
  }
}

"resource" "google_compute_url_map" "int-test-games" {
  "project" = "${local.nonprod_project_id}"

  "default_service" = "${google_compute_backend_bucket.default-rmg-assets-test.self_link}"

  "description" = "INT_TEST - Games - H5G B2B Pipeline"

  "host_rule" = {
    "hosts" = ["nj-nyx.int-test.games.h5grgs.com"]

    "path_matcher" = "nj-nyx"
  }

  "name" = "int-test-games"

  "path_matcher" = {
    "default_service" = "${google_compute_backend_bucket.default-rmg-assets-test.self_link}"

    "name" = "nj-nyx"

    "path_rule" = {
      "paths" = ["/test/*"]

      "service" = "${module.test-1-0-0-nonprod.google_backend_bucket_self_link}"
    }
  }
}

"resource" "google_compute_url_map" "stage-games" {
  "project" = "${local.prod_project_id}"

  "default_service" = "${google_compute_backend_bucket.default-rmg-assets.self_link}"

  "description" = "STAGE - Games - H5G B2B Pipeline"

  "host_rule" = {
    "hosts" = ["nj-nyx.stage.games.h5grgs.com"]

    "path_matcher" = "nj-nyx"
  }

  "name" = "stage-games"

  "path_matcher" = {
    "default_service" = "${google_compute_backend_bucket.default-rmg-assets.self_link}"

    "name" = "nj-nyx"

    "path_rule" = {
      "paths" = ["/test/*"]

      "service" = "${module.test-1-0-0-prod.google_backend_bucket_self_link}"
    }
  }
}

"resource" "google_compute_ssl_policy" "qa" {
  "project" = "${local.nonprod_project_id}"

  "name" = "h5g-qa"

  "profile" = "MODERN"

  "min_tls_version" = "TLS_1_2"
}

"resource" "google_compute_ssl_policy" "int-test" {
  "project" = "${local.nonprod_project_id}"

  "name" = "h5g-int-test"

  "profile" = "MODERN"

  "min_tls_version" = "TLS_1_2"
}

"resource" "google_compute_ssl_policy" "stage" {
  "project" = "${local.prod_project_id}"

  "name" = "h5g-stage"

  "profile" = "MODERN"

  "min_tls_version" = "TLS_1_2"
}

"resource" "google_compute_global_address" "qa-games" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-games"
}

"resource" "google_compute_global_address" "int-test-games" {
  "project" = "${local.nonprod_project_id}"

  "name" = "int-test-games"
}

"resource" "google_compute_global_address" "stage-games" {
  "project" = "${local.prod_project_id}"

  "name" = "stage-games"
}

"resource" "google_dns_record_set" "qa-games" {
  "project" = "h5g-infrastructure"

  "name" = "*.qa.games.h5grgs.com."

  "type" = "A"

  "ttl" = 300

  "managed_zone" = "h5grgs-com"

  "rrdatas" = ["${google_compute_global_address.qa-games.address}"]
}

"resource" "google_dns_record_set" "int-test-games" {
  "project" = "h5g-infrastructure"

  "name" = "*.int-test.games.h5grgs.com."

  "type" = "A"

  "ttl" = 300

  "managed_zone" = "h5grgs-com"

  "rrdatas" = ["${google_compute_global_address.int-test-games.address}"]
}

"resource" "google_dns_record_set" "stage-games" {
  "project" = "h5g-infrastructure"

  "name" = "*.stage.games.h5grgs.com."

  "type" = "A"

  "ttl" = 300

  "managed_zone" = "h5grgs-com"

  "rrdatas" = ["${google_compute_global_address.stage-games.address}"]
}

"resource" "google_compute_target_http_proxy" "qa-games" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-games"

  "url_map" = "${google_compute_url_map.qa-games.self_link}"
}

"resource" "google_compute_target_http_proxy" "int-test-games" {
  "project" = "${local.nonprod_project_id}"

  "name" = "int-test-games"

  "url_map" = "${google_compute_url_map.int-test-games.self_link}"
}

"resource" "google_compute_target_http_proxy" "stage-games" {
  "project" = "${local.prod_project_id}"

  "name" = "stage-games"

  "url_map" = "${google_compute_url_map.stage-games.self_link}"
}

"resource" "google_compute_target_https_proxy" "qa-games" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-games"

  "url_map" = "${google_compute_url_map.qa-games.self_link}"

  "ssl_certificates" = ["${google_compute_ssl_certificate.stub-qa.self_link}"]

  "ssl_policy" = "${google_compute_ssl_policy.qa.self_link}"
}

"resource" "google_compute_target_https_proxy" "int-test-games" {
  "project" = "${local.nonprod_project_id}"

  "name" = "int-test-games"

  "url_map" = "${google_compute_url_map.int-test-games.self_link}"

  "ssl_certificates" = ["${google_compute_ssl_certificate.stub-int-test.self_link}"]

  "ssl_policy" = "${google_compute_ssl_policy.int-test.self_link}"
}

"resource" "google_compute_target_https_proxy" "stage-games" {
  "project" = "${local.prod_project_id}"

  "name" = "stage-games"

  "url_map" = "${google_compute_url_map.stage-games.self_link}"

  "ssl_certificates" = ["${google_compute_ssl_certificate.stub-stage.self_link}"]

  "ssl_policy" = "${google_compute_ssl_policy.stage.self_link}"
}

"resource" "google_compute_global_forwarding_rule" "qa-games-http" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-games-http"

  "target" = "${google_compute_target_http_proxy.qa-games.self_link}"

  "ip_address" = "${google_compute_global_address.qa-games.address}"

  "port_range" = "80"
}

"resource" "google_compute_global_forwarding_rule" "qa-games-https" {
  "project" = "${local.nonprod_project_id}"

  "name" = "qa-games-https"

  "target" = "${google_compute_target_https_proxy.qa-games.self_link}"

  "ip_address" = "${google_compute_global_address.qa-games.address}"

  "port_range" = "443"
}

"resource" "google_compute_global_forwarding_rule" "int-test-games-http" {
  "project" = "${local.nonprod_project_id}"

  "name" = "int-test-games-http"

  "target" = "${google_compute_target_http_proxy.int-test-games.self_link}"

  "ip_address" = "${google_compute_global_address.int-test-games.address}"

  "port_range" = "80"
}

"resource" "google_compute_global_forwarding_rule" "int-test-games-https" {
  "project" = "${local.nonprod_project_id}"

  "name" = "int-test-games-https"

  "target" = "${google_compute_target_https_proxy.int-test-games.self_link}"

  "ip_address" = "${google_compute_global_address.int-test-games.address}"

  "port_range" = "443"
}

"resource" "google_compute_global_forwarding_rule" "stage-games-http" {
  "project" = "${local.prod_project_id}"

  "name" = "stage-games-http"

  "target" = "${google_compute_target_http_proxy.stage-games.self_link}"

  "ip_address" = "${google_compute_global_address.stage-games.address}"

  "port_range" = "80"
}

"resource" "google_compute_global_forwarding_rule" "stage-games-https" {
  "project" = "${local.prod_project_id}"

  "name" = "stage-games-https"

  "target" = "${google_compute_target_https_proxy.stage-games.self_link}"

  "ip_address" = "${google_compute_global_address.stage-games.address}"

  "port_range" = "443"
}

"module" "test-1-0-0-prod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "test"

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
}

"module" "test-1-0-0-nonprod" {
  "bucket_location" = "US"

  "nexus_group_id" = "com.google.h5g.demo"

  "nexus_artifact_id" = "test"

  "nexus_artifact_version" = "1.0.0"

  "nexus_username" = "temp-b2b-for-asset-load"

  "nexus_password" = "JBHigh52019$$$%"

  "nexus_host" = "http://35.193.73.84"

  "nexus_repository" = "berlinsky-h5g-demo"

  "project_id" = "${local.nonprod_project_id}"

  "integrator" = "nyx"

  "jurisdiction" = "nj"

  "source" = "git::ssh://git@10.55.10.200:7999/bbin/terraform-module-h5g-game-assets-frontend.git"
}

"provider" "google" {}

"provider" "google-beta" {}

"terraform" "backend" "gcs" {
  "bucket" = "b2b-pipeline-demo-tfstate"

  "prefix" = "tfstate"
}

"locals" = {
  "nonprod_project_id" = "${google_project_service.cloudresourcemanager-nonprod.project}"

  "prod_project_id" = "${google_project_service.cloudresourcemanager-prod.project}"
}