resource tls_private_key coreint_ca {
  algorithm = "ECDSA"
}

resource tls_self_signed_cert coreint_ca {
  private_key_pem = tls_private_key.coreint_ca.private_key_pem

  validity_period_hours = 24 * 365 * 10
  early_renewal_hours   = 2 * 24 * 30

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  subject {
    common_name         = "coreint-ca"
    organization        = "New Relic"
    organizational_unit = "Core integrations"
  }
}

resource tls_private_key ssh_client {
  algorithm = "ECDSA"
}


output tls_ca_and_ssh_keys {
  value = {
    tls_self_signed_cert = {
      coreint_ca = {
        cert_pem = tls_self_signed_cert.coreint_ca.cert_pem
      }
    }
    tls_private_key = {
      ssh_client = {
        public_key_openssh = tls_private_key.ssh_client.public_key_openssh
        public_key_pem     = tls_private_key.ssh_client.public_key_pem
      }
    }
  }
}


output sensitive__tls_ca_and_ssh_keys {
  sensitive = true
  value = {
    tls_private_key = {
      ssh_client = {
        private_key_pem = tls_private_key.ssh_client.private_key_pem
      }
    }
  }
}
