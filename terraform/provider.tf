terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    tls = {
    source  = "hashicorp/tls"
    version = "~> 4.0" # Explicitly declares the TLS provider
    }

    local = {
    source  = "hashicorp/local"
    version = "~> 2.0" # Required for local_sensitive_file
    }

  }
  required_version = ">= 1.4.0"
}
