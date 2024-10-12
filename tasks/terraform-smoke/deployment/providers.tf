terraform {
  backend "s3" {
    # Need to set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    bucket                      = "concourse-tf-state"
    key                         = "ci/concourse/bin-smoke"
    region                      = "fsn1"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://fsn1.your-objectstorage.com"
    }
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}
