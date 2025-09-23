# Create KMS Key Rings
resource "google_kms_key_ring" "key_rings" {
  for_each = var.kms_key_rings

  name       = each.key
  location   = each.value.location
  depends_on = [google_project_service.required_apis]
}

# Create KMS Keys
resource "google_kms_crypto_key" "keys" {
  for_each = var.kms_keys

  name            = each.key
  key_ring        = google_kms_key_ring.key_rings[each.value.key_ring_name].id
  rotation_period = each.value.rotation_period

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
}

# Create dedicated KMS key for GAR encryption
resource "google_kms_crypto_key" "gar_encryption_key" {
  name     = "gar-kms"
  key_ring = google_kms_key_ring.key_rings["main"].id

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  labels = {
    purpose = "gar-encryption"
    service = "artifact-registry"
  }
}